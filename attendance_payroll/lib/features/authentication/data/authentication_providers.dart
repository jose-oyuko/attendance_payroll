import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/authentication/data/drift_admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/data/drift_credential_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_auth_service.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/credential.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/company/data/company_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// PBKDF2 work factors. Each hash records its own, so raising these later does
// not invalidate existing secrets. Passwords are entered rarely and get a
// higher cost; PINs are entered at every clock-in and are mainly protected by
// the lockout policy (a short PIN's search space is small whatever the cost).
const int _passwordIterations = 100000;
const int _pinIterations = 20000;

/// Hashing runs on a background isolate so the UI never freezes.
Future<Uint8List> _deriveInBackground(Pbkdf2Job job) {
  return compute(derivePbkdf2, job);
}

final passwordHasherProvider = Provider<SecretHasher>(
  (ref) => SecretHasher(
    iterations: _passwordIterations,
    executor: _deriveInBackground,
  ),
);

final pinHasherProvider = Provider<SecretHasher>(
  (ref) =>
      SecretHasher(iterations: _pinIterations, executor: _deriveInBackground),
);

final adminUserRepositoryProvider = Provider<AdminUserRepository>(
  (ref) => DriftAdminUserRepository(ref.watch(appDatabaseProvider)),
);

final credentialRepositoryProvider = Provider<CredentialRepository>(
  (ref) => DriftCredentialRepository(ref.watch(appDatabaseProvider)),
);

final adminAuthServiceProvider = Provider<AdminAuthService>(
  (ref) => AdminAuthService(
    companies: ref.watch(companyRepositoryProvider),
    admins: ref.watch(adminUserRepositoryProvider),
    credentials: ref.watch(credentialRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
    passwordHasher: ref.watch(passwordHasherProvider),
  ),
);

final employeePinServiceProvider = Provider<EmployeePinService>(
  (ref) => EmployeePinService(
    employees: ref.watch(employeeRepositoryProvider),
    credentials: ref.watch(credentialRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
    pinHasher: ref.watch(pinHasherProvider),
  ),
);
