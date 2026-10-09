import 'package:attendance_payroll/core/utils/minor_units.dart';

/// An amount of money: an integer number of minor units (for example cents)
/// in one currency. Never a floating-point value, so sums are exact.
final class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  const Money.zero(this.currency) : minorUnits = 0;

  final int minorUnits;

  /// ISO 4217 code, for example `KES`.
  final String currency;

  bool get isNegative => minorUnits < 0;

  bool get isZero => minorUnits == 0;

  Money operator +(Money other) =>
      Money(minorUnits + _same(other).minorUnits, currency);

  Money operator -(Money other) =>
      Money(minorUnits - _same(other).minorUnits, currency);

  Money operator -() => Money(-minorUnits, currency);

  /// The sum of [amounts], all in [currency].
  static Money sum(String currency, Iterable<Money> amounts) =>
      amounts.fold(Money.zero(currency), (total, m) => total + m);

  /// `numerator / denominator` minor units of [currency], rounded half away
  /// from zero: the single rounding step of every calculated amount. Exact
  /// big-integer arithmetic, so no intermediate value can overflow or drift.
  static Money ofRatio(String currency, BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError.value(denominator, 'denominator', 'Must not be 0');
    }
    var n = numerator;
    var d = denominator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final quotient = n.abs() ~/ d;
    final remainder = n.abs().remainder(d);
    final rounded = remainder * BigInt.two >= d
        ? quotient + BigInt.one
        : quotient;
    return Money((n.isNegative ? -rounded : rounded).toInt(), currency);
  }

  Money _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Cannot combine $currency with ${other.currency}.');
    }
    return other;
  }

  @override
  int compareTo(Money other) => minorUnits.compareTo(_same(other).minorUnits);

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  /// "KES 88,250.00".
  @override
  String toString() => '$currency ${MinorUnits.format(minorUnits)}';
}
