import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/validators.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/day_schedule.dart';

/// One working day of a schedule: start and end as time since local
/// midnight. An end earlier than the start means the shift ends the next
/// day (a night shift).
final class ScheduleDay {
  const ScheduleDay({
    required this.weekday,
    required this.start,
    required this.end,
  });

  /// ISO weekday: [DateTime.monday] (1) to [DateTime.sunday] (7).
  final int weekday;
  final Duration start;
  final Duration end;

  bool get crossesMidnight => end < start;

  /// Scheduled time from start to end.
  Duration get length =>
      crossesMidnight ? end + const Duration(days: 1) - start : end - start;

  @override
  bool operator ==(Object other) {
    return other is ScheduleDay &&
        other.weekday == weekday &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(weekday, start, end);
}

/// Editable details of a work schedule.
final class WorkScheduleDetails {
  const WorkScheduleDetails({
    required this.name,
    required this.days,
    this.lateTolerance = const Duration(minutes: 10),
    this.earlyDepartureTolerance = const Duration(minutes: 10),
    this.automaticBreak,
  });

  static const int maxNameLength = 60;
  static const Duration maxTolerance = Duration(hours: 2);

  final String name;

  /// Working days, at most one per weekday; other days are days off.
  final List<ScheduleDay> days;
  final Duration lateTolerance;
  final Duration earlyDepartureTolerance;

  /// Break deducted on this schedule's days (replacing the company default),
  /// or `null` for none.
  final AutomaticBreak? automaticBreak;

  ScheduleDay? dayFor(int weekday) {
    for (final day in days) {
      if (day.weekday == weekday) {
        return day;
      }
    }
    return null;
  }

  /// Trimmed name and days in weekday order.
  WorkScheduleDetails normalized() {
    return WorkScheduleDetails(
      name: name.trim(),
      days: [...days]..sort((a, b) => a.weekday.compareTo(b.weekday)),
      lateTolerance: lateTolerance,
      earlyDepartureTolerance: earlyDepartureTolerance,
      automaticBreak: automaticBreak,
    );
  }

  /// The first rule these details break, or `null` when they are valid.
  ValidationFailure? validate() {
    if (Validators.isBlank(name) || name.trim().length > maxNameLength) {
      return const ValidationFailure(
        field: 'name',
        userMessage: 'Give the schedule a name of up to 60 characters.',
      );
    }
    if (days.isEmpty) {
      return const ValidationFailure(
        field: 'days',
        userMessage: 'Choose at least one working day.',
      );
    }
    final weekdays = <int>{};
    for (final day in days) {
      if (day.weekday < DateTime.monday ||
          day.weekday > DateTime.sunday ||
          !weekdays.add(day.weekday)) {
        return const ValidationFailure(
          field: 'days',
          userMessage: 'Each weekday can appear only once.',
        );
      }
      if (!_isTimeOfDay(day.start) ||
          !_isTimeOfDay(day.end) ||
          day.start == day.end) {
        return const ValidationFailure(
          field: 'days',
          userMessage: 'Each working day needs different start and end times.',
        );
      }
    }
    if (_outOfRange(lateTolerance) || _outOfRange(earlyDepartureTolerance)) {
      return const ValidationFailure(
        field: 'tolerance',
        userMessage:
            'Allowed lateness and early leaving must be 0 to 120 '
            'minutes.',
      );
    }
    final automaticBreak = this.automaticBreak;
    if (automaticBreak != null &&
        (automaticBreak.deduct <= Duration.zero ||
            automaticBreak.deduct > AttendancePolicy.maxBreak ||
            automaticBreak.after <= automaticBreak.deduct ||
            automaticBreak.after > const Duration(hours: 24))) {
      return const ValidationFailure(
        field: 'break',
        userMessage:
            'The break must be 1 minute to 4 hours, and apply after '
            'more time than it lasts.',
      );
    }
    return null;
  }

  /// What this schedule expects on [date] in [zone].
  DaySchedule dayScheduleOn(LocalDate date, CompanyTimeZone zone) {
    final day = dayFor(date.weekday);
    if (day == null) {
      return DayOff(scheduleName: name);
    }
    final endDate = day.crossesMidnight ? date.addDays(1) : date;
    return ScheduledShift(
      scheduleName: name,
      date: date,
      start: zone.instantAt(date, day.start),
      end: zone.instantAt(endDate, day.end),
      lateTolerance: lateTolerance,
      earlyDepartureTolerance: earlyDepartureTolerance,
      automaticBreak: automaticBreak,
      crossesMidnight: day.crossesMidnight,
    );
  }

  /// Names of the settings that differ from [other], for the audit log.
  List<String> changedFieldsFrom(WorkScheduleDetails other) {
    bool sameDays() {
      if (days.length != other.days.length) {
        return false;
      }
      for (var i = 0; i < days.length; i++) {
        if (days[i] != other.days[i]) {
          return false;
        }
      }
      return true;
    }

    return [
      if (name != other.name) 'name',
      if (!sameDays()) 'days',
      if (lateTolerance != other.lateTolerance) 'lateTolerance',
      if (earlyDepartureTolerance != other.earlyDepartureTolerance)
        'earlyDepartureTolerance',
      if (automaticBreak != other.automaticBreak) 'automaticBreak',
    ];
  }

  static bool _isTimeOfDay(Duration d) =>
      !d.isNegative && d < const Duration(days: 1);

  static bool _outOfRange(Duration d) => d.isNegative || d > maxTolerance;
}

/// A persisted work schedule.
final class WorkSchedule {
  const WorkSchedule({
    required this.id,
    required this.companyId,
    required this.details,
    required this.version,
  });

  final String id;
  final String companyId;
  final WorkScheduleDetails details;

  /// Pass back as `expectedVersion` when updating.
  final int version;
}

/// One period of an employee following a schedule (or none).
final class ScheduleAssignment {
  const ScheduleAssignment({
    required this.id,
    required this.employeeId,
    required this.scheduleId,
    required this.effectiveFrom,
    required this.effectiveTo,
  });

  final String id;
  final String employeeId;

  /// `null`: no schedule during this period.
  final String? scheduleId;
  final LocalDate effectiveFrom;

  /// Inclusive last day, or `null` while current.
  final LocalDate? effectiveTo;

  bool appliesOn(LocalDate date) {
    if (date.isBefore(effectiveFrom)) {
      return false;
    }
    final end = effectiveTo;
    return end == null || !date.isAfter(end);
  }
}
