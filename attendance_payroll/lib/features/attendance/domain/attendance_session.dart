import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';

/// Anomalies found while deriving sessions. Phase 5 turns these into
/// reviewable attendance exceptions; late arrival and early departure are
/// added with work schedules (Phase 6).
enum AttendanceIssueType {
  /// An open session was never closed.
  missingClockOut(blocksPayroll: true),

  /// The session ends on a later company-local date than it starts.
  overnightSession(blocksPayroll: true),

  /// The session is longer than the policy allows without review.
  excessiveDuration(blocksPayroll: true),

  /// A clock-in repeated within the duplicate window. The first one counts.
  duplicateClockIn(blocksPayroll: false),

  /// A clock-out repeated within the duplicate window. The first one counts.
  duplicateClockOut(blocksPayroll: false),

  /// A clock-out with no clock-in before it, so some work time may be
  /// unrecorded. It affects no session's time.
  clockOutWithoutClockIn(blocksPayroll: false);

  const AttendanceIssueType({required this.blocksPayroll});

  /// Whether the session's time must be reviewed before it can be paid.
  final bool blocksPayroll;
}

/// One anomaly, anchored to the event that revealed it.
final class AttendanceIssue {
  const AttendanceIssue({
    required this.type,
    required this.eventId,
    required this.occurredAt,
    this.sessionKey,
  });

  final AttendanceIssueType type;
  final String eventId;
  final DateTime occurredAt;

  /// The session it concerns, if any.
  final String? sessionKey;
}

enum SessionStatus {
  /// Clocked in and not yet clocked out.
  open,

  /// Clocked in and out with nothing to review.
  completed,

  /// Has an issue that blocks payroll until reviewed.
  exception,
}

/// A period of work derived from a clock-in and its clock-out.
///
/// Sessions are never stored as the source of truth: they are rebuilt from
/// events whenever needed, so they always agree with them. [key] is the
/// clock-in event's id, which stays the same across rebuilds and lets later
/// features (exceptions, approvals) refer to a session.
final class AttendanceSession {
  const AttendanceSession({
    required this.clockIn,
    required this.clockOut,
    required this.workDate,
    required this.status,
    required this.issues,
    required this.breakDuration,
  });

  final AttendanceEvent clockIn;
  final AttendanceEvent? clockOut;

  /// Company-local date on which the session started.
  final LocalDate workDate;
  final SessionStatus status;
  final List<AttendanceIssue> issues;
  final Duration breakDuration;

  String get key => clockIn.id;

  String get employeeId => clockIn.employeeId;

  DateTime get start => clockIn.occurredAt;

  DateTime? get end => clockOut?.occurredAt;

  /// Whether an administrator entered or corrected either end.
  bool get isCorrected =>
      clockIn.source == AttendanceEventSource.admin ||
      clockOut?.source == AttendanceEventSource.admin;

  /// Time between clock-in and clock-out, once clocked out.
  Duration? get duration => end?.difference(start);

  /// Time to pay: only for completed sessions. A session with an exception
  /// has no payable time until it is reviewed, so payroll never uses
  /// anomalous attendance blindly.
  Duration? get payableDuration {
    final worked = duration;
    if (status != SessionStatus.completed || worked == null) {
      return null;
    }
    return worked - breakDuration;
  }
}

/// Sessions plus every issue found, including those not tied to a session.
final class AttendanceTimeline {
  const AttendanceTimeline({required this.sessions, required this.issues});

  /// Chronological.
  final List<AttendanceSession> sessions;

  /// Chronological by the event that revealed each issue.
  final List<AttendanceIssue> issues;
}
