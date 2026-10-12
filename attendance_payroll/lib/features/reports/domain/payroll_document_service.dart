import 'dart:typed_data';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/reports/domain/report_documents.dart';

/// Lays documents out as PDF files. Screens never contain layout logic:
/// they ask for the bytes and preview, print or share them. Another format
/// (a thermal receipt, for example) would be a different implementation fed
/// the same document data.
abstract interface class PayrollDocumentService {
  /// One page per payslip.
  Future<Result<Uint8List>> generatePayslips(List<PayslipDocument> payslips);

  Future<Result<Uint8List>> generatePayrollSummary(
    PayrollSummaryDocument summary,
  );

  /// Everyone's attendance over a range, grouped by employee.
  Future<Result<Uint8List>> generateAttendanceReport(
    AttendanceDocument attendance,
  );

  /// One employee's attendance over a range, with signature lines.
  Future<Result<Uint8List>> generateTimesheet(AttendanceDocument timesheet);

  Future<Result<Uint8List>> generateExceptionReport(
    ExceptionReportDocument exceptions,
  );
}
