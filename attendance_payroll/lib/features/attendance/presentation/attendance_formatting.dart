import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';

extension AttendanceEventTypeLabel on AttendanceEventType {
  String get label => switch (this) {
    AttendanceEventType.clockIn => 'Clock-in',
    AttendanceEventType.clockOut => 'Clock-out',
  };
}

extension AttendanceIssueLabel on AttendanceIssueType {
  String get label => switch (this) {
    AttendanceIssueType.missingClockOut => 'No clock-out recorded',
    AttendanceIssueType.overnightSession => 'Ends on a later day',
    AttendanceIssueType.excessiveDuration => 'Unusually long',
    AttendanceIssueType.duplicateClockIn => 'Repeated clock-in (ignored)',
    AttendanceIssueType.duplicateClockOut => 'Repeated clock-out (ignored)',
    AttendanceIssueType.clockOutWithoutClockIn => 'Clock-out with no clock-in',
    AttendanceIssueType.lateArrival => 'Late arrival',
    AttendanceIssueType.earlyDeparture => 'Left early',
    AttendanceIssueType.missingAttendance => 'Absent on a scheduled day',
  };

  /// What happened and what the administrator can do about it.
  String get description => switch (this) {
    AttendanceIssueType.missingClockOut =>
      'There is a clock-in but no clock-out, so the time cannot be paid. '
          'Add the clock-out, or remove the clock-in if it was a mistake.',
    AttendanceIssueType.overnightSession =>
      'The session ends on a later day than it starts. Check the clock-out '
          'time, or accept it if the shift really crossed midnight.',
    AttendanceIssueType.excessiveDuration =>
      "The session is longer than the company's limit. Check the times, or "
          'accept them if the employee really worked this long.',
    AttendanceIssueType.duplicateClockIn =>
      'The employee clocked in again shortly after clocking in. Only the '
          'first clock-in counts.',
    AttendanceIssueType.duplicateClockOut =>
      'The employee clocked out again shortly after clocking out. Only the '
          'first clock-out counts.',
    AttendanceIssueType.clockOutWithoutClockIn =>
      'A clock-out with no clock-in before it, so some work may be '
          'unrecorded. Add the missing clock-in, or remove the clock-out.',
    AttendanceIssueType.lateArrival =>
      'The first clock-in of the day was after the scheduled start plus the '
          'allowed lateness. Excuse it if there was a reason, or correct the '
          'time if it was recorded wrongly.',
    AttendanceIssueType.earlyDeparture =>
      'The last clock-out of the day was before the scheduled end, beyond '
          'the allowed margin. Excuse it, or correct the time if it was '
          'recorded wrongly.',
    AttendanceIssueType.missingAttendance =>
      'The employee was scheduled to work but has no attendance that day. '
          'Excuse it (for example leave or a holiday), or add the clock-in and '
          'clock-out if they worked.',
  };

  /// The kind of entry the issue points at, or `null` for a whole day.
  AttendanceEventType? get eventType => switch (this) {
    AttendanceIssueType.missingClockOut ||
    AttendanceIssueType.duplicateClockIn ||
    AttendanceIssueType.lateArrival => AttendanceEventType.clockIn,
    AttendanceIssueType.overnightSession ||
    AttendanceIssueType.excessiveDuration ||
    AttendanceIssueType.duplicateClockOut ||
    AttendanceIssueType.clockOutWithoutClockIn ||
    AttendanceIssueType.earlyDeparture => AttendanceEventType.clockOut,
    AttendanceIssueType.missingAttendance => null,
  };
}

extension ExceptionStatusLabel on ExceptionStatus {
  String get label => switch (this) {
    ExceptionStatus.open => 'Needs action',
    ExceptionStatus.reviewed => 'Noted',
    ExceptionStatus.resolved => 'Resolved',
    ExceptionStatus.dismissed => 'Dismissed',
  };
}

extension ReviewDecisionLabel on ReviewDecision {
  String get label => switch (this) {
    ReviewDecision.reviewed => 'Noted',
    ReviewDecision.resolved => 'Resolved',
    ReviewDecision.dismissed => 'Dismissed',
  };
}
