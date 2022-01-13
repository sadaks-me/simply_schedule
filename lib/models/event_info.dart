import 'dart:convert';

EventInfo eventInfoFromString(String str) => EventInfo.fromMap(jsonDecode(str));
String eventInfoToString(EventInfo data) => jsonEncode(data.toJson());

class EventInfo {
  final String id;
  final String iCalUid;
  final String status;
  final String organizerName;
  final String organizerEmail;
  final String title;
  final String description;
  final String location;
  final String meetLink;
  final String eventLink;
  final List<dynamic> attendeeEmails;
  final bool shouldNotifyAttendees;
  final bool hasConferencingSupport;
  final int startTimeInEpoch;
  final int endTimeInEpoch;
  final String timezone;

  EventInfo({
    required this.id,
    required this.iCalUid,
    required this.status,
    required this.organizerName,
    required this.organizerEmail,
    required this.title,
    required this.description,
    required this.location,
    required this.meetLink,
    required this.eventLink,
    required this.attendeeEmails,
    required this.shouldNotifyAttendees,
    required this.hasConferencingSupport,
    required this.startTimeInEpoch,
    required this.endTimeInEpoch,
    required this.timezone,
  });

  EventInfo.fromMap(Map snapshot)
      : id = snapshot['id'] ?? '',
        iCalUid = snapshot['ical_uid'] ?? '',
        status = snapshot['status'] ?? '',
        organizerName = snapshot['organizer_name'] ?? '',
        organizerEmail = snapshot['organizer_email'] ?? '',
        title = snapshot['title'] ?? '',
        description = snapshot['desc'],
        location = snapshot['loc'],
        meetLink = snapshot['meet_link'],
        eventLink = snapshot['event_link'],
        attendeeEmails = snapshot['emails'] ?? '',
        shouldNotifyAttendees = snapshot['should_notify'],
        hasConferencingSupport = snapshot['has_conferencing'],
        startTimeInEpoch = snapshot['start'],
        endTimeInEpoch = snapshot['end'],
        timezone = snapshot['timezone'];

  toJson() {
    return {
      'id': id,
      'ical_uid': iCalUid,
      'status': status,
      'organizer_name': organizerName,
      'organizer_email': organizerEmail,
      'title': title,
      'desc': description,
      'loc': location,
      'meet_link': meetLink,
      'event_link': eventLink,
      'emails': attendeeEmails,
      'should_notify': shouldNotifyAttendees,
      'has_conferencing': hasConferencingSupport,
      'start': startTimeInEpoch,
      'end': endTimeInEpoch,
      'timezone': timezone,
    };
  }
}
