import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';

/// Where an employee stands on a given day. Without work schedules (Phase 6)
/// a day with no attendance cannot yet be told apart from a day off, so it is
/// reported neutrally as "not clocked in".
enum DayStatus { notClockedIn, working, present, needsReview }

/// One employee's attendance on one company date.
final class EmployeeDay {
  const EmployeeDay({
    required this.employee,
    required this.sessions,
    required this.issues,
  });

  final Employee employee;

  /// Sessions that started on the day, chronological.
  final List<AttendanceSession> sessions;

  /// Issues revealed by events on the day, including those not tied to a
  /// session.
  final List<AttendanceIssue> issues;

  /// Clocked in right now.
  bool get isWorking =>
      sessions.any((s) => s.clockOut == null && s.status == SessionStatus.open);

  bool get needsReview =>
      sessions.any((s) => s.status == SessionStatus.exception) ||
      issues.any((i) => i.sessionKey == null);

  DayStatus get status {
    if (needsReview) {
      return DayStatus.needsReview;
    }
    if (isWorking) {
      return DayStatus.working;
    }
    return sessions.isEmpty ? DayStatus.notClockedIn : DayStatus.present;
  }

  /// Payable time of the day's completed sessions. Sessions awaiting review
  /// contribute nothing until reviewed.
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

  int get present => employees.where((e) => e.sessions.isNotEmpty).length;

  int get working => employees.where((e) => e.isWorking).length;

  int get needsReview => employees.where((e) => e.needsReview).length;

  int get notClockedIn => employees.where((e) => e.sessions.isEmpty).length;
}
