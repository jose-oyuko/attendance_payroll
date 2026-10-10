import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';

/// Business rules for rate history, reported as `BusinessRuleFailure.rule`.
abstract final class EmployeeRateRules {
  /// A new rate may only cover days without a rate; rates already set are
  /// never rewritten (see `RatePlacement`).
  static const String overlapsExisting = 'rate_overlaps_existing';

  /// A rate must be in the company's currency.
  static const String currencyMismatch = 'rate_currency_mismatch';
}

abstract interface class EmployeeRateRepository {
  /// Adds [rate] to the employee's history, placed by `RatePlacement`:
  /// starting after the latest rate, it closes that rate the day before;
  /// starting earlier on a day without a rate, it fills that gap only.
  ///
  /// Fails with a `BusinessRuleFailure` (see [EmployeeRateRules]) when the new
  /// rate would cover a day that already has a rate or uses a currency other
  /// than the company's.
  Future<Result<EmployeeRate>> addRate(String employeeId, NewEmployeeRate rate);

  /// The employee's rates, oldest first.
  Future<Result<List<EmployeeRate>>> history(String employeeId);

  /// The rate that applies on [date], or `null` when none does.
  Future<Result<EmployeeRate?>> rateOn(String employeeId, LocalDate date);
}
