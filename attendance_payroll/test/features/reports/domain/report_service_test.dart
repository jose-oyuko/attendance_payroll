import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/reports/domain/report_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
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

  Future<void> entry(
    Employee who,
    AttendanceEventType type,
    int day,
    int hour,
  ) async {
    (await env.attendanceCorrections.addMissingEntry(
      admin,
      who.id,
      type: type,
      occurredAt: nairobiTime(day, hour, 0),
      reason: 'Paper register',
    )).unwrap();
  }

  Future<void> shift(Employee who, int day, int from, int to) async {
    await entry(who, AttendanceEventType.clockIn, day, from);
    await entry(who, AttendanceEventType.clockOut, day, to);
  }

  String? ruleOf(Result<Object?> result) {
    final failure = result.failureOrNull;
    return failure is BusinessRuleFailure ? failure.rule : null;
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
  });

  group('payslips', () {
    test('come from the current calculation, one per employee', () async {
      final amina = await hired('E0002', 'Amina', 'Odhiambo');
      await shift(john, 5, 8, 16);
      await shift(amina, 6, 8, 12);
      (await env.payroll.calculate(admin, october.id)).unwrap();

      final payslips = (await env.reports.payslips(admin, october.id)).unwrap();

      expect(payslips.map((p) => p.employee.name), [
        'Amina Odhiambo',
        'John Kamau',
      ]);
      final johns = payslips.last;
      expect(johns.employee.number, 'E0001');
      expect(johns.line.net, const Money(400000, 'KES'));
      expect(johns.line.regularHours, const Duration(hours: 8));
      expect(johns.period.status, PayrollPeriodStatus.review);
      expect(johns.header.company.name, isNotEmpty);
      // Generated on 2 November around 23:00, Nairobi time (the test clock
      // advances a little with every reading).
      expect(johns.header.generatedAt.date, LocalDate(2026, 11, 2));
      expect(johns.header.generatedAt.timeOfDay.inHours, 23);
    });

    test('can be for one employee', () async {
      final amina = await hired('E0002', 'Amina', 'Odhiambo');
      await shift(john, 5, 8, 16);
      await shift(amina, 6, 8, 12);
      (await env.payroll.calculate(admin, october.id)).unwrap();

      final payslips = (await env.reports.payslips(
        admin,
        october.id,
        employeeId: amina.id,
      )).unwrap();

      expect(payslips.single.employee.name, 'Amina Odhiambo');
      expect(payslips.single.line.net, const Money(200000, 'KES'));
    });

    test('need a calculation', () async {
      final result = await env.reports.payslips(admin, october.id);

      expect(ruleOf(result), ReportService.notCalculatedRule);
    });

    test('for someone not paid in the period are refused', () async {
      final amina = await hired('E0002', 'Amina', 'Odhiambo');
      await shift(john, 5, 8, 16);
      (await env.payroll.calculate(admin, october.id)).unwrap();

      final result = await env.reports.payslips(
        admin,
        october.id,
        employeeId: amina.id,
      );

      expect(ruleOf(result), ReportService.nothingToPrintRule);
    });
  });

  test('the payroll summary lists everyone with totals', () async {
    final amina = await hired('E0002', 'Amina', 'Odhiambo');
    await shift(john, 5, 8, 16);
    await shift(amina, 6, 8, 12);
    (await env.payroll.calculate(admin, october.id)).unwrap();

    final summary = (await env.reports.payrollSummary(
      admin,
      october.id,
    )).unwrap();

    expect(summary.lines.map((l) => l.employee.number), ['E0002', 'E0001']);
    expect(summary.result.totals.single.net, const Money(600000, 'KES'));
    expect(summary.period.name, 'October 2026');
  });

  group('attendance', () {
    test(
      'a report longer than the on-screen limit covers every date',
      () async {
        await shift(john, 5, 8, 16);
        final from = LocalDate(2026, 8, 1);
        final to = LocalDate(2026, 10, 31);

        final report = (await env.reports.attendanceReport(
          admin,
          from: from,
          to: to,
        )).unwrap();

        final rows = report.groups.single.rows;
        expect(rows, hasLength(92));
        expect(rows.first.date, from);
        expect(rows.last.date, to);
        for (final (i, row) in rows.indexed) {
          expect(row.date, from.addDays(i));
        }
        expect(report.groups.single.totals.present, 1);
        expect(report.groups.single.totals.payable, const Duration(hours: 8));
        final worked = rows.singleWhere((r) => r.sessions.isNotEmpty);
        expect(worked.date, LocalDate(2026, 10, 5));
        expect(worked.status, DayStatus.present);
        // Wall-clock times on the company's clock.
        expect(
          worked.sessions.single.start.timeOfDay,
          const Duration(hours: 8),
        );
        expect(
          worked.sessions.single.end!.timeOfDay,
          const Duration(hours: 16),
        );
      },
    );

    test('ranges are checked', () async {
      final reversed = await env.reports.attendanceReport(
        admin,
        from: LocalDate(2026, 10, 31),
        to: LocalDate(2026, 10, 1),
      );
      final tooLong = await env.reports.attendanceReport(
        admin,
        from: LocalDate(2025, 1, 1),
        to: LocalDate(2025, 1, 1).addDays(ReportService.maxReportDays),
      );

      expect(reversed.failureOrNull, isA<ValidationFailure>());
      expect(tooLong.failureOrNull, isA<ValidationFailure>());
    });

    test('a timesheet holds one employee', () async {
      final amina = await hired('E0002', 'Amina', 'Odhiambo');
      await shift(john, 5, 8, 16);
      await shift(amina, 5, 9, 17);

      final sheet = (await env.reports.timesheet(
        admin,
        amina.id,
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 7),
      )).unwrap();

      expect(sheet.groups.single.employee.name, 'Amina Odhiambo');
      expect(sheet.groups.single.rows, hasLength(7));
    });

    test('a timesheet with nothing to show is refused', () async {
      final archived = await hired('E0003', 'Esther', 'Wanjiru');
      await env.management.changeStatus(
        admin,
        (await env.management.get(admin, archived.id)).unwrap(),
        EmploymentStatus.archived,
      );

      final result = await env.reports.timesheet(
        admin,
        archived.id,
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 7),
      );

      expect(ruleOf(result), ReportService.nothingToPrintRule);
    });
  });

  test('the exception report lists only what needs a decision', () async {
    final amina = await hired('E0002', 'Amina', 'Odhiambo');
    // John forgot to clock out; Amina's day is complete.
    await entry(john, AttendanceEventType.clockIn, 6, 8);
    await shift(amina, 6, 8, 16);

    final report = (await env.reports.exceptionReport(
      admin,
      from: LocalDate(2026, 10, 1),
      to: LocalDate(2026, 10, 31),
    )).unwrap();

    final row = report.rows.single;
    expect(row.employee.name, 'John Kamau');
    expect(row.type, AttendanceIssueType.missingClockOut);
    expect(row.blocksPayroll, isTrue);
    expect(row.at.date, LocalDate(2026, 10, 6));
    expect(row.at.timeOfDay, const Duration(hours: 8));
  });
}
