import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/printing/data/drift_printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/data/esc_pos_encoder.dart';
import 'package:attendance_payroll/features/printing/data/payroll_receipts.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printing_service.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:attendance_payroll/features/printing/presentation/receipt_print_button.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/fake_printers.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;
  late PayrollPeriod october;

  Future<Employee> hired(String number, String first, String last) async {
    final employee = (await env.management.create(
      admin,
      EmployeeDetails(
        employeeNumber: number,
        firstName: first,
        lastName: last,
        employmentStartDate: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
    (await env.management.addRate(
      admin,
      employee.id,
      NewEmployeeRate(
        rateType: RateType.hourly,
        amountMinor: 50000,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
    return employee;
  }

  Future<void> shift(Employee who, int day, int from, int to) async {
    for (final (type, hour) in [
      (AttendanceEventType.clockIn, from),
      (AttendanceEventType.clockOut, to),
    ]) {
      (await env.attendanceCorrections.addMissingEntry(
        admin,
        who.id,
        type: type,
        occurredAt: nairobiTime(day, hour, 0),
        reason: 'Paper register',
      )).unwrap();
    }
  }

  /// A receipt as the printed lines, 32 characters wide.
  List<String> printed(Receipt receipt) {
    const encoder = EscPosEncoder(PaperWidth.mm58);
    final lines = <String>[];
    for (final line in receipt.lines) {
      switch (line) {
        case ReceiptText():
          lines.addAll(EscPosEncoder.wrap(line.text, 32));
        case ReceiptColumns():
          lines.addAll(encoder.columns(line.label, line.value));
        case ReceiptRule():
          lines.add(line.double ? '=' * 32 : '-' * 32);
        case ReceiptFeed() || ReceiptCut():
          break;
      }
    }
    return lines;
  }

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    john = await hired('E0001', 'John', 'Kamau');
    env.clock.jumpTo(nairobiTime(31, 23, 0).add(const Duration(days: 2)));
    october = (await env.payroll.createPeriod(
      admin,
      NewPayrollPeriod(
        name: 'October 2026',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 31),
      ),
    )).unwrap();
    await shift(john, 5, 8, 16);
    (await env.payroll.calculate(admin, october.id)).unwrap();
  });

  group('payslip receipt', () {
    test('shows who is paid, what for and how much', () async {
      final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

      final text = printed(payslipsReceipt(payslips));

      expect(text, contains('PAYSLIP'));
      expect(text, contains('October 2026'));
      expect(
        text.any((l) => l.startsWith('Employee') && l.endsWith('John Kamau')),
        isTrue,
      );
      expect(
        text.any((l) => l.startsWith('Employee no.') && l.endsWith('E0001')),
        isTrue,
      );
      expect(
        text.any((l) => l.startsWith('Regular pay') && l.endsWith('4,000.00')),
        isTrue,
      );
      // Eight hours at KES 500 an hour, worked out on the paper.
      expect(
        text.any((l) => l.contains('8.00 h') && l.contains('500.00')),
        isTrue,
      );
      expect(
        text.any((l) => l.startsWith('Gross pay') && l.endsWith('4,000.00')),
        isTrue,
      );
      expect(text, contains('KES 4,000.00'));
      expect(text.any((l) => l.contains('Amounts in KES')), isTrue);
    });

    test('says the figures may change until the payroll is final', () async {
      final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

      final text = printed(payslipsReceipt(payslips)).join('\n');

      expect(text, contains('NOT FINAL'));
      expect(text, contains('Status                 In review'));
    });

    test('leaves out the notice once the payroll is finalized', () async {
      (await env.payroll.approve(admin, october.id)).unwrap();
      (await env.payroll.finalize(admin, october.id)).unwrap();
      final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

      final text = printed(payslipsReceipt(payslips)).join('\n');

      expect(text, isNot(contains('NOT FINAL')));
      expect(text, contains('Finalized'));
    });

    test('lists deductions and takes them off the net pay', () async {
      (await env.payroll.addAdjustment(
        admin,
        october.id,
        NewPayrollAdjustment(
          employeeId: john.id,
          type: AdjustmentType.deduction,
          amount: const Money(50000, 'KES'),
          description: 'Uniform',
        ),
      )).unwrap();
      (await env.payroll.calculate(admin, october.id)).unwrap();
      final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

      final text = printed(payslipsReceipt(payslips));

      expect(text, contains('DEDUCTIONS'));
      expect(
        text.any((l) => l.startsWith('Deduction') && l.endsWith('500.00')),
        isTrue,
      );
      expect(text, contains('KES 3,500.00'));
    });

    test('cuts the paper after every employee', () async {
      final amina = await hired('E0002', 'Amina', 'Odhiambo');
      await shift(amina, 6, 8, 12);
      (await env.payroll.calculate(admin, october.id)).unwrap();
      final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

      final receipt = payslipsReceipt(payslips);

      expect(receipt.lines.whereType<ReceiptCut>(), hasLength(2));
      expect(receipt.lines.last, isA<ReceiptCut>());
    });
  });

  group('payroll summary receipt', () {
    test('lists everyone with totals', () async {
      final amina = await hired('E0002', 'Amina', 'Odhiambo');
      await shift(amina, 6, 8, 12);
      (await env.payroll.calculate(admin, october.id)).unwrap();
      final summary = (await env.reports.payrollSummary(
        admin,
        october.id,
      )).unwrap();

      final text = printed(payrollSummaryReceipt(summary));

      expect(text, contains('PAYROLL SUMMARY'));
      expect(
        text.any((l) => l.startsWith('Employees paid') && l.endsWith('2')),
        isTrue,
      );
      expect(
        text.any(
          (l) => l.startsWith('Amina Odhiambo') && l.endsWith('KES 2,000.00'),
        ),
        isTrue,
      );
      expect(
        text.any(
          (l) => l.startsWith('John Kamau') && l.endsWith('KES 4,000.00'),
        ),
        isTrue,
      );
      expect(
        text.any((l) => l.startsWith('Net pay') && l.endsWith('KES 6,000.00')),
        isTrue,
      );
    });
  });

  group('printReceipt', () {
    late FakePrinterService printer;
    late PrintingService printing;

    setUp(() async {
      printer = FakePrinterService();
      final settings = DriftPrinterSettingsRepository(
        env.db,
        clock: env.clock.call,
      );
      (await settings.save(
        const PrinterSettings(device: kitchenPrinter),
      )).unwrap();
      printing = PrintingService(
        printer: printer,
        settings: settings,
        audit: env.audit,
        transactions: env.transactions,
      );
    });

    Future<Result<void>> print(ReportRequest request) => printReceipt(
      reports: env.reports,
      printing: printing,
      session: admin,
      request: request,
    );

    test('prints a payslip', () async {
      final result = await print(
        ReportRequest(
          kind: ReportKind.payslips,
          periodId: october.id,
          employeeId: john.id,
        ),
      );

      expect(result.isOk, isTrue);
      expect(printer.printed, hasLength(1));
      expect(printed(printer.printed.single), contains('PAYSLIP'));
    });

    test('prints the payroll summary', () async {
      final result = await print(
        ReportRequest(kind: ReportKind.payrollSummary, periodId: october.id),
      );

      expect(result.isOk, isTrue);
      expect(printed(printer.printed.single), contains('PAYROLL SUMMARY'));
    });

    test('refuses documents that are not receipts', () async {
      final result = await print(
        ReportRequest(
          kind: ReportKind.attendance,
          from: LocalDate(2026, 10, 1),
          to: LocalDate(2026, 10, 31),
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(printer.printAttempts, 0);
    });

    test('does not print payroll that was never calculated', () async {
      final empty = (await env.payroll.createPeriod(
        admin,
        NewPayrollPeriod(
          name: 'November 2026',
          startDate: LocalDate(2026, 11, 1),
          endDate: LocalDate(2026, 11, 30),
        ),
      )).unwrap();

      final result = await print(
        ReportRequest(kind: ReportKind.payslips, periodId: empty.id),
      );

      expect(result.failureOrNull, isA<BusinessRuleFailure>());
      expect(printer.printAttempts, 0);
    });

    test('only documents with a receipt show the print action', () {
      expect(hasReceipt(ReportKind.payslips), isTrue);
      expect(hasReceipt(ReportKind.payrollSummary), isTrue);
      expect(hasReceipt(ReportKind.attendance), isFalse);
      expect(hasReceipt(ReportKind.timesheet), isFalse);
      expect(hasReceipt(ReportKind.exceptions), isFalse);
    });
  });
}
