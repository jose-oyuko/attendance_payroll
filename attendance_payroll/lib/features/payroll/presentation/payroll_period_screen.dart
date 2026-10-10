import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/payroll/data/payroll_providers.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_formatting.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_routes.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_view_providers.dart';
import 'package:attendance_payroll/features/payroll/presentation/widgets/payroll_dialogs.dart';
import 'package:attendance_payroll/features/payroll/presentation/widgets/payroll_period_sections.dart';
import 'package:attendance_payroll/features/payroll/presentation/widgets/payroll_status_chip.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:attendance_payroll/shared/widgets/subpage_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One payroll period: its calculation, adjustments, the lifecycle actions
/// allowed in its status, and its history.
class PayrollPeriodScreen extends ConsumerWidget {
  const PayrollPeriodScreen({required this.periodId, super.key});

  final String periodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(payrollPeriodProvider(periodId));
    final run = ref.watch(currentRunProvider(periodId));
    final adjustments = ref.watch(payrollAdjustmentsProvider(periodId));
    final names = ref.watch(payrollEmployeeNamesProvider);
    final company = ref.watch(currentCompanyProvider);
    final zone = ref.watch(companyTimeZoneProvider);
    return switch ((period, run, adjustments, names, company, zone)) {
      (
        AsyncData(value: final p),
        AsyncData(value: final r),
        AsyncData(value: final a),
        AsyncData(value: final n),
        AsyncData(value: final c),
        AsyncData(value: final z),
      ) =>
        _PeriodView(
          period: p,
          run: r,
          adjustments: a,
          names: n,
          currency: c.details.currencyCode,
          zone: z,
        ),
      (AsyncError(:final error), _, _, _, _, _) ||
      (_, AsyncError(:final error), _, _, _, _) ||
      (_, _, AsyncError(:final error), _, _, _) ||
      (_, _, _, AsyncError(:final error), _, _) ||
      (_, _, _, _, AsyncError(:final error), _) ||
      (_, _, _, _, _, AsyncError(:final error)) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.read(payrollRevisionProvider.notifier).changed(),
      ),
      _ => const LoadingState(),
    };
  }
}

class _PeriodView extends StatelessWidget {
  const _PeriodView({
    required this.period,
    required this.run,
    required this.adjustments,
    required this.names,
    required this.currency,
    required this.zone,
  });

  final PayrollPeriod period;
  final PayrollRun? run;
  final List<PayrollAdjustment> adjustments;
  final Map<String, String> names;
  final String currency;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context) {
    final run = this.run;
    final summary = <Widget>[
      _PeriodActions(
        period: period,
        run: run,
        names: names,
        currency: currency,
      ),
      if (run == null)
        const PayrollSection(
          title: 'Calculation',
          children: [
            ListTile(
              title: Text('Not calculated yet.'),
              subtitle: Text(
                'Calculate to pay the reviewed attendance in this period.',
              ),
            ),
          ],
        )
      else ...[
        PayrollTotalsGrid(result: run.result),
        if (run.result.issues.isNotEmpty)
          PayrollIssuesSection(issues: run.result.issues, names: names),
        PayrollLinesSection(result: run.result, names: names),
      ],
    ];
    final details = <Widget>[
      Consumer(
        builder: (context, ref, _) => PayrollAdjustmentsSection(
          period: period,
          adjustments: adjustments,
          names: names,
          onAdd: period.status.isEditable
              ? () => showAdjustmentDialog(
                  context,
                  ref,
                  period: period,
                  employees: names,
                  currency: currency,
                )
              : null,
        ),
      ),
      PayrollHistorySection(periodId: period.id, zone: zone),
    ];

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          SubpageHeader(
            title: period.name,
            backLocation: PayrollRoutes.list,
            actions: [PayrollStatusChip(status: period.status)],
          ),
          Text(
            '${formatLocalDate(context, period.startDate)} – '
            '${formatLocalDate(context, period.endDate)}',
            style: context.textStyles.bodyLarge,
          ),
          if (!period.status.isEditable) _LockBanner(period: period),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = WindowSize.fromWidth(
                constraints.maxWidth,
              ).isAtLeast(WindowSize.expanded);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.md,
                  children: [...summary, ...details],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.md,
                      children: summary,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.md,
                      children: details,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LockBanner extends StatelessWidget {
  const _LockBanner({required this.period});

  final PayrollPeriod period;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colors = period.status == PayrollPeriodStatus.finalized
        ? semantic.success
        : semantic.info;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Icon(Icons.lock_outline, color: colors.onContainer),
            Expanded(
              child: Text(
                'This payroll is ${period.status.label.toLowerCase()}. '
                'Attendance, rates and adjustments in this period are locked '
                'until it is reopened.',
                style: TextStyle(color: colors.onContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The lifecycle actions the period's status allows.
class _PeriodActions extends ConsumerStatefulWidget {
  const _PeriodActions({
    required this.period,
    required this.run,
    required this.names,
    required this.currency,
  });

  final PayrollPeriod period;
  final PayrollRun? run;
  final Map<String, String> names;
  final String currency;

  @override
  ConsumerState<_PeriodActions> createState() => _PeriodActionsState();
}

class _PeriodActionsState extends ConsumerState<_PeriodActions> {
  bool _busy = false;

  Future<void> _perform(
    Future<Result<Object?>> Function(AdminSession session) action, {
    required String done,
  }) async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null) {
      return;
    }
    setState(() => _busy = true);
    final result = await action(session);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ref.read(payrollRevisionProvider.notifier).changed();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(result.failureOrNull?.userMessage ?? done)),
      );
  }

  Future<void> _finalize() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Finalize ${widget.period.name}?',
      message:
          'Finalized payroll is the record of what was paid. Attendance, '
          'rates and adjustments in this period are locked, and changing '
          'them requires reopening the payroll with a reason.',
      confirmLabel: 'Finalize',
    );
    if (confirmed) {
      await _perform(
        (s) => ref.read(payrollServiceProvider).finalize(s, widget.period.id),
        done: 'Payroll finalized.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    final run = widget.run;
    final service = ref.read(payrollServiceProvider);
    final status = period.status;
    final buttons = <Widget>[
      if (status.isEditable)
        (run == null ? FilledButton.icon : OutlinedButton.icon)(
          onPressed: _busy
              ? null
              : () => _perform(
                  (s) => service.calculate(s, period.id),
                  done: 'Payroll calculated.',
                ),
          icon: const Icon(Icons.calculate_outlined),
          label: Text(run == null ? 'Calculate' : 'Recalculate'),
        ),
      if (status == PayrollPeriodStatus.review && run != null)
        FilledButton.icon(
          onPressed: _busy || run.result.hasBlockingIssues
              ? null
              : () => _perform(
                  (s) => service.approve(s, period.id),
                  done: 'Payroll approved.',
                ),
          icon: const Icon(Icons.task_alt),
          label: const Text('Approve'),
        ),
      if (status == PayrollPeriodStatus.approved)
        FilledButton.icon(
          onPressed: _busy ? null : _finalize,
          icon: const Icon(Icons.lock_outline),
          label: const Text('Finalize'),
        ),
      if (!status.isEditable)
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => showReopenDialog(context, ref, period: period),
          icon: const Icon(Icons.lock_open),
          label: const Text('Reopen'),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: buttons,
        ),
        if (status == PayrollPeriodStatus.review &&
            (run?.result.hasBlockingIssues ?? false))
          Text(
            'Resolve the blocking problems below, then recalculate before '
            'approving.',
            style: context.textStyles.bodySmall,
          ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}
