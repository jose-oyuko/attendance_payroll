import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/features/backup/data/apbackup_codec.dart';
import 'package:attendance_payroll/features/backup/data/drift_backup_database.dart';
import 'package:attendance_payroll/features/backup/data/drift_backup_settings_repository.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:attendance_payroll/features/backup/domain/backup_service.dart';

import 'test_env.dart';

/// Backup files in memory, in the order they were written.
class InMemoryBackupStorage implements BackupStorage {
  final Map<String, Uint8List> files = {};

  /// When set, every operation fails with this.
  Object? failWith;

  void _check() {
    if (failWith case final error?) {
      throw error;
    }
  }

  @override
  Future<List<StoredBackupFile>> list() async {
    _check();
    return [
      for (final MapEntry(:key, :value) in files.entries)
        StoredBackupFile(
          name: key,
          sizeBytes: value.length,
          modifiedAt: DateTime.utc(2026),
        ),
    ];
  }

  @override
  Future<Uint8List> readPrefix(String name, int maxBytes) async {
    _check();
    final bytes = files[name]!;
    return bytes.sublist(0, bytes.length < maxBytes ? bytes.length : maxBytes);
  }

  @override
  Future<Uint8List> read(String name) async {
    _check();
    return files[name]!;
  }

  @override
  Future<void> write(String name, Uint8List bytes) async {
    _check();
    files[name] = bytes;
  }

  @override
  Future<void> delete(String name) async {
    _check();
    files.remove(name);
  }
}

class InMemorySecretStore implements BackupSecretStore {
  InMemorySecretStore([this.password]);

  String? password;

  @override
  Future<String?> read() async => password;

  @override
  Future<void> write(String password) async => this.password = password;

  @override
  Future<void> clear() async => password = null;
}

/// The real file format with a cheap key derivation, run inline.
ApbackupCodec fastCodec() =>
    ApbackupCodec(iterations: 1000, inBackground: false);

/// One device: a database, a backup folder in memory and a service over them.
class BackupTestDevice {
  BackupTestDevice(this.env, Directory temp) {
    service = BackupService(
      storage: storage,
      codec: fastCodec(),
      database: DriftBackupDatabase(
        env.db,
        resolveTempDirectory: () async => temp,
      ),
      settings: DriftBackupSettingsRepository(env.db, clock: env.clock.call),
      secrets: secrets,
      kiosk: env.kioskMode,
      devices: DriftDeviceIdentityRepository(env.db),
      audit: env.audit,
      appVersion: '0.1.0',
      clock: env.clock.call,
    );
  }

  final TestEnv env;
  final InMemoryBackupStorage storage = InMemoryBackupStorage();
  final InMemorySecretStore secrets = InMemorySecretStore('backup-pass-123');
  late final BackupService service;

  Future<int> employees() async =>
      (await env.db
              .customSelect('SELECT count(*) AS c FROM employees')
              .getSingle())
          .read<int>('c');
}
