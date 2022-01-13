import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:schedule/models/event_info.dart';
import 'package:schedule/utils/util.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:url_launcher/link.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({Key? key, required this.eventInfo}) : super(key: key);
  static const routeName = 'DetailScreen';
  final EventInfo eventInfo;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, String> timeZones = {};
  TextEditingController textControllerDate = TextEditingController();
  TextEditingController textControllerStartTime = TextEditingController();
  TextEditingController textControllerEndTime = TextEditingController();
  TextEditingController textControllerTimeZone = TextEditingController();
  TextEditingController textControllerTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() => timeZoneDatabase.locations.forEach((key, value) =>
            timeZones.addAll({key: value.currentTimeZone.abbreviation})));
        DateTime startTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
            tz.getLocation(widget.eventInfo.timezone),
            widget.eventInfo.startTimeInEpoch);
        DateTime endTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
            tz.getLocation(widget.eventInfo.timezone),
            widget.eventInfo.endTimeInEpoch);

        String dateString = DateFormat.yMMMd().format(startTime);
        String startString = DateFormat.jm().format(startTime);
        String endString = DateFormat.jm().format(endTime);

        textControllerDate = TextEditingController(text: dateString);
        textControllerStartTime = TextEditingController(text: startString);
        textControllerEndTime = TextEditingController(text: endString);
        textControllerTimeZone =
            TextEditingController(text: timeZones[widget.eventInfo.timezone]);
        textControllerTitle =
            TextEditingController(text: widget.eventInfo.title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var padding = MediaQuery.of(context).padding;
    DateTime startTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.getLocation(widget.eventInfo.timezone),
        widget.eventInfo.startTimeInEpoch);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Meeting Details",
          style: Fonts.display4(),
        ),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            RichText(
              text: TextSpan(
                text: 'Meeting Name: ',
                style: Fonts.display5(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
                readOnly: true,
                enabled: false,
                controller: textControllerTitle,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: Fonts.title(),
                decoration: inputDecoration.copyWith(
                  contentPadding: const EdgeInsets.only(left: 10, right: 10),
                  hintText: "Title",
                  hintStyle: Fonts.title(colour: Colors.grey.withOpacity(0.6)),
                )),
            const SizedBox(height: 30),
            RichText(
              text: TextSpan(
                text: 'Date: ',
                style: Fonts.display5(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Date(startTime).isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      "Today",
                      textAlign: TextAlign.center,
                      style: Fonts.title(colour: Colors.white),
                    ),
                  )
                else if (Date(startTime).isTomorrow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      "Tomorrow",
                      textAlign: TextAlign.center,
                      style: Fonts.title(colour: Colors.white),
                    ),
                  )
                else ...{
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SvgPicture.asset("assets/icons/calendar.svg",
                              width: 15),
                        ),
                        Text(
                          textControllerDate.text,
                          textAlign: TextAlign.center,
                          style: Fonts.title(colour: Colors.white),
                        ),
                      ],
                    ),
                  ),
                }
              ],
            ),
            const SizedBox(height: 30),
            RichText(
              text: TextSpan(
                text: 'Time: ',
                style: Fonts.display5(),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: textControllerStartTime,
                readOnly: true,
                style: Fonts.title(height: 1.5),
                decoration: inputDecoration.copyWith(
                  contentPadding: const EdgeInsets.only(left: 10),
                  labelText: "FROM",
                  labelStyle: Fonts.body1(
                      weight: Fonts.fontWeightBold, colour: Colors.white60),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  readOnly: true,
                  enabled: false,
                  controller: textControllerEndTime,
                  style: Fonts.title(height: 1.5),
                  decoration: inputDecoration.copyWith(
                    contentPadding: const EdgeInsets.only(left: 10),
                    labelText: "TO",
                    labelStyle: Fonts.body1(
                        weight: Fonts.fontWeightBold, colour: Colors.white60),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                style: Fonts.title(height: 1.5),
                readOnly: true,
                enabled: false,
                controller: textControllerTimeZone,
                decoration: inputDecoration.copyWith(
                  contentPadding: const EdgeInsets.only(left: 10),
                  labelText: "TIME ZONE",
                  labelStyle: Fonts.body1(
                      weight: Fonts.fontWeightBold, colour: Colors.white60),
                ),
              )),
            ]),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                "Gmeet Link: ",
                textAlign: TextAlign.center,
                style: Fonts.display5(),
              ),
            ),
            Link(
              uri: Uri.parse(widget.eventInfo.meetLink),
              builder: (BuildContext context, FollowLink? followLink) =>
                  ListTile(
                title: Text(
                  widget.eventInfo.meetLink,
                  style: Fonts.title(
                      decoration: TextDecoration.underline,
                      colour: Colors.white70),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: followLink,
              ),
            ),
            const SizedBox(height: 30),
          ])),
      bottomNavigationBar: Container(
        padding:
            EdgeInsets.only(left: 30, right: 30, bottom: padding.bottom + 20),
        child: MaterialButton(
          onPressed: () => generateIcs(widget.eventInfo),
          color: Colors.white.withOpacity(.05),
          height: 60,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
              side: BorderSide(color: theme.colorScheme.secondary)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/icons/share.svg",
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                "Share Invite",
                textAlign: TextAlign.center,
                style: Fonts.display4(colour: theme.colorScheme.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
