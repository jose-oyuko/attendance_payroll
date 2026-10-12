import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/company/data/company_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/payroll/data/payroll_providers.dart';
import 'package:attendance_payroll/features/reports/data/pdf_payroll_document_service.dart';
import 'package:attendance_payroll/features/reports/domain/payroll_document_service.dart';
import 'package:attendance_payroll/features/reports/domain/report_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(
    companies: ref.watch(companyRepositoryProvider),
    employees: ref.watch(employeeManagementServiceProvider),
    attendance: ref.watch(attendanceServiceProvider),
    exceptions: ref.watch(attendanceExceptionServiceProvider),
    payroll: ref.watch(payrollServiceProvider),
  ),
);

final payrollDocumentServiceProvider = Provider<PayrollDocumentService>(
  (ref) => PdfPayrollDocumentService(),
);
