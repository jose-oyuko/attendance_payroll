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
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;
import 'generated/schema_v8.dart' as v8;

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

  test('v5 → v6 keeps the kiosk setting unchanged', () async {
    const at = '2026-10-08T05:00:00.000Z';
    const company = v5.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const device = v5.DeviceSettingsData(
      id: 'this_device',
      kioskCompanyId: 'co-1',
      updatedAt: at,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 5,
      newVersion: 6,
      createOld: v5.DatabaseAtV5.new,
      createNew: v6.DatabaseAtV6.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.deviceSettings, device);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.deviceSettings).get(), [
          v6.DeviceSettingsData.fromJson(device.toJson()),
        ]);
        expect(await newDb.select(newDb.exceptionReviews).get(), isEmpty);
      },
    );
  });

  test('v6 → v7 keeps exception reviews through the table rebuild', () async {
    const at = '2026-10-08T05:00:00.000Z';
    const company = v6.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const admin = v6.AdminUsersData(
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
    const employee = v6.EmployeesData(
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
    const event = v6.AttendanceEventsData(
      id: 'ev-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      employeeId: 'emp-1',
      eventType: 'clockOut',
      occurredAt: at,
      recordedAt: at,
      source: 'kiosk',
      deviceId: 'device-1',
      createdBy: 'emp-1',
    );
    const review = v6.ExceptionReviewsData(
      id: 'rev-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      companyId: 'co-1',
      employeeId: 'emp-1',
      issueKey: 'excessiveDuration:ev-1',
      issueType: 'excessiveDuration',
      eventId: 'ev-1',
      issueOccurredAt: at,
      status: 'resolved',
      reason: 'Stocktaking',
      reviewedBy: 'adm-1',
      reviewedAt: at,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 6,
      newVersion: 7,
      createOld: v6.DatabaseAtV6.new,
      createNew: v7.DatabaseAtV7.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.adminUsers, admin)
          ..insert(oldDb.employees, employee)
          ..insert(oldDb.attendanceEvents, event)
          ..insert(oldDb.exceptionReviews, review);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.exceptionReviews).get(), [
          v7.ExceptionReviewsData.fromJson(review.toJson()),
        ]);
        expect(await newDb.select(newDb.workSchedules).get(), isEmpty);
        expect(await newDb.select(newDb.scheduleAssignments).get(), isEmpty);
      },
    );
  });

  test('v7 → v8 keeps schedules unchanged', () async {
    const at = '2026-10-09T05:00:00.000Z';
    const company = v7.CompaniesData(
      id: 'co-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      name: 'Acme Ltd',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );
    const schedule = v7.WorkSchedulesData(
      id: 'sch-1',
      createdAt: at,
      updatedAt: at,
      version: 1,
      syncState: 'localOnly',
      companyId: 'co-1',
      name: 'Day shift',
      lateToleranceMinutes: 10,
      earlyDepartureToleranceMinutes: 10,
    );
    const day = v7.WorkScheduleDaysData(
      id: 'day-1',
      scheduleId: 'sch-1',
      weekday: 1,
      startMinute: 480,
      endMinute: 1020,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 7,
      newVersion: 8,
      createOld: v7.DatabaseAtV7.new,
      createNew: v8.DatabaseAtV8.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.companies, company)
          ..insert(oldDb.workSchedules, schedule)
          ..insert(oldDb.workScheduleDays, day);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.workSchedules).get(), [
          v8.WorkSchedulesData.fromJson(schedule.toJson()),
        ]);
        expect(await newDb.select(newDb.workScheduleDays).get(), [
          v8.WorkScheduleDaysData.fromJson(day.toJson()),
        ]);
        expect(await newDb.select(newDb.payrollPeriods).get(), isEmpty);
      },
    );
  });
}
