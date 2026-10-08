import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';

/// Business rules for rate history, reported as `BusinessRuleFailure.rule`.
abstract final class EmployeeRateRules {
  /// A new rate must start after the latest existing rate starts; history is
  /// never rewritten.
  static const String mustStartAfterLatest = 'rate_must_start_after_latest';

  /// A rate must be in the company's currency.
  static const String currencyMismatch = 'rate_currency_mismatch';
}

abstract interface class EmployeeRateRepository {
  /// Adds [rate] to the employee's history. The current rate, if any, is
  /// closed on the day before [NewEmployeeRate.effectiveFrom].
  ///
  /// Fails with a `BusinessRuleFailure` (see [EmployeeRateRules]) when the new
  /// rate does not start after the latest rate or uses a currency other than
  /// the company's.
  Future<Result<EmployeeRate>> addRate(String employeeId, NewEmployeeRate rate);

  /// The employee's rates, oldest first.
  Future<Result<List<EmployeeRate>>> history(String employeeId);

  /// The rate that applies on [date], or `null` when none does.
  Future<Result<EmployeeRate?>> rateOn(String employeeId, LocalDate date);
}
