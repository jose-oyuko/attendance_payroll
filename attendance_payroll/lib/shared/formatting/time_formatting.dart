import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/minor_units.dart';
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

/// Hours with two decimals, e.g. "176.50 h": exact to the hundredth,
/// rounded half up from seconds.
String formatHours(Duration duration) {
  final hundredths =
      (duration.inSeconds * 100 + Duration.secondsPerHour ~/ 2) ~/
      Duration.secondsPerHour;
  return '${MinorUnits.format(hundredths)} h';
}
