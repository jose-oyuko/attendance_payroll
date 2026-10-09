import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/schedules/domain/schedule_repositories.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:drift/drift.dart';

final class DriftWorkScheduleRepository implements WorkScheduleRepository {
  DriftWorkScheduleRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  String _nameTaken(WorkScheduleDetails d) =>
      'A schedule called "${d.name}" already exists.';

  @override
  Future<Result<WorkSchedule>> create(
    String companyId,
    WorkScheduleDetails details,
  ) async {
    final normalized = details.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireCompany(companyId);
        final now = _clock();
        final id = _newId();
        await _db
            .into(_db.workSchedules)
            .insert(
              _companion(normalized).copyWith(
                id: Value(id),
                companyId: Value(companyId),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        await _replaceDays(id, normalized);
        return _load(id);
      }),
      conflictMessage: _nameTaken(normalized),
    );
  }

  @override
  Future<Result<WorkSchedule>> getById(String id) {
    return guardDatabase(() => _load(id));
  }

  @override
  Future<Result<List<WorkSchedule>>> listByCompany(String companyId) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.workSchedules)
                ..where(
                  (s) => s.companyId.equals(companyId) & s.deletedAt.isNull(),
                )
                ..orderBy([(s) => OrderingTerm.asc(s.name)]))
              .get();
      final days = await _daysFor(rows.map((r) => r.id).toList());
      return [for (final row in rows) _toDomain(row, days[row.id] ?? [])];
    });
  }

  @override
  Future<Result<WorkSchedule>> update(
    String id,
    WorkScheduleDetails details, {
    required int expectedVersion,
  }) async {
    final normalized = details.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await updateVersioned(
          _db,
          _db.workSchedules,
          id: id,
          expectedVersion: expectedVersion,
          entity: 'schedule',
          changes: _companion(normalized).copyWith(
            updatedAt: Value(_clock()),
            version: Value(expectedVersion + 1),
          ),
        );
        await _replaceDays(id, normalized);
        return _load(id);
      }),
      conflictMessage: _nameTaken(normalized),
    );
  }

  Future<void> _replaceDays(String scheduleId, WorkScheduleDetails d) async {
    await (_db.delete(
      _db.workScheduleDays,
    )..where((day) => day.scheduleId.equals(scheduleId))).go();
    for (final day in d.days) {
      await _db
          .into(_db.workScheduleDays)
          .insert(
            WorkScheduleDaysCompanion.insert(
              id: _newId(),
              scheduleId: scheduleId,
              weekday: day.weekday,
              startMinute: day.start.inMinutes,
              endMinute: day.end.inMinutes,
            ),
          );
    }
  }

  Future<WorkSchedule> _load(String id) async {
    final row = await (_db.select(
      _db.workSchedules,
    )..where((s) => s.id.equals(id) & s.deletedAt.isNull())).getSingleOrNull();
    if (row == null) {
      throw const NotFoundFailure(entity: 'schedule');
    }
    return _toDomain(row, (await _daysFor([id]))[id] ?? []);
  }

  Future<Map<String, List<ScheduleDay>>> _daysFor(List<String> ids) async {
    final rows =
        await (_db.select(_db.workScheduleDays)
              ..where((d) => d.scheduleId.isIn(ids))
              ..orderBy([(d) => OrderingTerm.asc(d.weekday)]))
            .get();
    final byId = <String, List<ScheduleDay>>{};
    for (final row in rows) {
      (byId[row.scheduleId] ??= []).add(
        ScheduleDay(
          weekday: row.weekday,
          start: Duration(minutes: row.startMinute),
          end: Duration(minutes: row.endMinute),
        ),
      );
    }
    return byId;
  }

  WorkSchedulesCompanion _companion(WorkScheduleDetails d) {
    final automaticBreak = d.automaticBreak;
    return WorkSchedulesCompanion(
      name: Value(d.name),
      lateToleranceMinutes: Value(d.lateTolerance.inMinutes),
      earlyDepartureToleranceMinutes: Value(
        d.earlyDepartureTolerance.inMinutes,
      ),
      breakAfterMinutes: Value(automaticBreak?.after.inMinutes),
      breakMinutes: Value(automaticBreak?.deduct.inMinutes),
    );
  }

  WorkSchedule _toDomain(WorkScheduleRow row, List<ScheduleDay> days) {
    final breakAfter = row.breakAfterMinutes;
    final breakMinutes = row.breakMinutes;
    return WorkSchedule(
      id: row.id,
      companyId: row.companyId,
      version: row.version,
      details: WorkScheduleDetails(
        name: row.name,
        days: days,
        lateTolerance: Duration(minutes: row.lateToleranceMinutes),
        earlyDepartureTolerance: Duration(
          minutes: row.earlyDepartureToleranceMinutes,
        ),
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
