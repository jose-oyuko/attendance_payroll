import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/payroll/data/payroll_providers.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increases after every payroll action, so every payroll view (including
/// the dashboard, kept alive in another tab) shows the current state.
class PayrollRevision extends Notifier<int> {
  @override
  int build() => 0;

  void changed() => state++;
}

final payrollRevisionProvider = NotifierProvider<PayrollRevision, int>(
  PayrollRevision.new,
);

final payrollPeriodsProvider = FutureProvider.autoDispose<List<PayrollPeriod>>((
  ref,
) async {
  ref.watch(payrollRevisionProvider);
  final session = requireSession(ref);
  return (await ref.watch(payrollServiceProvider).periods(session)).unwrap();
});

final payrollPeriodProvider = FutureProvider.autoDispose
    .family<PayrollPeriod, String>((ref, id) async {
      ref.watch(payrollRevisionProvider);
      final session = requireSession(ref);
      return (await ref.watch(payrollServiceProvider).period(session, id))
          .unwrap();
    });

final currentRunProvider = FutureProvider.autoDispose
    .family<PayrollRun?, String>((ref, periodId) async {
      ref.watch(payrollRevisionProvider);
      final session = requireSession(ref);
      return (await ref
              .watch(payrollServiceProvider)
              .currentRun(session, periodId))
          .unwrap();
    });

final payrollAdjustmentsProvider = FutureProvider.autoDispose
    .family<List<PayrollAdjustment>, String>((ref, periodId) async {
      ref.watch(payrollRevisionProvider);
      final session = requireSession(ref);
      return (await ref
              .watch(payrollServiceProvider)
              .adjustments(session, periodId))
          .unwrap();
    });

final payrollHistoryProvider = FutureProvider.autoDispose
    .family<List<AuditRecord>, String>((ref, periodId) async {
      ref.watch(payrollRevisionProvider);
      final session = requireSession(ref);
      return (await ref
              .watch(payrollServiceProvider)
              .history(session, periodId))
          .unwrap();
    });

final payrollSettingsProvider =
    FutureProvider.autoDispose<StoredPayrollSettings>((ref) async {
      ref.watch(payrollRevisionProvider);
      final session = requireSession(ref);
      return (await ref.watch(payrollServiceProvider).settings(session))
          .unwrap();
    });

/// Every employee's display name by id, including archived ones (payroll
/// may pay them for the period).
final payrollEmployeeNamesProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final session = requireSession(ref);
      final employees =
          (await ref
                  .watch(employeeManagementServiceProvider)
                  .list(session, includeArchived: true))
              .unwrap();
      return {for (final e in employees) e.id: e.details.shownName};
    });
