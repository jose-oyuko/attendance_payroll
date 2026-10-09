import 'dart:convert';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;
  final october = (from: LocalDate(2026, 10, 1), to: LocalDate(2026, 10, 31));

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    john = await env.addEmployee(admin);
    // The administrator works on 8 October.
    env.clock.jumpTo(nairobiTime(8, 9, 0));
  });

  Future<AttendanceEvent> entry(
    AttendanceEventType type,
    int day,
    int hour,
    int minute, {
    Employee? who,
  }) async {
    final correction = (await env.attendanceCorrections.addMissingEntry(
      admin,
      (who ?? john).id,
      type: type,
      occurredAt: nairobiTime(day, hour, minute),
      reason: 'Recorded from the paper register',
    )).unwrap();
    return (await env.events.getById(
      correction.replacementEventId!,
    )).unwrap().event;
  }

  Future<List<AttendanceException>> list() async => (await env.exceptions.list(
    admin,
    from: october.from,
    to: october.to,
  )).unwrap();

  Future<AttendanceException> only(AttendanceIssueType type) async =>
      (await list()).singleWhere((e) => e.type == type);

  Future<AttendanceSession> sessionOn(int day) async =>
      (await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, day),
        to: LocalDate(2026, 10, day),
      )).unwrap().sessions.single;

  String? ruleOf(AppFailure? failure) =>
      failure is BusinessRuleFailure ? failure.rule : null;

  test('flagged attendance is listed as open exceptions', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    await entry(AttendanceEventType.clockOut, 5, 23, 30);

    final exception = await only(AttendanceIssueType.excessiveDuration);

    expect(exception.status, ExceptionStatus.open);
    expect(exception.status.needsAction, isTrue);
    expect(exception.blocksPayroll, isTrue);
    expect(exception.employee.id, john.id);
    expect(exception.session!.status, SessionStatus.exception);
    expect(exception.stillDetected, isTrue);
  });

  test('a long day accepted as recorded becomes payable', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    await entry(AttendanceEventType.clockOut, 5, 23, 30);

    final review = (await env.exceptions.decide(
      admin,
      await only(AttendanceIssueType.excessiveDuration),
      decision: ReviewDecision.resolved,
      reason: 'Stocktaking ran late; confirmed by the supervisor.',
    )).unwrap();

    expect(review.reviewedBy, admin.admin.id);
    final exception = await only(AttendanceIssueType.excessiveDuration);
    expect(exception.status, ExceptionStatus.resolved);
    expect(exception.status.needsAction, isFalse);
    final session = await sessionOn(5);
    expect(session.status, SessionStatus.approved);
    expect(session.payableDuration, const Duration(hours: 15, minutes: 30));
    final day = (await env.attendance.day(
      admin,
      LocalDate(2026, 10, 5),
    )).unwrap();
    expect(day.employees.single.status, DayStatus.present);
    final audit = (await env.auditRows()).last;
    expect(audit.action, 'attendance.exception_reviewed');
    expect(jsonDecode(audit.metadata!), {
      'employeeId': john.id,
      'type': 'excessiveDuration',
      'decision': 'resolved',
    });
  });

  test('a missing clock-out must be corrected, not accepted', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    final missing = await only(AttendanceIssueType.missingClockOut);

    final accepted = await env.exceptions.decide(
      admin,
      missing,
      decision: ReviewDecision.resolved,
      reason: 'Probably worked a full day',
    );
    final dismissed = await env.exceptions.decide(
      admin,
      missing,
      decision: ReviewDecision.dismissed,
      reason: 'Not important',
    );

    expect(
      ruleOf(accepted.failureOrNull),
      AttendanceExceptionService.mustCorrectRule,
    );
    expect(
      ruleOf(dismissed.failureOrNull),
      AttendanceExceptionService.mustCorrectRule,
    );
  });

  test(
    'fixing it with a correction records the exception as resolved',
    () async {
      await entry(AttendanceEventType.clockIn, 5, 8, 0);
      final missing = await only(AttendanceIssueType.missingClockOut);

      final correction = (await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockOut,
        occurredAt: nairobiTime(5, 17, 0),
        reason: 'Forgot to clock out; left at 17:00.',
        resolves: missing.issue,
      )).unwrap();

      final settled = (await list()).single;
      expect(settled.issueKey, missing.issueKey);
      expect(settled.stillDetected, isFalse);
      expect(settled.status, ExceptionStatus.resolved);
      expect(settled.latestReview!.relatedCorrectionId, correction.id);
      expect(
        settled.latestReview!.reason,
        'Forgot to clock out; left at 17:00.',
      );
      expect((await sessionOn(5)).payableDuration, const Duration(hours: 9));
    },
  );

  test('a harmless duplicate can be dismissed, a long day cannot', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    await entry(AttendanceEventType.clockIn, 5, 8, 1);
    await entry(AttendanceEventType.clockOut, 5, 23, 30);

    final duplicate = await env.exceptions.decide(
      admin,
      await only(AttendanceIssueType.duplicateClockIn),
      decision: ReviewDecision.dismissed,
      reason: 'Double tap',
    );
    final longDay = await env.exceptions.decide(
      admin,
      await only(AttendanceIssueType.excessiveDuration),
      decision: ReviewDecision.dismissed,
      reason: 'Whatever',
    );

    expect(duplicate.isOk, isTrue);
    expect(
      (await only(AttendanceIssueType.duplicateClockIn)).status,
      ExceptionStatus.dismissed,
    );
    expect(
      ruleOf(longDay.failureOrNull),
      AttendanceExceptionService.decisionNotAllowedRule,
    );
  });

  test('a note keeps the exception open and blocking', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    await entry(AttendanceEventType.clockOut, 5, 23, 30);

    await env.exceptions.decide(
      admin,
      await only(AttendanceIssueType.excessiveDuration),
      decision: ReviewDecision.reviewed,
      reason: 'Asked the employee to confirm.',
    );

    final exception = await only(AttendanceIssueType.excessiveDuration);
    expect(exception.status, ExceptionStatus.reviewed);
    expect(exception.status.needsAction, isTrue);
    expect((await sessionOn(5)).status, SessionStatus.exception);
  });

  test('a decision about changed data is refused', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    final clockOut = await entry(AttendanceEventType.clockOut, 5, 23, 30);
    final before = await only(AttendanceIssueType.excessiveDuration);
    await env.attendanceCorrections.changeTime(
      admin,
      clockOut.id,
      newOccurredAt: nairobiTime(5, 17, 0),
      reason: 'Wrong time entered',
    );

    final result = await env.exceptions.decide(
      admin,
      before,
      decision: ReviewDecision.resolved,
      reason: 'Too late',
    );

    expect(result.failureOrNull, isA<ConflictFailure>());
    expect(await list(), isEmpty);
  });

  test('an acceptance does not carry over to corrected data', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    final clockOut = await entry(AttendanceEventType.clockOut, 5, 23, 30);
    await env.exceptions.decide(
      admin,
      await only(AttendanceIssueType.excessiveDuration),
      decision: ReviewDecision.resolved,
      reason: 'Approved',
    );

    // The clock-out is moved, still long: a different fact needs a new look.
    await env.attendanceCorrections.changeTime(
      admin,
      clockOut.id,
      newOccurredAt: nairobiTime(5, 22, 0),
      reason: 'Left at 22:00',
    );

    final current = (await list()).where((e) => e.stillDetected).single;
    expect(current.status, ExceptionStatus.open);
    expect((await sessionOn(5)).status, SessionStatus.exception);
  });

  test('decisions need a reason and the permission', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);
    await entry(AttendanceEventType.clockOut, 5, 23, 30);
    final exception = await only(AttendanceIssueType.excessiveDuration);
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
        version: admin.admin.version,
      ),
      signedInAt: admin.signedInAt,
    );

    final noReason = await env.exceptions.decide(
      admin,
      exception,
      decision: ReviewDecision.resolved,
      reason: ' ',
    );
    final noPermission = await env.exceptions.decide(
      deactivated,
      exception,
      decision: ReviewDecision.resolved,
      reason: 'Looks fine',
    );

    expect((noReason.failureOrNull! as ValidationFailure).field, 'reason');
    expect(noPermission.failureOrNull, isA<PermissionFailure>());
    expect(
      (await only(AttendanceIssueType.excessiveDuration)).status,
      ExceptionStatus.open,
    );
  });

  test("a correction cannot resolve another employee's exception", () async {
    final mary = await env.addEmployee(admin, employeeNumber: 'E0002');
    await entry(AttendanceEventType.clockIn, 5, 8, 0, who: mary);
    final marys = await only(AttendanceIssueType.missingClockOut);

    final result = await env.attendanceCorrections.addMissingEntry(
      admin,
      john.id,
      type: AttendanceEventType.clockOut,
      occurredAt: nairobiTime(5, 17, 0),
      reason: 'Wrong person',
      resolves: marys.issue,
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
    final johns = (await env.attendance.timeline(
      admin,
      john.id,
      from: october.from,
      to: october.to,
    )).unwrap();
    expect(johns.sessions, isEmpty, reason: 'the correction rolled back');
  });

  test('settled exceptions outside the range are not listed', () async {
    await entry(AttendanceEventType.clockIn, 5, 8, 0);

    final september = (await env.exceptions.list(
      admin,
      from: LocalDate(2026, 9, 1),
      to: LocalDate(2026, 9, 30),
    )).unwrap();

    expect(september, isEmpty);
  });
}
