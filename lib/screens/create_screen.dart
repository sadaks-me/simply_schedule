import 'package:dart_date/dart_date.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';
import 'package:schedule/models/event_info.dart';
import 'package:schedule/screens/detail_screen.dart';
import 'package:schedule/utils/calendar_client.dart';
import 'package:schedule/utils/storage.dart';
import 'package:schedule/utils/util.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:timezone/timezone.dart';

import 'home_screen.dart';

enum TimeSpan { fifteen, thirty, fortyfive, sixty }

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  static const routeName = 'CreateScreen';

  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  CalendarClient calendarClient = CalendarClient();
  Map<String, String> timeZones = {};
  TextEditingController textControllerDate = TextEditingController();
  TextEditingController textControllerStartTime = TextEditingController();
  TextEditingController textControllerEndTime = TextEditingController();
  TextEditingController textControllerTimeZone = TextEditingController();
  TextEditingController textControllerTitle = TextEditingController();
  TextEditingController textControllerDesc = TextEditingController();
  TextEditingController textControllerLocation = TextEditingController();
  TextEditingController textControllerAttendee = TextEditingController();

  FocusNode textFocusNodeDate = FocusNode();
  FocusNode textFocusNodeTitle = FocusNode();
  FocusNode textFocusNodeDesc = FocusNode();
  FocusNode textFocusNodeLocation = FocusNode();
  FocusNode textFocusNodeAttendee = FocusNode();

  DateTime selectedDate = Date.today;
  TimeOfDay selectedStartTime = TimeOfDay.now();
  TimeOfDay selectedEndTime = TimeOfDay.now();
  TimeSpan? timeSpan;
  String? currentTitle;
  String? currentDesc;
  String? currentLocation;
  String? currentEmail;
  String errorString = '';
  String? timeZone;

  // List<String> attendeeEmails = [];
  List<calendar.EventAttendee> attendeeEmails = [];

  bool isEditingDate = false;
  bool isEditingStartTime = false;
  bool isEditingEndTime = false;
  bool isEditingBatch = false;
  bool isEditingTitle = false;
  bool isEditingEmail = false;
  bool isEditingLink = false;
  bool isErrorTime = false;
  bool shouldNofityAttendees = true;
  bool hasConferenceSupport = true;
  bool isDataStorageInProgress = false;

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Utils.pickerTheme,
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        textControllerDate.text = DateFormat.yMMMd().format(selectedDate);
      });
    }
  }

  _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Utils.pickerTheme,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != selectedStartTime) {
      selectedStartTime = picked;
      textControllerStartTime.text = selectedStartTime.format(context);
    } else {
      textControllerStartTime.text = selectedStartTime.format(context);
    }
    setState(() {
      int plusMinutes;
      timeSpan ??= TimeSpan.thirty;
      switch (timeSpan!) {
        case TimeSpan.fifteen:
          plusMinutes = 15;
          break;
        case TimeSpan.thirty:
          plusMinutes = 30;
          break;
        case TimeSpan.fortyfive:
          plusMinutes = 45;
          break;
        case TimeSpan.sixty:
          plusMinutes = 60;
          break;
      }
      selectedEndTime =
          TimeOfDayExtension(selectedStartTime).plusMinutes(plusMinutes);
      textControllerEndTime.text = selectedEndTime.format(context);
    });
  }

  _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Utils.pickerTheme,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != selectedEndTime) {
      setState(() {
        timeSpan = null;
        selectedEndTime = picked;
        textControllerEndTime.text = selectedEndTime.format(context);
      });
    } else {
      setState(() {
        textControllerEndTime.text = selectedEndTime.format(context);
      });
    }
  }

  String? _validateTitle(String? value) {
    if (value != null) {
      value = value.trim();
      if (value.isEmpty) {
        return 'Title can\'t be empty';
      }
    } else {
      return 'Title can\'t be empty';
    }
    return null;
  }

  openTimezoneSheet(BuildContext context) {
    Get.dialog(
        TimeZoneSearch(
          timeZones: timeZones,
          onSelected: (selected) => setState(() {
            timeZone = selected.key;
            textControllerTimeZone.text = selected.value;
          }),
        ),
        barrierColor: Colors.black87);
  }

  reset() async {
    textControllerDate.clear();
    textControllerStartTime.clear();
    textControllerEndTime.clear();
    textControllerTimeZone.clear();
    textControllerTitle.clear();
    textControllerDesc.clear();
    textControllerLocation.clear();
    textControllerAttendee.clear();

    textFocusNodeDate = FocusNode();
    textFocusNodeTitle = FocusNode();
    textFocusNodeDesc = FocusNode();
    textFocusNodeLocation = FocusNode();
    textFocusNodeAttendee = FocusNode();

    selectedDate = Date.today;
    selectedStartTime = TimeOfDay.now();
    selectedEndTime = TimeOfDay.now();
    currentTitle = null;
    currentDesc = null;
    currentLocation = null;
    currentEmail = null;
    errorString = '';
    attendeeEmails = [];
    timeSpan = null;
    isEditingDate = false;
    isEditingStartTime = false;
    isEditingEndTime = false;
    isEditingBatch = false;
    isEditingTitle = false;
    isEditingEmail = false;
    isEditingLink = false;
    isErrorTime = false;
    shouldNofityAttendees = true;
    hasConferenceSupport = true;
    isDataStorageInProgress = false;
    timeZone = await FlutterNativeTimezone.getLocalTimezone();
    textControllerTimeZone.text = timeZones[timeZone!]!;
    selectedStartTime = TimeOfDayExtension(selectedStartTime).roundMinutes();
    textControllerStartTime.text = selectedStartTime.format(context);
    timeSpan ??= TimeSpan.thirty;
    onTimeSpanSelected(timeSpan!);
  }

  @override
  void initState() {
    super.initState();
    timeZoneDatabase.locations.forEach((key, value) =>
        timeZones.addAll({key: value.currentTimeZone.abbreviation}));
    Future.microtask(() async {
      timeZone = await FlutterNativeTimezone.getLocalTimezone();
      textControllerTimeZone.text = timeZones[timeZone!]!;
      if (mounted) {
        selectedStartTime =
            TimeOfDayExtension(selectedStartTime).roundMinutes();
        textControllerStartTime.text = selectedStartTime.format(context);
        timeSpan ??= TimeSpan.thirty;
        onTimeSpanSelected(timeSpan!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var padding = MediaQuery.of(context).padding;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset("assets/images/logo_with_text.png"),
        actions: [
          PopupMenuButton(
              icon: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white10,
                    border: Border.all(color: Colors.white24),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(Icons.person)),
              padding: const EdgeInsets.only(right: 10),
              onSelected: (value) {
                if (value == 1) {
                  Get.to(() => const HomeScreen());
                }
              },
              itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/calendar.svg",
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text("My Meetings"),
                        ],
                      ),
                      value: 1,
                    )
                  ])
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            RichText(
              text: TextSpan(
                text: 'Meeting Name: ',
                style: Fonts.display5(),
                children: const <TextSpan>[
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              enabled: true,
              focusNode: textFocusNodeTitle,
              controller: textControllerTitle,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  isEditingTitle = true;
                  currentTitle = value;
                });
              },
              onSubmitted: (value) {
                textFocusNodeTitle.unfocus();
                FocusScope.of(context).requestFocus(textFocusNodeDesc);
              },
              maxLines: null,
              maxLength: 100,
              style: Fonts.title(height: 1.5),
              decoration: inputDecoration.copyWith(
                  contentPadding: const EdgeInsets.all(10),
                  counterStyle: Fonts.body1(
                      weight: Fonts.fontWeightBold, colour: Colors.white60),
                  hintText: "Add Title",
                  hintStyle: Fonts.title(colour: Colors.grey.withOpacity(0.6)),
                  errorText:
                      isEditingTitle ? _validateTitle(currentTitle) : null),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                text: 'Choose Date: ',
                style: Fonts.display5(),
                children: const <TextSpan>[
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                    onTap: () {
                      setState(() {
                        selectedDate = Date.today;
                        textControllerDate.text = "";
                        textFocusNodeDate.unfocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(
                              color: (textControllerDate.text.isEmpty &&
                                      Date(selectedDate).isToday)
                                  ? theme.colorScheme.secondary
                                  : Colors.white24),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        "Today",
                        textAlign: TextAlign.center,
                        style: Fonts.title(
                            colour: (textControllerDate.text.isEmpty &&
                                    Date(selectedDate).isToday)
                                ? theme.colorScheme.secondary
                                : Colors.white),
                      ),
                    )),
                const SizedBox(width: 10),
                InkWell(
                    onTap: () {
                      setState(() {
                        selectedDate = Date.tomorrow;
                        textControllerDate.text = "";
                        textFocusNodeDate.unfocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(
                              color: (textControllerDate.text.isEmpty &&
                                      Date(selectedDate).isTomorrow)
                                  ? theme.colorScheme.secondary
                                  : Colors.white24),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        "Tomorrow",
                        textAlign: TextAlign.center,
                        style: Fonts.title(
                            colour: (textControllerDate.text.isEmpty &&
                                    Date(selectedDate).isTomorrow)
                                ? theme.colorScheme.secondary
                                : Colors.white),
                      ),
                    )),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                  controller: textControllerDate,
                  textCapitalization: TextCapitalization.characters,
                  onTap: () => _selectDate(context),
                  readOnly: true,
                  focusNode: textFocusNodeDate,
                  style: Fonts.title(height: 1.5),
                  decoration: inputDecoration.copyWith(
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Other Date',
                    hintStyle:
                        Fonts.title(colour: Colors.grey.withOpacity(0.6)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: SvgPicture.asset(
                        "assets/icons/calendar.svg",
                        width: 40,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(maxWidth: 35),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(maxWidth: 25),
                  ),
                ))
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: RichText(
                    text: TextSpan(
                      text: 'Choose Time: ',
                      style: Fonts.display5(),
                      children: const <TextSpan>[
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: TextField(
                      onTap: () => openTimezoneSheet(context),
                      readOnly: true,
                      controller: textControllerTimeZone,
                      style: Fonts.title(height: 1.5),
                      enabled: true,
                      decoration: inputDecoration.copyWith(
                          contentPadding: const EdgeInsets.only(left: 10),
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ),
                          suffixIconConstraints:
                              const BoxConstraints(maxWidth: 25),
                          errorText: textControllerTimeZone.text.isNotEmpty
                              ? null
                              : '*required'),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                          controller: textControllerStartTime,
                          onTap: () => _selectStartTime(context),
                          readOnly: true,
                          style: Fonts.title(height: 1.5),
                          decoration: inputDecoration.copyWith(
                              contentPadding: const EdgeInsets.only(left: 10),
                              labelText: "FROM",
                              labelStyle: Fonts.body1(
                                  weight: Fonts.fontWeightBold,
                                  colour: Colors.white60),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: SvgPicture.asset(
                                  "assets/icons/edit.svg",
                                ),
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(maxWidth: 25),
                              errorText: isEditingStartTime
                                  ? textControllerStartTime.text.isNotEmpty
                                      ? null
                                      : '*required'
                                  : null)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: textControllerEndTime,
                        onTap: () => _selectEndTime(context),
                        readOnly: true,
                        style: Fonts.title(height: 1.5),
                        decoration: inputDecoration.copyWith(
                          contentPadding: const EdgeInsets.only(left: 10),
                          labelText: "TO",
                          labelStyle: Fonts.body1(
                              weight: Fonts.fontWeightBold,
                              colour: Colors.white60),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SvgPicture.asset(
                              "assets/icons/edit.svg",
                            ),
                          ),
                          suffixIconConstraints:
                              const BoxConstraints(maxWidth: 25),
                          errorText: isEditingEndTime
                              ? textControllerEndTime.text.isNotEmpty
                                  ? null
                                  : '*required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => onTimeSpanSelected(TimeSpan.fifteen),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(
                                  color: timeSpan == TimeSpan.fifteen
                                      ? theme.colorScheme.secondary
                                      : Colors.white24),
                              borderRadius: BorderRadius.circular(6)),
                          child: SvgPicture.asset(
                            "assets/icons/15m.svg",
                            color: timeSpan == TimeSpan.fifteen
                                ? theme.colorScheme.secondary
                                : Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onTimeSpanSelected(TimeSpan.thirty),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(
                                  color: timeSpan == TimeSpan.thirty
                                      ? theme.colorScheme.secondary
                                      : Colors.white24),
                              borderRadius: BorderRadius.circular(6)),
                          child: SvgPicture.asset(
                            "assets/icons/30m.svg",
                            color: timeSpan == TimeSpan.thirty
                                ? theme.colorScheme.secondary
                                : Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onTimeSpanSelected(TimeSpan.fortyfive),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(
                                  color: timeSpan == TimeSpan.fortyfive
                                      ? theme.colorScheme.secondary
                                      : Colors.white24),
                              borderRadius: BorderRadius.circular(6)),
                          child: SvgPicture.asset(
                            "assets/icons/45m.svg",
                            color: timeSpan == TimeSpan.fortyfive
                                ? theme.colorScheme.secondary
                                : Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onTimeSpanSelected(TimeSpan.sixty),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              border: Border.all(
                                  color: timeSpan == TimeSpan.sixty
                                      ? theme.colorScheme.secondary
                                      : Colors.white24),
                              borderRadius: BorderRadius.circular(6)),
                          child: SvgPicture.asset(
                            "assets/icons/60m.svg",
                            color: timeSpan == TimeSpan.sixty
                                ? theme.colorScheme.secondary
                                : Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                  flex: 2,
                )
              ],
            ),
            const SizedBox(height: 30)
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding:
            EdgeInsets.only(left: 30, right: 30, bottom: padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MaterialButton(
              onPressed: isDataStorageInProgress
                  ? null
                  : () async {
                      try {
                        setState(() {
                          isErrorTime = false;
                          isDataStorageInProgress = true;
                        });

                        textFocusNodeTitle.unfocus();
                        textFocusNodeDesc.unfocus();
                        textFocusNodeLocation.unfocus();
                        textFocusNodeAttendee.unfocus();

                        if (currentTitle != null) {
                          int startTimeInEpoch = tz.TZDateTime(
                            tz.getLocation(timeZone!),
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedStartTime.hour,
                            selectedStartTime.minute,
                          ).millisecondsSinceEpoch;

                          int endTimeInEpoch = tz.TZDateTime(
                            tz.getLocation(timeZone!),
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedEndTime.hour,
                            selectedEndTime.minute,
                          ).millisecondsSinceEpoch;

                          debugPrint(
                              'DIFFERENCE: ${endTimeInEpoch - startTimeInEpoch}');
                          debugPrint(
                              'Start Time: ${DateTime.fromMillisecondsSinceEpoch(startTimeInEpoch)}');
                          debugPrint(
                              'End Time: ${DateTime.fromMillisecondsSinceEpoch(endTimeInEpoch)}');

                          if (endTimeInEpoch - startTimeInEpoch > 0) {
                            if (_validateTitle(currentTitle) == null) {
                              await calendarClient
                                  .insert(
                                      title: currentTitle!,
                                      description: currentDesc ?? '',
                                      location: timeZone!,
                                      attendeeEmailList: attendeeEmails,
                                      shouldNotifyAttendees:
                                          shouldNofityAttendees,
                                      hasConferenceSupport:
                                          hasConferenceSupport,
                                      startTime: tz.TZDateTime
                                          .fromMillisecondsSinceEpoch(
                                              tz.getLocation(timeZone!),
                                              startTimeInEpoch),
                                      endTime: tz.TZDateTime
                                          .fromMillisecondsSinceEpoch(
                                        tz.getLocation(timeZone!),
                                        endTimeInEpoch,
                                      ),
                                      timeZone: timeZone!)
                                  .then((event) async {
                                List<String> emails = [];

                                for (int i = 0;
                                    i < attendeeEmails.length;
                                    i++) {
                                  emails.add(attendeeEmails[i].email!);
                                }
                                EventInfo eventInfo = EventInfo(
                                    id: event.id!,
                                    iCalUid: event.iCalUID ?? '',
                                    organizerName:
                                        event.organizer?.displayName ?? '',
                                    organizerEmail:
                                        event.organizer?.email ?? '',
                                    status: event.status ?? '',
                                    title: currentTitle ?? '',
                                    description: currentDesc ?? '',
                                    location: timeZone!,
                                    meetLink: event.hangoutLink ?? '',
                                    eventLink: event.htmlLink ?? '',
                                    attendeeEmails: emails,
                                    shouldNotifyAttendees:
                                        shouldNofityAttendees,
                                    hasConferencingSupport:
                                        hasConferenceSupport,
                                    startTimeInEpoch: startTimeInEpoch,
                                    endTimeInEpoch: endTimeInEpoch,
                                    timezone: timeZone!);
                                await Storage.storeEventData(eventInfo);
                                Get.to(
                                    () => DetailScreen(eventInfo: eventInfo));
                                reset();
                              }).catchError(
                                (e, s) => debugPrint(s.toString()),
                              );

                              setState(() {
                                isDataStorageInProgress = false;
                              });
                            } else {
                              setState(() {
                                isEditingTitle = true;
                                isEditingLink = true;
                              });
                            }
                          } else {
                            setState(() {
                              isErrorTime = true;
                              errorString =
                                  'Invalid time! Please use a proper start and end time';
                            });
                          }
                        } else {
                          setState(() {
                            isEditingDate = (!Date(selectedDate).isTomorrow ||
                                !Date(selectedDate).isToday);
                            isEditingStartTime = true;
                            isEditingEndTime = true;
                            isEditingBatch = true;
                            isEditingTitle = true;
                            isEditingLink = true;
                          });
                        }
                        setState(() {
                          isDataStorageInProgress = false;
                        });
                      } catch (e, s) {
                        debugPrint(s.toString());
                      }
                    },
              color: theme.colorScheme.secondary,
              height: 60,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              child: isDataStorageInProgress
                  ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/icons/calendar_add.svg",
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Create",
                          textAlign: TextAlign.center,
                          style: Fonts.display4(),
                        ),
                      ],
                    ),
            ),
            Visibility(
              visible: isErrorTime,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorString,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  onTimeSpanSelected(TimeSpan timeSpan) {
    this.timeSpan = timeSpan;
    int plusMinutes;
    switch (timeSpan) {
      case TimeSpan.fifteen:
        plusMinutes = 15;
        break;
      case TimeSpan.thirty:
        plusMinutes = 30;
        break;
      case TimeSpan.fortyfive:
        plusMinutes = 45;
        break;
      case TimeSpan.sixty:
        plusMinutes = 60;
        break;
    }
    selectedEndTime =
        TimeOfDayExtension(selectedStartTime).plusMinutes(plusMinutes);
    textControllerEndTime.text = selectedEndTime.format(context);
    setState(() {});
  }
}

class TimeZoneSearch extends StatefulWidget {
  const TimeZoneSearch(
      {Key? key, required this.timeZones, required this.onSelected})
      : super(key: key);
  final Map<String, String> timeZones;
  final ValueChanged<MapEntry<String, String>> onSelected;

  @override
  _TimeZoneSearchState createState() => _TimeZoneSearchState();
}

class _TimeZoneSearchState extends State<TimeZoneSearch> {
  TextEditingController searchTextController = TextEditingController();
  Map<String, String> _searchResult = {};

  // _searchResult;
  @override
  void initState() {
    _searchResult = Map.from(widget.timeZones);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return DraggableScrollableSheet(
        maxChildSize: 1,
        minChildSize: 0.7,
        initialChildSize: 0.9,
        builder: (context, scrollController) => Column(
              children: [
                FloatingActionButton(
                  onPressed: () => Get.back(),
                  mini: true,
                  backgroundColor: theme.secondaryHeaderColor,
                  child: const Icon(Icons.close),
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: Material(
                    color: theme.backgroundColor,
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        topLeft: Radius.circular(20)),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.white.withOpacity(.05)))),
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "🔍  ",
                                style: Fonts.title(height: 1.5),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: searchTextController,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: onSearchTextChanged,
                                  style: Fonts.title(height: 1.5),
                                  decoration: InputDecoration.collapsed(
                                    hintText: ' Search Country / Timezone',
                                    hintStyle:
                                        Fonts.title(colour: Colors.white24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: ListTile.divideTiles(
                                    context: context,
                                    color: Colors.white.withOpacity(.1),
                                    tiles: _searchResult.entries
                                        .map((e) => ListTile(
                                              onTap: () {
                                                widget.onSelected(e);
                                                Get.back();
                                              },
                                              dense: true,
                                              title: Text(
                                                e.key,
                                                style: Fonts.title(),
                                              ),
                                              trailing: Text(
                                                e.value,
                                                style: Fonts.title(
                                                    colour: theme
                                                        .colorScheme.secondary),
                                              ),
                                            ))
                                        .toList())
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ));
  }

  onSearchTextChanged(String text) async {
    print("onChanged: $text");
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {
        _searchResult = Map.from(widget.timeZones);
      });
      return;
    }
    widget.timeZones.forEach((key, value) {
      if (key.toLowerCase().contains(text.toLowerCase()) ||
          value.toLowerCase().contains(text.toLowerCase())) {
        _searchResult.addAll({key: value});
      }
    });
    setState(() {});
  }
}
