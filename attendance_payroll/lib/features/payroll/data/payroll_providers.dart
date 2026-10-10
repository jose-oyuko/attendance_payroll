import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/core/locking/payroll_lock.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/company/data/company_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/payroll/data/drift_payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/data/drift_payroll_run_repository.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period_lock.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Approved and finalized payroll periods lock the data they were paid from.
final payrollLockProvider = Provider<PayrollLock>(
  (ref) => PayrollPeriodLock(
    periods: DriftPayrollPeriodRepository(ref.watch(appDatabaseProvider)),
    companies: ref.watch(companyRepositoryProvider),
  ),
);

final payrollServiceProvider = Provider<PayrollService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PayrollService(
    companies: ref.watch(companyRepositoryProvider),
    employees: ref.watch(employeeRepositoryProvider),
    rates: ref.watch(employeeRateRepositoryProvider),
    attendance: ref.watch(attendanceReaderProvider),
    settings: DriftPayrollSettingsRepository(db),
    periods: DriftPayrollPeriodRepository(db),
    adjustments: DriftPayrollAdjustmentRepository(db),
    runs: DriftPayrollRunRepository(db),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  );
});
