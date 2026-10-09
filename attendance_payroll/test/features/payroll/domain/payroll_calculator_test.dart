import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_calculator.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';
import 'package:flutter_test/flutter_test.dart';

const _kes = 'KES';
const _calculator = PayrollCalculator();
const _h = Duration.new;

Money ksh(int minor) => Money(minor, _kes);

Employee employee({
  String id = 'emp-1',
  String first = 'John',
  LocalDate? start,
  LocalDate? end,
}) {
  final now = DateTime.utc(2026);
  return Employee(
    id: id,
    companyId: 'co',
    details: EmployeeDetails(
      employeeNumber: id,
      firstName: first,
      lastName: 'Kamau',
      employmentStartDate: start ?? LocalDate(2020, 1, 1),
      employmentEndDate: end,
    ),
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

EmployeeRate rate(
  int amountMinor, {
  RateType type = RateType.hourly,
  LocalDate? from,
  LocalDate? to,
  String currency = _kes,
  String id = 'rate-1',
}) {
  final now = DateTime.utc(2026);
  return EmployeeRate(
    id: id,
    employeeId: 'emp-1',
    rateType: type,
    amountMinor: amountMinor,
    currencyCode: currency,
    effectiveFrom: from ?? LocalDate(2020, 1, 1),
    effectiveTo: to,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

PayrollAdjustment adjustment(AdjustmentType type, int minor, String what) {
  return PayrollAdjustment(
    id: 'adj-$what',
    periodId: 'p',
    employeeId: 'emp-1',
    type: type,
    amount: ksh(minor),
    description: what,
    createdBy: 'admin',
    createdAt: DateTime.utc(2026, 10, 1),
  );
}

LocalDate oct(int day) => LocalDate(2026, 10, day);

PayrollResult calculate(
  List<EmployeePayInput> employees, {
  PayrollSettings settings = const PayrollSettings(),
  LocalDate? from,
  LocalDate? to,
}) {
  return _calculator.calculate(
    PayrollInput(
      from: from ?? oct(1),
      to: to ?? oct(31),
      currency: _kes,
      settings: settings,
      employees: employees,
    ),
  );
}

EmployeePayInput john({
  required Map<LocalDate, DayWork> days,
  List<EmployeeRate>? rates,
  List<PayrollAdjustment> adjustments = const [],
  Employee? who,
}) {
  return EmployeePayInput(
    employee: who ?? employee(),
    rates: rates ?? [rate(50000)],
    days: days,
    adjustments: adjustments,
  );
}

Map<LocalDate, DayWork> worked(Map<LocalDate, Duration> hours) => {
  for (final MapEntry(:key, :value) in hours.entries)
    key: DayWork(payable: value),
};

void main() {
  group('the spec example (§36)', () {
    // 18 days of 8 h, 4 days of 10 h (2 h overtime each), and one 30-minute
    // day: 176.5 h regular, 8 h overtime, with an 8-hour daily limit.
    final days = worked({
      for (var d = 1; d <= 18; d++) oct(d): _h(hours: 8),
      for (var d = 19; d <= 22; d++) oct(d): _h(hours: 10),
      oct(23): _h(minutes: 30),
    });
    const settings = PayrollSettings(dailyOvertimeAfter: Duration(hours: 8));

    test('regular, overtime and gross pay are exact', () {
      final line = calculate([
        john(days: days),
      ], settings: settings).lines.single;

      expect(line.regularHours, _h(hours: 176, minutes: 30));
      expect(line.overtimeHours, _h(hours: 8));
      expect(line.regularPay, ksh(8825000), reason: '176.5 × 500');
      expect(line.overtimePay, ksh(600000), reason: '8 × 750');
      expect(line.gross, ksh(9425000));
      expect(line.net, ksh(9425000));

      final overtime = line.items.singleWhere(
        (i) => i.kind == PayrollItemKind.overtimePay,
      );
      expect(overtime.percent, 150);
      expect(overtime.rate, ksh(50000));
      expect(overtime.hours, _h(hours: 8));
    });

    test('allowances and bonuses add, deductions subtract', () {
      final line = calculate([
        john(
          days: days,
          adjustments: [
            adjustment(AdjustmentType.allowance, 200000, 'Transport'),
            adjustment(AdjustmentType.bonus, 100000, 'Target bonus'),
            adjustment(AdjustmentType.deduction, 50000, 'Salary advance'),
          ],
        ),
      ], settings: settings).lines.single;

      expect(line.allowances, ksh(200000));
      expect(line.bonuses, ksh(100000));
      expect(line.deductions, ksh(50000));
      expect(line.gross, ksh(9725000));
      expect(line.net, ksh(9675000));
      expect(
        line.items.map((i) => i.description),
        containsAll(['Transport', 'Target bonus', 'Salary advance']),
      );
    });
  });

  group('rates', () {
    test('each day is paid at the rate in force that day', () {
      final line = calculate(
        [
          john(
            days: worked({
              LocalDate(2026, 6, 29): _h(hours: 8),
              LocalDate(2026, 6, 30): _h(hours: 8),
              LocalDate(2026, 7, 1): _h(hours: 8),
            }),
            rates: [
              rate(40000, to: LocalDate(2026, 6, 30)),
              rate(50000, id: 'rate-2', from: LocalDate(2026, 7, 1)),
            ],
          ),
        ],
        from: LocalDate(2026, 6, 25),
        to: LocalDate(2026, 7, 5),
      ).lines.single;

      final regular = line.items
          .where((i) => i.kind == PayrollItemKind.regularPay)
          .toList();
      expect(regular.map((i) => i.rate), [ksh(40000), ksh(50000)]);
      expect(regular.map((i) => i.amount), [ksh(640000), ksh(400000)]);
      expect(line.regularPay, ksh(1040000));
    });

    test('time without a rate is unpaid and blocks finalization', () {
      final result = calculate([
        john(
          days: worked({oct(1): _h(hours: 8), oct(20): _h(hours: 8)}),
          rates: [rate(50000, from: oct(15))],
        ),
      ]);

      expect(result.lines.single.regularPay, ksh(400000));
      expect(result.issues.single.code, PayrollIssueCode.missingRate);
      expect(result.hasBlockingIssues, isTrue);
    });

    test('a rate in another currency is not paid', () {
      final result = calculate([
        john(
          days: worked({oct(1): _h(hours: 8)}),
          rates: [rate(5000, currency: 'USD')],
        ),
      ]);

      expect(result.issues.single.code, PayrollIssueCode.currencyMismatch);
      expect(result.lines.single.gross, ksh(0));
    });

    test('daily rates pay per day worked; overtime by the standard day', () {
      final line = calculate(
        [
          john(
            days: worked({
              oct(1): _h(hours: 8),
              oct(2): _h(hours: 10),
              oct(3): _h(hours: 4),
            }),
            rates: [rate(200000, type: RateType.daily)],
          ),
        ],
        settings: const PayrollSettings(dailyOvertimeAfter: Duration(hours: 8)),
      ).lines.single;

      expect(line.regularPay, ksh(600000), reason: '3 days × 2,000');
      // 2 h × (2,000 ÷ 8 h) × 150% = 750.
      expect(line.overtimePay, ksh(75000));
    });

    group('monthly salaries', () {
      final salary = rate(6000000, type: RateType.monthly);

      test('a full month pays the salary, worked or not', () {
        final line = calculate([
          john(days: const {}, rates: [salary]),
        ]).lines.single;

        expect(line.regularPay, ksh(6000000));
        expect(line.items.single.days, 31);
      });

      test('a mid-month start is pro-rated by calendar days', () {
        final line = calculate([
          john(
            days: const {},
            rates: [salary],
            who: employee(start: oct(16)),
          ),
        ]).lines.single;

        // 60,000 × 16 ÷ 31 = 30,967.7419… → 30,967.74
        expect(line.regularPay, ksh(3096774));
        expect(line.items.single.description, 'Salary (16 of 31 days)');
      });

      test('a period across two months pays each month by its length', () {
        final line = calculate(
          [
            john(days: const {}, rates: [salary]),
          ],
          from: LocalDate(2026, 9, 16),
          to: oct(15),
        ).lines.single;

        final items = line.items.map((i) => i.description).toList();
        expect(items, ['Salary (15 of 30 days)', 'Salary (15 of 31 days)']);
        // 30,000.00 + 29,032.26
        expect(line.regularPay, ksh(3000000 + 2903226));
      });

      test('archived without an end date is flagged', () {
        final archived = employee();
        final result = calculate([
          john(
            days: const {},
            rates: [salary],
            who: Employee(
              id: archived.id,
              companyId: archived.companyId,
              details: archived.details.withStatus(EmploymentStatus.archived),
              createdAt: archived.createdAt,
              updatedAt: archived.updatedAt,
              version: archived.version,
            ),
          ),
        ]);

        expect(
          result.issues.single.code,
          PayrollIssueCode.archivedWithoutEndDate,
        );
        expect(result.hasBlockingIssues, isFalse);
      });

      test('employment ending stops the salary', () {
        final line = calculate([
          john(
            days: const {},
            rates: [salary],
            who: employee(end: oct(10)),
          ),
        ]).lines.single;

        expect(line.items.single.days, 10);
      });

      test('overtime uses salary × 12 ÷ 52 ÷ the standard week', () {
        final line = calculate(
          [
            john(days: worked({oct(1): _h(hours: 10)}), rates: [salary]),
          ],
          settings: const PayrollSettings(
            dailyOvertimeAfter: Duration(hours: 8),
          ),
        ).lines.single;

        // 2 h × (60,000 × 12 ÷ 52 ÷ 40) × 150% = 1,038.4615… → 1,038.46
        expect(line.overtimePay, ksh(103846));
      });
    });
  });

  group('overtime rules', () {
    test('there is no overtime until a threshold is set', () {
      final line = calculate([
        john(days: worked({oct(1): _h(hours: 14)})),
      ]).lines.single;

      expect(line.overtimeHours, Duration.zero);
      expect(line.regularHours, _h(hours: 14));
    });

    test('a weekly limit makes the week’s last hours overtime', () {
      // Mon 5 – Sat 10 October, 8 h a day: 48 h against 45.
      final line = calculate(
        [
          john(
            days: worked({for (var d = 5; d <= 10; d++) oct(d): _h(hours: 8)}),
          ),
        ],
        settings: const PayrollSettings(
          weeklyOvertimeAfter: Duration(hours: 45),
        ),
      ).lines.single;

      expect(line.regularHours, _h(hours: 45));
      expect(line.overtimeHours, _h(hours: 3));
    });

    test('daily and weekly limits never count the same hour twice', () {
      final split = PayrollCalculator.splitOvertime(
        worked({
          for (var d = 5; d <= 9; d++) oct(d): _h(hours: 9),
          oct(10): _h(hours: 4),
        }),
        const PayrollSettings(
          dailyOvertimeAfter: Duration(hours: 8),
          weeklyOvertimeAfter: Duration(hours: 40),
        ),
      );

      // Mon–Fri: 8 h regular + 1 h daily overtime each = 40 h regular.
      expect(split[oct(9)], (_h(hours: 8), _h(hours: 1)));
      // Saturday is all weekly overtime.
      expect(split[oct(10)], (Duration.zero, _h(hours: 4)));
    });

    test('a week spanning two periods is judged as one week', () {
      // Week of Mon 28 Sep: 24 h in September, then 10 h on 1 and 2 Oct.
      final line = calculate(
        [
          john(
            days: worked({
              LocalDate(2026, 9, 28): _h(hours: 8),
              LocalDate(2026, 9, 29): _h(hours: 8),
              LocalDate(2026, 9, 30): _h(hours: 8),
              oct(1): _h(hours: 10),
              oct(2): _h(hours: 10),
            }),
          ),
        ],
        settings: const PayrollSettings(
          weeklyOvertimeAfter: Duration(hours: 40),
        ),
      ).lines.single;

      // October pays only 1–2 Oct: 16 h regular, 4 h overtime.
      expect(line.regularHours, _h(hours: 16));
      expect(line.overtimeHours, _h(hours: 4));
    });

    test('the percentage is configurable', () {
      final line = calculate(
        [
          john(days: worked({oct(1): _h(hours: 9)})),
        ],
        settings: const PayrollSettings(
          dailyOvertimeAfter: Duration(hours: 8),
          overtimePercent: 200,
        ),
      ).lines.single;

      expect(line.overtimePay, ksh(100000), reason: '1 h × 500 × 200%');
    });
  });

  group('rounding', () {
    test('each line is rounded once, half away from zero', () {
      // 1 minute at KES 0.30/hour is half a cent.
      final line = calculate([
        john(days: worked({oct(1): _h(minutes: 1)}), rates: [rate(30)]),
      ]).lines.single;

      expect(line.regularPay, ksh(1));
    });

    test('odd minutes are paid to the second, not rounded to hours', () {
      // 7 h 20 m at KES 333.33/hour = 2,444.42
      final line = calculate([
        john(
          days: worked({oct(1): _h(hours: 7, minutes: 20)}),
          rates: [rate(33333)],
        ),
      ]).lines.single;

      expect(line.regularPay, ksh(244442));
    });
  });

  group('validation', () {
    test('attendance awaiting review blocks; still clocked in warns', () {
      final result = calculate([
        john(
          days: {
            oct(1): const DayWork(payable: Duration(hours: 8)),
            oct(2): const DayWork(awaitingReview: 1),
            oct(3): const DayWork(stillOpen: 1),
          },
        ),
      ]);

      expect(result.issues.map((i) => (i.code, i.severity)), [
        (
          PayrollIssueCode.attendanceAwaitingReview,
          PayrollIssueSeverity.blocking,
        ),
        (PayrollIssueCode.stillClockedIn, PayrollIssueSeverity.warning),
      ]);
      expect(result.lines.single.regularPay, ksh(400000));
    });

    test('negative net pay is reported, never hidden', () {
      final result = calculate([
        john(
          days: worked({oct(1): _h(hours: 1)}),
          adjustments: [
            adjustment(AdjustmentType.deduction, 100000, 'Loan repayment'),
          ],
        ),
      ]);

      expect(result.lines.single.net, ksh(-50000));
      expect(result.issues.single.code, PayrollIssueCode.negativeNetPay);
    });

    test('employees with nothing to pay get no line', () {
      final result = calculate([john(days: const {})]);

      expect(result.lines, isEmpty);
      expect(result.issues, isEmpty);
    });
  });

  test('the same inputs always give the same result', () {
    List<EmployeePayInput> inputs() => [
      for (final id in ['emp-3', 'emp-1', 'emp-2'])
        EmployeePayInput(
          employee: employee(id: id),
          rates: [rate(50000)],
          days: worked({oct(1): _h(hours: 8), oct(2): _h(hours: 9)}),
        ),
    ];
    String describe(PayrollResult r) => [
      for (final l in r.lines) '${l.employeeId}:${l.gross}:${l.net}',
    ].join('|');

    final first = calculate(inputs());
    final second = calculate(inputs().reversed.toList());

    expect(describe(first), describe(second));
    expect(first.lines.map((l) => l.employeeId), ['emp-1', 'emp-2', 'emp-3']);
  });
}
