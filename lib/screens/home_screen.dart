import 'dart:convert';

import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:schedule/models/event_info.dart';
import 'package:schedule/screens/detail_screen.dart';
import 'package:schedule/utils/util.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:timezone/standalone.dart' as tz;

import 'splash.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static const routeName = 'HomeScreen';

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Meetings",
          style: Fonts.display4(),
        ),
        actions: [
          PopupMenuButton(
              padding: const EdgeInsets.only(right: 10),
              onSelected: (value) {
                if (value == 1) {
                  eventBox.clear();
                  credBox.clear();
                  Get.offAll(() => const SplashScreen());
                }
              },
              itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_outlined,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text("Logout"),
                        ],
                      ),
                      value: 1,
                    ),
                  ])
        ],
      ),
      body: ValueListenableBuilder(
          valueListenable: eventBox.listenable(),
          builder: (context, dynamic box, child) {
            Map<dynamic, dynamic> raw = box.toMap();
            List<EventInfo> totalEvents = raw.values
                .map((eventsMap) => EventInfo.fromMap(jsonDecode(eventsMap)))
                .toList();
            List<EventInfo> events = totalEvents
              ..sort(
                  (a, b) => a.startTimeInEpoch.compareTo(b.startTimeInEpoch));
            if (events.isNotEmpty) {
              return StickyGroupedListView<EventInfo, DateTime>(
                elements: events,
                stickyHeaderBackgroundColor: Colors.transparent,
                groupBy: (EventInfo event) {
                  var startDate = DateTime.fromMillisecondsSinceEpoch(
                      event.startTimeInEpoch);
                  return DateTime(
                      startDate.year, startDate.month, startDate.day);
                },
                groupSeparatorBuilder: (EventInfo event) => Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
                          .add(const EdgeInsets.only(top: 10)),
                  color: theme.scaffoldBackgroundColor,
                  child: Text(
                    DateFormat.yMMMd().format(
                        DateTime.fromMillisecondsSinceEpoch(
                            event.startTimeInEpoch)),
                    style: Fonts.title(colour: theme.colorScheme.secondary),
                  ),
                ),
                itemBuilder: (context, EventInfo e) {
                  DateTime startTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
                      tz.getLocation(e.timezone), e.startTimeInEpoch);
                  DateTime endTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
                      tz.getLocation(e.timezone), e.endTimeInEpoch);
                  String startTimeString = DateFormat.jm().format(startTime);
                  String endTimeString = DateFormat.jm().format(endTime);

                  return GestureDetector(
                    onTap: () => Get.to(() => DetailScreen(eventInfo: e)),
                    child: Opacity(
                      opacity: startTime.isPast ? 0.3 : 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(
                            e.title,
                            style: Fonts.display5(
                                weight: Fonts.fontWeightExtraBold, height: 1),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              startTimeString +
                                  ' - ' +
                                  endTimeString +
                                  ' (${startTime.timeZoneName})',
                              style: Fonts.subtitle(colour: Colors.white70),
                            ),
                          ),
                          trailing: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                                onTap: () => generateIcs(e),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.05),
                                      border: Border.all(
                                          color: theme.colorScheme.secondary),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: SvgPicture.asset(
                                    "assets/icons/share.svg",
                                  ),
                                )),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                itemComparator: (a, b) =>
                    b.startTimeInEpoch.compareTo(a.startTimeInEpoch),
                // optional
                itemScrollController: GroupedItemScrollController(),
                // optional
                order: StickyGroupedListOrder.ASC, // optional
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset("assets/images/noevent.png"),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "You don’t have any meetings",
                      textAlign: TextAlign.center,
                      style: Fonts.subtitle(),
                    ),
                  ],
                ),
              );
            }
          }),
    );
  }
}
