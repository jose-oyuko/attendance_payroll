import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/validators.dart';

/// Lifecycle of a payroll period. Phase 7 creates and calculates periods
/// (`draft`); review, approval, finalization and reopening are Phase 8.
enum PayrollPeriodStatus {
  draft,
  open,
  processing,
  review,
  approved,
  finalized,
  reopened,
}

/// A span of company dates paid together, e.g. 1–31 October 2026.
final class PayrollPeriod {
  const PayrollPeriod({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.version,
  });

  final String id;
  final String companyId;
  final String name;

  /// Inclusive.
  final LocalDate startDate;
  final LocalDate endDate;
  final PayrollPeriodStatus status;
  final int version;

  bool contains(LocalDate date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);
}

/// A period to create.
final class NewPayrollPeriod {
  const NewPayrollPeriod({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  /// Longer periods are almost certainly a mistake (a typo in the year).
  static const int maxDays = 62;

  final String name;
  final LocalDate startDate;
  final LocalDate endDate;

  ValidationFailure? validate() {
    if (Validators.isBlank(name)) {
      return const ValidationFailure(
        field: 'name',
        userMessage: 'Give the period a name, for example October 2026.',
      );
    }
    if (endDate.isBefore(startDate)) {
      return const ValidationFailure(
        field: 'endDate',
        userMessage: 'The period cannot end before it starts.',
      );
    }
    final days =
        DateTime.utc(endDate.year, endDate.month, endDate.day)
            .difference(
              DateTime.utc(startDate.year, startDate.month, startDate.day),
            )
            .inDays +
        1;
    if (days > maxDays) {
      return const ValidationFailure(
        field: 'endDate',
        userMessage: 'A payroll period can be at most $maxDays days.',
      );
    }
    return null;
  }
}

/// Money added to or taken from one employee's pay for a period.
enum AdjustmentType { allowance, bonus, deduction }

/// A manual adjustment, kept with the period so recalculation includes it.
final class PayrollAdjustment {
  const PayrollAdjustment({
    required this.id,
    required this.periodId,
    required this.employeeId,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String periodId;
  final String employeeId;
  final AdjustmentType type;

  /// Always positive; [type] decides whether it adds or subtracts.
  final Money amount;
  final String description;
  final String createdBy;
  final DateTime createdAt;
}

/// An adjustment to add.
final class NewPayrollAdjustment {
  const NewPayrollAdjustment({
    required this.employeeId,
    required this.type,
    required this.amount,
    required this.description,
  });

  final String employeeId;
  final AdjustmentType type;
  final Money amount;
  final String description;

  ValidationFailure? validate() {
    if (amount.minorUnits <= 0) {
      return const ValidationFailure(
        field: 'amount',
        userMessage: 'The amount must be greater than zero.',
      );
    }
    if (Validators.isBlank(description)) {
      return const ValidationFailure(
        field: 'description',
        userMessage: 'Describe the adjustment, for example "Transport".',
      );
    }
    return null;
  }
}
