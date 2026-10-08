import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';

void main() {
  const policy = AttendancePolicy();
  const clockIn = AttendanceEventType.clockIn;
  const clockOut = AttendanceEventType.clockOut;
  late EventFactory e;

  setUp(() => e = EventFactory());

  String? ruleFor(
    AttendanceEvent? latest,
    AttendanceEventType action,
    DateTime now,
  ) {
    final state = AttendanceStateMachine.stateAfter(latest, now, policy);
    return AttendanceStateMachine.check(
      state: state,
      action: action,
      latest: latest,
      now: now,
    )?.rule;
  }

  test('with no history, only clocking in is allowed', () {
    final now = nairobiTime(5, 8, 0);
    final state = AttendanceStateMachine.stateAfter(null, now, policy);

    expect(state, isA<NotClockedIn>());
    expect(state.allowedActions, {clockIn});
    expect(ruleFor(null, clockIn, now), isNull);
    expect(
      ruleFor(null, clockOut, now),
      AttendanceStateMachine.notClockedInRule,
    );
  });

  test('after clocking in, only clocking out is allowed', () {
    final latest = e.clockIn(5, 8, 0);
    final now = nairobiTime(5, 12, 0);
    final state = AttendanceStateMachine.stateAfter(latest, now, policy);

    expect(state, isA<ClockedIn>());
    expect((state as ClockedIn).since, latest.occurredAt);
    expect(state.isStale, isFalse);
    expect(ruleFor(latest, clockOut, now), isNull);
    expect(
      ruleFor(latest, clockIn, now),
      AttendanceStateMachine.alreadyClockedInRule,
    );
  });

  test('after clocking out, only clocking in is allowed', () {
    final latest = e.clockOut(5, 17, 0);
    final now = nairobiTime(5, 17, 1);
    final state = AttendanceStateMachine.stateAfter(latest, now, policy);

    expect(state, isA<NotClockedIn>());
    expect((state as NotClockedIn).lastClockOutAt, latest.occurredAt);
    expect(
      ruleFor(latest, clockOut, now),
      AttendanceStateMachine.notClockedInRule,
    );
    expect(ruleFor(latest, clockIn, now), isNull);
  });

  test('a stale clock-in does not block the next day', () {
    final latest = e.clockIn(5, 8, 2);
    final nextMorning = nairobiTime(6, 8, 1);
    final state =
        AttendanceStateMachine.stateAfter(latest, nextMorning, policy)
            as ClockedIn;

    expect(state.isStale, isTrue);
    expect(state.allowedActions, {clockIn, clockOut});
    expect(ruleFor(latest, clockIn, nextMorning), isNull);
  });

  test('staleness starts just after the policy threshold', () {
    final latest = e.clockIn(5, 8, 0);
    final atThreshold = latest.occurredAt.add(policy.staleOpenSessionAfter);

    final at = AttendanceStateMachine.stateAfter(latest, atThreshold, policy);
    final after = AttendanceStateMachine.stateAfter(
      latest,
      atThreshold.add(const Duration(seconds: 1)),
      policy,
    );

    expect((at as ClockedIn).isStale, isFalse);
    expect((after as ClockedIn).isStale, isTrue);
  });

  test('a device clock earlier than the last event blocks recording', () {
    final latest = e.clockOut(5, 17, 0);
    final behind = nairobiTime(5, 16, 0);

    expect(
      ruleFor(latest, clockIn, behind),
      AttendanceStateMachine.clockBehindRule,
    );
    expect(ruleFor(latest, clockIn, latest.occurredAt), isNull);
  });
}
