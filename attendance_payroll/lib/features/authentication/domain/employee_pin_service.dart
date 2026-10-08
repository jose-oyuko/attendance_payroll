import 'dart:math';

import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/security/lockout_policy.dart';
import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/credential.dart';
import 'package:attendance_payroll/features/authentication/domain/credential_verifier.dart';
import 'package:attendance_payroll/features/authentication/domain/pin_policy.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';

enum PinState { notSet, active, temporary, locked }

/// What an administrator may know about an employee's PIN. Never the PIN.
final class PinStatus {
  const PinStatus(this.state, {this.lockedUntil});

  final PinState state;
  final DateTime? lockedUntil;
}

/// A successful PIN check.
final class PinVerification {
  const PinVerification({required this.employee, required this.mustChangePin});

  final Employee employee;

  /// The PIN was issued by an administrator and must be replaced now.
  final bool mustChangePin;
}

/// Employee PIN management and verification.
///
/// Administrators can issue (reset) a PIN but can never read one: only a hash
/// is stored, and an issued PIN is returned exactly once to be handed over.
final class EmployeePinService {
  EmployeePinService({
    required this._employees,
    required this._credentials,
    required this._audit,
    required this._transactions,
    required SecretHasher pinHasher,
    this._clock = systemClockUtc,
    Random? random,
  }) : _hasher = pinHasher,
       _random = random ?? Random.secure(),
       _verifier = CredentialVerifier(
         credentials: _credentials,
         hasher: pinHasher,
         policy: lockoutPolicy,
         clock: _clock,
       );

  /// Five wrong PINs lock the PIN for 1 minute, doubling per further lock up
  /// to a day, so a short PIN cannot be guessed at a kiosk.
  static const LockoutPolicy lockoutPolicy = LockoutPolicy(
    maxAttempts: 5,
    baseLockDuration: Duration(minutes: 1),
    maxLockDuration: Duration(days: 1),
  );

  static const String _wrongPin = 'Incorrect PIN.';

  final EmployeeRepository _employees;
  final CredentialRepository _credentials;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;
  final SecretHasher _hasher;
  final Clock _clock;
  final Random _random;
  final CredentialVerifier _verifier;

  Future<Result<PinStatus>> status(
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
    final found = await _credentials.find(CredentialOwner.employee(employeeId));
    return found.map((credential) {
      if (credential == null) {
        return const PinStatus(PinState.notSet);
      }
      final until = credential.lockedUntil;
      if (lockoutPolicy.isLocked(until, _clock())) {
        return PinStatus(PinState.locked, lockedUntil: until);
      }
      return PinStatus(
        credential.isTemporary ? PinState.temporary : PinState.active,
      );
    });
  }

  /// Replaces the employee's PIN with a random temporary one, clears any
  /// lock and returns the new PIN. It is shown once and cannot be retrieved
  /// again; the employee must change it on first use.
  Future<Result<String>> issueTemporaryPin(
    AdminSession session,
    String employeeId,
  ) async {
    if (session.check(Permission.manageEmployeePins) case final denied?) {
      return Err(denied);
    }
    final employee = await _employees.getInCompany(
      session.companyId,
      employeeId,
    );
    if (employee case Err(:final failure)) {
      return Err(failure);
    }
    final pin = PinPolicy.generate(_random);
    final pinHash = await _hasher.hash(pin);
    final saved = await _transactions.run(() async {
      (await _credentials.replaceSecret(
        CredentialOwner.employee(employeeId),
        pinHash,
        isTemporary: true,
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.employeePinReset,
          entityType: 'employee',
          entityId: employeeId,
        ),
      )).unwrap();
    });
    return saved.map((_) => pin);
  }

  /// Checks an employee's PIN, for example at the attendance kiosk. Only
  /// active employees can authenticate.
  Future<Result<PinVerification>> verifyPin(
    String employeeId,
    String pin,
  ) async {
    final found = await _employees.getById(employeeId);
    if (found case Err(:final failure)) {
      return Err(failure);
    }
    final employee = found.valueOrNull!;
    if (employee.details.employmentStatus != EmploymentStatus.active) {
      await _hasher.verifyAgainstDummy(pin);
      return const Err(
        AuthenticationFailure(
          userMessage: 'This employee cannot sign in. Contact your manager.',
        ),
      );
    }
    final verified = await _verifier.verify(
      CredentialOwner.employee(employeeId),
      pin,
      wrongSecretMessage: _wrongPin,
      onLockedOut: () => _audit.record(
        AuditEntry(
          companyId: employee.companyId,
          actorType: AuditActorType.system,
          actorId: null,
          action: AuditAction.employeePinLockedOut,
          entityType: 'employee',
          entityId: employeeId,
        ),
      ),
    );
    return verified.map(
      (credential) => PinVerification(
        employee: employee,
        mustChangePin: credential.isTemporary,
      ),
    );
  }

  /// The employee replaces their PIN, proving they know the current one.
  Future<Result<void>> changePin(
    String employeeId, {
    required String currentPin,
    required String newPin,
  }) async {
    if (PinPolicy.validate(newPin) case final invalid?) {
      return Err(invalid);
    }
    if (newPin == currentPin) {
      return const Err(
        ValidationFailure(
          field: 'pin',
          userMessage: 'Choose a PIN different from the current one.',
        ),
      );
    }
    final verified = await verifyPin(employeeId, currentPin);
    if (verified case Err(:final failure)) {
      return Err(failure);
    }
    final employee = verified.valueOrNull!.employee;
    final pinHash = await _hasher.hash(newPin);
    return _transactions.run(() async {
      (await _credentials.replaceSecret(
        CredentialOwner.employee(employeeId),
        pinHash,
        isTemporary: false,
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: employee.companyId,
          actorType: AuditActorType.employee,
          actorId: employeeId,
          action: AuditAction.employeePinChanged,
          entityType: 'employee',
          entityId: employeeId,
        ),
      )).unwrap();
    });
  }
}
