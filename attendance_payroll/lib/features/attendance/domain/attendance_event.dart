/// What happened. Stored by name, so future types (break start and end,
/// manual adjustments) need no migration; the state machine and session
/// builder decide how each type affects attendance.
enum AttendanceEventType { clockIn, clockOut }

/// How an event was captured. Imports and synchronised events are added with
/// the features that create them.
enum AttendanceEventSource {
  /// The employee at the attendance kiosk.
  kiosk,

  /// An administrator's correction (see `AttendanceCorrection`).
  admin,
}

/// A raw attendance action: the source of truth from which sessions are
/// derived. Events are append-only and never edited or deleted.
final class AttendanceEvent {
  const AttendanceEvent({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.occurredAt,
    required this.recordedAt,
    required this.source,
    required this.deviceId,
    required this.createdBy,
  });

  final String id;
  final String employeeId;
  final AttendanceEventType type;

  /// When the action happened (UTC). Sessions are built from this.
  final DateTime occurredAt;

  /// When this device stored the event (UTC). Differs from [occurredAt] for
  /// corrections and for events synchronised from elsewhere.
  final DateTime recordedAt;
  final AttendanceEventSource source;

  /// Installation that recorded the event.
  final String deviceId;

  /// Who recorded it: the employee for kiosk events, the administrator for
  /// corrections.
  final String createdBy;

  /// Total chronological order: by [occurredAt], then [recordedAt], then
  /// [id], so every device orders the same events identically.
  static int compareChronologically(AttendanceEvent a, AttendanceEvent b) {
    final byOccurrence = a.occurredAt.compareTo(b.occurredAt);
    if (byOccurrence != 0) {
      return byOccurrence;
    }
    final byRecording = a.recordedAt.compareTo(b.recordedAt);
    return byRecording != 0 ? byRecording : a.id.compareTo(b.id);
  }
}

/// An event to append.
final class NewAttendanceEvent {
  const NewAttendanceEvent({
    required this.employeeId,
    required this.type,
    required this.occurredAt,
    required this.recordedAt,
    required this.source,
    required this.deviceId,
    required this.createdBy,
  });

  final String employeeId;
  final AttendanceEventType type;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final AttendanceEventSource source;
  final String deviceId;
  final String createdBy;
}
