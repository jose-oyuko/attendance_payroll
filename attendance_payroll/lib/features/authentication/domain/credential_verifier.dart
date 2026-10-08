import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/security/lockout_policy.dart';
import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/authentication/domain/credential.dart';

/// Checks a secret against a stored credential and enforces the lockout
/// policy. Shared by administrator and employee authentication, which each
/// supply their own hasher and policy.
final class CredentialVerifier {
  CredentialVerifier({
    required this._credentials,
    required this._hasher,
    required this._policy,
    required this._clock,
  });

  final CredentialRepository _credentials;
  final SecretHasher _hasher;
  final LockoutPolicy _policy;
  final Clock _clock;

  /// Verifies [secret] for [owner] and records the attempt.
  ///
  /// Returns the credential when the secret matches. Otherwise fails with an
  /// [AuthenticationFailure]: [wrongSecretMessage] for a wrong secret or a
  /// missing credential, or a "try again later" message while locked. A
  /// locked credential is not checked at all, so guessing gains nothing.
  /// [onLockedOut] runs when this attempt triggers a lock.
  Future<Result<StoredCredential>> verify(
    CredentialOwner owner,
    String secret, {
    required String wrongSecretMessage,
    Future<void> Function()? onLockedOut,
  }) async {
    final found = await _credentials.find(owner);
    if (found case Err(:final failure)) {
      return Err(failure);
    }
    final credential = found.valueOrNull;
    if (credential == null) {
      await _hasher.verifyAgainstDummy(secret);
      return Err(AuthenticationFailure(userMessage: wrongSecretMessage));
    }

    final now = _clock();
    if (credential.lockedUntil case final until?
        when _policy.isLocked(until, now)) {
      return Err(lockedFailure(until.difference(now)));
    }

    if (await _hasher.verify(secret, credential.secretHash)) {
      if (credential.failedAttempts > 0 || credential.lockedUntil != null) {
        final reset = await _credentials.recordAttempts(
          owner,
          failedAttempts: 0,
          lockedUntil: null,
        );
        if (reset case Err(:final failure)) {
          return Err(failure);
        }
      }
      return Ok(credential);
    }

    final next = _policy.afterFailure(credential.failedAttempts, now);
    final saved = await _credentials.recordAttempts(
      owner,
      failedAttempts: next.failedAttempts,
      lockedUntil: next.lockedUntil,
    );
    if (saved case Err(:final failure)) {
      return Err(failure);
    }
    if (next.lockedUntil case final until?) {
      await onLockedOut?.call();
      return Err(lockedFailure(until.difference(now)));
    }
    return Err(AuthenticationFailure(userMessage: wrongSecretMessage));
  }

  /// "Try again in …" with the remaining time rounded up.
  static AuthenticationFailure lockedFailure(Duration remaining) {
    final minutes = (remaining.inSeconds / Duration.secondsPerMinute).ceil();
    final String wait;
    if (minutes >= Duration.minutesPerHour) {
      final hours = (minutes / Duration.minutesPerHour).ceil();
      wait = hours == 1 ? '1 hour' : '$hours hours';
    } else {
      wait = minutes <= 1 ? '1 minute' : '$minutes minutes';
    }
    return AuthenticationFailure(
      userMessage: 'Too many incorrect attempts. Try again in $wait.',
    );
  }
}
