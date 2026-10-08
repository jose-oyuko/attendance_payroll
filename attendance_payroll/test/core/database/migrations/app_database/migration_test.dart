import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;

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

  test('v2 → v3 keeps every existing row unchanged', () async {
    const at = '2026-10-07T08:00:00.000Z';
    const company = v2.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const admin = v2.AdminUsersData(
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
      lastLoginAt: at,
    );
    const employee = v2.EmployeesData(
      id: 'emp-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      companyId: 'co-1',
      employeeNumber: 'E0001',
      firstName: 'John',
      lastName: 'Kamau',
      employmentStatus: 'active',
      employmentStartDate: '2026-01-01',
    );
    const credential = v2.CredentialsData(
      id: 'cred-1',
      kind: 'employeePin',
      employeeId: 'emp-1',
      secretHash: r'pbkdf2-sha256$20000$c2FsdA==$a2V5',
      isTemporary: 1,
      failedAttempts: 2,
      changedAt: at,
      updatedAt: at,
    );
    const audit = v2.AuditLogData(
      id: 'audit-1',
      companyId: 'co-1',
      actorType: 'admin',
      actorId: 'adm-1',
      action: 'employee.pin_reset',
      entityType: 'employee',
      entityId: 'emp-1',
      occurredAt: at,
      deviceId: 'device-1',
      syncState: 'localOnly',
    );
    const device = v2.DeviceIdentityData(id: 'device-1', createdAt: at);

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.adminUsers, admin)
          ..insert(oldDb.employees, employee)
          ..insert(oldDb.credentials, credential)
          ..insert(oldDb.auditLog, audit)
          ..insert(oldDb.deviceIdentity, device);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.companies).get(), [
          v3.CompaniesData.fromJson(company.toJson()),
        ]);
        expect(await newDb.select(newDb.adminUsers).get(), [
          v3.AdminUsersData.fromJson(admin.toJson()),
        ]);
        expect(await newDb.select(newDb.employees).get(), [
          v3.EmployeesData.fromJson(employee.toJson()),
        ]);
        expect(await newDb.select(newDb.credentials).get(), [
          v3.CredentialsData.fromJson(credential.toJson()),
        ]);
        expect(await newDb.select(newDb.auditLog).get(), [
          v3.AuditLogData.fromJson(audit.toJson()),
        ]);
        expect(await newDb.select(newDb.deviceIdentity).get(), [
          v3.DeviceIdentityData.fromJson(device.toJson()),
        ]);
        expect(await newDb.select(newDb.attendanceEvents).get(), isEmpty);
      },
    );
  });

  test('v3 → v4 keeps attendance events unchanged', () async {
    const at = '2026-10-07T05:02:00.000Z';
    const company = v3.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const employee = v3.EmployeesData(
      id: 'emp-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      companyId: 'co-1',
      employeeNumber: 'E0001',
      firstName: 'John',
      lastName: 'Kamau',
      employmentStatus: 'active',
      employmentStartDate: '2026-01-01',
    );
    const event = v3.AttendanceEventsData(
      id: 'ev-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      employeeId: 'emp-1',
      eventType: 'clockIn',
      occurredAt: at,
      recordedAt: at,
      source: 'kiosk',
      deviceId: 'device-1',
      createdBy: 'emp-1',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.employees, employee)
          ..insert(oldDb.attendanceEvents, event);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.attendanceEvents).get(), [
          v4.AttendanceEventsData.fromJson(event.toJson()),
        ]);
        expect(await newDb.select(newDb.attendanceSettings).get(), isEmpty);
        expect(await newDb.select(newDb.attendanceCorrections).get(), isEmpty);
      },
    );
  });

  test('v4 → v5 keeps settings and corrections unchanged', () async {
    const at = '2026-10-07T05:02:00.000Z';
    const company = v4.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const settings = v4.AttendanceSettingsData(
      id: 'set-1',
      createdAt: at,
      updatedAt: at,
      version: 2,
      syncState: 'localOnly',
      companyId: 'co-1',
      duplicateWindowMinutes: 5,
      staleOpenSessionMinutes: 1200,
      excessiveDurationMinutes: 600,
      breakAfterMinutes: 360,
      breakMinutes: 30,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.attendanceSettings, settings);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.attendanceSettings).get(), [
          v5.AttendanceSettingsData.fromJson(settings.toJson()),
        ]);
        expect(await newDb.select(newDb.deviceSettings).get(), isEmpty);
      },
    );
  });
}
