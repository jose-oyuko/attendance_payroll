import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/attendance_area_tabs.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/attendance_range_views.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Everyone's attendance over a chosen range of dates, one row per employee
/// per day: a table on wide screens, cards grouped by employee on phones.
class AttendanceRangeScreen extends ConsumerWidget {
  const AttendanceRangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(companyTimeZoneProvider)) {
      AsyncData(:final value) => _RangeView(zone: value),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(companyTimeZoneProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _RangeView extends ConsumerStatefulWidget {
  const _RangeView({required this.zone});

  final CompanyTimeZone zone;

  @override
  ConsumerState<_RangeView> createState() => _RangeViewState();
}

class _RangeViewState extends ConsumerState<_RangeView> {
  late final LocalDate _today = widget.zone.dateOf(DateTime.now());

  /// This month so far.
  late DateRange _range = (
    from: LocalDate(_today.year, _today.month, 1),
    to: _today,
  );

  /// `null` for everyone.
  String? _employeeId;
  bool _problemsOnly = false;

  static DateTime _asDateTime(LocalDate d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: _asDateTime(_today),
      initialDateRange: DateTimeRange(
        start: _asDateTime(_range.from),
        end: _asDateTime(_range.to),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    final range = (
      from: LocalDate.fromDateTime(picked.start),
      to: LocalDate.fromDateTime(picked.end),
    );
    if (!range.to.isBefore(
      range.from.addDays(AttendanceService.maxRangeDays),
    )) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Choose at most ${AttendanceService.maxRangeDays} days.',
            ),
          ),
        );
      return;
    }
    setState(() => _range = range);
  }

  /// The rows to show, grouped by employee, after the filters.
  List<List<EmployeeDay>> _groups(AttendanceRange range) {
    final groups = <List<EmployeeDay>>[];
    for (final MapEntry(:key, :value) in range.byEmployee.entries) {
      if (_employeeId != null && key != _employeeId) {
        continue;
      }
      final days = _problemsOnly
          ? value.where((d) => d.hasProblem).toList()
          : value;
      if (days.isNotEmpty) {
        groups.add(days);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(attendanceRangeProvider(_range));
    final range = data.value;
    final names = {
      for (final days in range?.byEmployee.values ?? <List<EmployeeDay>>[])
        days.first.employee.id: days.first.employee.details.shownName,
    };
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          const AttendanceAreaTabs(selected: AttendanceTab.range),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${formatLocalDate(context, _range.from)} – '
                  '${formatLocalDate(context, _range.to)}',
                ),
              ),
              // Wide enough for a name, but never wider than the screen.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: names.containsKey(_employeeId) ? _employeeId : null,
                  hint: const Text('All employees'),
                  items: [
                    const DropdownMenuItem(child: Text('All employees')),
                    for (final MapEntry(:key, :value) in names.entries)
                      DropdownMenuItem(
                        value: key,
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) => setState(() => _employeeId = id),
                ),
              ),
              FilterChip(
                label: const Text('Only days with problems'),
                selected: _problemsOnly,
                onSelected: (on) => setState(() => _problemsOnly = on),
              ),
              // One employee chosen: their timesheet; otherwise everyone.
              TextButton.icon(
                onPressed: () => context.push(
                  ReportRoutes.previewOf(
                    ReportRequest(
                      kind: _employeeId == null
                          ? ReportKind.attendance
                          : ReportKind.timesheet,
                      employeeId: _employeeId,
                      from: _range.from,
                      to: _range.to,
                    ),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_employeeId == null ? 'PDF report' : 'Timesheet'),
              ),
            ],
          ),
          switch (data) {
            AsyncData(:final value) => _Rows(
              groups: _groups(value),
              zone: widget.zone,
              problemsOnly: _problemsOnly,
            ),
            AsyncError(:final error) => ErrorState(
              failure: AppFailure.from(error),
              onRetry: () => ref.invalidate(attendanceRangeProvider(_range)),
            ),
            _ => const LinearProgressIndicator(),
          },
        ],
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.groups,
    required this.zone,
    required this.problemsOnly,
  });

  final List<List<EmployeeDay>> groups;
  final CompanyTimeZone zone;
  final bool problemsOnly;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Card.outlined(
        child: ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: Text(
            problemsOnly
                ? 'Everything looks good.'
                : 'No attendance in this range.',
          ),
          subtitle: Text(
            problemsOnly
                ? 'No lateness, absences or attendance to review.'
                : 'Choose other dates or another employee.',
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) =>
          WindowSize.fromWidth(
            constraints.maxWidth,
          ).isAtLeast(WindowSize.medium)
          ? AttendanceRangeTable(groups: groups, zone: zone)
          : AttendanceRangeList(groups: groups, zone: zone),
    );
  }
}
