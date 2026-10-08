import 'package:attendance_payroll/core/errors/app_failure.dart';

/// Rules for administrator passwords: long enough to resist guessing, with no
/// composition rules (current NIST guidance).
abstract final class PasswordPolicy {
  static const int minLength = 8;
  static const int maxLength = 128;

  static ValidationFailure? validate(String password) {
    if (password.trim().length < minLength) {
      return const ValidationFailure(
        field: 'password',
        userMessage: 'Use at least $minLength characters.',
      );
    }
    if (password.length > maxLength) {
      return const ValidationFailure(
        field: 'password',
        userMessage: 'Use at most $maxLength characters.',
      );
    }
    return null;
  }
}
