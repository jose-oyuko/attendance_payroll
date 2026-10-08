import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';

/// An employee's attendance state, which decides which actions the kiosk
/// may record.
///
/// ```
/// NotClockedIn ──clockIn──▶ ClockedIn ──clockOut──▶ NotClockedIn
///                           ClockedIn (stale) ──clockIn──▶ ClockedIn
/// ```
///
/// Break events will add an `OnBreak` state here.
sealed class AttendanceState {
  const AttendanceState();

  Set<AttendanceEventType> get allowedActions;
}

final class NotClockedIn extends AttendanceState {
  const NotClockedIn({this.lastClockOutAt});

  final DateTime? lastClockOutAt;

  @override
  Set<AttendanceEventType> get allowedActions => const {
    AttendanceEventType.clockIn,
  };
}

final class ClockedIn extends AttendanceState {
  const ClockedIn({required this.since, required this.isStale});

  final DateTime since;

  /// Open for longer than a shift plausibly lasts: probably a forgotten
  /// clock-out. Clocking in again is then allowed and the old session is
  /// flagged for review, so a forgotten clock-out never blocks today's work.
  final bool isStale;

  @override
  Set<AttendanceEventType> get allowedActions => {
    AttendanceEventType.clockOut,
    if (isStale) AttendanceEventType.clockIn,
  };
}

/// The rules for recording attendance actions live here rather than in
/// scattered conditionals.
abstract final class AttendanceStateMachine {
  static const String alreadyClockedInRule = 'already_clocked_in';
  static const String notClockedInRule = 'not_clocked_in';
  static const String clockBehindRule = 'device_clock_behind';

  /// The state after [latest], the employee's most recent event, at [now].
  static AttendanceState stateAfter(
    AttendanceEvent? latest,
    DateTime now,
    AttendancePolicy policy,
  ) {
    if (latest == null || latest.type == AttendanceEventType.clockOut) {
      return NotClockedIn(lastClockOutAt: latest?.occurredAt);
    }
    return ClockedIn(
      since: latest.occurredAt,
      isStale: now.difference(latest.occurredAt) > policy.staleOpenSessionAfter,
    );
  }

  /// Why [action] may not be recorded at [now], or `null` when it may.
  ///
  /// Recording before the latest event would put events out of order, which
  /// only happens when the device clock was moved back.
  static BusinessRuleFailure? check({
    required AttendanceState state,
    required AttendanceEventType action,
    required AttendanceEvent? latest,
    required DateTime now,
  }) {
    if (latest != null && now.isBefore(latest.occurredAt)) {
      return const BusinessRuleFailure(
        rule: clockBehindRule,
        userMessage:
            "This device's clock is earlier than the last recorded "
            'attendance. Check the date and time settings.',
      );
    }
    if (state.allowedActions.contains(action)) {
      return null;
    }
    return switch (action) {
      AttendanceEventType.clockIn => const BusinessRuleFailure(
        rule: alreadyClockedInRule,
        userMessage: 'You are already clocked in.',
      ),
      AttendanceEventType.clockOut => const BusinessRuleFailure(
        rule: notClockedInRule,
        userMessage: 'You are not clocked in.',
      ),
    };
  }
}
