import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/reports/data/pdf/pdf_kit.dart';
import 'package:attendance_payroll/features/reports/data/pdf_payroll_document_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

/// The bundled fonts, read from the project like the app reads its assets.
Future<PdfFontData> _fonts() async {
  ByteData read(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());
  return PdfFontData(
    regular: read(PdfPayrollDocumentService.regularFontAsset),
    bold: read(PdfPayrollDocumentService.boldFontAsset),
  );
}

void _expectPdf(Uint8List bytes) {
  expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  expect(bytes.length, greaterThan(1000));
}

void main() {
  late TestEnv env;
  late AdminSession admin;
  late PdfPayrollDocumentService pdf;
  late PayrollPeriod october;
  late Employee john;

  Future<Employee> hired(String number, String first, String last) async {
    final e = (await env.management.create(
      admin,
      EmployeeDetails(
        employeeNumber: number,
        firstName: first,
        lastName: last,
        jobTitle: 'Cashier',
        employmentStartDate: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
    (await env.management.addRate(
      admin,
      e.id,
      NewEmployeeRate(
        rateType: RateType.hourly,
        amountMinor: 50000,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
    return e;
  }

  Future<void> entry(Employee who, AttendanceEventType type, int day, int h) =>
      env.attendanceCorrections
          .addMissingEntry(
            admin,
            who.id,
            type: type,
            occurredAt: nairobiTime(day, h, 0),
            reason: 'Paper register',
          )
          .then((r) => r.unwrap());

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    pdf = PdfPayrollDocumentService(loadFonts: _fonts);
    env.clock.jumpTo(nairobiTime(31, 23, 0).add(const Duration(days: 2)));
    // A name beyond plain ASCII, to check the embedded font is used.
    john = await hired('E0001', 'Wanjirū', 'Ōtieno');
    await entry(john, AttendanceEventType.clockIn, 5, 8);
    await entry(john, AttendanceEventType.clockOut, 5, 17);
    await entry(john, AttendanceEventType.clockIn, 6, 8);
    october = (await env.payroll.createPeriod(
      admin,
      NewPayrollPeriod(
        name: 'October 2026',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 31),
      ),
    )).unwrap();
    (await env.payroll.addAdjustment(
      admin,
      october.id,
      NewPayrollAdjustment(
        employeeId: john.id,
        type: AdjustmentType.deduction,
        amount: const Money(5000, 'KES'),
        description: 'Uniform',
      ),
    )).unwrap();
    (await env.payroll.calculate(admin, october.id)).unwrap();
  });

  test('payslips and the payroll summary are PDF files', () async {
    final payslips = (await env.reports.payslips(admin, october.id)).unwrap();
    final summary = (await env.reports.payrollSummary(
      admin,
      october.id,
    )).unwrap();

    _expectPdf((await pdf.generatePayslips(payslips)).unwrap());
    _expectPdf((await pdf.generatePayrollSummary(summary)).unwrap());
  });

  test('attendance, timesheet and exception reports are PDF files', () async {
    final from = LocalDate(2026, 10, 1);
    final to = LocalDate(2026, 10, 31);
    final attendance = (await env.reports.attendanceReport(
      admin,
      from: from,
      to: to,
    )).unwrap();
    final timesheet = (await env.reports.timesheet(
      admin,
      john.id,
      from: from,
      to: to,
    )).unwrap();
    final exceptions = (await env.reports.exceptionReport(
      admin,
      from: from,
      to: to,
    )).unwrap();
    expect(exceptions.rows, isNotEmpty);

    _expectPdf((await pdf.generateAttendanceReport(attendance)).unwrap());
    _expectPdf((await pdf.generateTimesheet(timesheet)).unwrap());
    _expectPdf((await pdf.generateExceptionReport(exceptions)).unwrap());
  });

  test('a long report runs past the default page limit', () async {
    for (var i = 2; i <= 30; i++) {
      await hired('E${i.toString().padLeft(4, '0')}', 'Person', 'No $i');
    }
    final report = (await env.reports.attendanceReport(
      admin,
      from: LocalDate(2026, 8, 1),
      to: LocalDate(2026, 10, 31),
    )).unwrap();
    expect(report.groups, hasLength(30));

    // 30 employees × 92 days: far more than 20 pages.
    _expectPdf((await pdf.generateAttendanceReport(report)).unwrap());
  });

  test('empty reports still produce a document', () async {
    final exceptions = (await env.reports.exceptionReport(
      admin,
      from: LocalDate(2026, 9, 1),
      to: LocalDate(2026, 9, 30),
    )).unwrap();
    expect(exceptions.rows, isEmpty);

    _expectPdf((await pdf.generateExceptionReport(exceptions)).unwrap());
  });

  test('a failure is reported, not thrown', () async {
    final broken = PdfPayrollDocumentService(
      loadFonts: () async => throw const FileSystemException('missing font'),
    );
    final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

    final result = await broken.generatePayslips(payslips);

    expect(result.failureOrNull, isA<AppFailure>());
  });
}
