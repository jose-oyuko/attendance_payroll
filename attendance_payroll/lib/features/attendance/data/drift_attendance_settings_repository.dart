import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_repository.dart';
import 'package:drift/drift.dart';

final class DriftAttendanceSettingsRepository
    implements AttendanceSettingsRepository {
  DriftAttendanceSettingsRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  static const String _conflictMessage =
      'The attendance settings were changed by someone else. Reload them and '
      'try again.';

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<StoredAttendancePolicy>> forCompany(String companyId) {
    return guardDatabase(() async {
      final row = await _rowFor(companyId);
      return row == null
          ? const StoredAttendancePolicy(policy: AttendancePolicy(), version: 0)
          : _toDomain(row);
    });
  }

  @override
  Future<Result<StoredAttendancePolicy>> save(
    String companyId,
    AttendancePolicy policy, {
    required int expectedVersion,
  }) async {
    if (policy.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireCompany(companyId);
        final now = _clock();
        final values = _companion(policy).copyWith(updatedAt: Value(now));
        final existing = await _rowFor(companyId);
        if (existing == null) {
          if (expectedVersion != 0) {
            throw const ConflictFailure(userMessage: _conflictMessage);
          }
          // Saving over the defaults. A concurrent first save hits the unique
          // company id and also becomes a conflict.
          await _db
              .into(_db.attendanceSettings)
              .insert(
                values.copyWith(
                  id: Value(_newId()),
                  companyId: Value(companyId),
                  createdAt: Value(now),
                ),
              );
        } else {
          await updateVersioned(
            _db,
            _db.attendanceSettings,
            id: existing.id,
            expectedVersion: expectedVersion,
            changes: values.copyWith(version: Value(expectedVersion + 1)),
            entity: 'attendance settings',
          );
        }
        return _toDomain((await _rowFor(companyId))!);
      }),
      conflictMessage: _conflictMessage,
    );
  }

  Future<AttendanceSettingsRow?> _rowFor(String companyId) {
    return (_db.select(_db.attendanceSettings)
          ..where((s) => s.companyId.equals(companyId) & s.deletedAt.isNull()))
        .getSingleOrNull();
  }

  AttendanceSettingsCompanion _companion(AttendancePolicy policy) {
    final automaticBreak = policy.automaticBreak;
    return AttendanceSettingsCompanion(
      duplicateWindowMinutes: Value(policy.duplicateWindow.inMinutes),
      staleOpenSessionMinutes: Value(policy.staleOpenSessionAfter.inMinutes),
      excessiveDurationMinutes: Value(policy.excessiveDurationAfter.inMinutes),
      breakAfterMinutes: Value(automaticBreak?.after.inMinutes),
      breakMinutes: Value(automaticBreak?.deduct.inMinutes),
    );
  }

  StoredAttendancePolicy _toDomain(AttendanceSettingsRow row) {
    final breakAfter = row.breakAfterMinutes;
    final breakMinutes = row.breakMinutes;
    return StoredAttendancePolicy(
      version: row.version,
      policy: AttendancePolicy(
        duplicateWindow: Duration(minutes: row.duplicateWindowMinutes),
        staleOpenSessionAfter: Duration(minutes: row.staleOpenSessionMinutes),
        excessiveDurationAfter: Duration(minutes: row.excessiveDurationMinutes),
        automaticBreak: breakAfter == null || breakMinutes == null
            ? null
            : AutomaticBreak(
                after: Duration(minutes: breakAfter),
                deduct: Duration(minutes: breakMinutes),
              ),
      ),
    );
  }
}
