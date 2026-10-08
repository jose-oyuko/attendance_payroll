import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:flutter/material.dart';

/// Formats a calendar date for display in the user's locale, e.g. "Jul 1, 2026".
String formatLocalDate(BuildContext context, LocalDate date) {
  return MaterialLocalizations.of(
    context,
  ).formatMediumDate(DateTime(date.year, date.month, date.day));
}

/// Formats the time of day of an instant in the device's timezone.
String formatTimeOfDay(BuildContext context, DateTime instant) {
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(instant.toLocal()));
}
