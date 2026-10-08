import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/platform/device_identity_repository.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';

final class DriftDeviceIdentityRepository implements DeviceIdentityRepository {
  DriftDeviceIdentityRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;
  String? _cached;

  @override
  Future<Result<String>> currentDeviceId() async {
    if (_cached case final id?) {
      return Ok(id);
    }
    final result = await guardDatabase(
      () => _db.transaction(() async {
        final existing = await _db.select(_db.deviceIdentity).getSingleOrNull();
        if (existing != null) {
          return existing.id;
        }
        final id = _newId();
        await _db
            .into(_db.deviceIdentity)
            .insert(
              DeviceIdentityCompanion.insert(id: id, createdAt: _clock()),
            );
        return id;
      }),
    );
    _cached = result.valueOrNull;
    return result;
  }
}
