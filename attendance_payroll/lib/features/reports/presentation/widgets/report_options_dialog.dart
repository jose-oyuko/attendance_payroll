import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_view_providers.dart';
import 'package:attendance_payroll/features/reports/domain/report_service.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:attendance_payroll/features/reports/presentation/report_view_providers.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension ReportKindLabel on ReportKind {
  String get title => switch (this) {
    ReportKind.payslips => 'Payslips',
    ReportKind.payrollSummary => 'Payroll summary',
    ReportKind.attendance => 'Attendance report',
    ReportKind.timesheet => 'Timesheet',
    ReportKind.exceptions => 'Exception report',
  };

  String get description => switch (this) {
    ReportKind.payslips =>
      "Each employee's pay for a period, one page per employee.",
    ReportKind.payrollSummary =>
      "Everyone's pay for a period with totals, for approval.",
    ReportKind.attendance =>
      "Everyone's clock-ins, clock-outs, time worked and exceptions.",
    ReportKind.timesheet =>
      "One employee's days over a range, with signature lines.",
    ReportKind.exceptions =>
      'Attendance problems still waiting for a decision.',
  };

  IconData get icon => switch (this) {
    ReportKind.payslips => Icons.receipt_long_outlined,
    ReportKind.payrollSummary => Icons.summarize_outlined,
    ReportKind.attendance => Icons.table_chart_outlined,
    ReportKind.timesheet => Icons.assignment_ind_outlined,
    ReportKind.exceptions => Icons.report_outlined,
  };
}

/// Asks for what [kind] needs (a payroll period, or dates, and an employee
/// where it applies); resolves to the request, or `null` when cancelled.
Future<ReportRequest?> showReportOptionsDialog(
  BuildContext context,
  ReportKind kind,
) => showDialog<ReportRequest>(
  context: context,
  builder: (_) => _ReportOptionsDialog(kind: kind),
);

class _ReportOptionsDialog extends ConsumerStatefulWidget {
  const _ReportOptionsDialog({required this.kind});

  final ReportKind kind;

  @override
  ConsumerState<_ReportOptionsDialog> createState() =>
      _ReportOptionsDialogState();
}

class _ReportOptionsDialogState extends ConsumerState<_ReportOptionsDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _periodId;
  String? _employeeId;
  ({LocalDate from, LocalDate to})? _range;

  static DateTime _asDateTime(LocalDate d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickRange(LocalDate today) async {
    final current = _range ?? _thisMonth(today);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: _asDateTime(today),
      initialDateRange: DateTimeRange(
        start: _asDateTime(current.from),
        end: _asDateTime(current.to),
      ),
    );
    if (picked != null && mounted) {
      setState(
        () => _range = (
          from: LocalDate.fromDateTime(picked.start),
          to: LocalDate.fromDateTime(picked.end),
        ),
      );
    }
  }

  static ({LocalDate from, LocalDate to}) _thisMonth(LocalDate today) =>
      (from: LocalDate(today.year, today.month, 1), to: today);

  void _submit(LocalDate? today) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final range = _range ?? (today == null ? null : _thisMonth(today));
    Navigator.of(context).pop(
      ReportRequest(
        kind: widget.kind,
        periodId: widget.kind.isPayroll ? _periodId : null,
        employeeId: _employeeId,
        from: widget.kind.isPayroll ? null : range?.from,
        to: widget.kind.isPayroll ? null : range?.to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final zone = ref.watch(companyTimeZoneProvider).value;
    final today = zone?.dateOf(DateTime.now());
    final periods = kind.isPayroll ? ref.watch(payrollPeriodsProvider) : null;
    final employees =
        kind == ReportKind.payslips || kind == ReportKind.timesheet
        ? ref.watch(reportEmployeesProvider)
        : null;
    final error = switch ((periods, employees)) {
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => error,
      _ => null,
    };
    final range = _range ?? (today == null ? null : _thisMonth(today));

    return AlertDialog(
      title: Text(kind.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text(kind.description),
            if (error != null) Text(AppFailure.from(error).userMessage),
            if (periods != null)
              DropdownButtonFormField<String>(
                initialValue: _periodId,
                decoration: const InputDecoration(labelText: 'Payroll period'),
                items: [
                  for (final p in periods.value ?? const <PayrollPeriod>[])
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (id) => setState(() => _periodId = id),
                validator: (id) => id == null ? 'Choose a period.' : null,
              ),
            if (employees != null)
              DropdownButtonFormField<String?>(
                initialValue: _employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: [
                  if (kind == ReportKind.payslips)
                    const DropdownMenuItem(child: Text('Everyone')),
                  for (final e
                      in employees.value ??
                          const <({String id, String name})>[])
                    DropdownMenuItem(value: e.id, child: Text(e.name)),
                ],
                onChanged: (id) => setState(() => _employeeId = id),
                validator: (id) => kind == ReportKind.timesheet && id == null
                    ? 'Choose an employee.'
                    : null,
              ),
            if (!kind.isPayroll && today != null && range != null) ...[
              OutlinedButton.icon(
                onPressed: () => _pickRange(today),
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${formatLocalDate(context, range.from)} – '
                  '${formatLocalDate(context, range.to)}',
                ),
              ),
              Text(
                'Up to ${ReportService.maxReportDays} days.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: kind.isPayroll || today != null
              ? () => _submit(today)
              : null,
          child: const Text('Open'),
        ),
      ],
    );
  }
}
