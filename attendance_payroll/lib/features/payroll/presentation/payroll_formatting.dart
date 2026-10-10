import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';

extension PayrollPeriodStatusLabel on PayrollPeriodStatus {
  String get label => switch (this) {
    PayrollPeriodStatus.draft => 'Draft',
    PayrollPeriodStatus.open => 'Open',
    PayrollPeriodStatus.processing => 'Processing',
    PayrollPeriodStatus.review => 'In review',
    PayrollPeriodStatus.approved => 'Approved',
    PayrollPeriodStatus.finalized => 'Finalized',
    PayrollPeriodStatus.reopened => 'Reopened',
  };

  /// Calculations and adjustments are allowed.
  bool get isEditable =>
      this != PayrollPeriodStatus.approved &&
      this != PayrollPeriodStatus.finalized;
}

extension AdjustmentTypeLabel on AdjustmentType {
  String get label => switch (this) {
    AdjustmentType.allowance => 'Allowance',
    AdjustmentType.bonus => 'Bonus',
    AdjustmentType.deduction => 'Deduction',
  };
}

extension PayrollItemKindLabel on PayrollItemKind {
  String get label => switch (this) {
    PayrollItemKind.regularPay => 'Regular pay',
    PayrollItemKind.overtimePay => 'Overtime pay',
    PayrollItemKind.allowance => 'Allowance',
    PayrollItemKind.bonus => 'Bonus',
    PayrollItemKind.deduction => 'Deduction',
  };
}

/// How an item was worked out, e.g. "16.00 h × KES 500.00".
String explainItem(PayrollItem item) {
  final rate = item.rate;
  final hours = item.hours;
  final days = item.days;
  final percent = item.percent;
  if (rate == null) {
    return item.description;
  }
  if (item.kind == PayrollItemKind.overtimePay && hours != null) {
    final basis = switch (item.rateType) {
      RateType.daily => '$rate a day',
      RateType.monthly => '$rate a month',
      _ => '$rate',
    };
    return '${formatHours(hours)} × $basis × $percent%';
  }
  return switch (item.rateType) {
    RateType.hourly when hours != null => '${formatHours(hours)} × $rate',
    RateType.daily when days != null => '$days days × $rate',
    RateType.monthly => '${item.description} of $rate',
    _ => item.description,
  };
}

/// What happened, for the history list.
String describePayrollAction(String code) => switch (code) {
  'payroll.period_created' => 'Period created',
  'payroll.calculated' => 'Calculated',
  'payroll.recalculated' => 'Recalculated',
  'payroll.adjustment_added' => 'Adjustment added',
  'payroll.adjustment_removed' => 'Adjustment removed',
  'payroll.approved' => 'Approved',
  'payroll.finalized' => 'Finalized',
  'payroll.reopened' => 'Reopened',
  _ => code,
};
