import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/platform/device_identity_repository.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';

/// Lets an administrator fix attendance: add a forgotten clock-in or
/// clock-out, change an entry's time, or remove an entry that should not
/// count.
///
/// Nothing is overwritten. Every correction is a permanent record with a
/// reason, who made it and when; a changed or removed entry stays in the
/// database, superseded. Sessions are rebuilt from the entries that count,
/// so a correction takes effect everywhere immediately.
final class AttendanceCorrectionService {
  AttendanceCorrectionService({
    required this._employees,
    required this._events,
    required this._corrections,
    required this._reviews,
    required this._devices,
    required this._audit,
    required this._transactions,
    this._clock = systemClockUtc,
  });

  final EmployeeRepository _employees;
  final AttendanceEventRepository _events;
  final AttendanceCorrectionRepository _corrections;
  final ExceptionReviewRepository _reviews;
  final DeviceIdentityRepository _devices;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;
  final Clock _clock;

  /// Adds a clock action the employee forgot to record, at [occurredAt].
  Future<Result<AttendanceCorrection>> addMissingEntry(
    AdminSession session,
    String employeeId, {
    required AttendanceEventType type,
    required DateTime occurredAt,
    required String reason,
    AttendanceIssue? resolves,
  }) async {
    final now = _clock();
    final invalid =
        session.check(Permission.correctAttendance) ??
        CorrectionReason.validate(reason) ??
        _checkTime(occurredAt, now);
    if (invalid != null) {
      return Err(invalid);
    }
    final employee = await _employees.getInCompany(
      session.companyId,
      employeeId,
    );
    if (employee case Err(:final failure)) {
      return Err(failure);
    }
    return _apply(session, now, resolves, (deviceId) async {
      final added = await _append(
        session,
        deviceId,
        employeeId: employeeId,
        type: type,
        occurredAt: occurredAt,
        now: now,
      );
      return NewAttendanceCorrection(
        employeeId: employeeId,
        kind: AttendanceCorrectionKind.added,
        eventType: type,
        originalEventId: null,
        replacementEventId: added.id,
        previousOccurredAt: null,
        newOccurredAt: occurredAt,
        reason: reason,
        correctedBy: session.admin.id,
        correctedAt: now,
      );
    });
  }

  /// Moves an entry to [newOccurredAt]. The original entry is kept,
  /// superseded by a new one at the corrected time.
  Future<Result<AttendanceCorrection>> changeTime(
    AdminSession session,
    String eventId, {
    required DateTime newOccurredAt,
    required String reason,
    AttendanceIssue? resolves,
  }) async {
    final now = _clock();
    final invalid =
        session.check(Permission.correctAttendance) ??
        CorrectionReason.validate(reason) ??
        _checkTime(newOccurredAt, now);
    if (invalid != null) {
      return Err(invalid);
    }
    final original = await _correctableEvent(session, eventId);
    if (original case Err(:final failure)) {
      return Err(failure);
    }
    final event = original.valueOrNull!;
    if (event.occurredAt == newOccurredAt) {
      return const Err(
        ValidationFailure(
          field: 'time',
          userMessage: 'Choose a time different from the current one.',
        ),
      );
    }
    return _apply(session, now, resolves, (deviceId) async {
      final replacement = await _append(
        session,
        deviceId,
        employeeId: event.employeeId,
        type: event.type,
        occurredAt: newOccurredAt,
        now: now,
      );
      return NewAttendanceCorrection(
        employeeId: event.employeeId,
        kind: AttendanceCorrectionKind.timeChanged,
        eventType: event.type,
        originalEventId: event.id,
        replacementEventId: replacement.id,
        previousOccurredAt: event.occurredAt,
        newOccurredAt: newOccurredAt,
        reason: reason,
        correctedBy: session.admin.id,
        correctedAt: now,
      );
    });
  }

  /// Stops an entry from counting, for example an accidental extra
  /// clock-in. The entry itself is kept, superseded.
  Future<Result<AttendanceCorrection>> removeEntry(
    AdminSession session,
    String eventId, {
    required String reason,
    AttendanceIssue? resolves,
  }) async {
    final now = _clock();
    final invalid =
        session.check(Permission.correctAttendance) ??
        CorrectionReason.validate(reason);
    if (invalid != null) {
      return Err(invalid);
    }
    final original = await _correctableEvent(session, eventId);
    if (original case Err(:final failure)) {
      return Err(failure);
    }
    final event = original.valueOrNull!;
    return _apply(
      session,
      now,
      resolves,
      (_) async => NewAttendanceCorrection(
        employeeId: event.employeeId,
        kind: AttendanceCorrectionKind.removed,
        eventType: event.type,
        originalEventId: event.id,
        replacementEventId: null,
        previousOccurredAt: event.occurredAt,
        newOccurredAt: null,
        reason: reason,
        correctedBy: session.admin.id,
        correctedAt: now,
      ),
    );
  }

  /// Corrections to the employee's attendance between [from] and [to],
  /// newest first: the audit trail shown alongside the attendance.
  Future<Result<List<AttendanceCorrection>>> history(
    AdminSession session,
    String employeeId, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (session.check(Permission.viewAttendance) case final denied?) {
      return Err(denied);
    }
    final employee = await _employees.getInCompany(
      session.companyId,
      employeeId,
    );
    if (employee case Err(:final failure)) {
      return Err(failure);
    }
    return _corrections.forEmployee(employeeId, from: from, to: to);
  }

  /// Runs one correction atomically: the new entry (if any), the correction
  /// record, its audit entry and, when it [resolves] an exception, the
  /// decision linking the two, are saved together or not at all.
  Future<Result<AttendanceCorrection>> _apply(
    AdminSession session,
    DateTime now,
    AttendanceIssue? resolves,
    Future<NewAttendanceCorrection> Function(String deviceId) build,
  ) async {
    final device = await _devices.currentDeviceId();
    if (device case Err(:final failure)) {
      return Err(failure);
    }
    return _transactions.run(() async {
      final correction = (await _corrections.record(
        await build(device.valueOrNull!),
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.attendanceCorrected,
          entityType: 'attendance_correction',
          entityId: correction.id,
          metadata: {
            'employeeId': correction.employeeId,
            'kind': correction.kind.name,
            'eventType': correction.eventType.name,
          },
        ),
      )).unwrap();
      if (resolves != null) {
        final revealedBy = (await _events.getById(resolves.eventId)).unwrap();
        if (revealedBy.event.employeeId != correction.employeeId) {
          throw const ValidationFailure(
            userMessage: 'That exception belongs to another employee.',
          );
        }
        (await _reviews.record(
          NewExceptionReview(
            companyId: session.companyId,
            employeeId: correction.employeeId,
            issue: resolves,
            decision: ReviewDecision.resolved,
            reason: correction.reason,
            reviewedBy: session.admin.id,
            reviewedAt: now,
            relatedCorrectionId: correction.id,
          ),
        )).unwrap();
      }
      return correction;
    });
  }

  Future<AttendanceEvent> _append(
    AdminSession session,
    String deviceId, {
    required String employeeId,
    required AttendanceEventType type,
    required DateTime occurredAt,
    required DateTime now,
  }) async {
    return (await _events.append(
      NewAttendanceEvent(
        employeeId: employeeId,
        type: type,
        occurredAt: occurredAt,
        recordedAt: now,
        source: AttendanceEventSource.admin,
        deviceId: deviceId,
        createdBy: session.admin.id,
      ),
    )).unwrap();
  }

  /// The event, if it belongs to the session's company and still counts.
  Future<Result<AttendanceEvent>> _correctableEvent(
    AdminSession session,
    String eventId,
  ) async {
    final found = await _events.getById(eventId);
    if (found case Err(:final failure)) {
      return Err(failure);
    }
    final (:event, :isSuperseded) = found.valueOrNull!;
    final employee = await _employees.getInCompany(
      session.companyId,
      event.employeeId,
    );
    if (employee case Err()) {
      return const Err(NotFoundFailure(entity: 'attendance entry'));
    }
    if (isSuperseded) {
      return const Err(
        ConflictFailure(
          userMessage:
              'This entry was already corrected. Reload the attendance and '
              'try again.',
        ),
      );
    }
    return Ok(event);
  }

  static ValidationFailure? _checkTime(DateTime occurredAt, DateTime now) {
    if (occurredAt.isAfter(now)) {
      return const ValidationFailure(
        field: 'time',
        userMessage: 'A correction cannot be in the future.',
      );
    }
    return null;
  }
}
