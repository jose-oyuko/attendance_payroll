import 'dart:math';

/// Failed-attempt bookkeeping after an attempt.
typedef AttemptState = ({int failedAttempts, DateTime? lockedUntil});

/// Limits guessing of PINs and passwords.
///
/// Every [maxAttempts] consecutive failures lock the credential. The first
/// lock lasts [baseLockDuration] and each further lock doubles it, up to
/// [maxLockDuration], so guessing a short PIN stays impractical. A successful
/// attempt resets the count.
final class LockoutPolicy {
  const LockoutPolicy({
    required this.maxAttempts,
    required this.baseLockDuration,
    required this.maxLockDuration,
  });

  final int maxAttempts;
  final Duration baseLockDuration;
  final Duration maxLockDuration;

  static const int _maxDoublings = 16;

  bool isLocked(DateTime? lockedUntil, DateTime now) {
    return lockedUntil != null && now.isBefore(lockedUntil);
  }

  /// The state after one more failure, given [failedAttempts] so far.
  AttemptState afterFailure(int failedAttempts, DateTime now) {
    final attempts = failedAttempts + 1;
    if (attempts % maxAttempts != 0) {
      return (failedAttempts: attempts, lockedUntil: null);
    }
    final doublings = min(attempts ~/ maxAttempts - 1, _maxDoublings);
    var duration = baseLockDuration * (1 << doublings);
    if (duration > maxLockDuration) {
      duration = maxLockDuration;
    }
    return (failedAttempts: attempts, lockedUntil: now.add(duration));
  }
}
