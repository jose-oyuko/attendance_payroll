import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/tables.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/kiosk/domain/app_lock_service.dart';
import 'package:drift/drift.dart';

/// The lock time lives in the device's own settings row, beside the kiosk
/// flag. Each repository writes only its own column, so neither undoes the
/// other.
final class DriftAppLockSettingsRepository
    implements AppLockSettingsRepository {
  DriftAppLockSettingsRepository(this._db, {this._clock = systemClockUtc});

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<int?>> lockAfterMinutes() {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.deviceSettings)
                ..where((s) => s.id.equals(DeviceSettings.singletonId)))
              .getSingleOrNull();
      return row?.lockAfterMinutes;
    });
  }

  @override
  Future<Result<void>> setLockAfterMinutes(int minutes) {
    return guardDatabase(() async {
      await _db
          .into(_db.deviceSettings)
          .insertOnConflictUpdate(
            DeviceSettingsCompanion.insert(
              id: DeviceSettings.singletonId,
              lockAfterMinutes: Value(minutes),
              updatedAt: _clock(),
            ),
          );
    });
  }
}
