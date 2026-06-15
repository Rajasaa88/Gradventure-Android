import 'package:add_2_calendar/add_2_calendar.dart';

class CalendarService {
  static Future<void> addEvent({
    required String title,
    required String description,
    required DateTime dateTime,
  }) async {
    final Event event = Event(
      title: title,
      description: description,
      location: 'Ruang Dosen PA / Online',
      startDate: dateTime,
      endDate: dateTime.add(const Duration(hours: 1)),
      allDay: false,
      iosParams: const IOSParams(
        reminder: Duration(minutes: 15),
      ),
    );
    await Add2Calendar.addEvent2Cal(event);
  }
}
