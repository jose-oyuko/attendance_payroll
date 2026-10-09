import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/data/drift_payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_service.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;
  Money ksh(int minor) => Money(minor, 'KES');
  final october = NewPayrollPeriod(
    name: 'October 2026',
    startDate: LocalDate(2026, 10, 1),
    endDate: LocalDate(2026, 10, 31),
  );

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    john = await env.addEmployee(admin);
    await env.management.addRate(
      admin,
      john.id,
      NewEmployeeRate(
        rateType: RateType.hourly,
        amountMinor: 50000,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 1, 1),
      ),
    );
    await env.payroll.updateSettings(
      admin,
      const PayrollSettings(dailyOvertimeAfter: Duration(hours: 8)),
      expectedVersion: 0,
    );
    // Payroll is run in November.
    env.clock.jumpTo(nairobiTime(31, 23, 0).add(const Duration(days: 2)));
  });

  Future<void> worked(int day, (int, int) from, (int, int) to) async {
    for (final (type, (h, m)) in [
      (AttendanceEventType.clockIn, from),
      (AttendanceEventType.clockOut, to),
    ]) {
      (await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: type,
        occurredAt: nairobiTime(day, h, m),
        reason: 'Paper register',
      )).unwrap();
    }
  }

  Future<PayrollPeriod> period() async =>
      (await env.payroll.createPeriod(admin, october)).unwrap();

  test('attendance to payroll: hours, overtime, adjustments', () async {
    await worked(5, (8, 0), (18, 0)); // 10 h: 8 regular + 2 overtime
    await worked(6, (8, 0), (16, 0)); // 8 h
    final p = await period();

    final first = (await env.payroll.calculate(admin, p.id)).unwrap();
    final line = first.result.lines.single;
    expect(line.employeeId, john.id);
    expect(line.regularHours, const Duration(hours: 16));
    expect(line.overtimeHours, const Duration(hours: 2));
    expect(line.regularPay, ksh(800000));
    expect(line.overtimePay, ksh(150000), reason: '2 h × 750');
    expect(line.gross, ksh(950000));
    expect(first.result.issues, isEmpty);

    await env.payroll.addAdjustment(
      admin,
      p.id,
      NewPayrollAdjustment(
        employeeId: john.id,
        type: AdjustmentType.allowance,
        amount: ksh(100000),
        description: 'Transport',
      ),
    );
    final second = (await env.payroll.calculate(admin, p.id)).unwrap();

    expect(second.result.lines.single.net, ksh(1050000));
    expect(
      await env.auditActions(),
      containsAllInOrder([
        'payroll.period_created',
        'payroll.calculated',
        'payroll.adjustment_added',
        'payroll.recalculated',
      ]),
    );
    final runs = await env.db.select(env.db.payrollRuns).get();
    expect(runs.map((r) => r.status).toSet(), {'superseded', 'calculated'});
  });

  test(
    'a stored run is a snapshot: later changes need a recalculation',
    () async {
      await worked(5, (8, 0), (16, 0));
      final p = await period();
      await env.payroll.calculate(admin, p.id);

      await env.management.addRate(
        admin,
        john.id,
        NewEmployeeRate(
          rateType: RateType.hourly,
          amountMinor: 90000,
          currencyCode: 'KES',
          effectiveFrom: LocalDate(2026, 10, 1),
        ),
      );

      final stored = (await env.payroll.currentRun(admin, p.id)).unwrap()!;
      expect(stored.result.lines.single.gross, ksh(400000));
      final item = stored.result.lines.single.items.single;
      expect(item.rate, ksh(50000));
      expect(item.hours, const Duration(hours: 8));
      expect(item.rateType, RateType.hourly);

      final recalculated = (await env.payroll.calculate(admin, p.id)).unwrap();
      expect(recalculated.result.lines.single.gross, ksh(720000));
    },
  );

  test(
    'attendance awaiting review is reported and paid once accepted',
    () async {
      await worked(5, (8, 0), (23, 30)); // flagged: unusually long
      final p = await period();

      final blocked = (await env.payroll.calculate(admin, p.id)).unwrap();
      expect(
        blocked.result.issues.single.code,
        PayrollIssueCode.attendanceAwaitingReview,
      );
      expect(blocked.result.hasBlockingIssues, isTrue);
      expect(blocked.result.lines.single.gross, ksh(0));

      final exception = (await env.exceptions.list(
        admin,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 5),
      )).unwrap().single;
      await env.exceptions.decide(
        admin,
        exception,
        decision: ReviewDecision.resolved,
        reason: 'Stocktaking',
      );

      final paid = (await env.payroll.calculate(admin, p.id)).unwrap();
      expect(paid.result.issues, isEmpty);
      // 15.5 h: 8 regular + 7.5 overtime.
      expect(paid.result.lines.single.regularPay, ksh(400000));
      expect(paid.result.lines.single.overtimePay, ksh(562500));
      expect(
        (await env.attendance.timeline(
          admin,
          john.id,
          from: LocalDate(2026, 10, 5),
          to: LocalDate(2026, 10, 5),
        )).unwrap().sessions.single.status,
        SessionStatus.approved,
      );
    },
  );

  group('periods', () {
    test('may not overlap', () async {
      await period();

      final overlap = await env.payroll.createPeriod(
        admin,
        NewPayrollPeriod(
          name: 'Late October',
          startDate: LocalDate(2026, 10, 25),
          endDate: LocalDate(2026, 11, 24),
        ),
      );
      final next = await env.payroll.createPeriod(
        admin,
        NewPayrollPeriod(
          name: 'November 2026',
          startDate: LocalDate(2026, 11, 1),
          endDate: LocalDate(2026, 11, 30),
        ),
      );

      expect(
        (overlap.failureOrNull! as BusinessRuleFailure).rule,
        PayrollPeriodRules.overlap,
      );
      expect(next.isOk, isTrue);
      expect((await env.payroll.periods(admin)).unwrap().map((p) => p.name), [
        'November 2026',
        'October 2026',
      ]);
    });

    test('are validated', () async {
      final reversed = await env.payroll.createPeriod(
        admin,
        NewPayrollPeriod(
          name: 'Backwards',
          startDate: LocalDate(2026, 10, 31),
          endDate: LocalDate(2026, 10, 1),
        ),
      );
      final tooLong = await env.payroll.createPeriod(
        admin,
        NewPayrollPeriod(
          name: 'Quarter',
          startDate: LocalDate(2026, 10, 1),
          endDate: LocalDate(2026, 12, 31),
        ),
      );

      expect((reversed.failureOrNull! as ValidationFailure).field, 'endDate');
      expect((tooLong.failureOrNull! as ValidationFailure).field, 'endDate');
    });

    test("another company's period is not visible", () async {
      final other = (await env.companies.create(
        const CompanyDetails(
          name: 'Other',
          currencyCode: 'KES',
          timezone: 'UTC',
        ),
      )).unwrap();
      final theirs = (await DriftPayrollPeriodRepository(
        env.db,
      ).create(other.id, october)).unwrap();

      final result = await env.payroll.calculate(admin, theirs.id);

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('approved or finalized payroll cannot change', () async {
      final p = await period();
      await (env.db.update(
        env.db.payrollPeriods,
      )..where((row) => row.id.equals(p.id))).write(
        PayrollPeriodsCompanion(
          status: Value(PayrollPeriodStatus.finalized.name),
        ),
      );

      final calc = await env.payroll.calculate(admin, p.id);
      final adjust = await env.payroll.addAdjustment(
        admin,
        p.id,
        NewPayrollAdjustment(
          employeeId: john.id,
          type: AdjustmentType.bonus,
          amount: ksh(100),
          description: 'Late bonus',
        ),
      );

      for (final failure in [calc.failureOrNull, adjust.failureOrNull]) {
        expect(
          (failure! as BusinessRuleFailure).rule,
          PayrollService.lockedRule,
        );
      }
    });
  });

  group('adjustments', () {
    test('must be in the company currency and for its employees', () async {
      final p = await period();
      final dollars = await env.payroll.addAdjustment(
        admin,
        p.id,
        NewPayrollAdjustment(
          employeeId: john.id,
          type: AdjustmentType.bonus,
          amount: const Money(1000, 'USD'),
          description: 'Bonus',
        ),
      );
      final nobody = await env.payroll.addAdjustment(
        admin,
        p.id,
        NewPayrollAdjustment(
          employeeId: 'nobody',
          type: AdjustmentType.bonus,
          amount: ksh(1000),
          description: 'Bonus',
        ),
      );

      expect(dollars.failureOrNull, isA<ValidationFailure>());
      expect(nobody.failureOrNull, isA<NotFoundFailure>());
    });

    test('can be removed, which is audited', () async {
      final p = await period();
      final added = (await env.payroll.addAdjustment(
        admin,
        p.id,
        NewPayrollAdjustment(
          employeeId: john.id,
          type: AdjustmentType.deduction,
          amount: ksh(5000),
          description: 'Uniform',
        ),
      )).unwrap();

      await env.payroll.removeAdjustment(admin, added.id);

      expect((await env.payroll.adjustments(admin, p.id)).unwrap(), isEmpty);
      expect(await env.auditActions(), contains('payroll.adjustment_removed'));
    });
  });

  test('settings are versioned and validated', () async {
    final stored = (await env.payroll.settings(admin)).unwrap();
    expect(stored.version, 1);
    expect(stored.settings.dailyOvertimeAfter, const Duration(hours: 8));

    final stale = await env.payroll.updateSettings(
      admin,
      const PayrollSettings(),
      expectedVersion: 0,
    );
    final invalid = await env.payroll.updateSettings(
      admin,
      const PayrollSettings(overtimePercent: 90),
      expectedVersion: 1,
    );

    expect(stale.failureOrNull, isA<ConflictFailure>());
    expect(invalid.failureOrNull, isA<ValidationFailure>());
  });
}
