import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:drift/drift.dart';

final class DriftAttendanceCorrectionRepository
    implements AttendanceCorrectionRepository {
  DriftAttendanceCorrectionRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<AttendanceCorrection>> record(
    NewAttendanceCorrection correction,
  ) {
    return guardDatabase(
      () async {
        final now = _clock();
        final row = await _db
            .into(_db.attendanceCorrections)
            .insertReturning(
              AttendanceCorrectionsCompanion.insert(
                id: _newId(),
                employeeId: correction.employeeId,
                kind: correction.kind.name,
                eventType: correction.eventType.name,
                originalEventId: Value(correction.originalEventId),
                replacementEventId: Value(correction.replacementEventId),
                previousOccurredAt: Value(correction.previousOccurredAt),
                newOccurredAt: Value(correction.newOccurredAt),
                reason: correction.reason.trim(),
                correctedBy: correction.correctedBy,
                correctedAt: correction.correctedAt,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return _toDomain(row);
      },
      conflictMessage:
          'This entry was already corrected. Reload the attendance and try '
          'again.',
    );
  }

  @override
  Future<Result<List<AttendanceCorrection>>> forEmployee(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  }) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.attendanceCorrections)
                ..where(
                  (row) =>
                      row.employeeId.equals(employeeId) &
                      row.deletedAt.isNull() &
                      ((row.newOccurredAt.isBiggerOrEqualValue(from) &
                              row.newOccurredAt.isSmallerThanValue(to)) |
                          (row.previousOccurredAt.isBiggerOrEqualValue(from) &
                              row.previousOccurredAt.isSmallerThanValue(to))),
                )
                ..orderBy([(row) => OrderingTerm.desc(row.correctedAt)]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  AttendanceCorrection _toDomain(AttendanceCorrectionRow row) {
    return AttendanceCorrection(
      id: row.id,
      employeeId: row.employeeId,
      kind: AttendanceCorrectionKind.values.byName(row.kind),
      eventType: AttendanceEventType.values.byName(row.eventType),
      originalEventId: row.originalEventId,
      replacementEventId: row.replacementEventId,
      previousOccurredAt: row.previousOccurredAt,
      newOccurredAt: row.newOccurredAt,
      reason: row.reason,
      correctedBy: row.correctedBy,
      correctedAt: row.correctedAt,
    );
  }
}
