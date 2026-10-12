import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/tables.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:drift/drift.dart';

final class DriftBackupSettingsRepository implements BackupSettingsRepository {
  DriftBackupSettingsRepository(this._db, {this._clock = systemClockUtc});

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<BackupSettings>> load() {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.backupSettingsTable)
                ..where((s) => s.id.equals(BackupSettingsTable.singletonId)))
              .getSingleOrNull();
      if (row == null) {
        return const BackupSettings();
      }
      return BackupSettings(
        automaticEnabled: row.automaticEnabled,
        retentionCount: row.retentionCount,
        reminderDays: row.reminderDays,
        lastAutomaticAttemptAt: row.lastAutomaticAttemptAt,
        lastAutomaticError: row.lastAutomaticError,
      );
    });
  }

  @override
  Future<Result<void>> save(BackupSettings settings) {
    return guardDatabase(() async {
      await _db
          .into(_db.backupSettingsTable)
          .insertOnConflictUpdate(
            BackupSettingsTableCompanion.insert(
              id: BackupSettingsTable.singletonId,
              retentionCount: settings.retentionCount,
              automaticEnabled: settings.automaticEnabled,
              reminderDays: settings.reminderDays,
              lastAutomaticAttemptAt: Value(settings.lastAutomaticAttemptAt),
              lastAutomaticError: Value(settings.lastAutomaticError),
              updatedAt: _clock(),
            ),
          );
    });
  }
}
