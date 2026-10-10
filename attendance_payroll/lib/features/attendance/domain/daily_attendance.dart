import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/day_schedule.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';

/// Where an employee stands on a given day.
enum DayStatus {
  /// Has attendance that needs an administrator's review.
  needsReview,

  /// Clocked in right now.
  working,

  /// Has attendance for the day.
  present,

  /// Scheduled, and the shift has not started (plus tolerance) yet.
  expected,

  /// Scheduled, past the start (plus tolerance), and no attendance.
  absent,

  /// Not scheduled to work this day.
  dayOff,

  /// No schedule is assigned, and no attendance.
  notClockedIn,
}

/// One employee's attendance on one company date.
final class EmployeeDay {
  const EmployeeDay({
    required this.date,
    required this.employee,
    required this.sessions,
    required this.issues,
    required this.schedule,
    required this.now,
  });

  /// The company date.
  final LocalDate date;

  final Employee employee;

  /// Sessions that started on the day, chronological.
  final List<AttendanceSession> sessions;

  /// Issues revealed on the day, including those not tied to a session.
  final List<AttendanceIssue> issues;

  /// What the employee was expected to work.
  final DaySchedule schedule;

  /// When this was worked out, to tell "expected" from "absent".
  final DateTime now;

  /// Clocked in right now.
  bool get isWorking =>
      sessions.any((s) => s.clockOut == null && s.status == SessionStatus.open);

  bool get isLate =>
      issues.any((i) => i.type == AttendanceIssueType.lateArrival);

  bool get leftEarly =>
      issues.any((i) => i.type == AttendanceIssueType.earlyDeparture);

  /// Anything an administrator may want to look at: an issue of any kind
  /// (lateness, leaving early, absence, attendance to review).
  bool get hasProblem => issues.isNotEmpty || needsReview;

  bool get needsReview =>
      sessions.any((s) => s.status == SessionStatus.exception) ||
      issues.any(
        (i) =>
            i.sessionKey == null &&
            i.type != AttendanceIssueType.missingAttendance,
      );

  DayStatus get status {
    if (needsReview) {
      return DayStatus.needsReview;
    }
    if (isWorking) {
      return DayStatus.working;
    }
    if (sessions.isNotEmpty) {
      return DayStatus.present;
    }
    return switch (schedule) {
      Unscheduled() => DayStatus.notClockedIn,
      DayOff() => DayStatus.dayOff,
      ScheduledShift(:final start, :final lateTolerance) =>
        now.isBefore(start.add(lateTolerance))
            ? DayStatus.expected
            : DayStatus.absent,
    };
  }

  /// Payable time of the day's completed or approved sessions. Sessions
  /// awaiting review contribute nothing until reviewed.
  Duration get payable => sessions.fold(
    Duration.zero,
    (total, s) => total + (s.payableDuration ?? Duration.zero),
  );
}

/// Every relevant employee's attendance on one company date.
final class DailyAttendance {
  const DailyAttendance({required this.date, required this.employees});

  final LocalDate date;

  /// Active employees, plus anyone else with attendance that day, by name.
  final List<EmployeeDay> employees;

  int _count(bool Function(EmployeeDay) test) => employees.where(test).length;

  int get present => _count((e) => e.sessions.isNotEmpty);

  int get working => _count((e) => e.isWorking);

  int get late => _count((e) => e.isLate);

  int get needsReview => _count((e) => e.needsReview);

  int get absent => _count((e) => e.status == DayStatus.absent);

  int get expected => _count((e) => e.status == DayStatus.expected);

  int get dayOff => _count((e) => e.status == DayStatus.dayOff);

  /// Without a schedule and without attendance.
  int get notClockedIn => _count((e) => e.status == DayStatus.notClockedIn);
}

/// Every relevant employee's attendance on each date of a range: one
/// [EmployeeDay] per employee per date.
final class AttendanceRange {
  AttendanceRange({required this.from, required this.to, required this.rows});

  final LocalDate from;
  final LocalDate to;

  /// By employee name, then by date.
  final List<EmployeeDay> rows;

  /// Each employee's days, in [rows] order.
  late final Map<String, List<EmployeeDay>> byEmployee = () {
    final grouped = <String, List<EmployeeDay>>{};
    for (final row in rows) {
      (grouped[row.employee.id] ??= []).add(row);
    }
    return grouped;
  }();
}

/// One employee's totals over some days.
final class AttendanceTotals {
  AttendanceTotals(Iterable<EmployeeDay> days) : _days = List.of(days);

  final List<EmployeeDay> _days;

  int _count(bool Function(EmployeeDay) test) => _days.where(test).length;

  late final int present = _count((d) => d.sessions.isNotEmpty);
  late final int late = _count((d) => d.isLate);
  late final int leftEarly = _count((d) => d.leftEarly);
  late final int absent = _count((d) => d.status == DayStatus.absent);
  late final int needsReview = _count((d) => d.needsReview);

  /// Payable time of settled sessions; time awaiting review is not counted.
  late final Duration payable = _days.fold(
    Duration.zero,
    (total, d) => total + d.payable,
  );
}
