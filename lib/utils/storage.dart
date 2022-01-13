import 'package:schedule/models/event_info.dart';
import 'package:schedule/utils/util.dart';

class Storage {
  static Future<void> storeEventData(EventInfo eventInfo) =>
      eventBox.put(eventInfo.id, eventInfoToString(eventInfo));

  static Future<void> updateEventData(EventInfo eventInfo) async {
    eventBox.delete(eventInfo.id);
    eventBox.put(eventInfo.id, eventInfoToString(eventInfo));
  }

  static Future<void> deleteEvent({required String id}) => eventBox.delete(id);
}
