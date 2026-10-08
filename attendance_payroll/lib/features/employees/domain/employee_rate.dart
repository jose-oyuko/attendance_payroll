import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/validators.dart';

/// The unit a pay rate is expressed in. An employee has one rate timeline;
/// each entry states its own unit.
enum RateType { hourly, daily, monthly }

/// One entry in an employee's pay rate history.
///
/// Money is an integer amount in the currency's minor unit (for example
/// KSh 500.00 is `50000`), so calculations never suffer floating-point error.
final class EmployeeRate {
  const EmployeeRate({
    required this.id,
    required this.employeeId,
    required this.rateType,
    required this.amountMinor,
    required this.currencyCode,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String employeeId;
  final RateType rateType;
  final int amountMinor;
  final String currencyCode;
  final LocalDate effectiveFrom;

  /// Inclusive last day, or `null` while this is the current rate.
  final LocalDate? effectiveTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isCurrent => effectiveTo == null;

  /// Whether this rate applies on [date].
  bool appliesOn(LocalDate date) {
    if (date.isBefore(effectiveFrom)) {
      return false;
    }
    final end = effectiveTo;
    return end == null || !date.isAfter(end);
  }
}

/// A rate to add to an employee's history.
final class NewEmployeeRate {
  const NewEmployeeRate({
    required this.rateType,
    required this.amountMinor,
    required this.currencyCode,
    required this.effectiveFrom,
  });

  final RateType rateType;
  final int amountMinor;
  final String currencyCode;
  final LocalDate effectiveFrom;

  NewEmployeeRate normalized() {
    return NewEmployeeRate(
      rateType: rateType,
      amountMinor: amountMinor,
      currencyCode: currencyCode.trim().toUpperCase(),
      effectiveFrom: effectiveFrom,
    );
  }

  /// The first rule this rate breaks, or `null` when it is valid.
  ValidationFailure? validate() {
    if (amountMinor <= 0) {
      return const ValidationFailure(
        field: 'amount',
        userMessage: 'The rate must be greater than zero.',
      );
    }
    if (!Validators.isCurrencyCode(currencyCode)) {
      return const ValidationFailure(
        field: 'currencyCode',
        userMessage: 'Enter a three-letter currency code, for example KES.',
      );
    }
    return null;
  }
}
