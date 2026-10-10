import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/locking/payroll_lock.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';

/// Administrator operations on employees.
///
/// Every call checks the session's permissions and keeps it inside its own
/// company; every change is written together with its audit entry in one
/// transaction, so neither can exist without the other.
final class EmployeeManagementService {
  EmployeeManagementService({
    required this._employees,
    required this._rates,
    required this._audit,
    required this._transactions,
    required this._payrollLock,
  });

  /// Suggested employee numbers look like `E0001`.
  static const String numberPrefix = 'E';
  static const int numberDigits = 4;
  static final RegExp _numberPattern = RegExp('^$numberPrefix(\\d+)\$');

  final EmployeeRepository _employees;
  final EmployeeRateRepository _rates;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;
  final PayrollLock _payrollLock;

  Future<Result<List<Employee>>> list(
    AdminSession session, {
    bool includeArchived = false,
  }) async {
    if (session.check(Permission.viewEmployees) case final denied?) {
      return Err(denied);
    }
    return _employees.listByCompany(
      session.companyId,
      includeArchived: includeArchived,
    );
  }

  Future<Result<Employee>> get(AdminSession session, String id) async {
    if (session.check(Permission.viewEmployees) case final denied?) {
      return Err(denied);
    }
    return _employees.getInCompany(session.companyId, id);
  }

  /// The next free number in the `E0001` sequence. Numbers in other formats
  /// are left alone; the administrator may still type any number.
  Future<Result<String>> suggestEmployeeNumber(AdminSession session) async {
    final all = await list(session, includeArchived: true);
    return all.map((employees) {
      var highest = 0;
      for (final employee in employees) {
        final match = _numberPattern.firstMatch(
          employee.details.employeeNumber,
        );
        final value = int.tryParse(match?[1] ?? '');
        if (value != null && value > highest) {
          highest = value;
        }
      }
      return '$numberPrefix${(highest + 1).toString().padLeft(numberDigits, '0')}';
    });
  }

  Future<Result<Employee>> create(
    AdminSession session,
    EmployeeDetails details,
  ) async {
    if (session.check(Permission.manageEmployees) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final employee = (await _employees.create(
        session.companyId,
        details,
      )).unwrap();
      await _record(session, AuditAction.employeeCreated, employee.id);
      return employee;
    });
  }

  /// Saves edited details. A status change made here is audited as an edit;
  /// use [changeStatus] for activation, suspension and archiving.
  Future<Result<Employee>> update(
    AdminSession session,
    String id,
    EmployeeDetails details, {
    required int expectedVersion,
  }) async {
    if (session.check(Permission.manageEmployees) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final before = (await _employees.getInCompany(
        session.companyId,
        id,
      )).unwrap();
      final after = (await _employees.update(
        id,
        details,
        expectedVersion: expectedVersion,
      )).unwrap();
      await _record(
        session,
        AuditAction.employeeUpdated,
        id,
        metadata: {'fields': after.details.changedFieldsFrom(before.details)},
      );
      return after;
    });
  }

  /// Activates, deactivates, suspends or archives [employee]. Archived and
  /// inactive employees keep their history but cannot sign in at the kiosk.
  Future<Result<Employee>> changeStatus(
    AdminSession session,
    Employee employee,
    EmploymentStatus status,
  ) async {
    if (session.check(Permission.manageEmployees) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final before = (await _employees.getInCompany(
        session.companyId,
        employee.id,
      )).unwrap();
      final after = (await _employees.update(
        employee.id,
        before.details.withStatus(status),
        expectedVersion: employee.version,
      )).unwrap();
      await _record(
        session,
        AuditAction.employeeStatusChanged,
        employee.id,
        metadata: {
          'from': before.details.employmentStatus.name,
          'to': status.name,
        },
      );
      return after;
    });
  }

  Future<Result<List<EmployeeRate>>> rateHistory(
    AdminSession session,
    String employeeId,
  ) async {
    if (session.check(Permission.viewEmployees) case final denied?) {
      return Err(denied);
    }
    final employee = await _employees.getInCompany(
      session.companyId,
      employeeId,
    );
    if (employee case Err(:final failure)) {
      return Err(failure);
    }
    return _rates.history(employeeId);
  }

  /// Adds a pay rate; see `EmployeeRateRepository.addRate` for the rules.
  Future<Result<EmployeeRate>> addRate(
    AdminSession session,
    String employeeId,
    NewEmployeeRate rate,
  ) async {
    if (session.check(Permission.manageEmployees) case final denied?) {
      return Err(denied);
    }
    // A new rate applies from its start onwards, so it would change any
    // approved or finalized payroll ending on or after that date.
    final locked = await _payrollLock.lockedPeriodOn(
      session.companyId,
      rate.effectiveFrom,
      orLater: true,
    );
    switch (locked) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final name?):
        return Err(
          BusinessRuleFailure(
            rule: payrollLockedRule,
            userMessage: payrollLockedMessage(name),
          ),
        );
      case Ok():
        break;
    }
    return _transactions.run(() async {
      (await _employees.getInCompany(session.companyId, employeeId)).unwrap();
      final added = (await _rates.addRate(employeeId, rate)).unwrap();
      // The amount stays in the rate history, not in the audit trail.
      await _record(
        session,
        AuditAction.employeeRateAdded,
        employeeId,
        metadata: {
          'rateType': added.rateType.name,
          'effectiveFrom': added.effectiveFrom.toIsoString(),
        },
      );
      return added;
    });
  }

  Future<void> _record(
    AdminSession session,
    AuditAction action,
    String employeeId, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    (await _audit.record(
      AuditEntry(
        companyId: session.companyId,
        actorType: AuditActorType.admin,
        actorId: session.admin.id,
        action: action,
        entityType: 'employee',
        entityId: employeeId,
        metadata: metadata,
      ),
    )).unwrap();
  }
}
