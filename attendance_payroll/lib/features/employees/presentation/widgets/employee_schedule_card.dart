import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/section_card.dart';
import 'package:attendance_payroll/features/schedules/data/schedule_providers.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_view_providers.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/date_field.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The employee's work schedule over time, and assigning a new one.
class EmployeeScheduleCard extends ConsumerWidget {
  const EmployeeScheduleCard({required this.employee, super.key});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scheduleHistoryProvider(employee.id));
    final schedules = ref.watch(schedulesProvider).value ?? const [];
    final names = {for (final s in schedules) s.id: s.details.name};
    String nameOf(String? id) =>
        id == null ? 'No schedule' : names[id] ?? 'Schedule';

    return SectionCard(
      title: 'Work schedule',
      action: FilledButton.tonal(
        onPressed: history.value == null
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) =>
                    _AssignDialog(employee: employee, history: history.value!),
              ),
        child: const Text('Assign schedule'),
      ),
      child: switch (history) {
        AsyncData(:final value) when value.isEmpty => const SectionNote(
          'No schedule. Lateness and absence are not checked.',
        ),
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xs,
          children: [
            Text(
              nameOf(value.last.scheduleId),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SectionNote(
              'Since ${formatLocalDate(context, value.last.effectiveFrom)}',
            ),
            for (final earlier in value.reversed.skip(1))
              SectionNote(
                '${nameOf(earlier.scheduleId)} · '
                '${formatLocalDate(context, earlier.effectiveFrom)} – '
                '${formatLocalDate(context, earlier.effectiveTo!)}',
              ),
          ],
        ),
        AsyncError(:final error) => SectionNote(
          AppFailure.from(error).userMessage,
        ),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

class _AssignDialog extends ConsumerStatefulWidget {
  const _AssignDialog({required this.employee, required this.history});

  final Employee employee;
  final List<ScheduleAssignment> history;

  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _scheduleId;
  late LocalDate? _from;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = LocalDate.fromDateTime(DateTime.now());
    final earliest = widget.history.lastOrNull?.effectiveFrom.addDays(1);
    _from = earliest != null && earliest.isAfter(today) ? earliest : today;
    _scheduleId = widget.history.lastOrNull?.scheduleId;
  }

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    final from = _from;
    if (_busy ||
        session == null ||
        from == null ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(workScheduleServiceProvider)
        .assign(session, widget.employee.id, _scheduleId, effectiveFrom: from);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        ref
          ..invalidate(scheduleHistoryProvider(widget.employee.id))
          ..read(attendanceRevisionProvider.notifier).changed();
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(schedulesProvider).value ?? const [];
    final error = _error;
    return AlertDialog(
      title: Text('Schedule for ${widget.employee.details.shownName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            if (error != null) FailureBanner(message: error),
            DropdownButtonFormField<String?>(
              initialValue: _scheduleId,
              decoration: const InputDecoration(labelText: 'Schedule'),
              items: [
                for (final schedule in schedules)
                  DropdownMenuItem(
                    value: schedule.id,
                    child: Text(schedule.details.name),
                  ),
                const DropdownMenuItem<String?>(child: Text('No schedule')),
              ],
              onChanged: (value) => setState(() => _scheduleId = value),
            ),
            DateField(
              label: 'From',
              value: _from,
              onChanged: (date) => setState(() => _from = date),
              validator: (date) => date == null ? 'Choose a date.' : null,
            ),
            const Text(
              'The current schedule ends the day before. Earlier periods are '
              'kept.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        BusyButton(label: 'Assign', busy: _busy, onPressed: _save),
      ],
    );
  }
}
