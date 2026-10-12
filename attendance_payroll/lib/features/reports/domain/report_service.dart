import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_management_service.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_service.dart';
import 'package:attendance_payroll/features/reports/domain/report_documents.dart';

/// Gathers the data of each document through the features' own services,
/// so documents show exactly what the screens and payroll use, and the
/// same permissions apply.
final class ReportService {
  ReportService({
    required this._companies,
    required this._employees,
    required this._attendance,
    required this._exceptions,
    required this._payroll,
    this._clock = systemClockUtc,
  });

  /// The longest range an attendance or exception report covers, in days.
  static const int maxReportDays = 366;

  static const String notCalculatedRule = 'report_payroll_not_calculated';
  static const String nothingToPrintRule = 'report_nothing_to_print';

  final CompanyRepository _companies;
  final EmployeeManagementService _employees;
  final AttendanceService _attendance;
  final AttendanceExceptionService _exceptions;
  final PayrollService _payroll;
  final Clock _clock;

  /// Payslips from the period's current calculation: everyone paid, by
  /// name, or only [employeeId].
  Future<Result<List<PayslipDocument>>> payslips(
    AdminSession session,
    String periodId, {
    String? employeeId,
  }) {
    return Result.guard(() async {
      final (:company, :zone) = await _company(session);
      final (:period, :run) = await _calculatedPeriod(session, periodId);
      final employees = await _employeesById(session);
      final header = _header(company, zone);
      final payslips = [
        for (final line in run.result.lines)
          if (employeeId == null || line.employeeId == employeeId)
            PayslipDocument(
              header: header,
              period: period,
              employee: DocumentEmployee.of(employees[line.employeeId]!),
              line: line,
            ),
      ]..sort((a, b) => _byName(a.employee, b.employee));
      if (payslips.isEmpty) {
        throw const BusinessRuleFailure(
          rule: nothingToPrintRule,
          userMessage: 'Nobody is paid in this calculation.',
        );
      }
      return payslips;
    });
  }

  /// Everyone's pay for the period, from its current calculation.
  Future<Result<PayrollSummaryDocument>> payrollSummary(
    AdminSession session,
    String periodId,
  ) {
    return Result.guard(() async {
      final (:company, :zone) = await _company(session);
      final (:period, :run) = await _calculatedPeriod(session, periodId);
      final employees = await _employeesById(session);
      final lines = [
        for (final line in run.result.lines)
          (
            employee: DocumentEmployee.of(employees[line.employeeId]!),
            line: line,
          ),
      ]..sort((a, b) => _byName(a.employee, b.employee));
      return PayrollSummaryDocument(
        header: _header(company, zone),
        period: period,
        lines: lines,
        result: run.result,
      );
    });
  }

  /// Everyone's attendance from [from] to [to].
  Future<Result<AttendanceDocument>> attendanceReport(
    AdminSession session, {
    required LocalDate from,
    required LocalDate to,
  }) => _attendanceDocument(session, from: from, to: to);

  /// One employee's attendance from [from] to [to].
  Future<Result<AttendanceDocument>> timesheet(
    AdminSession session,
    String employeeId, {
    required LocalDate from,
    required LocalDate to,
  }) async {
    final document = await _attendanceDocument(
      session,
      from: from,
      to: to,
      employeeId: employeeId,
    );
    if (document case Ok(:final value) when value.groups.isEmpty) {
      return const Err(
        BusinessRuleFailure(
          rule: nothingToPrintRule,
          userMessage: 'This employee has no attendance in these dates.',
        ),
      );
    }
    return document;
  }

  /// Exceptions in the range still waiting for a decision.
  Future<Result<ExceptionReportDocument>> exceptionReport(
    AdminSession session, {
    required LocalDate from,
    required LocalDate to,
  }) {
    return Result.guard(() async {
      _checkRange(from, to);
      final (:company, :zone) = await _company(session);
      final exceptions = (await _exceptions.list(
        session,
        from: from,
        to: to,
      )).unwrap();
      final rows = [
        for (final e in exceptions)
          if (e.status.needsAction) ExceptionDocumentRow.of(e, zone),
      ]..sort(_byEmployeeThenTime);
      return ExceptionReportDocument(
        header: _header(company, zone),
        from: from,
        to: to,
        rows: rows,
      );
    });
  }

  // -------------------------------------------------------------------------

  Future<Result<AttendanceDocument>> _attendanceDocument(
    AdminSession session, {
    required LocalDate from,
    required LocalDate to,
    String? employeeId,
  }) {
    return Result.guard(() async {
      _checkRange(from, to);
      final (:company, :zone) = await _company(session);
      // The attendance service reads at most `maxRangeDays` at a time; each
      // date's rows do not depend on the window it is read in.
      final days = <EmployeeDay>[];
      for (
        var start = from;
        !start.isAfter(to);
        start = start.addDays(AttendanceService.maxRangeDays)
      ) {
        final last = start.addDays(AttendanceService.maxRangeDays - 1);
        final end = last.isAfter(to) ? to : last;
        final range = (await _attendance.range(
          session,
          from: start,
          to: end,
        )).unwrap();
        days.addAll(
          range.rows.where(
            (d) => employeeId == null || d.employee.id == employeeId,
          ),
        );
      }
      final byEmployee = <String, List<EmployeeDay>>{};
      for (final day in days) {
        (byEmployee[day.employee.id] ??= []).add(day);
      }
      final groups = [
        for (final days in byEmployee.values)
          AttendanceDocumentGroup(
            days..sort((a, b) => a.date.compareTo(b.date)),
            zone,
          ),
      ]..sort((a, b) => _byName(a.employee, b.employee));
      return AttendanceDocument(
        header: _header(company, zone),
        from: from,
        to: to,
        groups: groups,
      );
    });
  }

  static void _checkRange(LocalDate from, LocalDate to) {
    if (to.isBefore(from)) {
      throw const ValidationFailure(
        field: 'to',
        userMessage: 'The end date cannot be before the start date.',
      );
    }
    if (!to.isBefore(from.addDays(maxReportDays))) {
      throw const ValidationFailure(
        field: 'to',
        userMessage: 'Choose at most $maxReportDays days.',
      );
    }
  }

  Future<({CompanyDetails company, CompanyTimeZone zone})> _company(
    AdminSession session,
  ) async {
    final company = (await _companies.getById(session.companyId)).unwrap();
    final name = company.details.timezone;
    if (!CompanyTimeZone.isKnown(name)) {
      throw const BusinessRuleFailure(
        rule: AttendanceService.unknownTimeZoneRule,
        userMessage:
            "The company's timezone is not recognised. Update it in the "
            'company settings.',
      );
    }
    return (company: company.details, zone: CompanyTimeZone(name));
  }

  Future<({PayrollPeriod period, PayrollRun run})> _calculatedPeriod(
    AdminSession session,
    String periodId,
  ) async {
    final period = (await _payroll.period(session, periodId)).unwrap();
    final run = (await _payroll.currentRun(session, periodId)).unwrap();
    if (run == null) {
      throw const BusinessRuleFailure(
        rule: notCalculatedRule,
        userMessage: 'Calculate the payroll before printing it.',
      );
    }
    return (period: period, run: run);
  }

  /// Every employee, archived ones included (they may be paid).
  Future<Map<String, Employee>> _employeesById(AdminSession session) async {
    final employees = (await _employees.list(
      session,
      includeArchived: true,
    )).unwrap();
    return {for (final e in employees) e.id: e};
  }

  DocumentHeader _header(CompanyDetails company, CompanyTimeZone zone) =>
      DocumentHeader(company: company, generatedAt: zone.wallTimeOf(_clock()));

  static int _byName(DocumentEmployee a, DocumentEmployee b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.number.compareTo(b.number);
  }

  static int _byEmployeeThenTime(
    ExceptionDocumentRow a,
    ExceptionDocumentRow b,
  ) {
    final byName = _byName(a.employee, b.employee);
    if (byName != 0) {
      return byName;
    }
    final byDate = a.at.date.compareTo(b.at.date);
    if (byDate != 0) {
      return byDate;
    }
    final byTime = a.at.timeOfDay.compareTo(b.at.timeOfDay);
    return byTime != 0 ? byTime : a.type.index.compareTo(b.type.index);
  }
}
