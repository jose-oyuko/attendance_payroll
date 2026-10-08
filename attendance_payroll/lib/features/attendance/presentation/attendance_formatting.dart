import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
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
  };

  /// The kind of entry the issue points at.
  AttendanceEventType get eventType => switch (this) {
    AttendanceIssueType.missingClockOut ||
    AttendanceIssueType.duplicateClockIn => AttendanceEventType.clockIn,
    AttendanceIssueType.overnightSession ||
    AttendanceIssueType.excessiveDuration ||
    AttendanceIssueType.duplicateClockOut ||
    AttendanceIssueType.clockOutWithoutClockIn => AttendanceEventType.clockOut,
  };
}
