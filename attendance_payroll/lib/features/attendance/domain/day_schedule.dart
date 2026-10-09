import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';

/// What an employee is expected to work on one company date.
sealed class DaySchedule {
  const DaySchedule();
}

/// No schedule is assigned: attendance is judged without expectations.
final class Unscheduled extends DaySchedule {
  const Unscheduled();
}

/// The employee's schedule has no shift on this day.
final class DayOff extends DaySchedule {
  const DayOff({required this.scheduleName});

  final String scheduleName;
}

/// A shift the employee is expected to work.
final class ScheduledShift extends DaySchedule {
  const ScheduledShift({
    required this.scheduleName,
    required this.date,
    required this.start,
    required this.end,
    required this.lateTolerance,
    required this.earlyDepartureTolerance,
    required this.automaticBreak,
    required this.crossesMidnight,
  });

  final String scheduleName;

  /// The shift ends on the day after it starts (a night shift), so a
  /// session crossing midnight is expected rather than suspicious.
  final bool crossesMidnight;

  /// The company date the shift starts on.
  final LocalDate date;

  /// Expected start and end as UTC instants. [end] may be on the next date
  /// for a shift that crosses midnight.
  final DateTime start;
  final DateTime end;

  /// A clock-in this much after [start] still counts as on time.
  final Duration lateTolerance;

  /// A clock-out this much before [end] still counts as a full shift.
  final Duration earlyDepartureTolerance;

  /// The schedule's break rule, which replaces the company default on
  /// scheduled days; `null` means no automatic break.
  final AutomaticBreak? automaticBreak;
}

/// One employee's [DaySchedule] for any date.
typedef ScheduleLookup = DaySchedule Function(LocalDate date);

/// Where attendance gets schedules from. Implemented by the schedules
/// feature, so attendance does not depend on it.
abstract interface class ScheduleSource {
  /// A lookup per employee of [companyId]; employees without any schedule
  /// history may be missing from the map (they are [Unscheduled]).
  Future<Result<Map<String, ScheduleLookup>>> forCompany(
    String companyId, {
    required CompanyTimeZone timeZone,
  });
}
