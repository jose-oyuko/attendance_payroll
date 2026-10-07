import 'package:attendance_payroll/core/logging/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Redactor.isSensitiveKey', () {
    test('flags keys that name secrets', () {
      for (final key in <String>[
        'pin',
        'PIN',
        'employeePin',
        'newPIN',
        'pin_hash',
        'passwordHash',
        'authToken',
        'client-secret',
        'Authorization',
      ]) {
        expect(Redactor.isSensitiveKey(key), isTrue, reason: key);
      }
    });

    test('does not flag unrelated keys', () {
      for (final key in <String>[
        'employeeNumber',
        'mapping',
        'shipping',
        'environment',
        'durationMinutes',
      ]) {
        expect(Redactor.isSensitiveKey(key), isFalse, reason: key);
      }
    });
  });

  group('Redactor.redactMap', () {
    test('masks sensitive values and keeps the rest', () {
      final redacted = Redactor.redactMap(<String, Object?>{
        'employeeId': 'e-1',
        'pin': '1234',
      });

      expect(redacted['employeeId'], 'e-1');
      expect(redacted['pin'], Redactor.mask);
    });

    test('recurses into nested maps and lists', () {
      final redacted = Redactor.redactMap(<String, Object?>{
        'request': <String, Object?>{'user': 'a', 'password': 'x'},
        'items': <Object?>[
          <String, Object?>{'token': 't', 'id': 1},
        ],
      });

      final request = redacted['request']! as Map<String, Object?>;
      expect(request['user'], 'a');
      expect(request['password'], Redactor.mask);

      final items = redacted['items']! as List<Object?>;
      final first = items.first! as Map<String, Object?>;
      expect(first['token'], Redactor.mask);
      expect(first['id'], 1);
    });

    test('does not modify the input', () {
      final input = <String, Object?>{'pin': '1234'};

      Redactor.redactMap(input);

      expect(input['pin'], '1234');
    });
  });
}
