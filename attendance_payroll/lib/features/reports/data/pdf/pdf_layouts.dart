import 'dart:typed_data';

import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_formatting.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_formatting.dart';
import 'package:attendance_payroll/features/reports/data/pdf/pdf_kit.dart';
import 'package:attendance_payroll/features/reports/domain/report_documents.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Document layouts. Top-level functions of plain data, so they can run on a
// background isolate.

String _period(PayrollPeriod p) =>
    '${p.name} (${PdfKit.range(p.startDate, p.endDate)})';

String _rateUnit(RateType type) => switch (type) {
  RateType.hourly => 'per hour',
  RateType.daily => 'per day',
  RateType.monthly => 'per month',
};

/// Payroll that is not finalized may still change; say so on the page.
pw.Widget? _notFinal(PayrollPeriod p) =>
    p.status == PayrollPeriodStatus.finalized
    ? null
    : PdfKit.notice(
        'Not final: this payroll is ${p.status.label.toLowerCase()}. '
        'The figures may still change.',
      );

// Payslips ----------------------------------------------------------------

Future<Uint8List> payslipsPdf(
  List<PayslipDocument> payslips,
  PdfFontData fonts,
) {
  final kit = PdfKit(fonts);
  return PdfKit.save([
    for (final p in payslips) _payslipPage(kit, p),
  ], 'Payslips');
}

pw.Page _payslipPage(PdfKit kit, PayslipDocument p) {
  final line = p.line;
  final earnings = [
    for (final item in line.items)
      if (!item.kind.isDeduction) item,
  ];
  final deductions = [
    for (final item in line.items)
      if (item.kind.isDeduction) item,
  ];
  final rates = {
    for (final item in line.items)
      if (item.kind == PayrollItemKind.regularPay && item.rate != null)
        '${item.rate} ${_rateUnit(item.rateType!)}',
  };
  List<String> row(PayrollItem item) => [
    item.kind.label,
    explainItem(item),
    '${item.amount}',
  ];
  return kit.page(
    header: p.header,
    title: 'Payslip',
    subtitle: p.period.name,
    build: (_) => [
      ?_notFinal(p.period),
      PdfKit.facts([
        ('Employee', p.employee.name),
        ('Employee no.', p.employee.number),
        if (p.employee.jobTitle case final title?) ('Job title', title),
        ('Pay period', PdfKit.range(p.period.startDate, p.period.endDate)),
        ('Payroll status', p.period.status.label),
      ]),
      PdfKit.heading('Earnings'),
      PdfKit.table(
        headers: const ['Item', 'Details', 'Amount'],
        rows: [
          for (final item in earnings) row(item),
          ['Gross pay', '', '${line.gross}'],
        ],
        numeric: const {2},
        emphasised: {earnings.length},
        widths: const {
          0: pw.FixedColumnWidth(90),
          1: pw.FlexColumnWidth(),
          2: pw.FixedColumnWidth(90),
        },
      ),
      if (deductions.isNotEmpty) ...[
        PdfKit.heading('Deductions'),
        PdfKit.table(
          headers: const ['Item', 'Details', 'Amount'],
          rows: [
            for (final item in deductions) row(item),
            ['Total deductions', '', '${line.deductions}'],
          ],
          numeric: const {2},
          emphasised: {deductions.length},
          widths: const {
            0: pw.FixedColumnWidth(90),
            1: pw.FlexColumnWidth(),
            2: pw.FixedColumnWidth(90),
          },
        ),
      ],
      PdfKit.heading('Summary'),
      PdfKit.facts([
        ('Regular hours', formatHours(line.regularHours)),
        ('Overtime hours', formatHours(line.overtimeHours)),
        if (rates.isNotEmpty) ('Rate', rates.join(', ')),
        ('Gross pay', '${line.gross}'),
        ('Deductions', '${line.deductions}'),
      ]),
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.all(8),
        color: PdfKit.shade,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Net pay',
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              '${line.net}',
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Payroll summary ---------------------------------------------------------

Future<Uint8List> payrollSummaryPdf(
  PayrollSummaryDocument summary,
  PdfFontData fonts,
) {
  final kit = PdfKit(fonts);
  final period = summary.period;
  final issues = summary.result.issues;
  final blocking = issues
      .where((i) => i.severity == PayrollIssueSeverity.blocking)
      .length;
  final totals = summary.result.totals;
  List<String> money(PayrollLine l) => [
    formatHours(l.regularHours),
    formatHours(l.overtimeHours),
    '${l.gross}',
    '${l.deductions}',
    '${l.net}',
  ];
  return PdfKit.save([
    kit.page(
      header: summary.header,
      title: 'Payroll summary',
      subtitle: period.name,
      format: PdfPageFormat.a4.landscape,
      build: (_) => [
        ?_notFinal(period),
        PdfKit.facts([
          ('Pay period', _period(period)),
          ('Payroll status', period.status.label),
          ('Employees paid', '${summary.lines.length}'),
        ]),
        if (issues.isNotEmpty)
          PdfKit.notice(
            '${PdfKit.count(issues.length, 'problem')} found in this '
            'calculation, $blocking blocking. Blocking problems must be '
            'resolved before the payroll is approved.',
          ),
        PdfKit.heading('Employees'),
        PdfKit.table(
          headers: const [
            'Employee',
            'No.',
            'Regular hours',
            'Overtime hours',
            'Gross pay',
            'Deductions',
            'Net pay',
          ],
          rows: [
            for (final (:employee, :line) in summary.lines)
              [employee.name, employee.number, ...money(line)],
            for (final t in totals)
              [
                totals.length == 1 ? 'Total' : 'Total (${t.currency})',
                '${t.lines.length}',
                formatHours(t.regularHours),
                formatHours(t.overtimeHours),
                '${t.gross}',
                '${t.deductions}',
                '${t.net}',
              ],
          ],
          numeric: const {2, 3, 4, 5, 6},
          emphasised: {
            for (var i = 0; i < totals.length; i++) summary.lines.length + i,
          },
          widths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FixedColumnWidth(55),
            2: pw.FlexColumnWidth(),
            3: pw.FlexColumnWidth(),
            4: pw.FlexColumnWidth(1.3),
            5: pw.FlexColumnWidth(1.3),
            6: pw.FlexColumnWidth(1.3),
          },
        ),
        if (totals.isNotEmpty) ...[
          PdfKit.heading('Breakdown'),
          for (final t in totals)
            PdfKit.facts([
              ('Regular pay', '${t.regularPay}'),
              ('Overtime pay', '${t.overtimePay}'),
              ('Allowances', '${t.allowances}'),
              ('Bonuses', '${t.bonuses}'),
              ('Deductions', '${t.deductions}'),
              ('Net pay', '${t.net}'),
            ]),
        ],
        PdfKit.signatures(const ['Prepared by', 'Approved by']),
      ],
    ),
  ], 'Payroll summary ${period.name}');
}

// Attendance --------------------------------------------------------------

String _status(AttendanceDocumentRow r) {
  final notes = [if (r.isLate) 'late', if (r.leftEarly) 'left early'];
  return notes.isEmpty
      ? r.status.label
      : '${r.status.label} · ${notes.join(', ')}';
}

List<String> _attendanceCells(AttendanceDocumentRow r) => [
  PdfKit.dayAndDate(r.date),
  r.sessions.isEmpty
      ? '—'
      : r.sessions.map((s) => PdfKit.timeOn(r.date, s.start)).join('\n'),
  r.sessions.isEmpty
      ? '—'
      : r.sessions
            .map(
              (s) => s.end == null ? 'missing' : PdfKit.timeOn(r.date, s.end!),
            )
            .join('\n'),
  switch (r) {
    _ when r.sessions.isEmpty => '—',
    // Time that is not settled yet is not "0 hours worked".
    _ when r.status == DayStatus.needsReview && r.worked == Duration.zero =>
      'to review',
    _ => formatWorkDuration(r.worked),
  },
  _status(r),
  r.issues.isEmpty ? '—' : r.issues.map((i) => i.label).join(', '),
];

String _totalsText(AttendanceTotals t) => [
  '${t.present} present',
  if (t.late > 0) '${t.late} late',
  if (t.leftEarly > 0) '${t.leftEarly} left early',
  if (t.absent > 0) '${t.absent} absent',
  if (t.needsReview > 0) '${t.needsReview} to review',
].join(' · ');

pw.Widget _attendanceTable(AttendanceDocumentGroup g) => PdfKit.table(
  headers: const [
    'Date',
    'Clock in',
    'Clock out',
    'Worked',
    'Status',
    'Exceptions',
  ],
  rows: [
    for (final r in g.rows) _attendanceCells(r),
    [
      'Total · ${g.rows.length} days',
      '',
      '',
      formatWorkDuration(g.totals.payable),
      _totalsText(g.totals),
      '',
    ],
  ],
  numeric: const {3},
  emphasised: {g.rows.length},
  widths: const {
    0: pw.FixedColumnWidth(90),
    1: pw.FixedColumnWidth(70),
    2: pw.FixedColumnWidth(70),
    3: pw.FixedColumnWidth(55),
    4: pw.FlexColumnWidth(2),
    5: pw.FlexColumnWidth(2),
  },
);

const String _unsettledNote =
    'Worked time counts settled attendance only; time awaiting review counts '
    'as zero until it is reviewed.';

Future<Uint8List> attendanceReportPdf(
  AttendanceDocument report,
  PdfFontData fonts,
) {
  final kit = PdfKit(fonts);
  final range = PdfKit.range(report.from, report.to);
  return PdfKit.save([
    kit.page(
      header: report.header,
      title: 'Attendance report',
      subtitle: range,
      format: PdfPageFormat.a4.landscape,
      build: (_) => [
        if (report.groups.isEmpty)
          pw.Text('No attendance in this range.')
        else ...[
          pw.Text(
            _unsettledNote,
            style: const pw.TextStyle(color: PdfKit.muted),
          ),
          for (final g in report.groups) ...[
            PdfKit.heading('${g.employee.name} · ${g.employee.number}'),
            _attendanceTable(g),
          ],
        ],
      ],
    ),
  ], 'Attendance report $range');
}

Future<Uint8List> timesheetPdf(AttendanceDocument sheet, PdfFontData fonts) {
  final kit = PdfKit(fonts);
  final range = PdfKit.range(sheet.from, sheet.to);
  final group = sheet.groups.single;
  return PdfKit.save([
    kit.page(
      header: sheet.header,
      title: 'Timesheet',
      subtitle: range,
      build: (_) => [
        PdfKit.facts([
          ('Employee', group.employee.name),
          ('Employee no.', group.employee.number),
          if (group.employee.jobTitle case final title?) ('Job title', title),
          ('Dates', range),
          ('Time worked', formatWorkDuration(group.totals.payable)),
          ('Days', _totalsText(group.totals)),
        ]),
        pw.SizedBox(height: 8),
        _attendanceTable(group),
        pw.SizedBox(height: 4),
        pw.Text(_unsettledNote, style: const pw.TextStyle(color: PdfKit.muted)),
        PdfKit.signatures(const ['Employee', 'Supervisor']),
      ],
    ),
  ], 'Timesheet ${group.employee.name} $range');
}

// Exceptions --------------------------------------------------------------

Future<Uint8List> exceptionReportPdf(
  ExceptionReportDocument report,
  PdfFontData fonts,
) {
  final kit = PdfKit(fonts);
  final range = PdfKit.range(report.from, report.to);
  return PdfKit.save([
    kit.page(
      header: report.header,
      title: 'Exception report',
      subtitle: range,
      format: PdfPageFormat.a4.landscape,
      build: (_) => [
        if (report.rows.isEmpty)
          pw.Text('No unresolved exceptions. Everything looks good.')
        else ...[
          pw.Text(
            '${PdfKit.count(report.rows.length, 'exception')} waiting for a '
            'decision, ${report.rows.where((r) => r.blocksPayroll).length} '
            'of them blocking payroll.',
          ),
          pw.SizedBox(height: 8),
          PdfKit.table(
            headers: const [
              'Employee',
              'No.',
              'Date',
              'Time',
              'Exception',
              'Status',
              'Blocks payroll',
            ],
            rows: [
              for (final r in report.rows)
                [
                  r.employee.name,
                  r.employee.number,
                  PdfKit.dayAndDate(r.at.date),
                  PdfKit.time(r.at.timeOfDay),
                  r.type.label,
                  r.status.label,
                  if (r.blocksPayroll) 'Yes' else 'No',
                ],
            ],
            widths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FixedColumnWidth(50),
              2: pw.FixedColumnWidth(90),
              3: pw.FixedColumnWidth(40),
              4: pw.FlexColumnWidth(2),
              5: pw.FixedColumnWidth(70),
              6: pw.FixedColumnWidth(80),
            },
          ),
        ],
      ],
    ),
  ], 'Exception report $range');
}
