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
import 'package:attendance_payroll/features/printing/data/payroll_receipts.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:attendance_payroll/features/reports/data/pdf/pdf_kit.dart';
import 'package:attendance_payroll/features/reports/data/pdf_payroll_document_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/attendance_fixtures.dart';
import '../support/fake_backups.dart';
import '../support/test_env.dart';

/// The critical workflow of the whole product, through the real services and
/// database, with nothing faked but the clock (spec §51):
///
/// create employee -> set rate -> clock in -> clock out -> create payroll ->
/// calculate -> approve -> finalize -> generate payslip.
void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;
  late Directory temp;

  Future<PdfFontData> fonts() async {
    ByteData read(String path) =>
        ByteData.sublistView(File(path).readAsBytesSync());
    return PdfFontData(
      regular: read(PdfPayrollDocumentService.regularFontAsset),
      bold: read(PdfPayrollDocumentService.boldFontAsset),
    );
  }

  /// John clocks in and out at the kiosk, as an employee would.
  Future<void> workShift(
    int day,
    int inHour,
    int inMinute,
    int outHour,
    int outMinute,
  ) async {
    env.clock.jumpTo(nairobiTime(day, inHour, inMinute));
    final inVerification = await env.signInAtKiosk(admin, john);
    (await env.attendance.clockIn(inVerification)).unwrap();
    env.clock.jumpTo(nairobiTime(day, outHour, outMinute));
    final outVerification = await env.signInAtKiosk(admin, john);
    (await env.attendance.clockOut(outVerification)).unwrap();
  }

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('integration-test');
    addTearDown(() => temp.deleteSync(recursive: true));
    env = TestEnv();
    admin = await env.setUpOwner();
    john = (await env.management.create(
      admin,
      EmployeeDetails(
        employeeNumber: 'E0001',
        firstName: 'John',
        lastName: 'Kamau',
        jobTitle: 'Cashier',
        employmentStartDate: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
    (await env.management.addRate(
      admin,
      john.id,
      NewEmployeeRate(
        rateType: RateType.hourly,
        amountMinor: 50000,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
  });

  Future<PayrollPeriod> finalizeOctober() async {
    await workShift(5, 8, 2, 17, 4);
    await workShift(6, 8, 0, 16, 0);
    env.clock.jumpTo(nairobiTime(31, 23, 0).add(const Duration(days: 2)));
    final period = (await env.payroll.createPeriod(
      admin,
      NewPayrollPeriod(
        name: 'October 2026',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 31),
      ),
    )).unwrap();
    (await env.payroll.calculate(admin, period.id)).unwrap();
    (await env.payroll.approve(admin, period.id)).unwrap();
    (await env.payroll.finalize(admin, period.id)).unwrap();
    return (await env.payroll.period(admin, period.id)).unwrap();
  }

  test(
    'an employee works, and the administrator pays them and prints it',
    () async {
      final period = await finalizeOctober();

      // The attendance is what the kiosk recorded.
      final events = await env.db.select(env.db.attendanceEvents).get();
      expect(events.map((e) => e.eventType), [
        'clockIn',
        'clockOut',
        'clockIn',
        'clockOut',
      ]);
      expect(events.every((e) => e.employeeId == john.id), isTrue);

      // The pay is explainable: hours at the rate, to the cent, in whole
      // minor units.
      final run = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
      final line = run.result.lines.single;
      final expected = Money.ofRatio(
        'KES',
        BigInt.from(line.regularHours.inSeconds * 50000),
        BigInt.from(3600),
      );
      expect(line.regularHours, greaterThan(const Duration(hours: 17)));
      expect(line.regularHours, lessThan(const Duration(hours: 18)));
      expect(line.regularPay, expected);
      expect(line.gross, expected);
      expect(line.net, expected);
      expect(run.result.hasBlockingIssues, isFalse);

      // Finalized, with the whole chain recorded.
      expect(period.status, PayrollPeriodStatus.finalized);
      expect(
        await env.auditActions(),
        containsAllInOrder([
          'company.created',
          'employee.created',
          'employee.rate_added',
          'payroll.period_created',
          'payroll.calculated',
          'payroll.approved',
          'payroll.finalized',
        ]),
      );

      // The payslip: a real PDF and a receipt, from the same figures.
      final payslips = (await env.reports.payslips(admin, period.id)).unwrap();
      expect(payslips.single.period.status, PayrollPeriodStatus.finalized);
      final pdf = PdfPayrollDocumentService(
        loadFonts: fonts,
        inBackground: false,
      );
      final bytes = (await pdf.generatePayslips(payslips)).unwrap();
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      final receipt = payslipsReceipt(payslips);
      final text = receipt.lines
          .whereType<ReceiptText>()
          .map((t) => t.text)
          .join('\n');
      expect(text, contains('KES $expected'.replaceFirst('KES KES ', 'KES ')));
      expect(text, isNot(contains('NOT FINAL')));
    },
  );

  test('finalized payroll cannot be changed by a later correction', () async {
    final period = await finalizeOctober();

    final result = await env.attendanceCorrections.addMissingEntry(
      admin,
      john.id,
      type: AttendanceEventType.clockIn,
      occurredAt: nairobiTime(7, 8, 0),
      reason: 'Forgot to clock in',
    );

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(
      result.failureOrNull!.userMessage.toLowerCase(),
      contains('payroll'),
    );
    final run = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
    expect(
      run.result.lines.single.regularHours,
      greaterThan(const Duration(hours: 17)),
    );
  });

  test('a later pay rise never rewrites finalized payroll', () async {
    final period = await finalizeOctober();
    final before = (await env.payroll.currentRun(admin, period.id)).unwrap()!;

    (await env.management.addRate(
      admin,
      john.id,
      NewEmployeeRate(
        rateType: RateType.hourly,
        amountMinor: 90000,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 11, 1),
      ),
    )).unwrap();
    final recalculated = await env.payroll.calculate(admin, period.id);

    // Recalculating a finalized period is refused...
    expect(recalculated.failureOrNull, isA<BusinessRuleFailure>());
    // ...and what was paid is exactly what was paid.
    final after = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
    expect(after.result.fingerprint, before.result.fingerprint);
    expect(
      (await env.payroll.period(admin, period.id)).unwrap().status,
      PayrollPeriodStatus.finalized,
    );
  });

  test(
    'reopening and recalculating uses the rate of the time worked',
    () async {
      final period = await finalizeOctober();
      final before = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
      (await env.management.addRate(
        admin,
        john.id,
        NewEmployeeRate(
          rateType: RateType.hourly,
          amountMinor: 90000,
          currencyCode: 'KES',
          effectiveFrom: LocalDate(2026, 11, 1),
        ),
      )).unwrap();

      (await env.payroll.reopen(
        admin,
        period.id,
        reason: 'Check the rate',
      )).unwrap();
      (await env.payroll.calculate(admin, period.id)).unwrap();

      // The November rate does not apply to October's work.
      final after = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
      expect(after.result.fingerprint, before.result.fingerprint);
      expect(await env.auditActions(), contains('payroll.reopened'));
      expect(await env.auditActions(), contains('payroll.recalculated'));
    },
  );

  test('a backup brings finalized payroll back exactly as it was', () async {
    final period = await finalizeOctober();
    final original = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
    final device = BackupTestDevice(env, temp);
    final backup = (await device.service.create(admin)).unwrap();

    // Things go wrong afterwards: the payroll is reopened and changed, and an
    // employee is added.
    (await env.payroll.reopen(admin, period.id, reason: 'Mistake')).unwrap();
    (await env.payroll.addAdjustment(
      admin,
      period.id,
      NewPayrollAdjustment(
        employeeId: john.id,
        type: AdjustmentType.deduction,
        amount: const Money(100000, 'KES'),
        description: 'Wrong deduction',
      ),
    )).unwrap();
    (await env.payroll.calculate(admin, period.id)).unwrap();
    await env.addEmployee(admin, employeeNumber: 'E0002');
    expect(
      (await env.payroll.currentRun(
        admin,
        period.id,
      )).unwrap()!.result.fingerprint,
      isNot(original.result.fingerprint),
    );

    (await device.service.restore(
      admin,
      device.storage.files[backup.fileName]!,
    )).unwrap();

    final restored = (await env.payroll.period(admin, period.id)).unwrap();
    final run = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
    expect(restored.status, PayrollPeriodStatus.finalized);
    expect(run.result.fingerprint, original.result.fingerprint);
    expect(run.result.lines.single.net, original.result.lines.single.net);
    expect(await device.employees(), 1);
    // Signing in with the restored credentials still works.
    expect((await env.auth.signIn(ownerUsername, ownerPassword)).isOk, isTrue);
    // And the payslip of the restored payroll is the same document.
    final payslips = (await env.reports.payslips(admin, period.id)).unwrap();
    expect(payslips.single.line.net, original.result.lines.single.net);
  });

  test('the same attendance always gives the same pay', () async {
    final period = await finalizeOctober();
    final first = (await env.payroll.currentRun(admin, period.id)).unwrap()!;

    (await env.payroll.reopen(
      admin,
      period.id,
      reason: 'Recalculate',
    )).unwrap();
    for (var i = 0; i < 3; i++) {
      (await env.payroll.calculate(admin, period.id)).unwrap();
      final run = (await env.payroll.currentRun(admin, period.id)).unwrap()!;
      expect(run.result.fingerprint, first.result.fingerprint);
    }
  });
}
