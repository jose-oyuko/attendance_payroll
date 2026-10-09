import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_formatting.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/correction_dialog.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lateness, early departure and absence are excused rather than dismissed.
bool _isExcusable(AttendanceIssueType type) =>
    type == AttendanceIssueType.lateArrival ||
    type == AttendanceIssueType.earlyDeparture ||
    type == AttendanceIssueType.missingAttendance;

/// Colours for an exception status.
SemanticColorSet exceptionStatusColors(
  BuildContext context,
  ExceptionStatus status,
) {
  final semantic = context.semanticColors;
  return switch (status) {
    ExceptionStatus.open => semantic.warning,
    ExceptionStatus.reviewed => semantic.info,
    ExceptionStatus.resolved => semantic.success,
    ExceptionStatus.dismissed => semantic.neutral,
  };
}

/// Everything about one exception, with the actions that settle it.
class ExceptionDetail extends ConsumerWidget {
  const ExceptionDetail({
    required this.exception,
    required this.zone,
    required this.onChanged,
    super.key,
  });

  final AttendanceException exception;
  final CompanyTimeZone zone;

  /// Called after a decision or correction is saved.
  final VoidCallback onChanged;

  String _at(BuildContext context, DateTime instant) =>
      '${formatCompanyTime(context, zone, instant)}, '
      '${formatLocalDate(context, zone.dateOf(instant))}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = exception.status;
    final colors = exceptionStatusColors(context, status);
    final session = exception.session;
    final names = ref.watch(adminNamesProvider).value ?? const {};
    final canAct =
        exception.stillDetected &&
        (ref.watch(adminSessionProvider)?.can(Permission.correctAttendance) ??
            false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  exception.type.label,
                  style: context.textStyles.titleLarge,
                ),
              ),
            ),
            _Chip(text: status.label, colors: colors),
          ],
        ),
        Text(
          '${exception.employee.details.shownName} · '
          '${_at(context, exception.occurredAt)}',
          style: context.textStyles.titleSmall,
        ),
        Text(
          exception.blocksPayroll
              ? 'Keeps this time out of payroll until it is settled.'
              : 'For information; it does not affect pay.',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (exception.stillDetected)
          Text(exception.type.description)
        else
          const Text(
            'Fixed by a correction; the attendance no longer shows it.',
          ),
        if (session != null) _SessionSummary(session: session, zone: zone),
        if (canAct)
          _Actions(exception: exception, zone: zone, onChanged: onChanged),
        if (exception.reviews.isNotEmpty) ...[
          Text('History', style: context.textStyles.titleSmall),
          for (final review in exception.reviews.reversed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(
                review.relatedCorrectionId == null
                    ? review.decision.label
                    : 'Resolved by a correction',
              ),
              subtitle: Text(
                '${review.reason}\n'
                '${names[review.reviewedBy] ?? 'Administrator'} · '
                '${_at(context, review.reviewedAt)}',
              ),
              isThreeLine: true,
            ),
        ],
      ],
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session, required this.zone});

  final AttendanceSession session;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context) {
    final end = session.end;
    final duration = session.duration;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'In ${formatCompanyTime(context, zone, session.start)} · '
          'Out ${end == null ? '—' : formatCompanyTime(context, zone, end)}'
          '${duration == null ? '' : ' · ${formatWorkDuration(duration)}'}',
        ),
      ),
    );
  }
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({
    required this.exception,
    required this.zone,
    required this.onChanged,
  });

  final AttendanceException exception;
  final CompanyTimeZone zone;
  final VoidCallback onChanged;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  Future<void> _correct(CorrectionRequest request) async {
    final saved = await showCorrectionDialog(
      context,
      request: request,
      zone: widget.zone,
      resolves: widget.exception.issue,
    );
    if (saved) {
      widget.onChanged();
    }
  }

  Future<void> _decide(ReviewDecision decision) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _DecisionDialog(exception: widget.exception, decision: decision),
    );
    if (saved ?? false) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exception = widget.exception;
    final issue = exception.issue!;
    final session = exception.session;
    final clockOut = session?.clockOut;
    final decisions = AttendanceExceptionService.decisionsFor(exception.type);
    final date = widget.zone.dateOf(exception.occurredAt);

    final eventId = issue.eventId;
    final clockIn = session?.clockIn;
    final corrections = <(String, CorrectionRequest)>[
      ...switch (exception.type) {
        AttendanceIssueType.missingClockOut => [
          (
            'Add clock-out',
            AddEntryRequest(
              employeeId: exception.employee.id,
              date: session?.workDate ?? date,
              type: AttendanceEventType.clockOut,
            ),
          ),
          if (clockIn != null)
            (
              'Remove clock-in',
              RemoveEntryRequest(
                eventId: clockIn.id,
                type: AttendanceEventType.clockIn,
                occurredAt: clockIn.occurredAt,
              ),
            ),
        ],
        AttendanceIssueType.overnightSession ||
        AttendanceIssueType.excessiveDuration ||
        AttendanceIssueType.earlyDeparture => [
          if (clockOut != null)
            (
              'Change clock-out time',
              ChangeTimeRequest(
                eventId: clockOut.id,
                type: AttendanceEventType.clockOut,
                occurredAt: clockOut.occurredAt,
              ),
            ),
        ],
        AttendanceIssueType.lateArrival => [
          if (clockIn != null)
            (
              'Change clock-in time',
              ChangeTimeRequest(
                eventId: clockIn.id,
                type: AttendanceEventType.clockIn,
                occurredAt: clockIn.occurredAt,
              ),
            ),
        ],
        AttendanceIssueType.missingAttendance => [
          (
            'Add clock-in',
            AddEntryRequest(employeeId: exception.employee.id, date: date),
          ),
        ],
        AttendanceIssueType.clockOutWithoutClockIn => [
          (
            'Add clock-in',
            AddEntryRequest(employeeId: exception.employee.id, date: date),
          ),
          if (eventId != null)
            (
              'Remove clock-out',
              RemoveEntryRequest(
                eventId: eventId,
                type: AttendanceEventType.clockOut,
                occurredAt: issue.occurredAt,
              ),
            ),
        ],
        AttendanceIssueType.duplicateClockIn ||
        AttendanceIssueType.duplicateClockOut => [
          if (eventId != null)
            (
              'Remove repeated entry',
              RemoveEntryRequest(
                eventId: eventId,
                type: exception.type.eventType!,
                occurredAt: issue.occurredAt,
              ),
            ),
        ],
      },
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (decisions.contains(ReviewDecision.resolved))
          FilledButton(
            onPressed: () => _decide(ReviewDecision.resolved),
            child: const Text('Accept as recorded'),
          ),
        for (final (label, request) in corrections)
          FilledButton.tonal(
            onPressed: () => _correct(request),
            child: Text(label),
          ),
        if (decisions.contains(ReviewDecision.dismissed))
          OutlinedButton(
            onPressed: () => _decide(ReviewDecision.dismissed),
            child: Text(_isExcusable(exception.type) ? 'Excuse' : 'Dismiss'),
          ),
        TextButton(
          onPressed: () => _decide(ReviewDecision.reviewed),
          child: const Text('Add note'),
        ),
      ],
    );
  }
}

class _DecisionDialog extends ConsumerStatefulWidget {
  const _DecisionDialog({required this.exception, required this.decision});

  final AttendanceException exception;
  final ReviewDecision decision;

  @override
  ConsumerState<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends ConsumerState<_DecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  (String, String, String) get _texts => switch (widget.decision) {
    ReviewDecision.resolved => (
      'Accept as recorded?',
      'The recorded times will be paid as they are. Say why they are right.',
      'Accept',
    ),
    ReviewDecision.dismissed when _isExcusable(widget.exception.type) => (
      'Excuse this?',
      'It will be recorded as excused. Say why, for example leave or a '
          'transport problem.',
      'Excuse',
    ),
    ReviewDecision.dismissed => (
      'Dismiss this exception?',
      'It will be marked as not needing any action.',
      'Dismiss',
    ),
    ReviewDecision.reviewed => (
      'Add a note',
      'The exception stays open. Use this to record what you are checking.',
      'Save note',
    ),
  };

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(attendanceExceptionServiceProvider)
        .decide(
          session,
          widget.exception,
          decision: widget.decision,
          reason: _reason.text,
        );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        ref.read(attendanceRevisionProvider.notifier).changed();
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, explanation, confirm) = _texts;
    final error = _error;
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(explanation),
            if (error != null)
              Text(error, style: TextStyle(color: context.colors.error)),
            TextFormField(
              controller: _reason,
              maxLength: CorrectionReason.maxLength,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Reason'),
              validator: (value) =>
                  CorrectionReason.validate(value ?? '')?.userMessage,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        BusyButton(label: confirm, busy: _busy, onPressed: _save),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.colors});

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

/// A status chip, for exception lists.
class ExceptionStatusChip extends StatelessWidget {
  const ExceptionStatusChip({required this.status, super.key});

  final ExceptionStatus status;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      text: status.label,
      colors: exceptionStatusColors(context, status),
    );
  }
}
