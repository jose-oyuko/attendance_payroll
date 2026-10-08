import 'dart:convert';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    john = await env.addEmployee(admin);
  });

  const tenHourShifts = AttendancePolicy(
    excessiveDurationAfter: Duration(hours: 8),
    automaticBreak: AutomaticBreak(
      after: Duration(hours: 6),
      deduct: Duration(minutes: 30),
    ),
  );

  test('a company starts with the defaults', () async {
    final stored = (await env.attendanceSettingsService.get(admin)).unwrap();

    expect(stored.isDefault, isTrue);
    expect(
      stored.policy.excessiveDurationAfter,
      const AttendancePolicy().excessiveDurationAfter,
    );
  });

  test('saved settings are kept, versioned and audited', () async {
    final saved = (await env.attendanceSettingsService.update(
      admin,
      tenHourShifts,
      expectedVersion: 0,
    )).unwrap();
    final again = (await env.attendanceSettingsService.update(
      admin,
      const AttendancePolicy(),
      expectedVersion: saved.version,
    )).unwrap();

    expect(saved.version, 1);
    expect(saved.policy.automaticBreak, tenHourShifts.automaticBreak);
    expect(again.version, 2);
    final audit = (await env.auditRows()).last;
    expect(audit.action, 'attendance.settings_changed');
    expect(jsonDecode(audit.metadata!), {
      'fields': ['excessiveDurationAfter', 'automaticBreak'],
    });
  });

  test('a stale save is a conflict', () async {
    await env.attendanceSettingsService.update(
      admin,
      tenHourShifts,
      expectedVersion: 0,
    );

    final stale = await env.attendanceSettingsService.update(
      admin,
      const AttendancePolicy(),
      expectedVersion: 0,
    );

    expect(stale.failureOrNull, isA<ConflictFailure>());
  });

  test('invalid values are rejected', () async {
    final result = await env.attendanceSettingsService.update(
      admin,
      const AttendancePolicy(excessiveDurationAfter: Duration.zero),
      expectedVersion: 0,
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('attendance is interpreted with the company settings', () async {
    // A 9-hour day is normal by default but excessive with an 8-hour limit.
    env.clock.jumpTo(nairobiTime(5, 7, 59));
    await env.attendance.clockIn(await env.signInAtKiosk(admin, john));
    env.clock.jumpTo(nairobiTime(5, 17, 0));
    await env.attendance.clockOut(await env.signInAtKiosk(admin, john));

    Future<AttendanceSession> monday() async => (await env.attendance.timeline(
      admin,
      john.id,
      from: LocalDate(2026, 10, 5),
      to: LocalDate(2026, 10, 5),
    )).unwrap().sessions.single;

    expect((await monday()).status, SessionStatus.completed);

    await env.attendanceSettingsService.update(
      admin,
      tenHourShifts,
      expectedVersion: 0,
    );

    final session = await monday();
    expect(session.status, SessionStatus.exception);
    expect(session.issues.single.type, AttendanceIssueType.excessiveDuration);
  });
}
