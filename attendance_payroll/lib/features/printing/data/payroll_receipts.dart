import 'package:attendance_payroll/core/utils/minor_units.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_formatting.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:attendance_payroll/features/reports/domain/report_documents.dart';
import 'package:attendance_payroll/shared/formatting/document_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';

// Payroll documents as thermal receipts. Plain functions of the same
// document data the PDFs use, so a receipt and a PDF of one payslip always
// agree. Width-independent: the encoder wraps for the paper in use.

/// One receipt holding every payslip, cut between employees so each can be
/// handed over separately.
Receipt payslipsReceipt(List<PayslipDocument> payslips) => Receipt([
  for (final payslip in payslips) ...[..._payslip(payslip), const ReceiptCut()],
]);

/// Everyone's pay on one receipt, with totals.
Receipt payrollSummaryReceipt(PayrollSummaryDocument summary) =>
    Receipt([..._summary(summary), const ReceiptCut()]);

List<ReceiptLine> _payslip(PayslipDocument p) {
  final line = p.line;
  final earnings = [
    for (final item in line.items)
      if (!item.kind.isDeduction) item,
  ];
  final deductions = [
    for (final item in line.items)
      if (item.kind.isDeduction) item,
  ];
  return [
    ..._header(p.header, 'PAYSLIP', p.period.name),
    ..._notFinal(p.period),
    ReceiptColumns('Employee', p.employee.name),
    ReceiptColumns('Employee no.', p.employee.number),
    if (p.employee.jobTitle case final title?)
      ReceiptColumns('Job title', title),
    ReceiptColumns(
      'Period',
      '${formatDocumentDate(p.period.startDate)} - '
          '${formatDocumentDate(p.period.endDate)}',
    ),
    ReceiptColumns('Status', p.period.status.label),
    const ReceiptRule(),
    ReceiptText('Amounts in ${line.currency}', align: ReceiptAlign.right),
    const ReceiptText('EARNINGS', bold: true),
    ..._items(earnings),
    ReceiptColumns('Gross pay', _amount(line.gross.minorUnits), bold: true),
    if (deductions.isNotEmpty) ...[
      const ReceiptRule(),
      const ReceiptText('DEDUCTIONS', bold: true),
      ..._items(deductions),
      ReceiptColumns(
        'Total deductions',
        _amount(line.deductions.minorUnits),
        bold: true,
      ),
    ],
    const ReceiptRule(double: true),
    const ReceiptText('NET PAY', align: ReceiptAlign.center, bold: true),
    ReceiptText('${line.net}', align: ReceiptAlign.center, large: true),
    const ReceiptRule(double: true),
    ReceiptColumns('Regular hours', formatHours(line.regularHours)),
    ReceiptColumns('Overtime hours', formatHours(line.overtimeHours)),
    const ReceiptFeed(),
    ..._footer(p.header),
  ];
}

List<ReceiptLine> _summary(PayrollSummaryDocument s) {
  final issues = s.result.issues;
  final blocking = issues
      .where((i) => i.severity == PayrollIssueSeverity.blocking)
      .length;
  return [
    ..._header(s.header, 'PAYROLL SUMMARY', s.period.name),
    ..._notFinal(s.period),
    ReceiptColumns(
      'Period',
      '${formatDocumentDate(s.period.startDate)} - '
          '${formatDocumentDate(s.period.endDate)}',
    ),
    ReceiptColumns('Status', s.period.status.label),
    ReceiptColumns('Employees paid', '${s.lines.length}'),
    if (issues.isNotEmpty) ...[
      const ReceiptRule(),
      ReceiptText(
        '${issues.length} ${issues.length == 1 ? 'problem' : 'problems'} '
        'found in this calculation, $blocking blocking.',
        bold: true,
      ),
    ],
    const ReceiptRule(),
    const ReceiptText('NET PAY BY EMPLOYEE', bold: true),
    for (final (:employee, :line) in s.lines) ...[
      ReceiptColumns(
        employee.name,
        '${line.currency} ${_amount(line.net.minorUnits)}',
      ),
      ReceiptText(
        '  ${employee.number}  ${formatHours(line.regularHours)}'
        '${line.overtimeHours == Duration.zero ? '' : ' + '
                  '${formatHours(line.overtimeHours)} OT'}',
      ),
    ],
    for (final totals in s.result.totals) ...[
      const ReceiptRule(double: true),
      ReceiptText(
        s.result.totals.length == 1 ? 'TOTAL' : 'TOTAL ${totals.currency}',
        bold: true,
      ),
      ReceiptColumns('Regular hours', formatHours(totals.regularHours)),
      ReceiptColumns('Overtime hours', formatHours(totals.overtimeHours)),
      ReceiptColumns('Gross pay', _amount(totals.gross.minorUnits)),
      ReceiptColumns('Deductions', _amount(totals.deductions.minorUnits)),
      ReceiptColumns(
        'Net pay',
        '${totals.currency} ${_amount(totals.net.minorUnits)}',
        bold: true,
      ),
    ],
    const ReceiptFeed(),
    ..._footer(s.header),
  ];
}

/// Each item as its label and amount, then how it was worked out.
List<ReceiptLine> _items(List<PayrollItem> items) => [
  for (final item in items) ...[
    ReceiptColumns(item.kind.label, _amount(item.amount.minorUnits)),
    ReceiptText('  ${explainItem(item)}'),
  ],
];

List<ReceiptLine> _header(
  DocumentHeader header,
  String title,
  String subtitle,
) {
  final company = header.company;
  final contact = [?company.phone, ?company.email].join(' ');
  return [
    ReceiptText(company.name, align: ReceiptAlign.center, bold: true),
    if (company.address case final address?)
      ReceiptText(address, align: ReceiptAlign.center),
    if (contact.isNotEmpty) ReceiptText(contact, align: ReceiptAlign.center),
    const ReceiptRule(),
    ReceiptText(title, align: ReceiptAlign.center, bold: true),
    ReceiptText(subtitle, align: ReceiptAlign.center),
    const ReceiptRule(),
  ];
}

List<ReceiptLine> _footer(DocumentHeader header) => [
  ReceiptText(
    'Generated ${formatDocumentDate(header.generatedAt.date)} '
    '${formatDocumentTime(header.generatedAt.timeOfDay)}',
    align: ReceiptAlign.center,
  ),
];

/// Payroll that is not finalized may still change; say so on the paper.
List<ReceiptLine> _notFinal(PayrollPeriod period) =>
    period.status == PayrollPeriodStatus.finalized
    ? const []
    : [
        ReceiptText(
          'NOT FINAL: this payroll is ${period.status.label.toLowerCase()}. '
          'The figures may still change.',
          bold: true,
        ),
        const ReceiptRule(),
      ];

String _amount(int minorUnits) => MinorUnits.format(minorUnits);
