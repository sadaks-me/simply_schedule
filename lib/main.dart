import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:googleapis_auth/auth.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schedule/screens/create_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/splash.dart';
import 'utils/calendar_client.dart';
import 'utils/util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init((await getApplicationDocumentsDirectory()).path);
  await Hive.openBox('event_box');
  await Hive.openBox('credential_box');
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: credBox.listenable(),
        builder: (context, dynamic box, child) {
          if (box.containsKey("credentials")) {
            return FutureBuilder<AuthClient>(
                future: getRefreshedClient(
                    credentialsFromJson(jsonDecode(box.get("credentials")))),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    CalendarClient.calendar = cal.CalendarApi(snapshot.data!);
                    return GetMaterialApp(
                        title: 'Simply Schedule',
                        debugShowCheckedModeBanner: false,
                        theme: Utils.appTheme,
                        themeMode: ThemeMode.light,
                        builder: (context, Widget? child) {
                          final mediaQueryData = MediaQuery.of(context);
                          final double constrainedTextScaleFactor =
                              mediaQueryData.textScaleFactor.clamp(1.0, 1.2);
                          return MediaQuery(
                              data: mediaQueryData.copyWith(
                                  textScaleFactor: constrainedTextScaleFactor),
                              child: child!);
                        },
                        home: const CreateScreen());
                  } else {
                    return const SizedBox();
                  }
                });
          } else {
            return GetMaterialApp(
                title: 'Simply Schedule',
                debugShowCheckedModeBanner: false,
                theme: Utils.appTheme,
                themeMode: ThemeMode.light,
                builder: (context, Widget? child) {
                  final mediaQueryData = MediaQuery.of(context);
                  final double constrainedTextScaleFactor =
                      mediaQueryData.textScaleFactor.clamp(1.0, 1.2);
                  return MediaQuery(
                      data: mediaQueryData.copyWith(
                          textScaleFactor: constrainedTextScaleFactor),
                      child: child!);
                },
                home: const SplashScreen());
          }
        });
  }
}
