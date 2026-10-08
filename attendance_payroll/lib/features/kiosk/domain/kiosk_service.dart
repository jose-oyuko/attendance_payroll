import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';

/// Whether this device is an attendance kiosk, and for which company.
abstract interface class KioskModeRepository {
  /// The kiosk's company id, or `null` when kiosk mode is off.
  Future<Result<String?>> kioskCompanyId();

  /// Turns kiosk mode on for [companyId], or off when `null`.
  Future<Result<void>> setKioskCompany(String? companyId);
}

/// What the kiosk needs to know about its company.
final class KioskContext {
  const KioskContext({
    required this.companyId,
    required this.companyName,
    required this.timeZone,
  });

  final String companyId;
  final String companyName;
  final CompanyTimeZone timeZone;
}

/// An employee as shown on the kiosk: a name to tap, nothing more.
final class KioskEmployee {
  const KioskEmployee({required this.id, required this.name});

  final String id;
  final String name;
}

/// The attendance kiosk: a locked mode for a shared device where employees
/// identify themselves (name, then PIN) and clock in or out.
///
/// The kiosk has no administrator session, so everything it may do goes
/// through here and is refused unless kiosk mode is on for this device, and
/// only for the kiosk company's employees.
final class KioskService {
  KioskService({
    required this._kioskMode,
    required this._companies,
    required this._employees,
    required this._pins,
    required this._audit,
    required this._transactions,
  });

  static const String kioskOffRule = 'kiosk_off';

  final KioskModeRepository _kioskMode;
  final CompanyRepository _companies;
  final EmployeeRepository _employees;
  final EmployeePinService _pins;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;

  /// The kiosk's company, or `null` when this device is not a kiosk.
  Future<Result<KioskContext?>> current() async {
    final companyId = await _kioskMode.kioskCompanyId();
    if (companyId case Err(:final failure)) {
      return Err(failure);
    }
    final id = companyId.valueOrNull;
    if (id == null) {
      return const Ok(null);
    }
    final company = await _companies.getById(id);
    return company.map(
      (c) => KioskContext(
        companyId: c.id,
        companyName: c.details.name,
        timeZone: CompanyTimeZone(c.details.timezone),
      ),
    );
  }

  /// Turns this device into the session company's kiosk. The administrator
  /// should be signed out afterwards: the kiosk exposes no admin features.
  Future<Result<void>> start(AdminSession session) {
    return _switch(session, on: true);
  }

  /// Leaves kiosk mode. Requires a signed-in administrator, so an employee at
  /// the kiosk cannot do it.
  Future<Result<void>> stop(AdminSession session) {
    return _switch(session, on: false);
  }

  /// Active employees to choose from, by name.
  Future<Result<List<KioskEmployee>>> employees() async {
    final kiosk = await _requireKiosk();
    if (kiosk case Err(:final failure)) {
      return Err(failure);
    }
    final employees = await _employees.listByCompany(kiosk.valueOrNull!);
    return employees.map((all) {
      final active = [
        for (final e in all)
          if (e.details.employmentStatus == EmploymentStatus.active)
            KioskEmployee(id: e.id, name: e.details.shownName),
      ];
      return active
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  /// Checks the PIN of a kiosk employee.
  Future<Result<PinVerification>> verifyPin(
    String employeeId,
    String pin,
  ) async {
    final allowed = await _requireKioskEmployee(employeeId);
    if (allowed case Err(:final failure)) {
      return Err(failure);
    }
    return _pins.verifyPin(employeeId, pin);
  }

  /// A kiosk employee replaces their PIN (also how a temporary PIN is
  /// replaced on first use).
  Future<Result<void>> changePin(
    String employeeId, {
    required String currentPin,
    required String newPin,
  }) async {
    final allowed = await _requireKioskEmployee(employeeId);
    if (allowed case Err(:final failure)) {
      return Err(failure);
    }
    return _pins.changePin(employeeId, currentPin: currentPin, newPin: newPin);
  }

  Future<Result<void>> _switch(AdminSession session, {required bool on}) async {
    if (session.check(Permission.manageKiosk) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      (await _kioskMode.setKioskCompany(
        on ? session.companyId : null,
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: on ? AuditAction.kioskStarted : AuditAction.kioskStopped,
          entityType: 'device',
          entityId: null,
        ),
      )).unwrap();
    });
  }

  Future<Result<String>> _requireKiosk() async {
    final companyId = await _kioskMode.kioskCompanyId();
    return switch (companyId) {
      Err(:final failure) => Err(failure),
      Ok(value: null) => const Err(
        BusinessRuleFailure(
          rule: kioskOffRule,
          userMessage: 'This device is not in kiosk mode.',
        ),
      ),
      Ok(:final value?) => Ok(value),
    };
  }

  Future<Result<void>> _requireKioskEmployee(String employeeId) async {
    final kiosk = await _requireKiosk();
    if (kiosk case Err(:final failure)) {
      return Err(failure);
    }
    final employee = await _employees.getInCompany(
      kiosk.valueOrNull!,
      employeeId,
    );
    return employee.map((_) {});
  }
}
