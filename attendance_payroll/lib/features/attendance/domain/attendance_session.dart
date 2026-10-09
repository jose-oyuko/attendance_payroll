import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';

/// Anomalies found while deriving attendance, reviewed as exceptions.
enum AttendanceIssueType {
  /// An open session was never closed.
  missingClockOut(blocksPayroll: true),

  /// The session ends on a later company-local date than it starts, and the
  /// employee's schedule does not expect that.
  overnightSession(blocksPayroll: true),

  /// The session is longer than the policy allows without review.
  excessiveDuration(blocksPayroll: true),

  /// A clock-in repeated within the duplicate window. The first one counts.
  duplicateClockIn(blocksPayroll: false),

  /// A clock-out repeated within the duplicate window. The first one counts.
  duplicateClockOut(blocksPayroll: false),

  /// A clock-out with no clock-in before it, so some work time may be
  /// unrecorded. It affects no session's time.
  clockOutWithoutClockIn(blocksPayroll: false),

  /// The day's first clock-in is later than the scheduled start plus the
  /// late tolerance.
  lateArrival(blocksPayroll: false),

  /// The day's last clock-out is earlier than the scheduled end minus the
  /// early-departure tolerance.
  earlyDeparture(blocksPayroll: false),

  /// A scheduled shift ended without any attendance.
  missingAttendance(blocksPayroll: false);

  const AttendanceIssueType({required this.blocksPayroll});

  /// Whether the session's time must be reviewed before it can be paid.
  /// Lateness, early departure and absence are reported but never block:
  /// pay follows the time actually worked.
  final bool blocksPayroll;
}

/// One anomaly, anchored to what revealed it: an event, or for missing
/// attendance the employee and date.
final class AttendanceIssue {
  const AttendanceIssue({
    required this.type,
    required this.employeeId,
    required this.anchor,
    required this.occurredAt,
    this.eventId,
    this.sessionKey,
  });

  final AttendanceIssueType type;
  final String employeeId;

  /// The event id, or `<employee id>@<date>` when no event exists.
  final String anchor;

  /// The event that revealed it, if any.
  final String? eventId;

  /// When it happened (for missing attendance: the scheduled start).
  final DateTime occurredAt;

  /// The session it concerns, if any.
  final String? sessionKey;

  /// Stable identity: the same issue revealed by the same anchor always has
  /// the same key, so review decisions can refer to it. A correction that
  /// replaces the event yields a new key, and with it a fresh review.
  String get key => keyFor(type, anchor);

  static String keyFor(AttendanceIssueType type, String anchor) =>
      '${type.name}:$anchor';

  /// The anchor of an issue about a whole day without events.
  static String dayAnchor(String employeeId, LocalDate date) =>
      '$employeeId@${date.toIsoString()}';
}

enum SessionStatus {
  /// Clocked in and not yet clocked out.
  open,

  /// Clocked in and out with nothing to review.
  completed,

  /// Has an issue that blocks payroll until reviewed.
  exception,

  /// Had issues that blocked payroll; an administrator accepted the time as
  /// recorded, so it is payable.
  approved,
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

  /// Time to pay: only for completed or approved sessions. A session with an
  /// exception has no payable time until it is reviewed, so payroll never
  /// uses anomalous attendance blindly.
  Duration? get payableDuration {
    final worked = duration;
    final payable =
        status == SessionStatus.completed || status == SessionStatus.approved;
    if (!payable || worked == null) {
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
