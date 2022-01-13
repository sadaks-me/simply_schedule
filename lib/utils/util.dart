import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide AndroidOptions;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:ical/serializer.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pigment/pigment.dart';
import 'package:schedule/models/event_info.dart';
import 'package:schedule/screens/home_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../secrets.dart';
import 'calendar_client.dart';

var credBox = Hive.box('credential_box');
var eventBox = Hive.box('event_box');
var _clientID = ClientId(
    Platform.isAndroid ? Secret.ANDROID_CLIENT_ID : Secret.IOS_CLIENT_ID, "");
const _scopes = [cal.CalendarApi.calendarScope];

extension TimeOfDayExtension on TimeOfDay {
  TimeOfDay plusMinutes(int minutes) {
    if (minutes == 0) {
      return this;
    } else {
      int mofd = hour * 60 + minute;
      int newMofd = ((minutes % 1440) + mofd + 1440) % 1440;
      if (mofd == newMofd) {
        return this;
      } else {
        int newHour = newMofd ~/ 60;
        int newMinute = newMofd % 60;
        return TimeOfDay(hour: newHour, minute: newMinute);
      }
    }
  }

  TimeOfDay roundMinutes() {
    if (minute < 30) {
      return replacing(hour: hour, minute: 30);
    } else {
      return replacing(hour: hour + 1, minute: 0);
    }
  }
}

Future clientLogin() async {
  await clientViaUserConsent(_clientID, _scopes, openBrowser)
      .then((client) async {
    client.credentialUpdates.listen((AccessCredentials credentials) {
      credBox.put("credentials", jsonEncode(credentialsToJson(credentials)));
    });
    credBox.put(
        "credentials", jsonEncode(credentialsToJson(client.credentials)));
    CalendarClient.calendar = cal.CalendarApi(client);
    if (Platform.isAndroid && mBrowser.isOpened()) {
      await mBrowser.close();
    } else {
      await closeWebView();
    }
    Get.off(() => const HomeScreen());
  });
}

Map<String, dynamic> credentialsToJson(AccessCredentials credentials) => {
      'accessToken': credentials.accessToken.toJson(),
      if (credentials.refreshToken != null)
        'refreshToken': credentials.refreshToken,
      'idToken': credentials.idToken,
      'scopes': credentials.scopes,
    };

AccessCredentials credentialsFromJson(Map<String, dynamic> credentials) {
  List<String> scopes = [];
  credentials["scopes"].forEach((s) => scopes.add(s));
  return AccessCredentials(AccessToken.fromJson(credentials["accessToken"]),
      credentials["refreshToken"], scopes,
      idToken: credentials["idToken"]);
}

Future<AuthClient> getRefreshedClient(AccessCredentials credentials) async {
  AccessCredentials newCredentials =
      await refreshCredentials(_clientID, credentials, http.Client());
  return authenticatedClient(http.Client(), newCredentials);
}

void launchUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url,
        webOnlyWindowName: "Google Calendar",
        enableDomStorage: true,
        enableJavaScript: true,
        statusBarBrightness: Brightness.dark,
        forceSafariVC: true,
        forceWebView: true,
        headers: {
          "User-Agent":
              "Mozilla / 5.0(Linux; Android 9; LG - H870 Build / PKQ1 .190522 .001) AppleWebKit / 537.36(KHTML, like Gecko) Version / 4.0 Chrome / 83.0 .4103 .106 Mobile Safari / 537.36"
        });
  } else {
    throw 'Could not launch $url';
  }
}

void openBrowser(String url) async {
  if (Platform.isAndroid) {
    if (mBrowser.isOpened()) await mBrowser.close();
    mBrowser.addMenuItems([]);
    await mBrowser.open(
        url: Uri.tryParse(url)!,
        options: ChromeSafariBrowserClassOptions(
          android: AndroidChromeCustomTabsOptions(
              showTitle: false,
              addDefaultShareMenuItem: false,
              enableUrlBarHiding: true,
              toolbarBackgroundColor: Colors.black),
        ));
  } else {
    if (await canLaunch(url)) {
      await launch(url,
          webOnlyWindowName: "Google Calendar",
          enableDomStorage: true,
          enableJavaScript: true,
          statusBarBrightness: Brightness.dark,
          forceSafariVC: true,
          forceWebView: true,
          headers: {
            "User-Agent":
                "Mozilla / 5.0(Linux; Android 9; LG - H870 Build / PKQ1 .190522 .001) AppleWebKit / 537.36(KHTML, like Gecko) Version / 4.0 Chrome / 83.0 .4103 .106 Mobile Safari / 537.36"
          });
    } else {
      throw 'Could not launch $url';
    }
  }
}

ChromeSafariBrowser mBrowser = MyChromeSafariBrowser();

class MyChromeSafariBrowser extends ChromeSafariBrowser {
  @override
  void onOpened() {
    debugPrint("ChromeSafari browser opened");
  }

  @override
  void onCompletedInitialLoad() {
    debugPrint("ChromeSafari browser initial load completed");
  }

  @override
  void onClosed() {
    debugPrint("ChromeSafari browser closed");
  }
}

void generateIcs(EventInfo eventInfo) async {
  String tempDir = (await getTemporaryDirectory()).path;
  final File file = File('$tempDir/invite.ics');
  await file.writeAsString(createIcs(eventInfo));
  await Share.shareFiles([file.path], subject: eventInfo.title);
}

String createIcs(EventInfo eventInfo) {
  formatDateTime(DateTime dt) => dt.isUtc
      ? DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dt)
      : DateFormat("yyyyMMdd'T'HHmmss").format(dt);
  var out = StringBuffer()
    ..writecrlf('BEGIN:VCALENDAR')
    ..writecrlf('PRODID:-//Google Inc//Google Calendar 70.9054//EN')
    ..writecrlf('VERSION:2.0')
    ..writecrlf('CALSCALE:GREGORIAN')
    ..writecrlf('METHOD:REQUEST')
    ..writecrlf('BEGIN:VEVENT')
    ..writecrlf(
        'DTSTART:${formatDateTime(DateTime.fromMillisecondsSinceEpoch(eventInfo.startTimeInEpoch))}')
    ..writecrlf(
        'DTEND:${formatDateTime(DateTime.fromMillisecondsSinceEpoch(eventInfo.endTimeInEpoch))}')
    ..writecrlf('DTSTAMP:${formatDateTime(DateTime.now())}')
    ..writecrlf(
        'ORGANIZER;CN=${eventInfo.organizerEmail}:mailto:${eventInfo.organizerEmail}')
    ..writecrlf('UID:${eventInfo.iCalUid}')
    ..writecrlf('X-GOOGLE-CONFERENCE:${eventInfo.meetLink}')
    ..writecrlf('CREATED:${formatDateTime(DateTime.now())}')
    ..writecrlf('DESCRIPTION:Join: ${eventInfo.meetLink}\n\n')
    ..writecrlf('LAST-MODIFIED:${formatDateTime(DateTime.now())}')
    ..writecrlf('LOCATION:${eventInfo.location}')
    ..writecrlf('SEQUENCE:0')
    ..writecrlf('STATUS:${eventInfo.status.toUpperCase()}')
    ..writecrlf('SUMMARY:${eventInfo.title}')
    ..writecrlf('TRANSP:OPAQUE')
    ..writecrlf('END:VEVENT')
    ..writecrlf('END:VCALENDAR');
  debugPrint(out.toString());
  return out.toString();
}

var inputDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white10,
  disabledBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Colors.white24, width: 1),
  ),
  enabledBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Colors.white24, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Pigment.fromString('#9b77cf'), width: 1),
  ),
  errorBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: Colors.redAccent, width: 1),
  ),
  border: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
  ),
  contentPadding: const EdgeInsets.only(left: 10, right: 10),
  errorStyle: const TextStyle(
    fontSize: 12,
    color: Colors.redAccent,
  ),
);

class Utils {
  static ThemeData appTheme = ThemeData(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primarySwatch: Colors.blue,
      primaryColor: Pigment.fromString('#11142b'),
      backgroundColor: Pigment.fromString('#11142b'),
      secondaryHeaderColor: Pigment.fromString('#5186ec'),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      colorScheme:
          ColorScheme.fromSwatch(accentColor: Pigment.fromString('#9b77cf')),
      scaffoldBackgroundColor: Pigment.fromString('#181f25'),
      fontFamily: GoogleFonts.rubik().fontFamily);

  static ThemeData pickerTheme = appTheme.copyWith(
    colorScheme: ColorScheme.light(
      primary: Pigment.fromString('#9b77cf'), // header background color
      onPrimary: Colors.white, // header text color
      onSurface: Colors.black, // body text color
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        primary: Pigment.fromString('#5186ec'), // button text color
      ),
    ),
  );
}

class Fonts {
  //Match pubspec font weights
  static const FontWeight fontWeightBook = FontWeight.w300;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w900;

  static TextStyle display1({
    double? size = 30,
    FontWeight weight = Fonts.fontWeightBold,
    Color? colour = Colors.white,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle display2({
    double size = 26,
    FontWeight weight = Fonts.fontWeightBold,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle display3({
    double size = 23,
    FontWeight weight = Fonts.fontWeightBold,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle display4({
    double size = 20,
    FontWeight weight = Fonts.fontWeightBold,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle display5({
    double size = 18,
    FontWeight weight = Fonts.fontWeightBold,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle title({
    double size = 16,
    FontWeight weight = Fonts.fontWeightBold,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) =>
      TextStyle(
          height: height,
          fontSize: size,
          fontWeight: weight,
          color: colour,
          letterSpacing: letterSpacing,
          decoration: decoration);

  static TextStyle subtitle({
    double size = 14,
    FontWeight weight = Fonts.fontWeightMedium,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle body1({
    double size = 13,
    FontWeight weight = Fonts.fontWeightBook,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle body2({
    double size = 12,
    FontWeight weight = Fonts.fontWeightBook,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );

  static TextStyle caption({
    double size = 11,
    FontWeight weight = Fonts.fontWeightMedium,
    Color? colour = Colors.white,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        height: height,
        fontSize: size,
        fontWeight: weight,
        color: colour,
        letterSpacing: letterSpacing,
      );
}
