import 'dart:math';

import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_calculator.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payroll is the part of the product that must be right to the cent, so on
/// top of the worked examples it is checked on thousands of random months
/// against rules that must always hold, and against an independent exact
/// calculation. The random source is seeded: a failure is reproducible.
void main() {
  const calculator = PayrollCalculator();
  const kes = 'KES';
  final firstOfMonth = LocalDate(2026, 10, 1);
  final lastOfMonth = LocalDate(2026, 10, 31);

  Employee employee(String id) {
    final now = DateTime.utc(2026);
    return Employee(
      id: id,
      companyId: 'co',
      details: EmployeeDetails(
        employeeNumber: id,
        firstName: 'Emp',
        lastName: id,
        employmentStartDate: LocalDate(2020, 1, 1),
      ),
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  EmployeeRate hourly(String employeeId, int minor) {
    final now = DateTime.utc(2026);
    return EmployeeRate(
      id: 'rate-$employeeId',
      employeeId: employeeId,
      rateType: RateType.hourly,
      amountMinor: minor,
      currencyCode: kes,
      effectiveFrom: LocalDate(2020, 1, 1),
      effectiveTo: null,
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  PayrollAdjustment adjustment(
    String employeeId,
    AdjustmentType type,
    int minor,
    int n,
  ) => PayrollAdjustment(
    id: 'adj-$employeeId-$n',
    periodId: 'p',
    employeeId: employeeId,
    type: type,
    amount: Money(minor, kes),
    description: 'Adjustment $n',
    createdBy: 'admin',
    createdAt: DateTime.utc(2026, 10, 1),
  );

  /// A random month for one employee, with its input, and the seconds of
  /// work in it.
  ({EmployeePayInput input, int seconds, int rate}) randomEmployee(
    Random random,
    String id,
  ) {
    final rate = 1 + random.nextInt(250000);
    final days = <LocalDate, DayWork>{};
    var seconds = 0;
    for (var d = 1; d <= 31; d++) {
      if (random.nextInt(3) == 0) {
        continue;
      }
      // Odd seconds, so rounding is exercised and not just whole hours.
      final worked = random.nextInt(14 * 3600);
      seconds += worked;
      days[LocalDate(2026, 10, d)] = DayWork(
        payable: Duration(seconds: worked),
      );
    }
    return (
      input: EmployeePayInput(
        employee: employee(id),
        rates: [hourly(id, rate)],
        days: days,
        adjustments: [
          for (var i = 0; i < random.nextInt(4); i++)
            adjustment(
              id,
              AdjustmentType.values[random.nextInt(
                AdjustmentType.values.length,
              )],
              1 + random.nextInt(500000),
              i,
            ),
        ],
      ),
      seconds: seconds,
      rate: rate,
    );
  }

  PayrollResult run(
    List<EmployeePayInput> employees, {
    PayrollSettings settings = const PayrollSettings(),
  }) => calculator.calculate(
    PayrollInput(
      from: firstOfMonth,
      to: lastOfMonth,
      currency: kes,
      settings: settings,
      employees: employees,
    ),
  );

  /// Exact rounding half away from zero of `numerator / denominator`.
  int roundedDivision(BigInt numerator, BigInt denominator) {
    final twice = numerator * BigInt.two + denominator;
    return (twice ~/ (denominator * BigInt.two)).toInt();
  }

  test('without overtime, pay is hours times rate, rounded once', () {
    final random = Random(20261012);
    for (var round = 0; round < 500; round++) {
      final e = randomEmployee(random, 'emp');
      final noAdjustments = EmployeePayInput(
        employee: e.input.employee,
        rates: e.input.rates,
        days: e.input.days,
        adjustments: const [],
      );

      final line = run([noAdjustments]).lines.single;

      final expected = roundedDivision(
        BigInt.from(e.seconds) * BigInt.from(e.rate),
        BigInt.from(3600),
      );
      expect(line.regularPay.minorUnits, expected, reason: 'round $round');
      expect(line.overtimeHours, Duration.zero);
      expect(line.regularHours.inSeconds, e.seconds);
      expect(line.net.minorUnits, expected);
    }
  });

  test('with daily overtime, every second is paid exactly once', () {
    final random = Random(20261013);
    for (var round = 0; round < 500; round++) {
      final e = randomEmployee(random, 'emp');
      final limit = Duration(hours: 4 + random.nextInt(6));
      final percent = 100 + random.nextInt(301);
      final settings = PayrollSettings(
        dailyOvertimeAfter: limit,
        overtimePercent: percent,
      );

      final line = run([e.input], settings: settings).lines.single;

      // No time is lost or invented between regular and overtime.
      expect(
        line.regularHours.inSeconds + line.overtimeHours.inSeconds,
        e.seconds,
        reason: 'round $round',
      );
      var overtime = 0;
      for (final day in e.input.days.values) {
        overtime += max(0, day.payable.inSeconds - limit.inSeconds);
      }
      expect(line.overtimeHours.inSeconds, overtime, reason: 'round $round');
      // Pay follows from the hours and the rate, to the cent.
      expect(
        line.regularPay.minorUnits,
        roundedDivision(
          BigInt.from(e.seconds - overtime) * BigInt.from(e.rate),
          BigInt.from(3600),
        ),
        reason: 'regular, round $round',
      );
      expect(
        line.overtimePay.minorUnits,
        roundedDivision(
          BigInt.from(overtime) * BigInt.from(e.rate) * BigInt.from(percent),
          BigInt.from(3600 * 100),
        ),
        reason: 'overtime, round $round',
      );
    }
  });

  test('the totals always add up', () {
    final random = Random(20261014);
    for (var round = 0; round < 300; round++) {
      final employees = [
        for (var i = 0; i < 1 + random.nextInt(8); i++)
          randomEmployee(random, 'emp-$i').input,
      ];
      final settings = PayrollSettings(
        dailyOvertimeAfter: random.nextBool()
            ? Duration(hours: 5 + random.nextInt(5))
            : null,
        weeklyOvertimeAfter: random.nextBool()
            ? Duration(hours: 30 + random.nextInt(20))
            : null,
        overtimePercent: 100 + random.nextInt(301),
      );

      final result = run(employees, settings: settings);

      for (final line in result.lines) {
        // Gross is what is earned; net is what is left after deductions.
        expect(
          line.gross,
          line.regularPay + line.overtimePay + line.allowances + line.bonuses,
        );
        expect(line.net, line.gross - line.deductions);
        // The itemised lines are the figures, nothing more or less.
        expect(
          Money.sum(kes, [
            for (final i in line.items)
              if (!i.kind.isDeduction) i.amount,
          ]),
          line.gross,
        );
        expect(line.regularPay.isNegative, isFalse);
        expect(line.overtimePay.isNegative, isFalse);
        expect(line.items.every((i) => i.amount.minorUnits > 0), isTrue);
      }
      // The company's totals are the sum of its people, with no rounding of
      // their own.
      for (final totals in result.totals) {
        expect(totals.net, Money.sum(kes, totals.lines.map((l) => l.net)));
        expect(totals.gross, Money.sum(kes, totals.lines.map((l) => l.gross)));
      }
    }
  });

  test('the same input always gives the same pay, in any order', () {
    final random = Random(20261015);
    for (var round = 0; round < 100; round++) {
      final employees = [
        for (var i = 0; i < 2 + random.nextInt(6); i++)
          randomEmployee(random, 'emp-$i').input,
      ];
      const settings = PayrollSettings(
        dailyOvertimeAfter: Duration(hours: 8),
        weeklyOvertimeAfter: Duration(hours: 40),
      );

      final first = run(employees, settings: settings).fingerprint;
      final again = run(employees, settings: settings).fingerprint;
      final shuffled = run(
        [...employees]..shuffle(random),
        settings: settings,
      ).fingerprint;

      expect(again, first, reason: 'round $round');
      expect(shuffled, first, reason: 'round $round');
    }
  });

  test('a person with no work is not paid, however many rates they have', () {
    final random = Random(20261016);
    for (var round = 0; round < 50; round++) {
      final id = 'emp-$round';
      final input = EmployeePayInput(
        employee: employee(id),
        rates: [hourly(id, 1 + random.nextInt(100000))],
        days: const {},
        adjustments: const [],
      );

      final result = run([input]);

      expect(result.lines.every((l) => l.net.isZero), isTrue);
    }
  });
}
