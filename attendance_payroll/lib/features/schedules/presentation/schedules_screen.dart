import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_formatting.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_routes.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_view_providers.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addButton = FilledButton.icon(
      onPressed: () => context.go(ScheduleRoutes.newSchedule),
      icon: const Icon(Icons.add),
      label: const Text('New schedule'),
    );
    return switch (ref.watch(schedulesProvider)) {
      AsyncData(:final value) when value.isEmpty => EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No schedules yet.',
        message:
            'Create a schedule, such as Mon–Fri 08:00–17:00, then assign it '
            'to employees to check lateness and absence.',
        action: addButton,
      ),
      AsyncData(:final value) => PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Align(alignment: AlignmentDirectional.centerEnd, child: addButton),
            Card.outlined(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, schedule) in value.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _ScheduleTile(schedule: schedule),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(schedulesProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule});

  final WorkSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final d = schedule.details;
    final automaticBreak = d.automaticBreak;
    return ListTile(
      onTap: () => context.go(ScheduleRoutes.edit(schedule.id)),
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(d.name, style: context.textStyles.titleMedium),
      subtitle: Text(
        '${summarizeDays(context, d.days)}\n'
        'Late after ${d.lateTolerance.inMinutes} min · '
        'early before ${d.earlyDepartureTolerance.inMinutes} min'
        '${automaticBreak == null ? '' : ' · ${automaticBreak.deduct.inMinutes} min break'}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
