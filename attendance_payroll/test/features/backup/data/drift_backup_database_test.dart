import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/backup/data/drift_backup_database.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/printing/data/drift_printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../core/database/migrations/app_database/generated/schema.dart';
import '../../../support/fake_printers.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late Directory temp;
  late DriftBackupDatabase backup;

  Future<int> count(String table) async =>
      (await env.db
              .customSelect('SELECT count(*) AS c FROM $table')
              .getSingle())
          .read<int>('c');

  /// A SQLite file with only a schema version, standing in for a backup
  /// from another version.
  Uint8List sqliteFileWithVersion(int version) {
    final path = '${temp.path}/versioned.db';
    sqlite.sqlite3.open(path)
      ..execute('CREATE TABLE t (x)')
      ..execute('PRAGMA user_version = $version')
      ..close();
    return File(path).readAsBytesSync();
  }

  Future<String?> failureRule(Future<Object?> Function() action) async {
    try {
      await action();
    } on BusinessRuleFailure catch (failure) {
      return failure.rule;
    }
    return null;
  }

  setUp(() {
    env = TestEnv();
    temp = Directory.systemTemp.createTempSync('backup-db-test');
    addTearDown(() => temp.deleteSync(recursive: true));
    backup = DriftBackupDatabase(
      env.db,
      resolveTempDirectory: () async => Directory('${temp.path}/work'),
    );
  });

  group('what is backed up', () {
    test('every table is either company data or belongs to the device', () {
      final all = {for (final t in env.db.allTables) t.actualTableName};

      expect({
        ...backup.companyTables,
        ...DriftBackupDatabase.deviceTables,
      }, all);
      expect(DriftBackupDatabase.deviceTables, {
        'device_identity',
        'device_settings',
        'printer_settings',
        'backup_settings',
      });
      expect(
        backup.companyTables,
        containsAll(['companies', 'employees', 'audit_log', 'credentials']),
      );
    });
  });

  group('snapshot', () {
    test('has nothing to back up before setup', () async {
      expect(await backup.currentCompanyId(), isNull);
      expect(
        await failureRule(backup.snapshot),
        BackupFailures.nothingToBackUpRule,
      );
    });

    test('is a sound database that says what it holds', () async {
      final admin = await env.setUpOwner();
      await env.addEmployee(admin);

      final snapshot = await backup.snapshot();

      expect(snapshot.schemaVersion, env.db.schemaVersion);
      expect(snapshot.companyName, 'Acme Ltd');
      expect(snapshot.companyId, await backup.currentCompanyId());
      expect(snapshot.summary.employees, 1);
      expect(snapshot.summary.payrollPeriods, 0);
      final checked = await backup.check(snapshot.bytes);
      expect(checked.employees, 1);
    });

    test('does not leave temporary files behind', () async {
      await env.setUpOwner();

      await backup.snapshot();

      expect(Directory('${temp.path}/work').listSync(), isEmpty);
    });
  });

  group('check', () {
    test('refuses files that are not databases', () async {
      expect(
        await failureRule(
          () => backup.check(Uint8List.fromList(List.filled(300, 7))),
        ),
        BackupFailures.invalidFileRule,
      );
    });

    test('refuses a database from a newer version of the app', () async {
      expect(
        await failureRule(
          () => backup.check(sqliteFileWithVersion(env.db.schemaVersion + 1)),
        ),
        BackupFailures.newerSchemaRule,
      );
    });

    test('refuses a database that is not this app', () async {
      expect(
        await failureRule(() => backup.check(sqliteFileWithVersion(0))),
        BackupFailures.invalidFileRule,
      );
    });
  });

  group('restore', () {
    test('replaces the company data with the snapshot', () async {
      final admin = await env.setUpOwner();
      await env.addEmployee(admin);
      final snapshot = await backup.snapshot();
      await env.addEmployee(admin, employeeNumber: 'E0002');
      expect(await count('employees'), 2);
      String? restoredCompany;

      await backup.restore(
        snapshot.bytes,
        inside: (id) async => restoredCompany = id,
      );

      expect(await count('employees'), 1);
      expect(restoredCompany, snapshot.companyId);
      expect(await backup.currentCompanyId(), snapshot.companyId);
    });

    test('the work done inside is part of the restored data', () async {
      final admin = await env.setUpOwner();
      final snapshot = await backup.snapshot();
      await env.addEmployee(admin);

      await backup.restore(
        snapshot.bytes,
        inside: (id) async {
          await env.db.customStatement(
            'INSERT INTO audit_log (id, company_id, actor_type, action, entity_type, occurred_at, device_id, sync_state) '
            "VALUES ('a-1', ?, 'system', 'backup.restored', 'backup', '2026-10-12T00:00:00.000Z', 'd', 'localOnly')",
            [id],
          );
        },
      );

      final actions = await env.auditActions();
      expect(actions, contains('backup.restored'));
      expect(await count('employees'), 0);
    });

    test('keeps what belongs to this device', () async {
      final admin = await env.setUpOwner();
      await env.addEmployee(admin);
      final snapshot = await backup.snapshot();
      final printers = DriftPrinterSettingsRepository(env.db);
      (await printers.save(
        const PrinterSettings(
          device: kitchenPrinter,
          paperWidth: PaperWidth.mm80,
        ),
      )).unwrap();
      final deviceBefore = (await DriftDeviceIdentityRepository(
        env.db,
      ).currentDeviceId()).unwrap();

      await backup.restore(snapshot.bytes, inside: (_) async {});

      final settings = (await printers.load()).unwrap();
      expect(settings.device, kitchenPrinter);
      expect(settings.paperWidth, PaperWidth.mm80);
      expect(
        (await DriftDeviceIdentityRepository(
          env.db,
        ).currentDeviceId()).unwrap(),
        deviceBefore,
      );
    });

    test('changes nothing when anything goes wrong', () async {
      final admin = await env.setUpOwner();
      await env.addEmployee(admin);
      final snapshot = await backup.snapshot();
      await env.addEmployee(admin, employeeNumber: 'E0002');
      final auditBefore = await count('audit_log');

      await expectLater(
        backup.restore(
          snapshot.bytes,
          inside: (_) async => throw StateError('boom'),
        ),
        throwsStateError,
      );

      expect(await count('employees'), 2);
      expect(await count('audit_log'), auditBefore);
      // The attached copy was detached, so a later restore works.
      await backup.restore(snapshot.bytes, inside: (_) async {});
      expect(await count('employees'), 1);
    });

    test('refuses a damaged snapshot without touching the data', () async {
      final admin = await env.setUpOwner();
      await env.addEmployee(admin);

      expect(
        await failureRule(
          () => backup.restore(
            Uint8List.fromList(List.filled(500, 1)),
            inside: (_) async {},
          ),
        ),
        BackupFailures.invalidFileRule,
      );
      expect(await count('employees'), 1);
    });

    test('brings a backup from an older version up to date', () async {
      await env.setUpOwner();
      final verifier = SchemaVerifier(GeneratedHelper());
      final old = await verifier.schemaAt(8);
      addTearDown(old.rawDatabase.close);
      old.rawDatabase.execute(
        'INSERT INTO companies (id, created_at, updated_at, version, sync_state, name, currency_code, timezone) '
        "VALUES ('old-co', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z', 1, 'localOnly', 'Old Ltd', 'KES', 'Africa/Nairobi')",
      );
      final path = '${temp.path}/v8.db';
      old.rawDatabase.execute("VACUUM INTO '$path'");
      final bytes = File(path).readAsBytesSync();

      final summary = await backup.check(bytes);
      String? restoredCompany;
      await backup.restore(bytes, inside: (id) async => restoredCompany = id);

      expect(summary.employees, 0);
      expect(restoredCompany, 'old-co');
      expect(await backup.currentCompanyId(), 'old-co');
      // The live database keeps working at the current schema.
      expect(await count('backup_settings'), 0);
      expect(await count('printer_settings'), 0);
      expect(
        (await env.db.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        env.db.schemaVersion,
      );
    });
  });
}
