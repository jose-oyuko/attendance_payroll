import 'dart:math';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/core/database/drift_transaction_runner.dart';
import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/features/audit/data/drift_audit_log_repository.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/data/drift_admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/data/drift_credential_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_auth_service.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/company/data/drift_company_repository.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_management_service.dart';
import 'package:drift/drift.dart';

import 'test_database.dart';

const String ownerUsername = 'owner';
const String ownerPassword = 'correct horse battery';

/// Cheap hashing for tests. Production work factors are set in
/// `authentication_providers.dart`; correctness does not depend on them.
SecretHasher fastHasher() => SecretHasher(iterations: 2);

/// Real repositories and services over a fresh in-memory database, with a
/// controllable clock.
class TestEnv {
  TestEnv({AuditLogRepository? audit}) : db = openTestDatabase() {
    this.audit =
        audit ??
        DriftAuditLogRepository(
          db,
          DriftDeviceIdentityRepository(db),
          clock: clock.call,
        );
  }

  final AppDatabase db;
  final TestClock clock = TestClock();
  late final AuditLogRepository audit;

  late final companies = DriftCompanyRepository(db, clock: clock.call);
  late final admins = DriftAdminUserRepository(db, clock: clock.call);
  late final credentials = DriftCredentialRepository(db, clock: clock.call);
  late final employees = DriftEmployeeRepository(db, clock: clock.call);
  late final rates = DriftEmployeeRateRepository(db, clock: clock.call);
  late final transactions = DriftTransactionRunner(db);

  late final auth = AdminAuthService(
    companies: companies,
    admins: admins,
    credentials: credentials,
    audit: audit,
    transactions: transactions,
    passwordHasher: fastHasher(),
    clock: clock.call,
  );

  late final pins = EmployeePinService(
    employees: employees,
    credentials: credentials,
    audit: audit,
    transactions: transactions,
    pinHasher: fastHasher(),
    clock: clock.call,
    random: Random(7),
  );

  late final management = EmployeeManagementService(
    employees: employees,
    rates: rates,
    audit: audit,
    transactions: transactions,
  );

  /// Completes first-run setup and returns the owner's session.
  Future<AdminSession> setUpOwner() async {
    return (await auth.setUp(
      company: acmeDetails,
      owner: const NewAdminUser(
        username: ownerUsername,
        displayName: 'Jane Owner',
      ),
      password: ownerPassword,
    )).unwrap();
  }

  Future<Employee> addEmployee(
    AdminSession session, {
    String employeeNumber = 'E0001',
  }) async {
    return (await management.create(
      session,
      johnDetails(employeeNumber: employeeNumber),
    )).unwrap();
  }

  Future<List<AuditLogRow>> auditRows() {
    return (db.select(
      db.auditLog,
    )..orderBy([(a) => OrderingTerm.asc(a.occurredAt)])).get();
  }

  Future<List<String>> auditActions() async {
    return [for (final row in await auditRows()) row.action];
  }
}
