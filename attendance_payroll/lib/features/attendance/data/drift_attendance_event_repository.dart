import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event_repository.dart';
import 'package:drift/drift.dart';

final class DriftAttendanceEventRepository
    implements AttendanceEventRepository {
  DriftAttendanceEventRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<AttendanceEvent>> append(NewAttendanceEvent event) {
    return guardDatabase(() async {
      final now = _clock();
      final row = await _db
          .into(_db.attendanceEvents)
          .insertReturning(
            AttendanceEventsCompanion.insert(
              id: _newId(),
              employeeId: event.employeeId,
              eventType: event.type.name,
              occurredAt: event.occurredAt,
              recordedAt: event.recordedAt,
              source: event.source.name,
              deviceId: event.deviceId,
              createdBy: event.createdBy,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toDomain(row);
    });
  }

  @override
  Future<Result<({AttendanceEvent event, bool isSuperseded})>> getById(
    String id,
  ) {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.attendanceEvents)
                ..where((e) => e.id.equals(id) & e.deletedAt.isNull()))
              .getSingleOrNull();
      if (row == null) {
        throw const NotFoundFailure(entity: 'attendance entry');
      }
      final superseding =
          await (_db.select(_db.attendanceCorrections)
                ..where((c) => c.originalEventId.equals(id))
                ..limit(1))
              .getSingleOrNull();
      return (event: _toDomain(row), isSuperseded: superseding != null);
    });
  }

  @override
  Future<Result<AttendanceEvent?>> latestFor(String employeeId) {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.attendanceEvents)
                ..where(
                  (e) =>
                      e.employeeId.equals(employeeId) &
                      e.deletedAt.isNull() &
                      _counts(e),
                )
                ..orderBy(_newestFirst)
                ..limit(1))
              .getSingleOrNull();
      return row == null ? null : _toDomain(row);
    });
  }

  @override
  Future<Result<List<AttendanceEvent>>> between(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  }) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.attendanceEvents)
                ..where(
                  (e) =>
                      e.employeeId.equals(employeeId) &
                      e.deletedAt.isNull() &
                      e.occurredAt.isBiggerOrEqualValue(from) &
                      e.occurredAt.isSmallerThanValue(to) &
                      _counts(e),
                )
                ..orderBy(_oldestFirst))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<List<AttendanceEvent>>> betweenForCompany(
    String companyId, {
    required DateTime from,
    required DateTime to,
  }) {
    return guardDatabase(() async {
      final events = _db.attendanceEvents;
      final query =
          _db.select(events).join([
              innerJoin(
                _db.employees,
                _db.employees.id.equalsExp(events.employeeId),
              ),
            ])
            ..where(
              _db.employees.companyId.equals(companyId) &
                  events.deletedAt.isNull() &
                  events.occurredAt.isBiggerOrEqualValue(from) &
                  events.occurredAt.isSmallerThanValue(to) &
                  _counts(events),
            )
            ..orderBy([
              OrderingTerm.asc(events.occurredAt),
              OrderingTerm.asc(events.recordedAt),
              OrderingTerm.asc(events.id),
            ]);
      final rows = await query.get();
      return [for (final row in rows) _toDomain(row.readTable(events))];
    });
  }

  /// Not superseded by a correction.
  Expression<bool> _counts($AttendanceEventsTable e) {
    final superseded = _db.selectOnly(_db.attendanceCorrections)
      ..addColumns([_db.attendanceCorrections.originalEventId])
      ..where(_db.attendanceCorrections.originalEventId.isNotNull());
    return e.id.isNotInQuery(superseded);
  }

  // Same total order as AttendanceEvent.compareChronologically.
  static final List<OrderClauseGenerator<$AttendanceEventsTable>> _oldestFirst =
      [
        (e) => OrderingTerm.asc(e.occurredAt),
        (e) => OrderingTerm.asc(e.recordedAt),
        (e) => OrderingTerm.asc(e.id),
      ];

  static final List<OrderClauseGenerator<$AttendanceEventsTable>> _newestFirst =
      [
        (e) => OrderingTerm.desc(e.occurredAt),
        (e) => OrderingTerm.desc(e.recordedAt),
        (e) => OrderingTerm.desc(e.id),
      ];

  AttendanceEvent _toDomain(AttendanceEventRow row) {
    return AttendanceEvent(
      id: row.id,
      employeeId: row.employeeId,
      type: AttendanceEventType.values.byName(row.eventType),
      occurredAt: row.occurredAt,
      recordedAt: row.recordedAt,
      source: AttendanceEventSource.values.byName(row.source),
      deviceId: row.deviceId,
      createdBy: row.createdBy,
    );
  }
}
