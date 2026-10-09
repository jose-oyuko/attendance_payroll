import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/schedules/domain/schedule_repositories.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:drift/drift.dart';

final class DriftScheduleAssignmentRepository
    implements ScheduleAssignmentRepository {
  DriftScheduleAssignmentRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<ScheduleAssignment>> assign(
    String employeeId,
    String? scheduleId, {
    required LocalDate effectiveFrom,
  }) {
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireEmployee(employeeId);
        final now = _clock();
        final latest =
            await (_db.select(_db.scheduleAssignments)
                  ..where(
                    (a) =>
                        a.employeeId.equals(employeeId) & a.deletedAt.isNull(),
                  )
                  ..orderBy([(a) => OrderingTerm.desc(a.effectiveFrom)])
                  ..limit(1))
                .getSingleOrNull();
        if (latest != null) {
          if (!effectiveFrom.isAfter(latest.effectiveFrom)) {
            throw BusinessRuleFailure(
              rule: ScheduleAssignmentRules.mustStartAfterLatest,
              userMessage:
                  'The new schedule must start after '
                  '${latest.effectiveFrom.toIsoString()}, when the current '
                  'one started.',
            );
          }
          final closesOn = effectiveFrom.addDays(-1);
          final end = latest.effectiveTo;
          if (end == null || end.isAfter(closesOn)) {
            await updateVersioned(
              _db,
              _db.scheduleAssignments,
              id: latest.id,
              expectedVersion: latest.version,
              entity: 'schedule assignment',
              changes: ScheduleAssignmentsCompanion(
                effectiveTo: Value(closesOn),
                updatedAt: Value(now),
                version: Value(latest.version + 1),
              ),
            );
          }
        }
        final row = await _db
            .into(_db.scheduleAssignments)
            .insertReturning(
              ScheduleAssignmentsCompanion.insert(
                id: _newId(),
                employeeId: employeeId,
                scheduleId: Value(scheduleId),
                effectiveFrom: effectiveFrom,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return _toDomain(row);
      }),
    );
  }

  @override
  Future<Result<List<ScheduleAssignment>>> history(String employeeId) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.scheduleAssignments)
                ..where(
                  (a) => a.employeeId.equals(employeeId) & a.deletedAt.isNull(),
                )
                ..orderBy([(a) => OrderingTerm.asc(a.effectiveFrom)]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<List<ScheduleAssignment>>> forCompany(String companyId) {
    return guardDatabase(() async {
      final a = _db.scheduleAssignments;
      final rows =
          await (_db.select(a).join([
                  innerJoin(
                    _db.employees,
                    _db.employees.id.equalsExp(a.employeeId),
                  ),
                ])
                ..where(
                  _db.employees.companyId.equals(companyId) &
                      a.deletedAt.isNull(),
                )
                ..orderBy([OrderingTerm.asc(a.effectiveFrom)]))
              .get();
      return [for (final row in rows) _toDomain(row.readTable(a))];
    });
  }

  ScheduleAssignment _toDomain(ScheduleAssignmentRow row) {
    return ScheduleAssignment(
      id: row.id,
      employeeId: row.employeeId,
      scheduleId: row.scheduleId,
      effectiveFrom: row.effectiveFrom,
      effectiveTo: row.effectiveTo,
    );
  }
}
