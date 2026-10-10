import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';

/// Tells other features whether a change would affect approved or finalized
/// payroll, which must never change silently. Implemented by the payroll
/// feature; attendance and employees depend only on this interface.
abstract interface class PayrollLock {
  /// The name of an approved or finalized payroll period of [companyId]
  /// containing [date] or, with [orLater], ending on or after it; `null`
  /// when nothing locked is affected.
  Future<Result<String?>> lockedPeriodOn(
    String companyId,
    LocalDate date, {
    bool orLater = false,
  });

  /// Like [lockedPeriodOn] for the company date of [instant]. A clock-out
  /// may close a session that started the day before, so with
  /// [includePreviousDay] that day is checked too.
  Future<Result<String?>> lockedPeriodAt(
    String companyId,
    DateTime instant, {
    bool includePreviousDay = false,
  });
}

/// The message for a refused change, as the specification words it.
String payrollLockedMessage(String periodName) =>
    'Payroll for $periodName has already been approved or finalized. This '
    'change may affect a finalized payroll. Reopen the payroll first.';

/// The rule reported with [payrollLockedMessage].
const String payrollLockedRule = 'payroll_locked';
