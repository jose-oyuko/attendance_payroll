import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:flutter/material.dart';

/// The company-local time of [instant], e.g. "8:02 AM" or "08:02" depending
/// on the device's 24-hour setting.
String formatCompanyTime(
  BuildContext context,
  CompanyTimeZone zone,
  DateTime instant,
) {
  final timeOfDay = zone.wallTimeOf(instant).timeOfDay;
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(
      hour: timeOfDay.inHours,
      minute: timeOfDay.inMinutes % Duration.minutesPerHour,
    ),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// "8h 58m", "45m".
String formatWorkDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % Duration.minutesPerHour;
  if (hours == 0) {
    return '${minutes}m';
  }
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

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
