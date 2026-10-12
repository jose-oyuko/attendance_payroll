import 'dart:typed_data';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/reports/data/report_providers.dart';
import 'package:attendance_payroll/features/reports/domain/payroll_document_service.dart';
import 'package:attendance_payroll/features/reports/domain/report_service.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// A produced document, ready to preview, print or share.
final class ReportFile {
  const ReportFile({
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String title;
  final String fileName;
  final Uint8List bytes;
}

/// "payslips-october-2026.pdf".
String _fileName(String title) {
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'document' : slug}.pdf';
}

String _dates(LocalDate from, LocalDate to) => from == to
    ? from.toIsoString()
    : '${from.toIsoString()} to ${to.toIsoString()}';

/// Gathers the document's data and lays it out. Not cached beyond the
/// preview: reopening a document shows the current data.
final reportFileProvider = FutureProvider.autoDispose
    .family<ReportFile, ReportRequest>((ref, request) async {
      final (title, bytes) = await _produce(
        ref.watch(reportServiceProvider),
        ref.watch(payrollDocumentServiceProvider),
        requireSession(ref),
        request,
      );
      return ReportFile(
        title: title,
        fileName: _fileName(title),
        bytes: bytes.unwrap(),
      );
    });

/// The document's title and its PDF.
Future<(String, Result<Uint8List>)> _produce(
  ReportService reports,
  PayrollDocumentService pdf,
  AdminSession session,
  ReportRequest request,
) async {
  switch (request.kind) {
    case ReportKind.payslips:
      final payslips = (await reports.payslips(
        session,
        request.periodId!,
        employeeId: request.employeeId,
      )).unwrap();
      final period = payslips.first.period.name;
      return (
        request.employeeId == null
            ? 'Payslips $period'
            : 'Payslip ${payslips.single.employee.name} $period',
        await pdf.generatePayslips(payslips),
      );
    case ReportKind.payrollSummary:
      final summary = (await reports.payrollSummary(
        session,
        request.periodId!,
      )).unwrap();
      return (
        'Payroll summary ${summary.period.name}',
        await pdf.generatePayrollSummary(summary),
      );
    case ReportKind.attendance:
      final report = (await reports.attendanceReport(
        session,
        from: request.from!,
        to: request.to!,
      )).unwrap();
      return (
        'Attendance ${_dates(report.from, report.to)}',
        await pdf.generateAttendanceReport(report),
      );
    case ReportKind.timesheet:
      final sheet = (await reports.timesheet(
        session,
        request.employeeId!,
        from: request.from!,
        to: request.to!,
      )).unwrap();
      return (
        'Timesheet ${sheet.groups.single.employee.name} '
            '${_dates(sheet.from, sheet.to)}',
        await pdf.generateTimesheet(sheet),
      );
    case ReportKind.exceptions:
      final report = (await reports.exceptionReport(
        session,
        from: request.from!,
        to: request.to!,
      )).unwrap();
      return (
        'Exceptions ${_dates(report.from, report.to)}',
        await pdf.generateExceptionReport(report),
      );
  }
}

/// Shows a produced document.
typedef DocumentViewer = Widget Function(ReportFile file);

/// The platform's PDF viewer, with its print and share actions. Replaced
/// only where the printing plugin does not exist, such as widget tests.
final documentViewerProvider = Provider<DocumentViewer>(
  (ref) =>
      (file) => PdfPreview(
        build: (_) async => file.bytes,
        pdfFileName: file.fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
);

/// Every employee by name, archived ones included (they appear in past
/// payroll and attendance).
final reportEmployeesProvider =
    FutureProvider.autoDispose<List<({String id, String name})>>((ref) async {
      final session = requireSession(ref);
      final employees =
          (await ref
                  .watch(employeeManagementServiceProvider)
                  .list(session, includeArchived: true))
              .unwrap();
      return [for (final e in employees) (id: e.id, name: e.details.shownName)]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
