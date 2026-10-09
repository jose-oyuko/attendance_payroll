import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Today at a glance. Payroll cards are added with payroll (Phase 8).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(currentCompanyProvider).value;
    final today = ref.watch(todaysAttendanceProvider);
    final openExceptions = ref.watch(openExceptionCountProvider).value;
    final semantic = context.semanticColors;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  company == null
                      ? "Today's attendance"
                      : "Today's attendance · ${company.details.name}",
                  style: context.textStyles.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AdminDestination.attendance.path),
                child: const Text('Open attendance'),
              ),
            ],
          ),
          switch (today) {
            AsyncData(:final value) => AdaptiveGrid(
              children: [
                _StatusCard(
                  icon: Icons.how_to_reg_outlined,
                  title: 'Present',
                  value: '${value.present} of ${value.employees.length}',
                  accent: semantic.success,
                ),
                _StatusCard(
                  icon: Icons.work_history_outlined,
                  title: 'Working now',
                  value: '${value.working}',
                  accent: semantic.info,
                ),
                _StatusCard(
                  icon: Icons.report_outlined,
                  title: 'Open exceptions',
                  value: '${openExceptions ?? '…'}',
                  caption: openExceptions == 0
                      ? 'Everything looks good.'
                      : 'In the last $recentExceptionDays days.',
                  accent: semantic.warning,
                  onTap: () => context.go(AttendanceRoutes.exceptions),
                ),
                _StatusCard(
                  icon: Icons.schedule_outlined,
                  title: 'Late',
                  value: '${value.late}',
                  accent: semantic.warning,
                ),
                _StatusCard(
                  icon: Icons.person_off_outlined,
                  title: 'Absent',
                  value: '${value.absent}',
                  caption: value.expected > 0
                      ? '${value.expected} still expected today'
                      : null,
                  accent: semantic.neutral,
                ),
              ],
            ),
            AsyncError(:final error) => Text(
              AppFailure.from(error).userMessage,
            ),
            _ => const LinearProgressIndicator(),
          },
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.caption,
    this.onTap,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String title;
  final String value;
  final String? caption;
  final SemanticColorSet accent;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return MergeSemantics(
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.container,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(icon, color: accent.onContainer),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.textStyles.labelLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(value, style: context.textStyles.titleMedium),
                      if (caption != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          caption,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
