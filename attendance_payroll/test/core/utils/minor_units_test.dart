import 'package:attendance_payroll/core/utils/minor_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MinorUnits.parse', () {
    test('parses whole and decimal amounts exactly', () {
      expect(MinorUnits.parse('500'), 50000);
      expect(MinorUnits.parse('500.5'), 50050);
      expect(MinorUnits.parse('500.05'), 50005);
      expect(MinorUnits.parse(' 1,250.75 '), 125075);
      expect(MinorUnits.parse('0.10'), 10);
      expect(MinorUnits.parse('500.'), 50000);
    });

    test('rejects malformed, negative and over-precise amounts', () {
      for (final input in ['', 'abc', '-5', '1.234', '1.2.3', '5e2']) {
        expect(MinorUnits.parse(input), isNull, reason: input);
      }
    });

    test('supports currencies without minor units', () {
      expect(MinorUnits.parse('500', decimals: 0), 500);
      expect(MinorUnits.parse('500.5', decimals: 0), isNull);
    });
  });

  group('MinorUnits.format', () {
    test('formats with grouping and fixed decimals', () {
      expect(MinorUnits.format(8825000), '88,250.00');
      expect(MinorUnits.format(50005), '500.05');
      expect(MinorUnits.format(5), '0.05');
      expect(MinorUnits.format(-125075), '-1,250.75');
      expect(MinorUnits.format(123456789, decimals: 0), '123,456,789');
    });

    test('round-trips with parse', () {
      for (final minor in [0, 1, 99, 100, 50050, 9442500]) {
        expect(MinorUnits.parse(MinorUnits.format(minor)), minor);
      }
    });
  });
}
