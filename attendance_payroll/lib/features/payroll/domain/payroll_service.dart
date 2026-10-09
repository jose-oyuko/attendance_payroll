import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_reader.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_calculator.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';

/// Payroll periods, adjustments and calculation, for administrators.
///
/// Calculation reads only settled attendance (see [AttendanceReader]): time
/// awaiting review is reported, never paid blindly. Each calculation is
/// stored as a new run; earlier runs are kept, superseded.
final class PayrollService {
  PayrollService({
    required this._companies,
    required this._employees,
    required this._rates,
    required this._attendance,
    required this._settings,
    required this._periods,
    required this._adjustments,
    required this._runs,
    required this._audit,
    required this._transactions,
    this._calculator = const PayrollCalculator(),
    this._clock = systemClockUtc,
  });

  static const String lockedRule = 'payroll_locked';

  final CompanyRepository _companies;
  final EmployeeRepository _employees;
  final EmployeeRateRepository _rates;
  final AttendanceReader _attendance;
  final PayrollSettingsRepository _settings;
  final PayrollPeriodRepository _periods;
  final PayrollAdjustmentRepository _adjustments;
  final PayrollRunRepository _runs;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;
  final PayrollCalculator _calculator;
  final Clock _clock;

  // Settings ----------------------------------------------------------------

  Future<Result<StoredPayrollSettings>> settings(AdminSession session) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    return _settings.forCompany(session.companyId);
  }

  Future<Result<StoredPayrollSettings>> updateSettings(
    AdminSession session,
    PayrollSettings settings, {
    required int expectedVersion,
  }) async {
    if (session.check(Permission.managePayroll) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final saved = (await _settings.save(
        session.companyId,
        settings,
        expectedVersion: expectedVersion,
      )).unwrap();
      await _record(
        session,
        AuditAction.payrollSettingsChanged,
        'payroll_settings',
        session.companyId,
      );
      return saved;
    });
  }

  // Periods -----------------------------------------------------------------

  Future<Result<PayrollPeriod>> createPeriod(
    AdminSession session,
    NewPayrollPeriod period,
  ) async {
    if (session.check(Permission.managePayroll) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final created = (await _periods.create(
        session.companyId,
        period,
      )).unwrap();
      await _record(
        session,
        AuditAction.payrollPeriodCreated,
        'payroll_period',
        created.id,
        metadata: {
          'startDate': created.startDate.toIsoString(),
          'endDate': created.endDate.toIsoString(),
        },
      );
      return created;
    });
  }

  Future<Result<List<PayrollPeriod>>> periods(AdminSession session) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    return _periods.listByCompany(session.companyId);
  }

  Future<Result<PayrollPeriod>> period(AdminSession session, String id) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    return _periodOf(session, id);
  }

  // Adjustments -------------------------------------------------------------

  Future<Result<PayrollAdjustment>> addAdjustment(
    AdminSession session,
    String periodId,
    NewPayrollAdjustment adjustment,
  ) async {
    if (session.check(Permission.managePayroll) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final period = (await _periodOf(session, periodId)).unwrap();
      _requireEditable(period);
      (await _employees.getInCompany(
        session.companyId,
        adjustment.employeeId,
      )).unwrap();
      final company = (await _companies.getById(session.companyId)).unwrap();
      if (adjustment.amount.currency != company.details.currencyCode) {
        throw ValidationFailure(
          field: 'amount',
          userMessage:
              'Adjustments must be in the company currency '
              '(${company.details.currencyCode}).',
        );
      }
      final added = (await _adjustments.add(
        periodId,
        adjustment,
        createdBy: session.admin.id,
      )).unwrap();
      await _record(
        session,
        AuditAction.payrollAdjustmentAdded,
        'payroll_adjustment',
        added.id,
        metadata: {
          'periodId': periodId,
          'employeeId': added.employeeId,
          'type': added.type.name,
        },
      );
      return added;
    });
  }

  Future<Result<void>> removeAdjustment(
    AdminSession session,
    String adjustmentId,
  ) async {
    if (session.check(Permission.managePayroll) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final adjustment = (await _adjustments.getById(adjustmentId)).unwrap();
      final period = (await _periodOf(session, adjustment.periodId)).unwrap();
      _requireEditable(period);
      (await _adjustments.remove(adjustmentId)).unwrap();
      await _record(
        session,
        AuditAction.payrollAdjustmentRemoved,
        'payroll_adjustment',
        adjustmentId,
        metadata: {'periodId': period.id, 'type': adjustment.type.name},
      );
    });
  }

  Future<Result<List<PayrollAdjustment>>> adjustments(
    AdminSession session,
    String periodId,
  ) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    final period = await _periodOf(session, periodId);
    if (period case Err(:final failure)) {
      return Err(failure);
    }
    return _adjustments.forPeriod(periodId);
  }

  // Calculation -------------------------------------------------------------

  /// Calculates the period from current attendance, rates, adjustments and
  /// settings, and stores it as the period's current run.
  Future<Result<PayrollRun>> calculate(
    AdminSession session,
    String periodId,
  ) async {
    if (session.check(Permission.managePayroll) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final period = (await _periodOf(session, periodId)).unwrap();
      _requireEditable(period);
      final company = (await _companies.getById(session.companyId)).unwrap();
      final settings = (await _settings.forCompany(
        session.companyId,
      )).unwrap().settings;
      final adjustments = (await _adjustments.forPeriod(periodId)).unwrap();

      // Whole ISO weeks around the period, so weekly overtime is judged on
      // complete weeks.
      final from = period.startDate.addDays(1 - period.startDate.weekday);
      final to = period.endDate.addDays(7 - period.endDate.weekday);
      final attendance = (await _attendance.read(
        session.companyId,
        from: from,
        to: to,
      )).unwrap();

      final inputs = <EmployeePayInput>[];
      for (final employee in attendance.employees) {
        final days = <LocalDate, DayWork>{};
        for (final s in attendance.sessionsFor(employee.id)) {
          final day = days[s.workDate] ?? const DayWork();
          days[s.workDate] = switch (s.status) {
            SessionStatus.completed || SessionStatus.approved => DayWork(
              payable: day.payable + (s.payableDuration ?? Duration.zero),
              awaitingReview: day.awaitingReview,
              stillOpen: day.stillOpen,
            ),
            SessionStatus.exception => DayWork(
              payable: day.payable,
              awaitingReview: day.awaitingReview + 1,
              stillOpen: day.stillOpen,
            ),
            SessionStatus.open => DayWork(
              payable: day.payable,
              awaitingReview: day.awaitingReview,
              stillOpen: day.stillOpen + 1,
            ),
          };
        }
        inputs.add(
          EmployeePayInput(
            employee: employee,
            rates: (await _rates.history(employee.id)).unwrap(),
            days: days,
            adjustments: [
              for (final a in adjustments)
                if (a.employeeId == employee.id) a,
            ],
          ),
        );
      }

      final result = _calculator.calculate(
        PayrollInput(
          from: period.startDate,
          to: period.endDate,
          currency: company.details.currencyCode,
          settings: settings,
          employees: inputs,
        ),
      );
      return (await _transactions.run(() async {
        final previousRuns = (await _runs.countForPeriod(periodId)).unwrap();
        final run = (await _runs.saveCalculated(
          periodId,
          result,
          calculatedBy: session.admin.id,
          calculatedAt: _clock(),
        )).unwrap();
        await _record(
          session,
          previousRuns == 0
              ? AuditAction.payrollCalculated
              : AuditAction.payrollRecalculated,
          'payroll_run',
          run.id,
          metadata: {
            'periodId': periodId,
            'employees': result.lines.length,
            'blockingIssues': result.hasBlockingIssues,
          },
        );
        return run;
      })).unwrap();
    });
  }

  /// The period's current calculation, or `null` if never calculated.
  Future<Result<PayrollRun?>> currentRun(
    AdminSession session,
    String periodId,
  ) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    final period = await _periodOf(session, periodId);
    if (period case Err(:final failure)) {
      return Err(failure);
    }
    return _runs.currentForPeriod(periodId);
  }

  // -------------------------------------------------------------------------

  /// Approved and finalized payroll never changes silently (Phase 8 adds the
  /// explicit reopen workflow).
  static void _requireEditable(PayrollPeriod period) {
    if (period.status == PayrollPeriodStatus.approved ||
        period.status == PayrollPeriodStatus.finalized) {
      throw const BusinessRuleFailure(
        rule: lockedRule,
        userMessage:
            'This payroll has been approved or finalized and cannot change. '
            'Reopen it first.',
      );
    }
  }

  Future<Result<PayrollPeriod>> _periodOf(
    AdminSession session,
    String id,
  ) async {
    final found = await _periods.getById(id);
    return switch (found) {
      Ok(:final value) when value.companyId != session.companyId => const Err(
        NotFoundFailure(entity: 'payroll period'),
      ),
      _ => found,
    };
  }

  Future<void> _record(
    AdminSession session,
    AuditAction action,
    String entityType,
    String entityId, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    (await _audit.record(
      AuditEntry(
        companyId: session.companyId,
        actorType: AuditActorType.admin,
        actorId: session.admin.id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
      ),
    )).unwrap();
  }
}
