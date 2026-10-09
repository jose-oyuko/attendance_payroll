import 'package:attendance_payroll/core/errors/app_failure.dart';

/// How a company pays overtime and converts daily and monthly rates to an
/// hourly equivalent. Rules vary by country and sector, so nothing is
/// assumed: overtime applies only once a threshold is set.
final class PayrollSettings {
  const PayrollSettings({
    this.dailyOvertimeAfter,
    this.weeklyOvertimeAfter,
    this.overtimePercent = 150,
    this.standardDay = const Duration(hours: 8),
    this.standardWeek = const Duration(hours: 40),
  });

  /// Work beyond this in one day is overtime; `null` for no daily rule.
  final Duration? dailyOvertimeAfter;

  /// Work beyond this in one ISO week (Monday to Sunday) is overtime, after
  /// any daily overtime; `null` for no weekly rule.
  final Duration? weeklyOvertimeAfter;

  /// Overtime pay as a percentage of the normal hourly rate: 150 is "time
  /// and a half".
  final int overtimePercent;

  /// Hours in a normal day: a daily rate divided by this gives the hourly
  /// rate for that employee's overtime.
  final Duration standardDay;

  /// Hours in a normal week: a monthly salary × 12 ÷ 52 ÷ this gives the
  /// hourly rate for that employee's overtime.
  final Duration standardWeek;

  static const int maxOvertimePercent = 400;

  ValidationFailure? validate() {
    final daily = dailyOvertimeAfter;
    if (daily != null && (daily <= Duration.zero || daily > _day)) {
      return const ValidationFailure(
        field: 'dailyOvertimeAfter',
        userMessage: 'Daily overtime must start after 1 minute to 24 hours.',
      );
    }
    final weekly = weeklyOvertimeAfter;
    if (weekly != null && (weekly <= Duration.zero || weekly > _week)) {
      return const ValidationFailure(
        field: 'weeklyOvertimeAfter',
        userMessage: 'Weekly overtime must start after 1 minute to 168 hours.',
      );
    }
    if (overtimePercent < 100 || overtimePercent > maxOvertimePercent) {
      return const ValidationFailure(
        field: 'overtimePercent',
        userMessage:
            'The overtime rate must be 100% to 400% of the normal '
            'rate.',
      );
    }
    if (standardDay <= Duration.zero || standardDay > _day) {
      return const ValidationFailure(
        field: 'standardDay',
        userMessage: 'A standard day must be 1 minute to 24 hours.',
      );
    }
    if (standardWeek <= Duration.zero || standardWeek > _week) {
      return const ValidationFailure(
        field: 'standardWeek',
        userMessage: 'A standard week must be 1 minute to 168 hours.',
      );
    }
    return null;
  }

  static const Duration _day = Duration(hours: 24);
  static const Duration _week = Duration(days: 7);
}
