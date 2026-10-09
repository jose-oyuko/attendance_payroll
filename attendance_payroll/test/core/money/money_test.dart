import 'package:attendance_payroll/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kes = 'KES';
  Money ksh(int minor) => Money(minor, kes);

  test('adds, subtracts and negates exactly', () {
    expect(ksh(8825000) + ksh(600000), ksh(9425000));
    expect(ksh(100) - ksh(250), ksh(-150));
    expect(-ksh(5), ksh(-5));
    expect(Money.sum(kes, [ksh(1), ksh(2), ksh(3)]), ksh(6));
    expect(Money.sum(kes, []), const Money.zero(kes));
  });

  test('a tenth of a cent never accumulates: 0.1 + 0.2 is exact', () {
    // The classic floating-point trap, with integer cents instead.
    expect(ksh(10) + ksh(20), ksh(30));
  });

  test('refuses to mix currencies', () {
    expect(() => ksh(1) + const Money(1, 'USD'), throwsArgumentError);
    expect(() => ksh(1).compareTo(const Money(1, 'USD')), throwsArgumentError);
  });

  group('ofRatio rounds half away from zero', () {
    Money ratio(int n, int d) =>
        Money.ofRatio(kes, BigInt.from(n), BigInt.from(d));

    test('exact values stay exact', () {
      expect(ratio(10, 2), ksh(5));
    });

    test('halves round away from zero', () {
      expect(ratio(5, 2), ksh(3));
      expect(ratio(-5, 2), ksh(-3));
      expect(ratio(5, -2), ksh(-3));
    });

    test('below a half rounds down, above rounds up', () {
      expect(ratio(14, 10), ksh(1));
      expect(ratio(16, 10), ksh(2));
      expect(ratio(1, 3), ksh(0));
      expect(ratio(2, 3), ksh(1));
    });

    test('large intermediate products do not overflow', () {
      // KES 1,000,000.00/hour for 10,000 hours at 150%: the numerator
      // exceeds 64 bits.
      final pay = Money.ofRatio(
        kes,
        BigInt.from(100000000) *
            BigInt.from(36000000) *
            BigInt.from(150) *
            BigInt.from(1000000),
        BigInt.from(3600) * BigInt.from(100) * BigInt.from(1000000),
      );
      expect(pay, ksh(1500000000000));
    });

    test('a zero denominator is an error', () {
      expect(() => ratio(1, 0), throwsArgumentError);
    });
  });

  test('formats for display', () {
    expect(ksh(8825000).toString(), 'KES 88,250.00');
    expect(ksh(-150).toString(), 'KES -1.50');
  });
}
