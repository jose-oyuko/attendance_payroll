import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

// Generated first by `dart run drift_dev make-migrations`, then completed by
// hand. That command does not overwrite this file: when adding version N,
// extend the data-integrity test for N-1 → N.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a fresh install matches the latest exported schema', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  group('every upgrade path produces the exported schema', () {
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      for (final toVersion in versions.skip(i + 1)) {
        test('$fromVersion → $toVersion', () async {
          final schema = await verifier.schemaAt(fromVersion);
          final db = AppDatabase(schema.newConnection());
          addTearDown(db.close);

          await verifier.migrateAndValidate(db, toVersion);
        });
      }
    }
  });

  test('v1 → v2 keeps every existing row unchanged', () async {
    const at = '2026-10-01T08:00:00.000Z';
    const company = v1.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 3,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const admin = v1.AdminUsersData(
      id: 'adm-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      companyId: 'co-1',
      username: 'owner',
      displayName: 'Jane Owner',
      role: 'owner',
      active: 1,
    );
    const employee = v1.EmployeesData(
      id: 'emp-1',
      createdAt: at,
      updatedAt: at,
      version: 2,
      syncState: 'localOnly',
      companyId: 'co-1',
      employeeNumber: 'E001',
      firstName: 'John',
      lastName: 'Kamau',
      employmentStatus: 'active',
      employmentStartDate: '2026-01-01',
    );
    const rate = v1.EmployeeRatesData(
      id: 'rate-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      employeeId: 'emp-1',
      rateType: 'hourly',
      amountMinor: 50000,
      currencyCode: 'KES',
      effectiveFrom: '2026-01-01',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.adminUsers, admin)
          ..insert(oldDb.employees, employee)
          ..insert(oldDb.employeeRates, rate);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.companies).get(), [
          v2.CompaniesData.fromJson(company.toJson()),
        ]);
        expect(await newDb.select(newDb.adminUsers).get(), [
          v2.AdminUsersData.fromJson(admin.toJson()),
        ]);
        expect(await newDb.select(newDb.employees).get(), [
          v2.EmployeesData.fromJson(employee.toJson()),
        ]);
        expect(await newDb.select(newDb.employeeRates).get(), [
          v2.EmployeeRatesData.fromJson(rate.toJson()),
        ]);
        expect(await newDb.select(newDb.credentials).get(), isEmpty);
      },
    );
  });
}
