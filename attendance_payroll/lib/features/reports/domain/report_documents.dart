import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';

// The data of each printable document, gathered by `ReportService`. Times
// are already company wall-clock times, so a document can be laid out
// anywhere (including a background isolate) without the database or the
// timezone database.

/// What every document prints at the top and bottom.
final class DocumentHeader {
  const DocumentHeader({required this.company, required this.generatedAt});

  final CompanyDetails company;

  /// When the document was produced, on the company's clock.
  final WallTime generatedAt;
}

/// The employee as printed on a document.
final class DocumentEmployee {
  DocumentEmployee.of(Employee employee)
    : name = employee.details.shownName,
      number = employee.details.employeeNumber,
      jobTitle = employee.details.jobTitle;

  final String name;
  final String number;
  final String? jobTitle;
}

/// One employee's pay for a period, from the period's current calculation.
final class PayslipDocument {
  const PayslipDocument({
    required this.header,
    required this.period,
    required this.employee,
    required this.line,
  });

  final DocumentHeader header;

  /// Includes the payroll status: a payslip from payroll that is not yet
  /// finalized is marked as such.
  final PayrollPeriod period;
  final DocumentEmployee employee;
  final PayrollLine line;
}

/// Everyone's pay for a period.
final class PayrollSummaryDocument {
  const PayrollSummaryDocument({
    required this.header,
    required this.period,
    required this.lines,
    required this.result,
  });

  final DocumentHeader header;
  final PayrollPeriod period;

  /// By employee name.
  final List<({DocumentEmployee employee, PayrollLine line})> lines;

  /// The whole calculation, for totals and unresolved problems.
  final PayrollResult result;
}

/// One session as printed: company wall-clock start and end.
final class DocumentSession {
  DocumentSession.of(AttendanceSession session, CompanyTimeZone zone)
    : start = zone.wallTimeOf(session.start),
      end = switch (session.end) {
        final end? => zone.wallTimeOf(end),
        null => null,
      };

  final WallTime start;

  /// `null` while the session is open (or the clock-out is missing).
  final WallTime? end;
}

/// One employee's attendance on one date.
final class AttendanceDocumentRow {
  AttendanceDocumentRow.of(EmployeeDay day, CompanyTimeZone zone)
    : date = day.date,
      sessions = [for (final s in day.sessions) DocumentSession.of(s, zone)],
      worked = day.payable,
      status = day.status,
      isLate = day.isLate,
      leftEarly = day.leftEarly,
      issues = {for (final i in day.issues) i.type}.toList();

  final LocalDate date;
  final List<DocumentSession> sessions;

  /// Payable time of settled sessions (time awaiting review counts 0).
  final Duration worked;
  final DayStatus status;
  final bool isLate;
  final bool leftEarly;
  final List<AttendanceIssueType> issues;
}

/// One employee's days in a range, with totals.
final class AttendanceDocumentGroup {
  AttendanceDocumentGroup(List<EmployeeDay> days, CompanyTimeZone zone)
    : employee = DocumentEmployee.of(days.first.employee),
      rows = [for (final d in days) AttendanceDocumentRow.of(d, zone)],
      totals = AttendanceTotals(days);

  final DocumentEmployee employee;
  final List<AttendanceDocumentRow> rows;
  final AttendanceTotals totals;
}

/// Attendance over a range: everyone (attendance report) or one employee
/// (timesheet).
final class AttendanceDocument {
  const AttendanceDocument({
    required this.header,
    required this.from,
    required this.to,
    required this.groups,
  });

  final DocumentHeader header;
  final LocalDate from;
  final LocalDate to;

  /// By employee name; each group's rows by date.
  final List<AttendanceDocumentGroup> groups;
}

/// An attendance exception still waiting for a decision.
final class ExceptionDocumentRow {
  ExceptionDocumentRow.of(AttendanceException e, CompanyTimeZone zone)
    : employee = DocumentEmployee.of(e.employee),
      at = zone.wallTimeOf(e.occurredAt),
      type = e.type,
      status = e.status,
      blocksPayroll = e.blocksPayroll;

  final DocumentEmployee employee;
  final WallTime at;
  final AttendanceIssueType type;
  final ExceptionStatus status;
  final bool blocksPayroll;
}

/// Unresolved attendance exceptions in a range.
final class ExceptionReportDocument {
  const ExceptionReportDocument({
    required this.header,
    required this.from,
    required this.to,
    required this.rows,
  });

  final DocumentHeader header;
  final LocalDate from;
  final LocalDate to;

  /// By employee name, then time.
  final List<ExceptionDocumentRow> rows;
}
