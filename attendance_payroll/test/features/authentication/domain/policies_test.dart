import 'dart:math';

import 'package:attendance_payroll/features/authentication/domain/password_policy.dart';
import 'package:attendance_payroll/features/authentication/domain/pin_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinPolicy', () {
    test('accepts 4 to 6 non-trivial digits', () {
      for (final pin in ['2468', '13579', '804613', '1357']) {
        expect(PinPolicy.validate(pin), isNull, reason: pin);
      }
    });

    test('rejects wrong lengths and non-digits', () {
      for (final pin in ['', '123', '1234567', '12a4', ' 2468']) {
        expect(PinPolicy.validate(pin)?.field, 'pin', reason: pin);
      }
    });

    test('rejects repeated and consecutive digits', () {
      for (final pin in ['0000', '111111', '1234', '0123', '9876', '543210']) {
        expect(PinPolicy.validate(pin), isNotNull, reason: pin);
      }
    });

    test('generated PINs are valid and of the temporary length', () {
      final random = Random(1);
      for (var i = 0; i < 200; i++) {
        final pin = PinPolicy.generate(random);
        expect(pin, hasLength(PinPolicy.temporaryLength));
        expect(PinPolicy.validate(pin), isNull, reason: pin);
      }
    });
  });

  group('PasswordPolicy', () {
    test('requires 8 to 128 characters, ignoring surrounding spaces', () {
      expect(PasswordPolicy.validate('long enough'), isNull);
      expect(PasswordPolicy.validate('short'), isNotNull);
      expect(PasswordPolicy.validate('   seven   '), isNotNull);
      expect(PasswordPolicy.validate('x' * 129), isNotNull);
    });
  });
}
