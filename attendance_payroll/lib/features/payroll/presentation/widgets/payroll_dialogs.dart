import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/minor_units.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/payroll/data/payroll_providers.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_formatting.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_view_providers.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/date_field.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// A dialog that saves one payroll change and refreshes payroll views.
///
/// [save] returns the result of the service call; on success the dialog
/// closes with `true`. The dialog disposes [controllers] once it has left
/// the screen: its fields use them until the closing animation ends.
class _PayrollDialog extends ConsumerStatefulWidget {
  const _PayrollDialog({
    required this.title,
    required this.saveLabel,
    required this.fields,
    required this.save,
    this.controllers = const [],
  });

  final String title;
  final String saveLabel;
  final List<Widget> Function(StateSetter setState) fields;
  final Future<Result<Object?>> Function(AdminSession session) save;
  final List<TextEditingController> controllers;

  @override
  ConsumerState<_PayrollDialog> createState() => _PayrollDialogState();
}

class _PayrollDialogState extends ConsumerState<_PayrollDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.save(session);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        ref.read(payrollRevisionProvider.notifier).changed();
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
    final error = _error;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (error != null) FailureBanner(message: error),
              ...widget.fields(setState),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        BusyButton(label: widget.saveLabel, busy: _busy, onPressed: _submit),
      ],
    );
  }
}

/// Creates a period; defaults to the month of [today].
Future<PayrollPeriod?> showNewPeriodDialog(
  BuildContext context,
  WidgetRef ref, {
  required LocalDate today,
}) async {
  final name = TextEditingController(
    text: '${_monthNames[today.month - 1]} ${today.year}',
  );
  var start = LocalDate(today.year, today.month, 1);
  LocalDate? end = LocalDate(
    today.year,
    today.month,
    1,
  ).addDays(DateTime.utc(today.year, today.month + 1, 0).day - 1);
  PayrollPeriod? created;
  await showDialog<bool>(
    context: context,
    builder: (_) => _PayrollDialog(
      controllers: [name],
      title: 'New payroll period',
      saveLabel: 'Create period',
      fields: (setState) => [
        TextFormField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name.' : null,
        ),
        DateField(
          label: 'First day',
          value: start,
          onChanged: (d) => setState(() => start = d ?? start),
        ),
        DateField(
          label: 'Last day',
          value: end,
          onChanged: (d) => setState(() => end = d),
          validator: (d) => d == null ? 'Choose the last day.' : null,
        ),
      ],
      save: (session) async {
        final result = await ref
            .read(payrollServiceProvider)
            .createPeriod(
              session,
              NewPayrollPeriod(
                name: name.text,
                startDate: start,
                endDate: end!,
              ),
            );
        created = result.valueOrNull;
        return result;
      },
    ),
  );
  return created;
}

/// Adds an allowance, bonus or deduction to [period].
Future<void> showAdjustmentDialog(
  BuildContext context,
  WidgetRef ref, {
  required PayrollPeriod period,
  required Map<String, String> employees,
  required String currency,
}) async {
  final amount = TextEditingController();
  final description = TextEditingController();
  String? employeeId;
  var type = AdjustmentType.allowance;
  final sorted = employees.entries.toList()
    ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  await showDialog<bool>(
    context: context,
    builder: (_) => _PayrollDialog(
      controllers: [amount, description],
      title: 'Add adjustment',
      saveLabel: 'Add',
      fields: (setState) => [
        DropdownButtonFormField<String>(
          initialValue: employeeId,
          decoration: const InputDecoration(labelText: 'Employee'),
          items: [
            for (final e in sorted)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() => employeeId = v),
          validator: (v) => v == null ? 'Choose an employee.' : null,
        ),
        SegmentedButton<AdjustmentType>(
          segments: [
            for (final t in AdjustmentType.values)
              ButtonSegment(value: t, label: Text(t.label)),
          ],
          selected: {type},
          onSelectionChanged: (s) => setState(() => type = s.first),
        ),
        TextFormField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '$currency ',
          ),
          validator: (v) {
            final minor = MinorUnits.parse(v ?? '');
            return minor == null || minor <= 0
                ? 'Enter an amount greater than zero.'
                : null;
          },
        ),
        TextFormField(
          controller: description,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'For example: Transport allowance',
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Describe the adjustment.' : null,
        ),
      ],
      save: (session) => ref
          .read(payrollServiceProvider)
          .addAdjustment(
            session,
            period.id,
            NewPayrollAdjustment(
              employeeId: employeeId!,
              type: type,
              amount: Money(MinorUnits.parse(amount.text)!, currency),
              description: description.text,
            ),
          ),
    ),
  );
}

/// Reopens approved or finalized payroll, with a reason.
Future<void> showReopenDialog(
  BuildContext context,
  WidgetRef ref, {
  required PayrollPeriod period,
}) async {
  final reason = TextEditingController();
  final finalized = period.status == PayrollPeriodStatus.finalized;
  await showDialog<bool>(
    context: context,
    builder: (_) => _PayrollDialog(
      controllers: [reason],
      title: 'Reopen ${period.name}?',
      saveLabel: 'Reopen',
      fields: (_) => [
        Text(
          finalized
              ? 'This payroll was finalized. Reopening unlocks its attendance, '
                    'rates and adjustments so they can change, and it must be '
                    'recalculated, approved and finalized again. The '
                    'finalized figures stay in the history.'
              : 'The approval is withdrawn and the payroll returns to review.',
        ),
        TextFormField(
          controller: reason,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Reason'),
          validator: (v) =>
              (v ?? '').trim().length < 3 ? 'Give a reason.' : null,
        ),
      ],
      save: (session) => ref
          .read(payrollServiceProvider)
          .reopen(session, period.id, reason: reason.text),
    ),
  );
}

/// Overtime rules and rate conversions.
Future<void> showPayrollSettingsDialog(
  BuildContext context,
  WidgetRef ref, {
  required StoredPayrollSettings stored,
}) async {
  final s = stored.settings;
  String hours(Duration? d) =>
      d == null ? '' : '${d.inMinutes / 60}'.replaceFirst(RegExp(r'\.0$'), '');
  final daily = TextEditingController(text: hours(s.dailyOvertimeAfter));
  final weekly = TextEditingController(text: hours(s.weeklyOvertimeAfter));
  final percent = TextEditingController(text: '${s.overtimePercent}');
  final day = TextEditingController(text: hours(s.standardDay));
  final week = TextEditingController(text: hours(s.standardWeek));
  var dailyOn = s.dailyOvertimeAfter != null;
  var weeklyOn = s.weeklyOvertimeAfter != null;

  Duration? parseHours(String text) {
    final value = double.tryParse(text.trim());
    return value == null ? null : Duration(minutes: (value * 60).round());
  }

  String? positiveHours(String? v) {
    final d = parseHours(v ?? '');
    return d == null || d <= Duration.zero ? 'Enter a number of hours.' : null;
  }

  Widget hoursField(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]'))],
    decoration: InputDecoration(labelText: label, suffixText: 'hours'),
    validator: positiveHours,
  );

  await showDialog<bool>(
    context: context,
    builder: (_) => _PayrollDialog(
      controllers: [daily, weekly, percent, day, week],
      title: 'Overtime and pay rules',
      saveLabel: 'Save',
      fields: (setState) => [
        const Text(
          'Overtime applies only when a limit is set. Rules differ by '
          'country and sector, so set them to match your obligations.',
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily overtime'),
          value: dailyOn,
          onChanged: (v) => setState(() => dailyOn = v),
        ),
        if (dailyOn) hoursField(daily, 'Overtime after, each day'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Weekly overtime'),
          value: weeklyOn,
          onChanged: (v) => setState(() => weeklyOn = v),
        ),
        if (weeklyOn) hoursField(weekly, 'Overtime after, each week'),
        TextFormField(
          controller: percent,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Overtime pay',
            suffixText: '% of the normal rate',
          ),
          validator: (v) =>
              int.tryParse(v ?? '') == null ? 'Enter a percentage.' : null,
        ),
        hoursField(day, 'Standard day (for daily rates)'),
        hoursField(week, 'Standard week (for monthly salaries)'),
      ],
      save: (session) => ref
          .read(payrollServiceProvider)
          .updateSettings(
            session,
            PayrollSettings(
              dailyOvertimeAfter: dailyOn ? parseHours(daily.text) : null,
              weeklyOvertimeAfter: weeklyOn ? parseHours(weekly.text) : null,
              overtimePercent: int.parse(percent.text),
              standardDay: parseHours(day.text)!,
              standardWeek: parseHours(week.text)!,
            ),
            expectedVersion: stored.version,
          ),
    ),
  );
}
