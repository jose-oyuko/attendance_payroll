import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:flutter/material.dart';

const List<String> weekdayShortNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// "Mon", for an ISO weekday.
String weekdayName(int weekday) => weekdayShortNames[weekday - 1];

TimeOfDay timeOfDayFrom(Duration sinceMidnight) => TimeOfDay(
  hour: sinceMidnight.inHours,
  minute: sinceMidnight.inMinutes % Duration.minutesPerHour,
);

Duration durationFrom(TimeOfDay time) =>
    Duration(hours: time.hour, minutes: time.minute);

/// "08:00–17:00", or "22:00–06:00 next day".
String formatShift(BuildContext context, ScheduleDay day) {
  final start = timeOfDayFrom(day.start).format(context);
  final end = timeOfDayFrom(day.end).format(context);
  return day.crossesMidnight ? '$start–$end next day' : '$start–$end';
}

/// A compact summary such as "Mon–Fri 08:00–17:00 · Sat 09:00–13:00":
/// consecutive days with the same hours are grouped.
String summarizeDays(BuildContext context, List<ScheduleDay> days) {
  if (days.isEmpty) {
    return 'No working days';
  }
  final sorted = [...days]..sort((a, b) => a.weekday.compareTo(b.weekday));
  final groups = <List<ScheduleDay>>[];
  for (final day in sorted) {
    final last = groups.lastOrNull?.last;
    if (last != null &&
        last.weekday + 1 == day.weekday &&
        last.start == day.start &&
        last.end == day.end) {
      groups.last.add(day);
    } else {
      groups.add([day]);
    }
  }
  return [
    for (final group in groups)
      '${group.length == 1 ? weekdayName(group.first.weekday) : '${weekdayName(group.first.weekday)}–${weekdayName(group.last.weekday)}'} '
          '${formatShift(context, group.first)}',
  ].join(' · ');
}
