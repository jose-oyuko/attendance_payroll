import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';

/// A schedule with the same hours on each of [weekdays] (default Mon–Fri
/// 08:00–17:00).
WorkScheduleDetails dayShift({
  String name = 'Day shift',
  List<int> weekdays = const [1, 2, 3, 4, 5],
  Duration start = const Duration(hours: 8),
  Duration end = const Duration(hours: 17),
  Duration lateTolerance = const Duration(minutes: 10),
  AutomaticBreak? automaticBreak,
}) {
  return WorkScheduleDetails(
    name: name,
    days: [
      for (final weekday in weekdays)
        ScheduleDay(weekday: weekday, start: start, end: end),
    ],
    lateTolerance: lateTolerance,
    automaticBreak: automaticBreak,
  );
}
