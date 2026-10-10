import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_routes.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_view_providers.dart';
import 'package:attendance_payroll/features/payroll/presentation/widgets/payroll_dialogs.dart';
import 'package:attendance_payroll/features/payroll/presentation/widgets/payroll_status_chip.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Payroll periods, newest first, with the rules that apply to all of them.
class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  Future<void> _newPeriod(BuildContext context, WidgetRef ref) async {
    final zone = await ref.read(companyTimeZoneProvider.future);
    if (!context.mounted) {
      return;
    }
    final created = await showNewPeriodDialog(
      context,
      ref,
      today: zone.dateOf(DateTime.now()),
    );
    if (created != null && context.mounted) {
      context.go(PayrollRoutes.period(created.id));
    }
  }

  Future<void> _settings(BuildContext context, WidgetRef ref) async {
    final stored = await ref.read(payrollSettingsProvider.future);
    if (context.mounted) {
      await showPayrollSettingsDialog(context, ref, stored: stored);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newButton = FilledButton.icon(
      onPressed: () => _newPeriod(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('New period'),
    );
    final settingsButton = OutlinedButton.icon(
      onPressed: () => _settings(context, ref),
      icon: const Icon(Icons.tune),
      label: const Text('Overtime rules'),
    );
    return switch (ref.watch(payrollPeriodsProvider)) {
      AsyncData(:final value) when value.isEmpty => EmptyState(
        icon: Icons.payments_outlined,
        title: 'No payroll periods have been created.',
        message:
            'Create a period, such as this month, then calculate it from '
            'reviewed attendance.',
        action: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [newButton, settingsButton],
        ),
      ),
      AsyncData(:final value) => PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [settingsButton, newButton],
            ),
            Card.outlined(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, period) in value.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _PeriodTile(period: period),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(payrollPeriodsProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _PeriodTile extends ConsumerWidget {
  const _PeriodTile({required this.period});

  final PayrollPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(currentRunProvider(period.id)).value;
    final dates =
        '${formatLocalDate(context, period.startDate)} – '
        '${formatLocalDate(context, period.endDate)}';
    final totals = run?.result.totals;
    final net = totals == null
        ? 'Not calculated'
        : totals.isEmpty
        ? 'Nobody to pay'
        : 'Net pay ${totals.map((t) => t.net).join(' + ')}';
    return ListTile(
      onTap: () => context.go(PayrollRoutes.period(period.id)),
      leading: const Icon(Icons.payments_outlined),
      title: Text(period.name, style: context.textStyles.titleMedium),
      subtitle: Text('$dates\n$net'),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          PayrollStatusChip(status: period.status),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
