import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:timezone/standalone.dart';

class CalendarClient {
  static CalendarApi? calendar;

  Future<Event> insert({
    required String title,
    required String description,
    required String location,
    required List<EventAttendee> attendeeEmailList,
    required bool shouldNotifyAttendees,
    required bool hasConferenceSupport,
    required DateTime startTime,
    required DateTime endTime,
    required String timeZone,
  }) async {
    String calendarId = "primary";
    Event event = Event();
    event.sequence = 0;
    event.visibility = "public";
    event.anyoneCanAddSelf = true;
    event.summary = title;
    event.description = description;
    event.attendees = attendeeEmailList;
    event.location = location;
    event.reminders = EventReminders(useDefault: true);

    if (hasConferenceSupport) {
      ConferenceData conferenceData = ConferenceData();
      CreateConferenceRequest conferenceRequest = CreateConferenceRequest();
      conferenceRequest.requestId =
          "${startTime.millisecondsSinceEpoch}-${endTime.millisecondsSinceEpoch}";
      conferenceData.createRequest = conferenceRequest;
      event.conferenceData = conferenceData;
    }

    EventDateTime start = EventDateTime();
    start.timeZone = timeZone;
    final detroitStartTime = TZDateTime.from(startTime, getLocation(timeZone));
    start.dateTime = detroitStartTime;
    event.start = start;

    EventDateTime end = EventDateTime();
    end.timeZone = timeZone;
    final detroitEndTime = TZDateTime.from(endTime, getLocation(timeZone));
    end.dateTime = detroitEndTime;
    event.end = end;
    try {
      await calendar!.events
          .insert(event, calendarId,
              conferenceDataVersion: hasConferenceSupport ? 1 : 0,
              sendUpdates: shouldNotifyAttendees ? "all" : "none")
          .then((Event value) {
        debugPrint("Event: ${event.toJson()}");
        debugPrint("Event Status: ${value.status}");
        if (value.status == "confirmed") {
          event.id = value.id;
          event.iCalUID = value.iCalUID;
          event.organizer = value.organizer;
          event.creator = value.creator;
          event.status = value.status;
          event.hangoutLink = value.hangoutLink;
          event.htmlLink = value.htmlLink;
          event.start = value.start;
          event.end = value.end;
          debugPrint('Event added to Google Calendar');
        } else {
          debugPrint("Unable to add event to Google Calendar");
        }
      });
    } catch (e) {
      debugPrint('Error creating event $e');
    }
    return event;
  }
}
