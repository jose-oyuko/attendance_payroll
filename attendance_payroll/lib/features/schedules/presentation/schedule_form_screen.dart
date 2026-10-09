import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/schedules/data/schedule_providers.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_formatting.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_routes.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_view_providers.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:attendance_payroll/shared/widgets/subpage_header.dart';
import 'package:attendance_payroll/shared/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Creates a schedule, or edits one when [scheduleId] is given.
class ScheduleFormScreen extends ConsumerWidget {
  const ScheduleFormScreen({super.key, this.scheduleId});

  final String? scheduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = scheduleId;
    if (id == null) {
      return const _ScheduleForm(existing: null);
    }
    return switch (ref.watch(scheduleProvider(id))) {
      AsyncData(:final value) => _ScheduleForm(existing: value),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        retryLabel: 'Back to schedules',
        onRetry: () => context.go(ScheduleRoutes.list),
      ),
      _ => const LoadingState(),
    };
  }
}

/// One weekday's row in the form.
class _DayDraft {
  _DayDraft({required this.enabled, required this.start, required this.end});

  bool enabled;
  TimeOfDay start;
  TimeOfDay end;
}

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm({required this.existing});

  final WorkSchedule? existing;

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  // Pre-filled for a new schedule; every value can be changed.
  static const TimeOfDay _defaultStart = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay _defaultEnd = TimeOfDay(hour: 17, minute: 0);
  static const int _defaultToleranceMinutes = 10;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lateMinutes;
  late final TextEditingController _earlyMinutes;
  late final TextEditingController _breakMinutes;
  late final TextEditingController _breakAfterHours;
  late final List<_DayDraft> _days;
  late bool _breakEnabled;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.existing?.details;
    _name = TextEditingController(text: d?.name);
    _lateMinutes = TextEditingController(
      text: '${d?.lateTolerance.inMinutes ?? _defaultToleranceMinutes}',
    );
    _earlyMinutes = TextEditingController(
      text:
          '${d?.earlyDepartureTolerance.inMinutes ?? _defaultToleranceMinutes}',
    );
    final automaticBreak = d?.automaticBreak;
    _breakEnabled = automaticBreak != null;
    _breakMinutes = TextEditingController(
      text: '${automaticBreak?.deduct.inMinutes ?? 60}',
    );
    _breakAfterHours = TextEditingController(
      text: '${automaticBreak?.after.inHours ?? 6}',
    );
    _days = [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        _draftFor(weekday, d),
    ];
  }

  static _DayDraft _draftFor(int weekday, WorkScheduleDetails? d) {
    if (d == null) {
      return _DayDraft(
        enabled: weekday <= DateTime.friday,
        start: _defaultStart,
        end: _defaultEnd,
      );
    }
    final day = d.dayFor(weekday);
    return _DayDraft(
      enabled: day != null,
      start: day == null ? _defaultStart : timeOfDayFrom(day.start),
      end: day == null ? _defaultEnd : timeOfDayFrom(day.end),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _lateMinutes,
      _earlyMinutes,
      _breakMinutes,
      _breakAfterHours,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _copyFirstToAll() {
    final first = _days.where((d) => d.enabled).firstOrNull;
    if (first == null) {
      return;
    }
    setState(() {
      for (final day in _days.where((d) => d.enabled)) {
        day
          ..start = first.start
          ..end = first.end;
      }
    });
  }

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null || !_formKey.currentState!.validate()) {
      return;
    }
    final details = WorkScheduleDetails(
      name: _name.text,
      days: [
        for (final (index, day) in _days.indexed)
          if (day.enabled)
            ScheduleDay(
              weekday: index + 1,
              start: durationFrom(day.start),
              end: durationFrom(day.end),
            ),
      ],
      lateTolerance: Duration(minutes: int.parse(_lateMinutes.text)),
      earlyDepartureTolerance: Duration(minutes: int.parse(_earlyMinutes.text)),
      automaticBreak: _breakEnabled
          ? AutomaticBreak(
              after: Duration(hours: int.parse(_breakAfterHours.text)),
              deduct: Duration(minutes: int.parse(_breakMinutes.text)),
            )
          : null,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(workScheduleServiceProvider);
    final existing = widget.existing;
    final result = existing == null
        ? await service.create(session, details)
        : await service.update(
            session,
            existing.id,
            details,
            expectedVersion: existing.version,
          );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        ref
          ..invalidate(schedulesProvider)
          ..invalidate(scheduleProvider)
          ..read(attendanceRevisionProvider.notifier).changed();
        context.go(ScheduleRoutes.list);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.userMessage;
        });
    }
  }

  String? _wholeNumber(String? value) =>
      int.tryParse((value ?? '').trim()) == null
      ? 'Enter a whole number.'
      : null;

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: _wholeNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final error = _error;
    final compact = context.windowSize == WindowSize.compact;

    return PageContainer(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            SubpageHeader(
              title: existing == null
                  ? 'New schedule'
                  : 'Edit ${existing.details.name}',
              backLocation: ScheduleRoutes.list,
            ),
            if (error != null) FailureBanner(message: error),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'For example: Day shift',
              ),
              maxLength: WorkScheduleDetails.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name.' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Working days',
                    style: context.textStyles.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: _copyFirstToAll,
                  child: const Text('Same hours every day'),
                ),
              ],
            ),
            for (final (index, day) in _days.indexed)
              _DayRow(
                weekday: index + 1,
                draft: day,
                compact: compact,
                onChanged: () => setState(() {}),
              ),
            if (existing != null)
              Text(
                'Changes apply to every date employees are on this schedule, '
                'including past dates, until their payroll is finalized.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            Row(
              spacing: AppSpacing.md,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _numberField(_lateMinutes, 'Late after (minutes)'),
                ),
                Expanded(
                  child: _numberField(
                    _earlyMinutes,
                    'Early if leaving more than (minutes)',
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deduct an automatic break'),
              subtitle: const Text(
                "Replaces the company's break on this schedule's days.",
              ),
              value: _breakEnabled,
              onChanged: (value) => setState(() => _breakEnabled = value),
            ),
            if (_breakEnabled)
              Row(
                spacing: AppSpacing.md,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _numberField(_breakMinutes, 'Break (minutes)'),
                  ),
                  Expanded(
                    child: _numberField(
                      _breakAfterHours,
                      'For sessions of at least (hours)',
                    ),
                  ),
                ],
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: BusyButton(
                label: existing == null ? 'Create schedule' : 'Save changes',
                busy: _busy,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.weekday,
    required this.draft,
    required this.compact,
    required this.onChanged,
  });

  final int weekday;
  final _DayDraft draft;
  final bool compact;
  final VoidCallback onChanged;

  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final toggle = SizedBox(
      width: _labelWidth,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(weekdayName(weekday)),
        value: draft.enabled,
        onChanged: (value) {
          draft.enabled = value ?? false;
          onChanged();
        },
      ),
    );
    if (!draft.enabled) {
      return Row(
        children: [
          toggle,
          Text(
            'Day off',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    final nextDay = durationFrom(draft.end) < durationFrom(draft.start);
    final times = [
      Expanded(
        child: TimeField(
          label: 'Start',
          value: draft.start,
          onChanged: (time) {
            draft.start = time;
            onChanged();
          },
        ),
      ),
      Expanded(
        child: TimeField(
          label: nextDay ? 'End (next day)' : 'End',
          value: draft.end,
          onChanged: (time) {
            draft.end = time;
            onChanged();
          },
          validator: (time) =>
              time == draft.start ? 'End must differ from start.' : null,
        ),
      ),
    ];
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toggle,
          Row(spacing: AppSpacing.sm, children: times),
        ],
      );
    }
    return Row(spacing: AppSpacing.sm, children: [toggle, ...times]);
  }
}
