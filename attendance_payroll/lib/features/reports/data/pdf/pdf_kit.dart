import 'dart:typed_data';

import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/reports/domain/report_documents.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The font files embedded in every document, so text renders the same on
/// every device and offline. Plain bytes, so they can be sent to the
/// isolate that lays documents out.
final class PdfFontData {
  const PdfFontData({required this.regular, required this.bold});

  final ByteData regular;
  final ByteData bold;
}

/// Shared building blocks of the documents: theme, page frame, tables and
/// context-free text formatting (documents have no locale or device
/// settings, so they use one unambiguous style: "05 Oct 2026", "08:02").
final class PdfKit {
  PdfKit(PdfFontData fonts)
    : theme = pw.ThemeData.withFont(
        base: pw.Font.ttf(fonts.regular),
        bold: pw.Font.ttf(fonts.bold),
      ).copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 9));

  final pw.ThemeData theme;

  /// Upper bound per document, well above a year of a large company's
  /// daily attendance.
  static const int maxPages = 5000;

  static const PdfColor muted = PdfColors.grey700;
  static const PdfColor rule = PdfColors.grey400;
  static const PdfColor shade = PdfColors.grey200;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String date(LocalDate d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  /// "Mon 05 Oct 2026".
  static String dayAndDate(LocalDate d) =>
      '${_weekdays[DateTime.utc(d.year, d.month, d.day).weekday - 1]} '
      '${date(d)}';

  static String range(LocalDate from, LocalDate to) =>
      from == to ? date(from) : '${date(from)} – ${date(to)}';

  /// "08:02", 24-hour.
  static String time(Duration timeOfDay) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(timeOfDay.inHours)}:${two(timeOfDay.inMinutes % 60)}';
  }

  static String wallTime(WallTime t) => '${date(t.date)} ${time(t.timeOfDay)}';

  /// A time on [day]'s row; a time on another date says which.
  static String timeOn(LocalDate day, WallTime t) => t.date == day
      ? time(t.timeOfDay)
      : '${time(t.timeOfDay)} (${date(t.date)})';

  /// A document: [title] and [subtitle] on every page, the generation time
  /// and page number at the bottom.
  pw.MultiPage page({
    required DocumentHeader header,
    required String title,
    required String subtitle,
    required List<pw.Widget> Function(pw.Context context) build,
    PdfPageFormat format = PdfPageFormat.a4,
  }) {
    return pw.MultiPage(
      pageFormat: format,
      // The default of 20 would cut long reports short (a year of daily
      // attendance runs to hundreds of pages).
      maxPages: maxPages,
      theme: theme,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => context.pageNumber == 1
          ? _firstPageHeader(header.company, title, subtitle)
          : _runningHeader(header.company, title, subtitle),
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated ${wallTime(header.generatedAt)}',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
      ),
      build: build,
    );
  }

  pw.Widget _firstPageHeader(
    CompanyDetails company,
    String title,
    String subtitle,
  ) {
    final contact = [?company.phone, ?company.email].join(' · ');
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: rule)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company.name,
                  style: const pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (company.legalName case final legal?) _muted(legal),
                if (company.address case final address?) _muted(address),
                if (contact.isNotEmpty) _muted(contact),
                if (company.registrationNumber case final reg?)
                  _muted('Reg. no. $reg'),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(subtitle),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _runningHeader(
    CompanyDetails company,
    String title,
    String subtitle,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: rule)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            company.name,
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          _muted('$title · $subtitle'),
        ],
      ),
    );
  }

  static pw.Widget _muted(String text) =>
      pw.Text(text, style: const pw.TextStyle(color: muted));

  /// A section heading.
  static pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
  );

  /// A note in a shaded box, e.g. that payroll is not final.
  static pw.Widget notice(String text) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(6),
    decoration: const pw.BoxDecoration(
      color: shade,
      border: pw.Border(left: pw.BorderSide(color: muted, width: 3)),
    ),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
    ),
  );

  /// Label–value pairs in two columns.
  static pw.Widget facts(List<(String, String)> facts) => pw.Table(
    columnWidths: const {0: pw.FixedColumnWidth(110), 1: pw.FlexColumnWidth()},
    children: [
      for (final (label, value) in facts)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(label, style: const pw.TextStyle(color: muted)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(value),
            ),
          ],
        ),
    ],
  );

  /// A ruled table. Rows in [emphasised] are bold and shaded (totals);
  /// [numeric] columns are right-aligned.
  static pw.Widget table({
    required List<String> headers,
    required List<List<String>> rows,
    Set<int> numeric = const {},
    Set<int> emphasised = const {},
    Map<int, pw.TableColumnWidth> widths = const {},
  }) {
    pw.Widget cell(String text, int column, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        textAlign: numeric.contains(column)
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        style: bold ? const pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    );

    return pw.Table(
      columnWidths: widths,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: rule, width: 0.5),
        bottom: pw.BorderSide(color: rule, width: 0.5),
      ),
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: muted)),
          ),
          children: [
            for (final (i, h) in headers.indexed) cell(h, i, bold: true),
          ],
        ),
        for (final (r, row) in rows.indexed)
          pw.TableRow(
            decoration: emphasised.contains(r)
                ? const pw.BoxDecoration(color: shade)
                : null,
            children: [
              for (final (i, value) in row.indexed)
                cell(value, i, bold: emphasised.contains(r)),
            ],
          ),
      ],
    );
  }

  /// Lines to sign by hand, e.g. "Employee", "Approved by".
  static pw.Widget signatures(List<String> roles) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 20),
    child: pw.Row(
      children: [
        for (final (i, role) in roles.indexed) ...[
          if (i > 0) pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  height: 24,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: muted)),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$role · signature and date',
                  style: const pw.TextStyle(fontSize: 8, color: muted),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  /// "1 problem", "3 problems".
  static String count(int n, String singular, [String? plural]) =>
      '$n ${n == 1 ? singular : plural ?? '${singular}s'}';

  /// The document's bytes.
  static Future<Uint8List> save(List<pw.Page> pages, String title) {
    final document = pw.Document(title: title, creator: 'Attendance & Payroll');
    pages.forEach(document.addPage);
    return document.save();
  }
}
