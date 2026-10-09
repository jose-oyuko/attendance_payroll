import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_formatting.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/attendance_area_tabs.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/exception_detail.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Filter {
  needsAction('Needs action'),
  settled('Settled'),
  all('All');

  const _Filter(this.label);

  final String label;

  bool accepts(AttendanceException e) => switch (this) {
    _Filter.needsAction => e.status.needsAction,
    _Filter.settled => !e.status.needsAction,
    _Filter.all => true,
  };
}

/// Attendance exceptions across the company, with their details and the
/// actions that settle them.
class ExceptionsScreen extends ConsumerWidget {
  const ExceptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(companyTimeZoneProvider);
    final range = ref.watch(recentRangeProvider);
    return switch ((zone, range)) {
      (AsyncData(value: final z), AsyncData(value: final r)) => _Exceptions(
        zone: z,
        initialRange: r,
      ),
      (AsyncError(:final error), _) ||
      (_, AsyncError(:final error)) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(recentRangeProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _Exceptions extends ConsumerStatefulWidget {
  const _Exceptions({required this.zone, required this.initialRange});

  final CompanyTimeZone zone;
  final DateRange initialRange;

  @override
  ConsumerState<_Exceptions> createState() => _ExceptionsState();
}

class _ExceptionsState extends ConsumerState<_Exceptions> {
  late DateRange _range = widget.initialRange;
  _Filter _filter = _Filter.needsAction;
  String? _selectedKey;

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(widget.initialRange.to.year + 1),
      initialDateRange: DateTimeRange(
        start: _asDateTime(_range.from),
        end: _asDateTime(_range.to),
      ),
    );
    if (picked != null) {
      setState(() {
        _range = (
          from: LocalDate.fromDateTime(picked.start),
          to: LocalDate.fromDateTime(picked.end),
        );
        _selectedKey = null;
      });
    }
  }

  static DateTime _asDateTime(LocalDate d) => DateTime(d.year, d.month, d.day);

  /// Decisions and corrections announce themselves through
  /// [attendanceRevisionProvider]; only the selection needs resetting.
  void _refresh() => setState(() => _selectedKey = null);

  Future<void> _open(AttendanceException exception, bool split) async {
    if (split) {
      setState(() => _selectedKey = exception.issueKey);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: ExceptionDetail(
            exception: exception,
            zone: widget.zone,
            onChanged: () {
              Navigator.of(sheetContext).pop();
              _refresh();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final split = context.windowSize.isAtLeast(WindowSize.expanded);
    final exceptions = ref.watch(exceptionsProvider(_range));

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        const AttendanceAreaTabs(selected: AttendanceTab.exceptions),
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
            for (final filter in _Filter.values)
              ChoiceChip(
                label: Text(filter.label),
                selected: _filter == filter,
                onSelected: (_) => setState(() {
                  _filter = filter;
                  _selectedKey = null;
                }),
              ),
          ],
        ),
      ],
    );

    final body = switch (exceptions) {
      AsyncData(:final value) => _content(value, split),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(exceptionsProvider(_range)),
      ),
      _ => const LoadingState(),
    };

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [header, body],
      ),
    );
  }

  Widget _content(List<AttendanceException> all, bool split) {
    final shown = [
      for (final e in all)
        if (_filter.accepts(e)) e,
    ];
    if (shown.isEmpty) {
      return EmptyState(
        icon: Icons.task_alt,
        title: _filter == _Filter.needsAction
            ? 'Everything looks good.'
            : 'No exceptions in this period.',
        message: _filter == _Filter.needsAction
            ? 'No attendance needs your attention in this period.'
            : null,
      );
    }
    final list = Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, exception) in shown.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _ExceptionTile(
              exception: exception,
              zone: widget.zone,
              selected: split && exception.issueKey == _selectedKey,
              onTap: () => _open(exception, split),
            ),
          ],
        ],
      ),
    );
    if (!split) {
      return list;
    }
    final selected = shown.where((e) => e.issueKey == _selectedKey).firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(child: list),
        Expanded(
          child: Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: selected == null
                  ? Text(
                      'Select an exception to see the details.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  : ExceptionDetail(
                      key: ValueKey(selected.issueKey),
                      exception: selected,
                      zone: widget.zone,
                      onChanged: _refresh,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExceptionTile extends StatelessWidget {
  const _ExceptionTile({
    required this.exception,
    required this.zone,
    required this.selected,
    required this.onTap,
  });

  final AttendanceException exception;
  final CompanyTimeZone zone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final at = exception.occurredAt;
    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: Icon(
        exception.blocksPayroll ? Icons.warning_amber : Icons.info_outline,
        color: exception.status.needsAction && exception.blocksPayroll
            ? context.semanticColors.warning.color
            : context.colors.onSurfaceVariant,
      ),
      title: Text(
        '${exception.employee.details.shownName} · '
        '${exception.type.label}',
      ),
      subtitle: Text(
        '${formatLocalDate(context, zone.dateOf(at))}, '
        '${formatCompanyTime(context, zone, at)}',
      ),
      trailing: ExceptionStatusChip(status: exception.status),
    );
  }
}
