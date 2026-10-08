import 'package:attendance_payroll/core/database/app_database.steps.dart';
import 'package:attendance_payroll/core/database/converters.dart';
import 'package:attendance_payroll/core/database/sync_state.dart';
import 'package:attendance_payroll/core/database/tables.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// The application's SQLite database.
///
/// Only repositories in feature `data/` folders use this class; presentation
/// and domain code never see it.
@DriftDatabase(
  tables: [
    Companies,
    AdminUsers,
    Employees,
    EmployeeRates,
    Credentials,
    AuditLog,
    DeviceIdentity,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the database file in the app's documents directory, running SQLite
  /// on a background isolate so queries never block the UI.
  factory AppDatabase.onDevice() {
    return AppDatabase(driftDatabase(name: fileName));
  }

  static const String fileName = 'attendance_payroll';

  /// Schema history. Every change increments this number and adds a migration
  /// step; see docs/DATABASE.md.
  ///
  /// 1 — companies, admin users, employees, employee rates.
  /// 2 — credentials, audit log, device identity.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.createTable(schema.credentials);
          await m.createTable(schema.auditLog);
          await m.createIndex(schema.auditLogCompanyTime);
          await m.createIndex(schema.auditLogEntity);
          await m.createTable(schema.deviceIdentity);
        },
      ),
      beforeOpen: (details) async {
        // SQLite leaves foreign keys off unless enabled per connection.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// The live company [id]. Throws a [NotFoundFailure] otherwise, which rolls
  /// back the surrounding transaction.
  Future<CompanyRow> requireCompany(String id) async {
    final row = await (select(
      companies,
    )..where((c) => c.id.equals(id) & c.deletedAt.isNull())).getSingleOrNull();
    return row ?? (throw const NotFoundFailure(entity: 'company'));
  }

  /// The live employee [id]. Throws a [NotFoundFailure] otherwise, which rolls
  /// back the surrounding transaction.
  Future<EmployeeRow> requireEmployee(String id) async {
    final row = await (select(
      employees,
    )..where((e) => e.id.equals(id) & e.deletedAt.isNull())).getSingleOrNull();
    return row ?? (throw const NotFoundFailure(entity: 'employee'));
  }
}
