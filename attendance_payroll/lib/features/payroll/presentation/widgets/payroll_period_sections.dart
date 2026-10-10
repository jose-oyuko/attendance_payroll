import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/payroll/data/payroll_providers.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_formatting.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_view_providers.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A titled, outlined card used for each section of a period.
class PayrollSection extends StatelessWidget {
  const PayrollSection({
    required this.title,
    required this.children,
    super.key,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: context.textStyles.titleMedium),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

/// Hours and money for the whole period, one group per currency.
class PayrollTotalsGrid extends StatelessWidget {
  const PayrollTotalsGrid({required this.result, super.key});

  final PayrollResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        for (final t in result.totals)
          AdaptiveGrid(
            children: [
              _Figure(label: 'Employees paid', value: '${t.lines.length}'),
              _Figure(
                label: 'Regular hours',
                value: formatHours(t.regularHours),
              ),
              _Figure(
                label: 'Overtime hours',
                value: formatHours(t.overtimeHours),
              ),
              _Figure(label: 'Gross pay', value: '${t.gross}'),
              _Figure(label: 'Deductions', value: '${t.deductions}'),
              _Figure(label: 'Net pay', value: '${t.net}', emphasis: true),
            ],
          ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(label, style: context.textStyles.labelLarge),
              Text(
                value,
                style: emphasis
                    ? context.textStyles.titleLarge
                    : context.textStyles.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Problems found by the calculation; blocking ones prevent approval.
class PayrollIssuesSection extends StatelessWidget {
  const PayrollIssuesSection({
    required this.issues,
    required this.names,
    super.key,
  });

  final List<PayrollIssue> issues;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final needsAttendanceReview = issues.any(
      (i) => i.code == PayrollIssueCode.attendanceAwaitingReview,
    );
    return PayrollSection(
      title: 'Problems to resolve',
      trailing: needsAttendanceReview
          ? TextButton(
              onPressed: () => context.go(AttendanceRoutes.exceptions),
              child: const Text('Review exceptions'),
            )
          : null,
      children: [
        for (final issue in issues)
          ListTile(
            leading: issue.severity == PayrollIssueSeverity.blocking
                ? Icon(Icons.block, color: context.colors.error)
                : Icon(Icons.warning_amber, color: semantic.warning.color),
            title: Text(
              names[issue.employeeId] ??
                  (issue.employeeId == null ? 'Payroll' : 'Unknown employee'),
            ),
            subtitle: Text(
              '${issue.severity == PayrollIssueSeverity.blocking ? 'Blocking' : 'Warning'}'
              ' · ${issue.message}',
            ),
          ),
      ],
    );
  }
}

/// One row per paid employee; tapping shows how their pay was worked out.
class PayrollLinesSection extends StatelessWidget {
  const PayrollLinesSection({
    required this.result,
    required this.names,
    super.key,
  });

  final PayrollResult result;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final lines = [...result.lines]
      ..sort(
        (a, b) => (names[a.employeeId] ?? '').toLowerCase().compareTo(
          (names[b.employeeId] ?? '').toLowerCase(),
        ),
      );
    return PayrollSection(
      title: 'Employees',
      children: [
        if (lines.isEmpty)
          const ListTile(title: Text('Nobody worked or was paid.')),
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) const Divider(height: 1),
          ListTile(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _LineBreakdown(
                line: line,
                name: names[line.employeeId] ?? 'Unknown employee',
              ),
            ),
            title: Text(names[line.employeeId] ?? 'Unknown employee'),
            subtitle: Text(
              line.overtimeHours == Duration.zero
                  ? formatHours(line.regularHours)
                  : '${formatHours(line.regularHours)} + '
                        '${formatHours(line.overtimeHours)} overtime',
            ),
            trailing: Text('${line.net}', style: context.textStyles.titleSmall),
          ),
        ],
      ],
    );
  }
}

class _LineBreakdown extends StatelessWidget {
  const _LineBreakdown({required this.line, required this.name});

  final PayrollLine line;
  final String name;

  @override
  Widget build(BuildContext context) {
    Widget row(
      String label,
      String value, {
      String? detail,
      bool bold = false,
    }) {
      final style = bold ? context.textStyles.titleSmall : null;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: style),
                  if (detail != null)
                    Text(
                      detail,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(value, style: style),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in line.items)
              row(
                item.kind.label,
                item.kind.isDeduction ? '${-item.amount}' : '${item.amount}',
                detail: explainItem(item),
              ),
            const Divider(),
            row('Gross pay', '${line.gross}', bold: true),
            row('Deductions', '${-line.deductions}'),
            row('Net pay', '${line.net}', bold: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Allowances, bonuses and deductions entered for the period.
class PayrollAdjustmentsSection extends ConsumerWidget {
  const PayrollAdjustmentsSection({
    required this.period,
    required this.adjustments,
    required this.names,
    super.key,
    this.onAdd,
  });

  final PayrollPeriod period;
  final List<PayrollAdjustment> adjustments;
  final Map<String, String> names;

  /// Absent when the period is locked.
  final VoidCallback? onAdd;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    PayrollAdjustment adjustment,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove adjustment?',
      message:
          'The ${adjustment.type.label.toLowerCase()} of ${adjustment.amount} '
          'for ${names[adjustment.employeeId] ?? 'this employee'} is removed. '
          'Recalculate the payroll afterwards.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    final session = ref.read(adminSessionProvider);
    if (!confirmed || session == null) {
      return;
    }
    final result = await ref
        .read(payrollServiceProvider)
        .removeAdjustment(session, adjustment.id);
    ref.read(payrollRevisionProvider.notifier).changed();
    if (result.failureOrNull case final failure? when context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onAdd = this.onAdd;
    return PayrollSection(
      title: 'Adjustments',
      trailing: onAdd == null
          ? null
          : TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
      children: [
        if (adjustments.isEmpty)
          const ListTile(title: Text('No allowances, bonuses or deductions.')),
        for (final a in adjustments)
          ListTile(
            title: Text(names[a.employeeId] ?? 'Unknown employee'),
            subtitle: Text('${a.type.label} · ${a.description}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.type == AdjustmentType.deduction
                      ? '${-a.amount}'
                      : '${a.amount}',
                ),
                if (onAdd != null)
                  IconButton(
                    tooltip: 'Remove adjustment',
                    onPressed: () => _remove(context, ref, a),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Everything that happened to the period, newest first.
class PayrollHistorySection extends ConsumerWidget {
  const PayrollHistorySection({
    required this.periodId,
    required this.zone,
    super.key,
  });

  final String periodId;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PayrollSection(
      title: 'History',
      children: switch (ref.watch(payrollHistoryProvider(periodId))) {
        AsyncData(:final value) => [
          for (final record in value)
            ListTile(
              dense: true,
              title: Text(describePayrollAction(record.action)),
              subtitle: Text(
                [
                  '${formatLocalDate(context, zone.dateOf(record.occurredAt))}'
                      ' ${formatCompanyTime(context, zone, record.occurredAt)}',
                  if (record.metadata['reason'] case final String reason)
                    reason,
                ].join(' · '),
              ),
            ),
        ],
        AsyncError(:final error) => [
          ListTile(title: Text(AppFailure.from(error).userMessage)),
        ],
        _ => const [LinearProgressIndicator()],
      },
    );
  }
}
