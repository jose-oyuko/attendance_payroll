import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';

enum AttendanceCorrectionKind {
  /// A clock action the employee forgot was added.
  added,

  /// An event's time was changed (the original is kept, superseded).
  timeChanged,

  /// An event that should not count was removed (kept, superseded).
  removed,
}

/// An administrator's correction to attendance, kept forever as part of the
/// audit trail. The events it refers to are never edited or deleted.
final class AttendanceCorrection {
  const AttendanceCorrection({
    required this.id,
    required this.employeeId,
    required this.kind,
    required this.eventType,
    required this.originalEventId,
    required this.replacementEventId,
    required this.previousOccurredAt,
    required this.newOccurredAt,
    required this.reason,
    required this.correctedBy,
    required this.correctedAt,
  });

  final String id;
  final String employeeId;
  final AttendanceCorrectionKind kind;
  final AttendanceEventType eventType;

  /// The superseded event (time changes and removals).
  final String? originalEventId;

  /// The event that now counts (additions and time changes).
  final String? replacementEventId;

  /// The time before the correction (time changes and removals).
  final DateTime? previousOccurredAt;

  /// The time after the correction (additions and time changes).
  final DateTime? newOccurredAt;
  final String reason;

  /// Administrator who made it.
  final String correctedBy;
  final DateTime correctedAt;
}

/// A correction to record.
final class NewAttendanceCorrection {
  const NewAttendanceCorrection({
    required this.employeeId,
    required this.kind,
    required this.eventType,
    required this.originalEventId,
    required this.replacementEventId,
    required this.previousOccurredAt,
    required this.newOccurredAt,
    required this.reason,
    required this.correctedBy,
    required this.correctedAt,
  });

  final String employeeId;
  final AttendanceCorrectionKind kind;
  final AttendanceEventType eventType;
  final String? originalEventId;
  final String? replacementEventId;
  final DateTime? previousOccurredAt;
  final DateTime? newOccurredAt;
  final String reason;
  final String correctedBy;
  final DateTime correctedAt;
}

/// Rules for the explanation every correction must carry.
abstract final class CorrectionReason {
  static const int minLength = 3;
  static const int maxLength = 500;

  static ValidationFailure? validate(String reason) {
    final length = reason.trim().length;
    if (length < minLength) {
      return const ValidationFailure(
        field: 'reason',
        userMessage: 'Give a reason for the correction.',
      );
    }
    if (length > maxLength) {
      return const ValidationFailure(
        field: 'reason',
        userMessage: 'Keep the reason under $maxLength characters.',
      );
    }
    return null;
  }
}

abstract interface class AttendanceCorrectionRepository {
  /// Records [correction]. Fails with a `ConflictFailure` if its original
  /// event was already superseded by another correction.
  Future<Result<AttendanceCorrection>> record(
    NewAttendanceCorrection correction,
  );

  /// Corrections affecting the employee's attendance between [from] and [to]
  /// (by the corrected time), newest correction first.
  Future<Result<List<AttendanceCorrection>>> forEmployee(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  });
}
