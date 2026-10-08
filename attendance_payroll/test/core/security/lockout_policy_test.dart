import 'package:attendance_payroll/core/security/lockout_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = LockoutPolicy(
    maxAttempts: 3,
    baseLockDuration: Duration(minutes: 1),
    maxLockDuration: Duration(minutes: 5),
  );
  final now = DateTime.utc(2026, 10, 8, 9);

  test('failures below the limit only count', () {
    final state = policy.afterFailure(1, now);

    expect(state.failedAttempts, 2);
    expect(state.lockedUntil, isNull);
  });

  test('reaching the limit locks for the base duration', () {
    final state = policy.afterFailure(2, now);

    expect(state.failedAttempts, 3);
    expect(state.lockedUntil, now.add(const Duration(minutes: 1)));
  });

  test('each further lock doubles, up to the maximum', () {
    Duration lockAt(int previousFailures) =>
        policy.afterFailure(previousFailures, now).lockedUntil!.difference(now);

    expect(lockAt(5), const Duration(minutes: 2));
    expect(lockAt(8), const Duration(minutes: 4));
    expect(lockAt(11), const Duration(minutes: 5));
    expect(lockAt(3000 - 1), const Duration(minutes: 5));
  });

  test('isLocked is true only before the lock expires', () {
    final until = now.add(const Duration(minutes: 1));

    expect(policy.isLocked(until, now), isTrue);
    expect(policy.isLocked(until, until), isFalse);
    expect(policy.isLocked(null, now), isFalse);
  });
}
