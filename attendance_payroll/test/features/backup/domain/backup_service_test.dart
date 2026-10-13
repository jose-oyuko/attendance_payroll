import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_backups.dart';
import '../../../support/test_env.dart';

void main() {
  late Directory temp;
  late BackupTestDevice device;
  late TestEnv env;
  late AdminSession admin;
  late BackupService service;

  String? ruleOf(Result<Object?> result) {
    final failure = result.failureOrNull;
    return failure is BusinessRuleFailure ? failure.rule : null;
  }

  /// The rule of the failure a future ends with, or `null`.
  Future<String?> ruleOfFailure(Future<Object?> Function() action) async {
    try {
      await action();
    } on BusinessRuleFailure catch (failure) {
      return failure.rule;
    }
    return null;
  }

  Future<List<BackupInfo>> backups() async =>
      (await service.list(admin)).unwrap().backups;

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('backup-service-test');
    addTearDown(() => temp.deleteSync(recursive: true));
    env = TestEnv();
    admin = await env.setUpOwner();
    device = BackupTestDevice(env, temp);
    service = device.service;
  });

  group('creating a backup', () {
    test('keeps a verified, encrypted copy and says what is in it', () async {
      await env.addEmployee(admin);

      final info = (await service.create(admin)).unwrap();

      expect(info.fileName, endsWith('-manual.apbackup'));
      expect(info.header.kind, BackupKind.manual);
      expect(info.header.createdBy, 'Jane Owner');
      expect(info.header.companyName, 'Acme Ltd');
      expect(info.header.backupVersion, BackupService.backupVersion);
      expect(info.header.summary.employees, 1);
      expect(device.storage.files.keys, [info.fileName]);
      expect(info.sizeBytes, device.storage.files[info.fileName]!.length);
      // Encrypted: the company name is only in the readable header, and no
      // part of the data is readable.
      final text = String.fromCharCodes(device.storage.files[info.fileName]!);
      expect(text, isNot(contains('John')));
      expect(text, isNot(contains('SQLite format')));
    });

    test('is recorded in the audit log without the password', () async {
      await service.create(admin);

      final row = (await env.auditRows()).singleWhere(
        (r) => r.action == 'backup.created',
      );
      expect(row.metadata, isNot(contains('backup-pass-123')));
      expect(row.entityType, 'backup');
    });

    test('works without a password, with standard protection', () async {
      device.secrets.password = null;
      await env.addEmployee(admin);

      final info = (await service.create(admin)).unwrap();

      expect(info.header.passwordProtected, isFalse);
      // Still encrypted: not a readable database.
      final bytes = device.storage.files[info.fileName]!;
      expect(String.fromCharCodes(bytes), isNot(contains('SQLite format')));
      expect(String.fromCharCodes(bytes), isNot(contains('John')));
      // And it opens without a password.
      final snapshot = await fastCodec().decode(bytes, null);
      expect(snapshot, isNotEmpty);
    });

    test('with a password, the backup is marked as protected by it', () async {
      final info = (await service.create(admin)).unwrap();

      expect(info.header.passwordProtected, isTrue);
      expect(
        ruleOfFailure(
          () => fastCodec().decode(device.storage.files[info.fileName]!, null),
        ),
        completion(BackupFailures.noPasswordRule),
      );
    });

    test('keeps nothing when the folder cannot be written', () async {
      device.storage.failWith = BackupFailures.storageFailed('disk full');

      final result = await service.create(admin);

      expect(ruleOf(result), BackupFailures.storageFailedRule);
      expect(await env.auditActions(), isNot(contains('backup.created')));
    });

    test('lists backups newest first, with their status', () async {
      final first = (await service.create(admin)).unwrap();
      final second = (await service.create(admin)).unwrap();

      final listing = (await service.list(admin)).unwrap();

      expect(listing.backups.map((b) => b.fileName), [
        second.fileName,
        first.fileName,
      ]);
      final status = (await service.status(admin)).unwrap();
      expect(status.hasPassword, isTrue);
      expect(status.lastBackupAt, second.header.createdAt);
      expect(status.reminderDue, isFalse);
    });

    test('reminds when there is no backup, or the newest is old', () async {
      expect((await service.status(admin)).unwrap().reminderDue, isTrue);

      await service.create(admin);
      expect((await service.status(admin)).unwrap().reminderDue, isFalse);

      env.clock.advance(const Duration(days: 8));
      expect((await service.status(admin)).unwrap().reminderDue, isTrue);
    });

    test('counts files that are not backups instead of failing', () async {
      await service.create(admin);
      device.storage.files['junk.apbackup'] = Uint8List.fromList([1, 2, 3]);

      final listing = (await service.list(admin)).unwrap();

      expect(listing.backups, hasLength(1));
      expect(listing.unreadable, 1);
    });
  });

  group('restoring a backup', () {
    test('brings back the data as it was, and keeps a safety backup', () async {
      await env.addEmployee(admin);
      final backup = (await service.create(admin)).unwrap();
      await env.addEmployee(admin, employeeNumber: 'E0002');
      expect(await device.employees(), 2);
      final file = device.storage.files[backup.fileName]!;

      final outcome = (await service.restore(admin, file)).unwrap();

      expect(await device.employees(), 1);
      expect(outcome.restored.createdAt, backup.header.createdAt);
      final safety = outcome.safetyBackup!;
      expect(safety.header.kind, BackupKind.safety);
      expect(safety.header.summary.employees, 2);
      // The audit log says it happened, in the restored data.
      expect(await env.auditActions(), contains('backup.restored'));
    });

    test(
      'the data it replaced can be restored from the safety backup',
      () async {
        await env.addEmployee(admin);
        final backup = (await service.create(admin)).unwrap();
        await env.addEmployee(admin, employeeNumber: 'E0002');
        final outcome = (await service.restore(
          admin,
          device.storage.files[backup.fileName]!,
        )).unwrap();
        expect(await device.employees(), 1);

        (await service.restore(
          admin,
          device.storage.files[outcome.safetyBackup!.fileName]!,
        )).unwrap();

        expect(await device.employees(), 2);
      },
    );

    test(
      'a wrong password changes nothing and makes no safety backup',
      () async {
        final backup = (await service.create(admin)).unwrap();
        await env.addEmployee(admin);
        final file = device.storage.files[backup.fileName]!;

        final result = await service.restore(
          admin,
          file,
          password: 'nope-nope',
        );

        expect(ruleOf(result), BackupFailures.wrongPasswordRule);
        expect(await device.employees(), 1);
        expect(await backups(), hasLength(1));
      },
    );

    test('a backup made with another password needs that password', () async {
      final backup = (await service.create(admin)).unwrap();
      final file = device.storage.files[backup.fileName]!;
      (await service.setPassword(admin, 'a-brand-new-password')).unwrap();

      expect(
        ruleOf(await service.restore(admin, file)),
        BackupFailures.wrongPasswordRule,
      );
      expect(
        (await service.restore(admin, file, password: 'backup-pass-123')).isOk,
        isTrue,
      );
    });

    test('a damaged file changes nothing', () async {
      final backup = (await service.create(admin)).unwrap();
      await env.addEmployee(admin);
      final damaged = Uint8List.fromList(
        device.storage.files[backup.fileName]!,
      );
      damaged[damaged.length - 30] ^= 0xFF;

      final result = await service.restore(admin, damaged);

      expect(result.isErr, isTrue);
      expect(await device.employees(), 1);
    });

    test('a file that is not a backup is refused', () async {
      final result = await service.restore(
        admin,
        Uint8List.fromList(List.filled(100, 3)),
      );

      expect(ruleOf(result), BackupFailures.invalidFileRule);
    });

    test('is refused on a kiosk device', () async {
      final backup = (await service.create(admin)).unwrap();
      (await env.kioskMode.setKioskCompany(admin.companyId)).unwrap();

      final result = await service.restore(
        admin,
        device.storage.files[backup.fileName]!,
      );

      expect(ruleOf(result), BackupFailures.kioskActiveRule);
    });

    test(
      'another company needs explicit permission to replace this one',
      () async {
        final other = BackupTestDevice(TestEnv(), temp);
        final otherAdmin = await other.env.setUpOwner();
        final theirs = (await other.service.create(otherAdmin)).unwrap();
        final file = other.storage.files[theirs.fileName]!;
        final header = service.inspect(file).unwrap();

        expect((await service.isDifferentCompany(header)).unwrap(), isTrue);
        expect(
          ruleOf(
            await service.restore(admin, file, password: 'backup-pass-123'),
          ),
          BackupFailures.differentCompanyRule,
        );

        (await service.restore(
          admin,
          file,
          password: 'backup-pass-123',
          allowDifferentCompany: true,
        )).unwrap();
        expect((await service.isDifferentCompany(header)).unwrap(), isFalse);
      },
    );

    test('says what a file is before anything is restored', () async {
      await env.addEmployee(admin);
      final backup = (await service.create(admin)).unwrap();

      final header = service
          .inspect(device.storage.files[backup.fileName]!)
          .unwrap();

      expect(header.companyName, 'Acme Ltd');
      expect(header.summary.employees, 1);
      expect(await device.employees(), 1);
    });

    test('keeps only the last few safety backups', () async {
      final backup = (await service.create(admin)).unwrap();
      final file = device.storage.files[backup.fileName]!;

      for (var i = 0; i < 5; i++) {
        (await service.restore(admin, file)).unwrap();
      }

      final safety = (await backups()).where(
        (b) => b.header.kind == BackupKind.safety,
      );
      expect(safety.length, BackupService.safetyBackupsKept);
    });
  });

  group('restoring on a new installation', () {
    late BackupTestDevice fresh;

    setUp(() {
      fresh = BackupTestDevice(TestEnv(), temp);
    });

    test('needs no administrator, because there is none yet', () async {
      await env.addEmployee(admin);
      final backup = (await service.create(admin)).unwrap();
      final file = device.storage.files[backup.fileName]!;

      final outcome = (await fresh.service.restoreOnNewInstallation(
        file,
        password: 'backup-pass-123',
      )).unwrap();

      expect(outcome.safetyBackup, isNull);
      expect(await fresh.employees(), 1);
      expect(await fresh.env.auditActions(), contains('backup.restored'));
    });

    test('a wrong password leaves the device empty', () async {
      final backup = (await service.create(admin)).unwrap();

      final result = await fresh.service.restoreOnNewInstallation(
        device.storage.files[backup.fileName]!,
        password: 'wrong-wrong',
      );

      expect(ruleOf(result), BackupFailures.wrongPasswordRule);
      expect(await fresh.employees(), 0);
    });

    test('is refused once the device has company data', () async {
      final backup = (await service.create(admin)).unwrap();

      final result = await service.restoreOnNewInstallation(
        device.storage.files[backup.fileName]!,
        password: 'backup-pass-123',
      );

      expect(ruleOf(result), BackupFailures.notFreshRule);
    });
  });

  group('exporting and deleting', () {
    test('export returns the stored file and is audited', () async {
      final backup = (await service.create(admin)).unwrap();

      final bytes = (await service.export(admin, backup.fileName)).unwrap();

      expect(bytes, device.storage.files[backup.fileName]);
      expect(await env.auditActions(), contains('backup.exported'));
    });

    test('delete removes the file and is audited', () async {
      final backup = (await service.create(admin)).unwrap();

      (await service.delete(admin, backup.fileName)).unwrap();

      expect(device.storage.files, isEmpty);
      expect(await env.auditActions(), contains('backup.deleted'));
    });

    test('names that are not backup files are refused', () async {
      expect(
        ruleOf(await service.export(admin, '../secret.txt')),
        BackupFailures.invalidFileRule,
      );
      expect(
        ruleOf(await service.delete(admin, 'a/b.apbackup')),
        BackupFailures.invalidFileRule,
      );
    });
  });

  group('standard protection', () {
    test('a backup without a password restores without one', () async {
      device.secrets.password = null;
      await env.addEmployee(admin);
      final backup = (await service.create(admin)).unwrap();
      await env.addEmployee(admin, employeeNumber: 'E0002');

      (await service.restore(
        admin,
        device.storage.files[backup.fileName]!,
      )).unwrap();

      expect(await device.employees(), 1);
    });

    test('the device password is not needed for it, nor in the way', () async {
      device.secrets.password = null;
      final backup = (await service.create(admin)).unwrap();
      (await service.setPassword(admin, 'a-brand-new-password')).unwrap();

      final result = await service.restore(
        admin,
        device.storage.files[backup.fileName]!,
      );

      expect(result.isOk, isTrue);
    });

    test('a password-protected backup asks for its password', () async {
      final backup = (await service.create(admin)).unwrap();
      device.secrets.password = null;

      final without = await service.restore(
        admin,
        device.storage.files[backup.fileName]!,
      );
      final withIt = await service.restore(
        admin,
        device.storage.files[backup.fileName]!,
        password: 'backup-pass-123',
      );

      expect(ruleOf(without), BackupFailures.noPasswordRule);
      expect(withIt.isOk, isTrue);
    });

    test(
      'the safety backup follows the device, not the restored file',
      () async {
        final protected = (await service.create(admin)).unwrap();
        device.secrets.password = null;

        final outcome = (await service.restore(
          admin,
          device.storage.files[protected.fileName]!,
          password: 'backup-pass-123',
        )).unwrap();

        expect(outcome.safetyBackup!.header.passwordProtected, isFalse);
      },
    );

    test(
      'stopping the password makes new backups standard, and is audited',
      () async {
        final before = (await service.create(admin)).unwrap();

        (await service.removePassword(admin)).unwrap();
        final after = (await service.create(admin)).unwrap();

        expect(device.secrets.password, isNull);
        expect(before.header.passwordProtected, isTrue);
        expect(after.header.passwordProtected, isFalse);
        expect((await service.status(admin)).unwrap().hasPassword, isFalse);
        expect(await env.auditActions(), contains('backup.password_removed'));
        // The backup made with the password still needs it.
        expect(
          ruleOf(
            await service.restore(
              admin,
              device.storage.files[before.fileName]!,
            ),
          ),
          BackupFailures.noPasswordRule,
        );
      },
    );

    test('restores on a new installation without a password', () async {
      device.secrets.password = null;
      await env.addEmployee(admin);
      final backup = (await service.create(admin)).unwrap();
      final fresh = BackupTestDevice(TestEnv(), temp);

      final outcome = await fresh.service.restoreOnNewInstallation(
        device.storage.files[backup.fileName]!,
      );

      expect(outcome.isOk, isTrue);
      expect(await fresh.employees(), 1);
    });
  });

  group('the password', () {
    test('must be long enough', () async {
      final result = await service.setPassword(admin, 'short');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(device.secrets.password, 'backup-pass-123');
    });

    test(
      'is saved in the secret store and audited without its value',
      () async {
        (await service.setPassword(admin, 'a-brand-new-password')).unwrap();

        expect(device.secrets.password, 'a-brand-new-password');
        final rows = await env.auditRows();
        final changed = rows.singleWhere(
          (r) => r.action == 'backup.password_changed',
        );
        expect(changed.metadata ?? '', isNot(contains('brand')));
      },
    );
  });

  group('settings', () {
    test('start with automatic backups on, keeping ten', () async {
      final settings = (await service.settings(admin)).unwrap();

      expect(settings.automaticEnabled, isTrue);
      expect(settings.retentionCount, 10);
      expect(settings.reminderDays, 7);
    });

    test('are validated, saved and audited', () async {
      expect(
        (await service.updateSettings(
          admin,
          automaticEnabled: true,
          retentionCount: 0,
          reminderDays: 7,
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await service.updateSettings(
          admin,
          automaticEnabled: true,
          retentionCount: 5,
          reminderDays: 400,
        )).failureOrNull,
        isA<ValidationFailure>(),
      );

      (await service.updateSettings(
        admin,
        automaticEnabled: false,
        retentionCount: 5,
        reminderDays: 14,
      )).unwrap();

      final saved = (await service.settings(admin)).unwrap();
      expect(saved.automaticEnabled, isFalse);
      expect(saved.retentionCount, 5);
      expect(saved.reminderDays, 14);
      expect(await env.auditActions(), contains('backup.settings_changed'));
    });
  });

  group('retention', () {
    Future<void> setRetention(int keep) async {
      (await service.updateSettings(
        admin,
        automaticEnabled: true,
        retentionCount: keep,
        reminderDays: 7,
      )).unwrap();
    }

    test('keeps the newest automatic backups and deletes older ones', () async {
      await setRetention(2);
      final names = <String>[];
      for (var i = 0; i < 4; i++) {
        names.add(
          (await service.create(
            admin,
            kind: BackupKind.automatic,
          )).unwrap().fileName,
        );
      }

      expect(device.storage.files.keys.toSet(), names.skip(2).toSet());
    });

    test('never deletes manual backups', () async {
      await setRetention(1);
      for (var i = 0; i < 3; i++) {
        await service.create(admin);
      }
      await service.create(admin, kind: BackupKind.automatic);
      await service.create(admin, kind: BackupKind.automatic);

      final kinds = (await backups()).map((b) => b.header.kind);
      expect(kinds.where((k) => k == BackupKind.manual), hasLength(3));
      expect(kinds.where((k) => k == BackupKind.automatic), hasLength(1));
    });

    test('lowering the limit trims at once', () async {
      for (var i = 0; i < 4; i++) {
        await service.create(admin, kind: BackupKind.automatic);
      }

      await setRetention(1);

      expect(await backups(), hasLength(1));
    });
  });

  group('automatic backups', () {
    test('are made when opened and the newest backup is old', () async {
      env.clock.advance(const Duration(hours: 1));

      final made = (await service.runAutomaticIfDue(admin)).unwrap();

      expect(made, isNotNull);
      expect(made!.header.kind, BackupKind.automatic);
      expect(made.header.createdBy, BackupService.automaticAuthor);
    });

    test('are skipped when a backup is recent', () async {
      await service.create(admin);
      env.clock.advance(const Duration(hours: 23));

      expect((await service.runAutomaticIfDue(admin)).unwrap(), isNull);
      expect(await backups(), hasLength(1));

      env.clock.advance(const Duration(hours: 2));
      expect((await service.runAutomaticIfDue(admin)).unwrap(), isNotNull);
    });

    test('a safety backup does not count as recent', () async {
      final backup = (await service.create(admin)).unwrap();
      env.clock.advance(const Duration(days: 2));
      (await service.restore(
        admin,
        device.storage.files[backup.fileName]!,
      )).unwrap();

      expect((await service.runAutomaticIfDue(admin)).unwrap(), isNotNull);
    });

    test('are skipped when switched off', () async {
      (await service.updateSettings(
        admin,
        automaticEnabled: false,
        retentionCount: 10,
        reminderDays: 7,
      )).unwrap();

      expect((await service.runAutomaticIfDue(admin)).unwrap(), isNull);
      expect(device.storage.files, isEmpty);
    });

    test('need no password: they use standard protection', () async {
      device.secrets.password = null;

      final made = (await service.runAutomaticIfDue(admin)).unwrap();

      expect(made, isNotNull);
      expect(made!.header.passwordProtected, isFalse);
    });

    test('a failure is remembered, not retried straight away', () async {
      device.storage.failWith = BackupFailures.storageFailed('disk full');

      final failed = await service.runAutomaticIfDue(admin);

      expect(ruleOf(failed), BackupFailures.storageFailedRule);
      final status = (await service.status(admin)).unwrap();
      expect(status.lastAutomaticError, contains('Could not read or write'));

      device.storage.failWith = null;
      expect((await service.runAutomaticIfDue(admin)).unwrap(), isNull);

      env.clock.advance(const Duration(hours: 2));
      expect((await service.runAutomaticIfDue(admin)).unwrap(), isNotNull);
      expect((await service.status(admin)).unwrap().lastAutomaticError, isNull);
    });
  });

  test('every operation checks the session', () async {
    final stranger = AdminSession(
      admin: AdminUser(
        id: 'x',
        companyId: admin.companyId,
        username: 'gone',
        displayName: 'Gone',
        role: AdminRole.owner,
        active: false,
        lastLoginAt: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        version: 1,
      ),
      signedInAt: DateTime.utc(2026),
    );
    final backup = (await service.create(admin)).unwrap();
    final file = device.storage.files[backup.fileName]!;

    final results = <Result<Object?>>[
      await service.list(stranger),
      await service.status(stranger),
      await service.create(stranger),
      await service.runAutomaticIfDue(stranger),
      await service.export(stranger, backup.fileName),
      await service.delete(stranger, backup.fileName),
      await service.restore(stranger, file),
      await service.setPassword(stranger, 'long-enough-password'),
      await service.removePassword(stranger),
      await service.settings(stranger),
      await service.updateSettings(
        stranger,
        automaticEnabled: true,
        retentionCount: 5,
        reminderDays: 7,
      ),
    ];

    for (final result in results) {
      expect(result.failureOrNull, isA<PermissionFailure>());
    }
    expect(device.storage.files, hasLength(1));
  });
}
