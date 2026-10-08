import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_formatting.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/correction_dialog.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:attendance_payroll/shared/widgets/subpage_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One employee's attendance over a date range, with corrections.
class EmployeeAttendanceScreen extends ConsumerWidget {
  const EmployeeAttendanceScreen({
    required this.employeeId,
    required this.backLocation,
    super.key,
  });

  final String employeeId;
  final String backLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(companyTimeZoneProvider)) {
      AsyncData(:final value) => _AttendanceView(
        employeeId: employeeId,
        backLocation: backLocation,
        zone: value,
      ),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(companyTimeZoneProvider),
      ),
      _ => const LoadingState(),
    };
  }
}

class _AttendanceView extends ConsumerStatefulWidget {
  const _AttendanceView({
    required this.employeeId,
    required this.backLocation,
    required this.zone,
  });

  static const int defaultDays = 14;

  final String employeeId;
  final String backLocation;
  final CompanyTimeZone zone;

  @override
  ConsumerState<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends ConsumerState<_AttendanceView> {
  late LocalDate _from;
  late LocalDate _to;

  AttendanceQuery get _query =>
      (employeeId: widget.employeeId, from: _from, to: _to);

  @override
  void initState() {
    super.initState();
    _to = widget.zone.dateOf(DateTime.now());
    _from = _to.addDays(1 - _AttendanceView.defaultDays);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(_to.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(_from.year, _from.month, _from.day),
        end: DateTime(_to.year, _to.month, _to.day),
      ),
    );
    if (picked != null) {
      setState(() {
        _from = LocalDate.fromDateTime(picked.start);
        _to = LocalDate.fromDateTime(picked.end);
      });
    }
  }

  Future<void> _correct(CorrectionRequest request) async {
    final saved = await showCorrectionDialog(
      context,
      request: request,
      zone: widget.zone,
    );
    if (saved && mounted) {
      ref
        ..invalidate(attendanceTimelineProvider(_query))
        ..invalidate(correctionHistoryProvider(_query));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance corrected.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(attendanceEmployeeProvider(widget.employeeId));
    final timeline = ref.watch(attendanceTimelineProvider(_query));
    final canCorrect =
        ref.watch(adminSessionProvider)?.can(Permission.correctAttendance) ??
        false;
    final name = employee.value?.details.shownName;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          SubpageHeader(
            title: name == null ? 'Attendance' : 'Attendance · $name',
            backLocation: widget.backLocation,
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${formatLocalDate(context, _from)} – '
                  '${formatLocalDate(context, _to)}',
                ),
              ),
              if (canCorrect)
                FilledButton.icon(
                  onPressed: () => _correct(
                    AddEntryRequest(employeeId: widget.employeeId, date: _to),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add missing entry'),
                ),
            ],
          ),
          Text(
            'Times are shown in company time (${widget.zone.name}).',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          switch (timeline) {
            AsyncData(:final value)
                when value.sessions.isEmpty && value.issues.isEmpty =>
              const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No attendance in this period.',
              ),
            AsyncData(:final value) => _Timeline(
              timeline: value,
              zone: widget.zone,
              onCorrect: canCorrect ? _correct : null,
            ),
            AsyncError(:final error) => ErrorState(
              failure: AppFailure.from(error),
              onRetry: () => ref.invalidate(attendanceTimelineProvider(_query)),
            ),
            _ => const LoadingState(),
          },
          _CorrectionHistory(query: _query, zone: widget.zone),
        ],
      ),
    );
  }
}

typedef _OnCorrect = Future<void> Function(CorrectionRequest request);

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.timeline,
    required this.zone,
    required this.onCorrect,
  });

  final AttendanceTimeline timeline;
  final CompanyTimeZone zone;
  final _OnCorrect? onCorrect;

  @override
  Widget build(BuildContext context) {
    final loose = [
      for (final issue in timeline.issues)
        if (issue.sessionKey == null) issue,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        for (final session in timeline.sessions.reversed)
          _SessionCard(session: session, zone: zone, onCorrect: onCorrect),
        if (loose.isNotEmpty) ...[
          Text('Other entries to review', style: context.textStyles.titleSmall),
          for (final issue in loose)
            Card.outlined(
              child: _IssueTile(issue: issue, zone: zone, onCorrect: onCorrect),
            ),
        ],
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.zone,
    required this.onCorrect,
  });

  final AttendanceSession session;
  final CompanyTimeZone zone;
  final _OnCorrect? onCorrect;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final payable = session.payableDuration;
    final (statusText, statusColors) = switch (session.status) {
      SessionStatus.open => ('Clocked in', semantic.info),
      SessionStatus.completed => (
        payable == null ? 'Completed' : formatWorkDuration(payable),
        semantic.success,
      ),
      SessionStatus.exception => ('Needs review', semantic.warning),
    };
    final clockOut = session.clockOut;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatLocalDate(context, session.workDate),
                    style: context.textStyles.titleSmall,
                  ),
                ),
                if (session.isCorrected) ...[
                  Icon(
                    Icons.edit_note,
                    size: AppSpacing.md + AppSpacing.xs,
                    color: context.colors.onSurfaceVariant,
                    semanticLabel: 'Corrected',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _StatusLabel(text: statusText, colors: statusColors),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _EventChip(
                  event: session.clockIn,
                  zone: zone,
                  onCorrect: onCorrect,
                ),
                if (clockOut != null)
                  _EventChip(event: clockOut, zone: zone, onCorrect: onCorrect)
                else
                  const Chip(label: Text('No clock-out')),
              ],
            ),
            for (final issue in session.issues)
              _IssueTile(issue: issue, zone: zone, onCorrect: onCorrect),
          ],
        ),
      ),
    );
  }
}

/// A clock-in or clock-out time, with correction actions.
class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.event,
    required this.zone,
    required this.onCorrect,
  });

  final AttendanceEvent event;
  final CompanyTimeZone zone;
  final _OnCorrect? onCorrect;

  @override
  Widget build(BuildContext context) {
    final label =
        '${event.type == AttendanceEventType.clockIn ? 'In' : 'Out'} '
        '${formatCompanyTime(context, zone, event.occurredAt)}';
    final onCorrect = this.onCorrect;
    if (onCorrect == null) {
      return Chip(label: Text(label));
    }
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.schedule),
          onPressed: () => onCorrect(
            ChangeTimeRequest(
              eventId: event.id,
              type: event.type,
              occurredAt: event.occurredAt,
            ),
          ),
          child: const Text('Change time'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.remove_circle_outline),
          onPressed: () => onCorrect(
            RemoveEntryRequest(
              eventId: event.id,
              type: event.type,
              occurredAt: event.occurredAt,
            ),
          ),
          child: const Text('Remove'),
        ),
      ],
      builder: (context, controller, _) => ActionChip(
        avatar: event.source == AttendanceEventSource.admin
            ? const Icon(Icons.edit_note)
            : null,
        label: Text(label),
        tooltip: '${event.type.label}: correct or remove',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.issue,
    required this.zone,
    required this.onCorrect,
  });

  final AttendanceIssue issue;
  final CompanyTimeZone zone;
  final _OnCorrect? onCorrect;

  @override
  Widget build(BuildContext context) {
    final onCorrect = this.onCorrect;
    final type = issue.type;
    // Session-level issues are fixed through the session's own entries; the
    // extra entries behind other issues can be corrected here.
    final entryCanBeFixed =
        issue.sessionKey == null ||
        type == AttendanceIssueType.duplicateClockIn ||
        type == AttendanceIssueType.duplicateClockOut;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        type.blocksPayroll ? Icons.warning_amber : Icons.info_outline,
        color: type.blocksPayroll
            ? context.semanticColors.warning.color
            : context.colors.onSurfaceVariant,
      ),
      title: Text(type.label),
      subtitle: issue.sessionKey == null
          ? Text(
              '${type.eventType.label} at '
              '${formatCompanyTime(context, zone, issue.occurredAt)} on '
              '${formatLocalDate(context, zone.dateOf(issue.occurredAt))}',
            )
          : null,
      trailing: onCorrect == null || !entryCanBeFixed
          ? null
          : TextButton(
              onPressed: () => onCorrect(
                RemoveEntryRequest(
                  eventId: issue.eventId,
                  type: type.eventType,
                  occurredAt: issue.occurredAt,
                ),
              ),
              child: const Text('Remove entry'),
            ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.text, required this.colors});

  final String text;
  final SemanticColorSet colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          text,
          style: context.textStyles.labelMedium?.copyWith(
            color: colors.onContainer,
          ),
        ),
      ),
    );
  }
}

class _CorrectionHistory extends ConsumerWidget {
  const _CorrectionHistory({required this.query, required this.zone});

  final AttendanceQuery query;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(correctionHistoryProvider(query)).value;
    final names = ref.watch(adminNamesProvider).value ?? const {};
    if (history == null || history.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Semantics(
              header: true,
              child: Text('Corrections', style: context.textStyles.titleMedium),
            ),
            for (final correction in history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(_describe(context, correction)),
                subtitle: Text(
                  '${correction.reason}\n'
                  '${names[correction.correctedBy] ?? 'Administrator'} · '
                  '${formatLocalDate(context, zone.dateOf(correction.correctedAt))} '
                  '${formatCompanyTime(context, zone, correction.correctedAt)}',
                ),
                isThreeLine: true,
              ),
          ],
        ),
      ),
    );
  }

  String _describe(BuildContext context, AttendanceCorrection c) {
    String at(DateTime instant) =>
        '${formatCompanyTime(context, zone, instant)} on '
        '${formatLocalDate(context, zone.dateOf(instant))}';
    final what = c.eventType.label.toLowerCase();
    return switch (c.kind) {
      AttendanceCorrectionKind.added =>
        'Added $what at ${at(c.newOccurredAt!)}',
      AttendanceCorrectionKind.timeChanged =>
        'Changed $what ${formatCompanyTime(context, zone, c.previousOccurredAt!)}'
            ' → ${at(c.newOccurredAt!)}',
      AttendanceCorrectionKind.removed =>
        'Removed $what at ${at(c.previousOccurredAt!)}',
    };
  }
}
