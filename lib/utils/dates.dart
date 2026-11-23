import 'package:intl/intl.dart';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysFromToday(DateTime d) =>
    dayOnly(d).difference(dayOnly(DateTime.now())).inDays;

/// "Today", "Tomorrow", "Yesterday", otherwise "Thu, Nov 26".
String friendlyDay(DateTime d) {
  switch (daysFromToday(d)) {
    case 0:
      return 'Today';
    case 1:
      return 'Tomorrow';
    case -1:
      return 'Yesterday';
  }
  return DateFormat('EEE, MMM d').format(d);
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}
