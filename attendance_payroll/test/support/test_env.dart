import 'dart:math';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/core/database/drift_transaction_runner.dart';
import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/features/attendance/data/drift_attendance_correction_repository.dart';
import 'package:attendance_payroll/features/attendance/data/drift_attendance_event_repository.dart';
import 'package:attendance_payroll/features/attendance/data/drift_attendance_settings_repository.dart';
import 'package:attendance_payroll/features/attendance/data/drift_exception_review_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_reader.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_service.dart';
import 'package:attendance_payroll/features/audit/data/drift_audit_log_repository.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/data/drift_admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/data/drift_credential_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_auth_service.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/authentication/domain/pin_policy.dart';
import 'package:attendance_payroll/features/company/data/drift_company_repository.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_management_service.dart';
import 'package:attendance_payroll/features/kiosk/data/drift_kiosk_mode_repository.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:attendance_payroll/features/payroll/data/drift_payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/data/drift_payroll_run_repository.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_service.dart';
import 'package:attendance_payroll/features/schedules/data/drift_schedule_assignment_repository.dart';
import 'package:attendance_payroll/features/schedules/data/drift_work_schedule_repository.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule_service.dart';
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

  late final events = DriftAttendanceEventRepository(db, clock: clock.call);
  late final attendanceSettings = DriftAttendanceSettingsRepository(
    db,
    clock: clock.call,
  );
  late final corrections = DriftAttendanceCorrectionRepository(
    db,
    clock: clock.call,
  );

  late final reviews = DriftExceptionReviewRepository(db, clock: clock.call);

  late final reader = AttendanceReader(
    companies: companies,
    employees: employees,
    events: events,
    settings: attendanceSettings,
    reviews: reviews,
    schedules: scheduleSource,
    clock: clock.call,
  );

  late final schedulesRepo = DriftWorkScheduleRepository(db, clock: clock.call);
  late final assignments = DriftScheduleAssignmentRepository(
    db,
    clock: clock.call,
  );
  late final scheduleSource = CompanyScheduleSource(
    schedules: schedulesRepo,
    assignments: assignments,
  );
  late final scheduleService = WorkScheduleService(
    schedules: schedulesRepo,
    assignments: assignments,
    employees: employees,
    audit: audit,
    transactions: transactions,
  );

  late final payroll = PayrollService(
    companies: companies,
    employees: employees,
    rates: rates,
    attendance: reader,
    settings: DriftPayrollSettingsRepository(db, clock: clock.call),
    periods: DriftPayrollPeriodRepository(db, clock: clock.call),
    adjustments: DriftPayrollAdjustmentRepository(db, clock: clock.call),
    runs: DriftPayrollRunRepository(db, clock: clock.call),
    audit: audit,
    transactions: transactions,
    clock: clock.call,
  );

  late final attendance = AttendanceService(
    employees: employees,
    events: events,
    devices: DriftDeviceIdentityRepository(db),
    transactions: transactions,
    reader: reader,
    clock: clock.call,
  );

  late final exceptions = AttendanceExceptionService(
    reader: reader,
    reviews: reviews,
    audit: audit,
    transactions: transactions,
    clock: clock.call,
  );

  late final attendanceSettingsService = AttendanceSettingsService(
    settings: attendanceSettings,
    audit: audit,
    transactions: transactions,
  );

  late final attendanceCorrections = AttendanceCorrectionService(
    employees: employees,
    events: events,
    corrections: corrections,
    reviews: reviews,
    devices: DriftDeviceIdentityRepository(db),
    audit: audit,
    transactions: transactions,
    clock: clock.call,
  );

  late final kioskMode = DriftKioskModeRepository(db, clock: clock.call);

  late final kiosk = KioskService(
    kioskMode: kioskMode,
    companies: companies,
    employees: employees,
    pins: pins,
    audit: audit,
    transactions: transactions,
  );

  /// Gives [employee] a personal PIN through the real issue-and-change flow,
  /// then verifies it as the kiosk would.
  Future<PinVerification> signInAtKiosk(
    AdminSession session,
    Employee employee, {
    String pin = '2580',
  }) async {
    assert(PinPolicy.validate(pin) == null, 'Use a valid PIN in tests.');
    if ((await pins.status(session, employee.id)).unwrap().state ==
        PinState.notSet) {
      final temporary = (await pins.issueTemporaryPin(
        session,
        employee.id,
      )).unwrap();
      (await pins.changePin(
        employee.id,
        currentPin: temporary,
        newPin: pin,
      )).unwrap();
    }
    return (await pins.verifyPin(employee.id, pin)).unwrap();
  }

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
