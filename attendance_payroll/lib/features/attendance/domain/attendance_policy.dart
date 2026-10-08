import 'package:attendance_payroll/core/errors/app_failure.dart';

/// Deducts a fixed break from long sessions, for workplaces that do not
/// record breaks. Work schedules (Phase 6) can supply this per schedule;
/// manual break events can replace it later without changing sessions' shape.
final class AutomaticBreak {
  const AutomaticBreak({required this.after, required this.deduct});

  /// Sessions at least this long get the deduction.
  final Duration after;
  final Duration deduct;

  /// The break for a session of [worked] time; never more than [worked], so
  /// payable time cannot become negative.
  Duration breakFor(Duration worked) {
    if (worked < after) {
      return Duration.zero;
    }
    return deduct < worked ? deduct : worked;
  }

  @override
  bool operator ==(Object other) {
    return other is AutomaticBreak &&
        other.after == after &&
        other.deduct == deduct;
  }

  @override
  int get hashCode => Object.hash(after, deduct);
}

/// How attendance is interpreted. Each company sets its own values (see
/// `AttendanceSettingsRepository`); the defaults suit a typical day shift.
///
/// These are deliberately not zero-tolerance: a long session is flagged for
/// review, never discarded or silently shortened.
final class AttendancePolicy {
  const AttendancePolicy({
    this.duplicateWindow = const Duration(minutes: 10),
    this.staleOpenSessionAfter = const Duration(hours: 16),
    this.excessiveDurationAfter = const Duration(hours: 12),
    this.automaticBreak,
  });

  // Accepted ranges. They keep settings meaningful (a zero excessive-duration
  // threshold would flag every session) without dictating local practice.
  static const Duration maxDuplicateWindow = Duration(hours: 1);
  static const Duration minStaleOpenSession = Duration(hours: 2);
  static const Duration maxStaleOpenSession = Duration(hours: 72);
  static const Duration minExcessiveDuration = Duration(hours: 1);
  static const Duration maxExcessiveDuration = Duration(hours: 24);
  static const Duration maxBreak = Duration(hours: 4);

  /// How long a successful PIN entry authorises a clock action. A security
  /// setting, not a local preference, so it is fixed.
  static const Duration pinVerificationValidFor = Duration(minutes: 2);

  /// A repeated clock-in or clock-out within this time of the previous one
  /// is a harmless duplicate (for example a double tap) and is ignored for
  /// time. A repeat after longer means something was missed, and is flagged
  /// as a missing clock-out or a clock-out without a clock-in.
  final Duration duplicateWindow;

  /// An open session older than this is treated as a forgotten clock-out:
  /// the employee may clock in again, and the old session is flagged.
  final Duration staleOpenSessionAfter;

  /// Completed sessions longer than this are flagged for review.
  final Duration excessiveDurationAfter;

  /// Break deducted from payable time, or `null` for none.
  final AutomaticBreak? automaticBreak;

  /// Extra events loaded either side of a date range, so sessions crossing
  /// the range boundaries are built with their full context. Always longer
  /// than any session that could still be open or unflagged.
  Duration get sessionLookaround {
    final longest = staleOpenSessionAfter > excessiveDurationAfter
        ? staleOpenSessionAfter
        : excessiveDurationAfter;
    return longest * 2;
  }

  /// The first value outside its accepted range, or `null` when valid.
  ValidationFailure? validate() {
    if (duplicateWindow.isNegative || duplicateWindow > maxDuplicateWindow) {
      return const ValidationFailure(
        field: 'duplicateWindow',
        userMessage: 'The duplicate window must be between 0 and 60 minutes.',
      );
    }
    if (staleOpenSessionAfter < minStaleOpenSession ||
        staleOpenSessionAfter > maxStaleOpenSession) {
      return const ValidationFailure(
        field: 'staleOpenSessionAfter',
        userMessage:
            'A forgotten clock-out must be assumed after 2 to 72 hours.',
      );
    }
    if (excessiveDurationAfter < minExcessiveDuration ||
        excessiveDurationAfter > maxExcessiveDuration) {
      return const ValidationFailure(
        field: 'excessiveDurationAfter',
        userMessage: 'Long sessions must be flagged after 1 to 24 hours.',
      );
    }
    final automaticBreak = this.automaticBreak;
    if (automaticBreak != null) {
      if (automaticBreak.deduct <= Duration.zero ||
          automaticBreak.deduct > maxBreak) {
        return const ValidationFailure(
          field: 'breakDeduct',
          userMessage:
              'The automatic break must be between 1 minute and 4 '
              'hours.',
        );
      }
      if (automaticBreak.after <= automaticBreak.deduct ||
          automaticBreak.after > maxExcessiveDuration) {
        return const ValidationFailure(
          field: 'breakAfter',
          userMessage:
              'The break must apply after more time than it lasts, '
              'and within 24 hours.',
        );
      }
    }
    return null;
  }

  /// Names of the settings that differ from [other], for the audit log.
  List<String> changedFieldsFrom(AttendancePolicy other) {
    return [
      if (duplicateWindow != other.duplicateWindow) 'duplicateWindow',
      if (staleOpenSessionAfter != other.staleOpenSessionAfter)
        'staleOpenSessionAfter',
      if (excessiveDurationAfter != other.excessiveDurationAfter)
        'excessiveDurationAfter',
      if (automaticBreak != other.automaticBreak) 'automaticBreak',
    ];
  }
}
