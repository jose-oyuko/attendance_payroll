import 'dart:math';

import 'package:attendance_payroll/core/errors/app_failure.dart';

/// Rules for employee PINs.
///
/// PINs are short, so trivially guessable ones (`1111`, `1234`, `9876`) are
/// refused; the lockout policy limits guessing of the rest.
abstract final class PinPolicy {
  static const int minLength = 4;
  static const int maxLength = 6;

  /// Length of PINs issued by an administrator.
  static const int temporaryLength = 6;

  static final RegExp _digits = RegExp(r'^\d+$');

  /// The first rule [pin] breaks, or `null` when it is acceptable.
  static ValidationFailure? validate(String pin) {
    if (!_digits.hasMatch(pin) ||
        pin.length < minLength ||
        pin.length > maxLength) {
      return const ValidationFailure(
        field: 'pin',
        userMessage: 'A PIN is $minLength to $maxLength digits.',
      );
    }
    if (_isTrivial(pin)) {
      return const ValidationFailure(
        field: 'pin',
        userMessage:
            'That PIN is too easy to guess. Avoid repeated or '
            'consecutive digits.',
      );
    }
    return null;
  }

  /// A random acceptable PIN of [temporaryLength] digits.
  static String generate(Random random) {
    while (true) {
      final pin = List<String>.generate(
        temporaryLength,
        (_) => random.nextInt(10).toString(),
      ).join();
      if (validate(pin) == null) {
        return pin;
      }
    }
  }

  /// All digits equal, or each digit one more (or one less) than the last.
  static bool _isTrivial(String pin) {
    final digits = pin.codeUnits;
    final step = digits[1] - digits[0];
    if (step.abs() > 1) {
      return false;
    }
    for (var i = 2; i < digits.length; i++) {
      if (digits[i] - digits[i - 1] != step) {
        return false;
      }
    }
    return true;
  }
}
