import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Locations inside the Attendance area.
abstract final class AttendanceRoutes {
  static const String day = '/attendance';
  static const String employeeSegment = 'employees/:employeeId';
  static const String idParameter = 'employeeId';

  static String employee(String id) => '$day/employees/$id';
}

/// Everyone's attendance on one day, and the way into kiosk mode.
class AttendanceDayScreen extends ConsumerWidget {
  const AttendanceDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(companyTimeZoneProvider)) {
      AsyncData(:final value) => _DayView(zone: value),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(companyTimeZoneProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _DayView extends ConsumerStatefulWidget {
  const _DayView({required this.zone});

  final CompanyTimeZone zone;

  @override
  ConsumerState<_DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<_DayView> {
  late LocalDate _date;
  late final LocalDate _today;

  @override
  void initState() {
    super.initState();
    _today = widget.zone.dateOf(DateTime.now());
    _date = _today;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(_today.year, _today.month, _today.day),
      initialDate: DateTime(_date.year, _date.month, _date.day),
    );
    if (picked != null) {
      setState(() => _date = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _startKiosk() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Start kiosk mode?',
      message:
          'You will be signed out and this device will show only the '
          'attendance kiosk, where employees tap their name, enter their PIN '
          'and clock in or out. It stays a kiosk after restarting. To leave '
          'kiosk mode, an administrator must sign in.',
      confirmLabel: 'Start kiosk',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final failure = await ref
        .read(authControllerProvider.notifier)
        .startKiosk();
    if (failure != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(dailyAttendanceProvider(_date));
    final canStartKiosk =
        ref.watch(adminSessionProvider)?.can(Permission.manageKiosk) ?? false;
    final isToday = _date == _today;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: () => setState(() => _date = _date.addDays(-1)),
                icon: const Icon(Icons.chevron_left),
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  isToday ? 'Today' : formatLocalDate(context, _date),
                ),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: isToday
                    ? null
                    : () => setState(() => _date = _date.addDays(1)),
                icon: const Icon(Icons.chevron_right),
              ),
              if (canStartKiosk)
                FilledButton.icon(
                  onPressed: _startKiosk,
                  icon: const Icon(Icons.tablet_outlined),
                  label: const Text('Start kiosk'),
                ),
            ],
          ),
          switch (day) {
            AsyncData(:final value) when value.employees.isEmpty =>
              const EmptyState(
                icon: Icons.people_outline,
                title: 'No employees yet.',
                message: 'Add employees to see their attendance here.',
              ),
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                DaySummary(day: value, showWorking: isToday),
                _DayList(day: value, zone: widget.zone),
              ],
            ),
            AsyncError(:final error) => ErrorState(
              failure: AppFailure.from(error),
              onRetry: () => ref.invalidate(dailyAttendanceProvider(_date)),
            ),
            _ => const LoadingState(),
          },
        ],
      ),
    );
  }
}

/// Counts for a day, as compact cards.
class DaySummary extends StatelessWidget {
  const DaySummary({required this.day, required this.showWorking, super.key});

  final DailyAttendance day;

  /// "Working now" only makes sense for today.
  final bool showWorking;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return AdaptiveGrid(
      children: [
        _Count(label: 'Present', value: day.present, colors: semantic.success),
        if (showWorking)
          _Count(
            label: 'Working now',
            value: day.working,
            colors: semantic.info,
          ),
        _Count(
          label: 'Needs review',
          value: day.needsReview,
          colors: semantic.warning,
        ),
        _Count(
          label: 'Not clocked in',
          value: day.notClockedIn,
          colors: semantic.neutral,
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final int value;
  final SemanticColorSet colors;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.container,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    '$value',
                    style: context.textStyles.titleLarge?.copyWith(
                      color: colors.onContainer,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(label, style: context.textStyles.titleSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.day, required this.zone});

  final DailyAttendance day;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, row) in day.employees.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _EmployeeRow(row: row, zone: zone),
          ],
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.row, required this.zone});

  final EmployeeDay row;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (label, colors) = switch (row.status) {
      DayStatus.needsReview => ('Needs review', semantic.warning),
      DayStatus.working => ('Working', semantic.info),
      DayStatus.present => (formatWorkDuration(row.payable), semantic.success),
      DayStatus.notClockedIn => ('Not clocked in', semantic.neutral),
    };
    final times = [
      for (final session in row.sessions)
        '${formatCompanyTime(context, zone, session.start)} – '
            '${session.end == null ? '…' : formatCompanyTime(context, zone, session.end!)}',
    ].join(', ');
    final details = row.employee.details;
    return ListTile(
      onTap: () => context.go(AttendanceRoutes.employee(row.employee.id)),
      title: Text(details.shownName),
      subtitle: Text(
        times.isEmpty
            ? details.employeeNumber
            : '${details.employeeNumber} · $times',
      ),
      trailing: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs / 2,
          ),
          child: Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              color: colors.onContainer,
            ),
          ),
        ),
      ),
    );
  }
}
