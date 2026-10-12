import 'dart:io';

import 'package:attendance_payroll/core/constants/app_constants.dart';
import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/backup/data/apbackup_codec.dart';
import 'package:attendance_payroll/features/backup/data/drift_backup_database.dart';
import 'package:attendance_payroll/features/backup/data/drift_backup_settings_repository.dart';
import 'package:attendance_payroll/features/backup/data/local_backup_storage.dart';
import 'package:attendance_payroll/features/backup/data/secure_backup_secret_store.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:attendance_payroll/features/backup/domain/backup_service.dart';
import 'package:attendance_payroll/features/kiosk/data/kiosk_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Where backups are kept. Google Drive or another provider would replace
/// this one provider.
final backupStorageProvider = Provider<BackupStorage>(
  (ref) => LocalBackupStorage(() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}${Platform.pathSeparator}backups');
  }),
);

final backupCodecProvider = Provider<BackupCodec>((ref) => ApbackupCodec());

final backupDatabaseProvider = Provider<BackupDatabase>(
  (ref) => DriftBackupDatabase(
    ref.watch(appDatabaseProvider),
    resolveTempDirectory: getTemporaryDirectory,
  ),
);

final backupSecretStoreProvider = Provider<BackupSecretStore>(
  (ref) => const SecureBackupSecretStore(),
);

final backupSettingsRepositoryProvider = Provider<BackupSettingsRepository>(
  (ref) => DriftBackupSettingsRepository(ref.watch(appDatabaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    storage: ref.watch(backupStorageProvider),
    codec: ref.watch(backupCodecProvider),
    database: ref.watch(backupDatabaseProvider),
    settings: ref.watch(backupSettingsRepositoryProvider),
    secrets: ref.watch(backupSecretStoreProvider),
    kiosk: ref.watch(kioskModeRepositoryProvider),
    devices: ref.watch(deviceIdentityRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    appVersion: AppConstants.appVersion,
  ),
);
