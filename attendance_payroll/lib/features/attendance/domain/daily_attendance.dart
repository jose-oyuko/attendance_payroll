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
    required this.employee,
    required this.sessions,
    required this.issues,
    required this.schedule,
    required this.now,
  });

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
