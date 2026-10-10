import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';

/// A company's payroll settings and the version to pass back when saving.
final class StoredPayrollSettings {
  const StoredPayrollSettings({required this.settings, required this.version});

  final PayrollSettings settings;

  /// 0 while the company uses the defaults.
  final int version;
}

abstract interface class PayrollSettingsRepository {
  Future<Result<StoredPayrollSettings>> forCompany(String companyId);

  /// Fails with a `ConflictFailure` when [expectedVersion] is stale (pass 0
  /// when replacing the defaults).
  Future<Result<StoredPayrollSettings>> save(
    String companyId,
    PayrollSettings settings, {
    required int expectedVersion,
  });
}

/// Business rules for periods, reported as `BusinessRuleFailure.rule`.
abstract final class PayrollPeriodRules {
  /// Periods of a company may not share any date.
  static const String overlap = 'payroll_period_overlap';
}

abstract interface class PayrollPeriodRepository {
  /// Fails with a `BusinessRuleFailure` ([PayrollPeriodRules.overlap]) when
  /// the dates overlap another period of the company.
  Future<Result<PayrollPeriod>> create(
    String companyId,
    NewPayrollPeriod period,
  );

  Future<Result<PayrollPeriod>> getById(String id);

  /// The company's periods, latest first.
  Future<Result<List<PayrollPeriod>>> listByCompany(String companyId);

  /// Moves the period to [status]. Fails with a `ConflictFailure` when
  /// [expectedVersion] is stale.
  Future<Result<PayrollPeriod>> setStatus(
    String id,
    PayrollPeriodStatus status, {
    required int expectedVersion,
  });
}

abstract interface class PayrollAdjustmentRepository {
  Future<Result<PayrollAdjustment>> add(
    String periodId,
    NewPayrollAdjustment adjustment, {
    required String createdBy,
  });

  Future<Result<PayrollAdjustment>> getById(String id);

  /// Removes it from the period (kept as deleted for the record).
  Future<Result<void>> remove(String id);

  /// The period's adjustments, oldest first.
  Future<Result<List<PayrollAdjustment>>> forPeriod(String periodId);
}

/// Lifecycle of one calculation.
enum PayrollRunStatus {
  /// The current calculation of its period.
  calculated,

  /// Replaced by a later calculation; kept as history.
  superseded,

  /// Accepted for payment.
  approved,

  /// Locked: the record of what was paid.
  finalized,
}

/// A stored calculation: who ran it and when, and its frozen results.
final class PayrollRun {
  const PayrollRun({
    required this.id,
    required this.periodId,
    required this.status,
    required this.calculatedAt,
    required this.calculatedBy,
    required this.result,
    this.approvedAt,
    this.approvedBy,
    this.finalizedAt,
    this.finalizedBy,
  });

  final String id;
  final String periodId;
  final PayrollRunStatus status;
  final DateTime calculatedAt;
  final String calculatedBy;

  /// The lines, items and issues exactly as calculated.
  final PayrollResult result;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? finalizedAt;
  final String? finalizedBy;
}

abstract interface class PayrollRunRepository {
  /// Stores [result] as the period's current run; any earlier current run
  /// becomes superseded in the same transaction.
  Future<Result<PayrollRun>> saveCalculated(
    String periodId,
    PayrollResult result, {
    required String calculatedBy,
    required DateTime calculatedAt,
  });

  /// The period's current run, or `null` when it was never calculated.
  Future<Result<PayrollRun?>> currentForPeriod(String periodId);

  /// How many times the period was calculated.
  Future<Result<int>> countForPeriod(String periodId);

  /// Records an approval or finalization, or undoes an approval by
  /// returning the run to [PayrollRunStatus.calculated].
  Future<Result<PayrollRun>> setStatus(
    String runId,
    PayrollRunStatus status, {
    required String by,
    required DateTime at,
  });
}
