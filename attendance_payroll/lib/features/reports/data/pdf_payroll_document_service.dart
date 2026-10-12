import 'dart:isolate';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/reports/data/pdf/pdf_kit.dart';
import 'package:attendance_payroll/features/reports/data/pdf/pdf_layouts.dart';
import 'package:attendance_payroll/features/reports/domain/payroll_document_service.dart';
import 'package:attendance_payroll/features/reports/domain/report_documents.dart';
import 'package:flutter/services.dart';

/// [PayrollDocumentService] producing PDF files with the `pdf` package.
///
/// Layout runs on a background isolate so a long report never freezes the
/// screen. The embedded fonts are loaded from the app's assets once.
final class PdfPayrollDocumentService implements PayrollDocumentService {
  PdfPayrollDocumentService({
    Future<PdfFontData> Function()? loadFonts,
    this._inBackground = true,
  }) : _loadFonts = loadFonts ?? _assetFonts;

  static const String regularFontAsset = 'assets/fonts/Roboto-Regular.ttf';
  static const String boldFontAsset = 'assets/fonts/Roboto-Bold.ttf';

  final Future<PdfFontData> Function() _loadFonts;
  final bool _inBackground;
  Future<PdfFontData>? _fonts;

  static Future<PdfFontData> _assetFonts() async => PdfFontData(
    regular: await rootBundle.load(regularFontAsset),
    bold: await rootBundle.load(boldFontAsset),
  );

  @override
  Future<Result<Uint8List>> generatePayslips(List<PayslipDocument> payslips) =>
      _generate(payslipsPdf, payslips);

  @override
  Future<Result<Uint8List>> generatePayrollSummary(
    PayrollSummaryDocument summary,
  ) => _generate(payrollSummaryPdf, summary);

  @override
  Future<Result<Uint8List>> generateAttendanceReport(
    AttendanceDocument attendance,
  ) => _generate(attendanceReportPdf, attendance);

  @override
  Future<Result<Uint8List>> generateTimesheet(AttendanceDocument timesheet) =>
      _generate(timesheetPdf, timesheet);

  @override
  Future<Result<Uint8List>> generateExceptionReport(
    ExceptionReportDocument exceptions,
  ) => _generate(exceptionReportPdf, exceptions);

  Future<Result<Uint8List>> _generate<T>(
    Future<Uint8List> Function(T document, PdfFontData fonts) layout,
    T document,
  ) {
    return Result.guard(() async {
      final fonts = await (_fonts ??= _loadFonts());
      return _inBackground
          ? _inIsolate(layout, document, fonts)
          : layout(document, fonts);
    });
  }

  /// Static, so the closure sent to the isolate holds only [layout] (a
  /// top-level function), the document and the fonts, never this service.
  static Future<Uint8List> _inIsolate<T>(
    Future<Uint8List> Function(T document, PdfFontData fonts) layout,
    T document,
    PdfFontData fonts,
  ) => Isolate.run(() => layout(document, fonts));
}
