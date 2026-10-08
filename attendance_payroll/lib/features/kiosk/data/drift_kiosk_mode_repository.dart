import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/tables.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:drift/drift.dart';

final class DriftKioskModeRepository implements KioskModeRepository {
  DriftKioskModeRepository(this._db, {this._clock = systemClockUtc});

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<String?>> kioskCompanyId() {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.deviceSettings)
                ..where((s) => s.id.equals(DeviceSettings.singletonId)))
              .getSingleOrNull();
      return row?.kioskCompanyId;
    });
  }

  @override
  Future<Result<void>> setKioskCompany(String? companyId) {
    return guardDatabase(() async {
      await _db
          .into(_db.deviceSettings)
          .insertOnConflictUpdate(
            DeviceSettingsCompanion.insert(
              id: DeviceSettings.singletonId,
              kioskCompanyId: Value(companyId),
              updatedAt: _clock(),
            ),
          );
    });
  }
}
