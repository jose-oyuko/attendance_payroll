import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/minor_units.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_view_providers.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/section_card.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/date_field.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension RateTypeLabel on RateType {
  String get unitLabel => switch (this) {
    RateType.hourly => 'per hour',
    RateType.daily => 'per day',
    RateType.monthly => 'per month',
  };

  String get label => switch (this) {
    RateType.hourly => 'Hourly',
    RateType.daily => 'Daily',
    RateType.monthly => 'Monthly',
  };
}

String _amount(EmployeeRate rate) {
  return '${rate.currencyCode} ${MinorUnits.format(rate.amountMinor)} '
      '${rate.rateType.unitLabel}';
}

/// Current pay rate and its history. Changing the rate adds a new entry; past
/// entries are never edited.
class EmployeeRateCard extends ConsumerWidget {
  const EmployeeRateCard({required this.employee, super.key});

  final Employee employee;

  Future<void> _changeRate(
    BuildContext context,
    List<EmployeeRate> history,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddRateDialog(employee: employee, history: history),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(employeeRatesProvider(employee.id));
    final history = rates.value;
    return SectionCard(
      title: 'Pay rate',
      action: history == null
          ? null
          : FilledButton.tonal(
              onPressed: () => _changeRate(context, history),
              child: Text(history.isEmpty ? 'Set rate' : 'Change rate'),
            ),
      child: switch (rates) {
        AsyncData(:final value) when value.isEmpty => const SectionNote(
          'No pay rate yet. Payroll needs one.',
        ),
        AsyncData(:final value) => _RateHistory(rates: value),
        AsyncError(:final error) => SectionNote(
          AppFailure.from(error).userMessage,
        ),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

class _RateHistory extends StatelessWidget {
  const _RateHistory({required this.rates});

  /// Oldest first.
  final List<EmployeeRate> rates;

  @override
  Widget build(BuildContext context) {
    final latest = rates.last;
    final earlier = rates.reversed.skip(1).toList();
    final until = latest.effectiveTo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(_amount(latest), style: context.textStyles.titleLarge),
        SectionNote(
          until == null
              ? 'Since ${formatLocalDate(context, latest.effectiveFrom)}'
              : '${formatLocalDate(context, latest.effectiveFrom)} – '
                    '${formatLocalDate(context, until)}',
        ),
        if (earlier.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Earlier rates', style: context.textStyles.labelLarge),
          for (final rate in earlier)
            SectionNote(
              '${_amount(rate)} · '
              '${formatLocalDate(context, rate.effectiveFrom)} – '
              '${formatLocalDate(context, rate.effectiveTo!)}',
            ),
        ],
      ],
    );
  }
}

class _AddRateDialog extends ConsumerStatefulWidget {
  const _AddRateDialog({required this.employee, required this.history});

  final Employee employee;
  final List<EmployeeRate> history;

  @override
  ConsumerState<_AddRateDialog> createState() => _AddRateDialogState();
}

class _AddRateDialogState extends ConsumerState<_AddRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late RateType _type;
  late LocalDate? _from;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final latest = widget.history.lastOrNull;
    _type = latest?.rateType ?? RateType.hourly;
    final today = LocalDate.fromDateTime(DateTime.now());
    final earliest = latest?.effectiveFrom.addDays(1);
    _from = earliest != null && earliest.isAfter(today) ? earliest : today;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(String currencyCode) async {
    final session = ref.read(adminSessionProvider);
    final from = _from;
    final amount = MinorUnits.parse(_amount.text);
    if (_busy ||
        session == null ||
        from == null ||
        amount == null ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(employeeManagementServiceProvider)
        .addRate(
          session,
          widget.employee.id,
          NewEmployeeRate(
            rateType: _type,
            amountMinor: amount,
            currencyCode: currencyCode,
            effectiveFrom: from,
          ),
        );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        ref.invalidate(employeeRatesProvider(widget.employee.id));
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
    final company = ref.watch(currentCompanyProvider).value?.details;
    final error = _error;
    return AlertDialog(
      title: Text('Pay rate for ${widget.employee.details.shownName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            if (error != null) FailureBanner(message: error),
            SegmentedButton<RateType>(
              segments: [
                for (final type in RateType.values)
                  ButtonSegment(value: type, label: Text(type.label)),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount ${_type.unitLabel}',
                prefixText: company == null ? null : '${company.currencyCode} ',
              ),
              validator: (value) {
                final amount = MinorUnits.parse(value ?? '');
                return amount == null || amount <= 0
                    ? 'Enter an amount greater than zero, for example 500.00.'
                    : null;
              },
            ),
            DateField(
              label: 'Effective from',
              value: _from,
              onChanged: (date) => setState(() => _from = date),
              validator: (date) => date == null ? 'Choose a date.' : null,
            ),
            const Text(
              'The current rate ends the day before. Earlier rates are kept '
              'for past payroll.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        BusyButton(
          label: 'Save rate',
          busy: _busy || company == null,
          onPressed: company == null ? null : () => _save(company.currencyCode),
        ),
      ],
    );
  }
}
