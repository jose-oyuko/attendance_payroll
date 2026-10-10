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

/// Where a new rate starting on a given day fits in an employee's history.
///
/// Rates already set are never rewritten, so a new rate may only cover days
/// that have no rate:
/// - starting after the latest rate starts, it applies from then on and the
///   latest rate ends the day before (a change of rate);
/// - starting earlier, on a day without a rate, it fills that gap and ends
///   the day before the next rate starts.
final class RatePlacement {
  const RatePlacement._(this.from, this.until);

  /// The new rate's place in [history] (any order), or `null` when [from]
  /// already has a rate that the new one would overwrite.
  static RatePlacement? of(List<EmployeeRate> history, LocalDate from) {
    final latest = history.fold<EmployeeRate?>(
      null,
      (l, r) => l == null || r.effectiveFrom.isAfter(l.effectiveFrom) ? r : l,
    );
    if (latest == null || from.isAfter(latest.effectiveFrom)) {
      return RatePlacement._(from, null);
    }
    if (history.any((r) => r.appliesOn(from))) {
      return null;
    }
    final next = history
        .map((r) => r.effectiveFrom)
        .where((start) => start.isAfter(from))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return RatePlacement._(from, next.addDays(-1));
  }

  final LocalDate from;

  /// The new rate's last day when it fills a gap; `null` when it is the new
  /// current rate.
  final LocalDate? until;

  bool get fillsGap => until != null;
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
