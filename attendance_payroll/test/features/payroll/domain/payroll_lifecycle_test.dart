import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/locking/payroll_lock.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;
  late PayrollPeriod october;

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

  Future<AttendanceEvent> entry(
    AttendanceEventType type,
    int day,
    int hour,
  ) async {
    final correction = (await env.attendanceCorrections.addMissingEntry(
      admin,
      john.id,
      type: type,
      occurredAt: nairobiTime(day, hour, 0),
      reason: 'Paper register',
    )).unwrap();
    return (await env.events.getById(
      correction.replacementEventId!,
    )).unwrap().event;
  }

  Future<PayrollPeriodStatus> status() async =>
      (await env.payroll.period(admin, october.id)).unwrap().status;

  String? ruleOf(Result<Object?> result) {
    final failure = result.failureOrNull;
    return failure is BusinessRuleFailure ? failure.rule : null;
  }

  Future<void> finalizeOctober() async {
    (await env.payroll.calculate(admin, october.id)).unwrap();
    (await env.payroll.approve(admin, october.id)).unwrap();
    (await env.payroll.finalize(admin, october.id)).unwrap();
  }

  test('a full cycle: calculate, approve, finalize, with history', () async {
    await entry(AttendanceEventType.clockIn, 5, 8);
    await entry(AttendanceEventType.clockOut, 5, 16);
    expect(await status(), PayrollPeriodStatus.draft);

    await env.payroll.calculate(admin, october.id);
    expect(await status(), PayrollPeriodStatus.review);
    final approved = (await env.payroll.approve(admin, october.id)).unwrap();
    expect(approved.status, PayrollRunStatus.approved);
    expect(approved.approvedBy, admin.admin.id);
    expect(await status(), PayrollPeriodStatus.approved);
    final finalized = (await env.payroll.finalize(admin, october.id)).unwrap();

    expect(finalized.status, PayrollRunStatus.finalized);
    expect(finalized.finalizedAt, isNotNull);
    expect(finalized.result.lines.single.net, const Money(400000, 'KES'));
    expect(await status(), PayrollPeriodStatus.finalized);
    final history = (await env.payroll.history(admin, october.id)).unwrap();
    expect(history.map((h) => h.action), [
      'payroll.finalized',
      'payroll.approved',
      'payroll.calculated',
      'payroll.period_created',
    ]);
  });

  test('steps cannot be skipped', () async {
    expect(
      ruleOf(await env.payroll.approve(admin, october.id)),
      PayrollService.wrongStatusRule,
    );
    await env.payroll.calculate(admin, october.id);
    expect(
      ruleOf(await env.payroll.finalize(admin, october.id)),
      PayrollService.wrongStatusRule,
    );
  });

  test('blocking problems prevent approval', () async {
    await entry(AttendanceEventType.clockIn, 5, 8); // no clock-out
    await env.payroll.calculate(admin, october.id);

    expect(
      ruleOf(await env.payroll.approve(admin, october.id)),
      PayrollService.blockingIssuesRule,
    );
  });

  test(
    'a calculation that no longer matches the data cannot be approved',
    () async {
      await entry(AttendanceEventType.clockIn, 5, 8);
      await entry(AttendanceEventType.clockOut, 5, 16);
      await env.payroll.calculate(admin, october.id);
      // Attendance changes after the calculation.
      await entry(AttendanceEventType.clockIn, 6, 8);
      await entry(AttendanceEventType.clockOut, 6, 16);

      final stale = await env.payroll.approve(admin, october.id);
      expect(stale.failureOrNull, isA<ConflictFailure>());

      await env.payroll.calculate(admin, october.id);
      final approved = (await env.payroll.approve(admin, october.id)).unwrap();
      expect(approved.result.lines.single.net, const Money(800000, 'KES'));
    },
  );

  test('only a payroll approver may approve', () async {
    await env.payroll.calculate(admin, october.id);
    final deactivated = AdminSession(
      admin: AdminUser(
        id: admin.admin.id,
        companyId: admin.companyId,
        username: admin.admin.username,
        displayName: admin.admin.displayName,
        role: AdminRole.owner,
        active: false,
        lastLoginAt: null,
        createdAt: admin.admin.createdAt,
        updatedAt: admin.admin.updatedAt,
        version: 1,
      ),
      signedInAt: admin.signedInAt,
    );

    final result = await env.payroll.approve(deactivated, october.id);

    expect(result.failureOrNull, isA<PermissionFailure>());
  });

  group('finalized payroll is locked (§25)', () {
    late AttendanceEvent clockOut;

    setUp(() async {
      await entry(AttendanceEventType.clockIn, 5, 8);
      clockOut = await entry(AttendanceEventType.clockOut, 5, 16);
      await finalizeOctober();
    });

    test('attendance corrections are refused with the spec message', () async {
      final added = await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockIn,
        occurredAt: nairobiTime(7, 8, 0),
        reason: 'Forgot',
      );
      final changed = await env.attendanceCorrections.changeTime(
        admin,
        clockOut.id,
        newOccurredAt: nairobiTime(5, 17, 0),
        reason: 'Left later',
      );

      for (final result in [added, changed]) {
        expect(ruleOf(result), payrollLockedRule);
        expect(
          result.failureOrNull!.userMessage,
          contains('This change may affect a finalized payroll'),
        );
      }
    });

    test('a clock-out just after midnight still belongs to its day', () async {
      // 1 Nov 00:30 could close a session that started on 31 October.
      final result = await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockOut,
        occurredAt: nairobiTime(31, 0, 30).add(const Duration(days: 1)),
        reason: 'Night shift',
      );

      expect(ruleOf(result), payrollLockedRule);
    });

    test('later dates are not affected', () async {
      final november = await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockIn,
        occurredAt: nairobiTime(31, 8, 0).add(const Duration(days: 2)),
        reason: 'November shift',
      );

      expect(november.isOk, isTrue);
    });

    test('pay rates, adjustments and recalculation are refused', () async {
      final rate = await env.management.addRate(
        admin,
        john.id,
        NewEmployeeRate(
          rateType: RateType.hourly,
          amountMinor: 60000,
          currencyCode: 'KES',
          effectiveFrom: LocalDate(2026, 10, 20),
        ),
      );
      final adjustment = await env.payroll.addAdjustment(
        admin,
        october.id,
        NewPayrollAdjustment(
          employeeId: john.id,
          type: AdjustmentType.bonus,
          amount: const Money(100, 'KES'),
          description: 'Late bonus',
        ),
      );
      final recalculation = await env.payroll.calculate(admin, october.id);

      for (final result in [rate, adjustment, recalculation]) {
        expect(ruleOf(result), payrollLockedRule);
      }
    });

    test('a rate from after the period is allowed', () async {
      final rate = await env.management.addRate(
        admin,
        john.id,
        NewEmployeeRate(
          rateType: RateType.hourly,
          amountMinor: 60000,
          currencyCode: 'KES',
          effectiveFrom: LocalDate(2026, 11, 1),
        ),
      );

      expect(rate.isOk, isTrue);
    });
  });

  test(
    'accepting a pay-affecting exception is locked; a note is not',
    () async {
      await entry(AttendanceEventType.clockIn, 5, 8);
      await entry(AttendanceEventType.clockOut, 5, 23);
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
      await finalizeOctober();
      // The decision is final for October; a new exception on the same
      // session (here: a note on it) does not change pay.
      final current = (await env.exceptions.list(
        admin,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 5),
      )).unwrap().single;

      final note = await env.exceptions.decide(
        admin,
        current,
        decision: ReviewDecision.reviewed,
        reason: 'Checked during audit',
      );
      final again = await env.exceptions.decide(
        admin,
        current,
        decision: ReviewDecision.resolved,
        reason: 'Re-approve',
      );

      expect(note.isOk, isTrue);
      expect(ruleOf(again), payrollLockedRule);
    },
  );

  group('reopening', () {
    test('needs a reason', () async {
      await finalizeOctober();

      final result = await env.payroll.reopen(admin, october.id, reason: ' ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await status(), PayrollPeriodStatus.finalized);
    });

    test('a finalized run is kept; the next calculation replaces it', () async {
      await entry(AttendanceEventType.clockIn, 5, 8);
      await entry(AttendanceEventType.clockOut, 5, 16);
      await finalizeOctober();

      (await env.payroll.reopen(
        admin,
        october.id,
        reason: 'Missed overtime for 7 October',
      )).unwrap();
      expect(await status(), PayrollPeriodStatus.reopened);
      // Changes are allowed again.
      await entry(AttendanceEventType.clockIn, 7, 8);
      await entry(AttendanceEventType.clockOut, 7, 16);
      final recalculated = (await env.payroll.calculate(
        admin,
        october.id,
      )).unwrap();

      expect(recalculated.result.lines.single.net, const Money(800000, 'KES'));
      expect(await status(), PayrollPeriodStatus.review);
      final runs = await env.db.select(env.db.payrollRuns).get();
      expect(runs.map((r) => r.status).toList()..sort(), [
        'calculated',
        'finalized',
      ]);
      final history = (await env.payroll.history(admin, october.id)).unwrap();
      final reopened = history.firstWhere(
        (h) => h.action == 'payroll.reopened',
      );
      expect(reopened.metadata, {
        'from': 'finalized',
        'reason': 'Missed overtime for 7 October',
      });
    });

    test('reopening an approval returns it to review', () async {
      await env.payroll.calculate(admin, october.id);
      await env.payroll.approve(admin, october.id);

      await env.payroll.reopen(admin, october.id, reason: 'Wrong bonus');

      expect(await status(), PayrollPeriodStatus.review);
      final run = (await env.payroll.currentRun(admin, october.id)).unwrap()!;
      expect(run.status, PayrollRunStatus.calculated);
      expect(run.approvedBy, isNull);
    });
  });
}
