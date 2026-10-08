import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_state.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_database.dart';
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

  /// John enters his PIN just before a Nairobi wall time; the next clock
  /// reading (the clock action) is exactly that time.
  Future<PinVerification> atKiosk(int day, int hour, int minute) async {
    final target = nairobiTime(day, hour, minute);
    env.clock.jumpTo(target.subtract(const Duration(seconds: 30)));
    final verification = await env.signInAtKiosk(admin, john);
    env.clock.jumpTo(target);
    return verification;
  }

  Future<String?> ruleOf<T>(Future<Result<T>> result) async {
    final failure = (await result).failureOrNull;
    return failure is BusinessRuleFailure ? failure.rule : null;
  }

  Future<int> eventCount() async =>
      (await env.db.select(env.db.attendanceEvents).get()).length;

  group('clocking in and out', () {
    test('records events and moves through the states', () async {
      final clockedIn = (await env.attendance.clockIn(
        await atKiosk(5, 8, 2),
      )).unwrap();

      expect(clockedIn.event.type, AttendanceEventType.clockIn);
      expect(clockedIn.event.source, AttendanceEventSource.kiosk);
      expect(clockedIn.event.createdBy, john.id);
      expect(clockedIn.event.deviceId, isNotEmpty);
      expect(clockedIn.event.occurredAt, nairobiTime(5, 8, 2));
      expect(clockedIn.event.recordedAt, clockedIn.event.occurredAt);
      expect(clockedIn.state, isA<ClockedIn>());

      final verification = await atKiosk(5, 17, 4);
      expect(
        (await env.attendance.currentState(verification)).unwrap(),
        isA<ClockedIn>(),
      );
      final clockedOut = (await env.attendance.clockOut(verification)).unwrap();

      expect(clockedOut.state, isA<NotClockedIn>());
      expect(await eventCount(), 2);
    });

    test('invalid transitions are refused and record nothing', () async {
      expect(
        await ruleOf(env.attendance.clockOut(await atKiosk(5, 7, 0))),
        'not_clocked_in',
      );
      await env.attendance.clockIn(await atKiosk(5, 8, 0));
      expect(
        await ruleOf(env.attendance.clockIn(await atKiosk(5, 8, 1))),
        'already_clocked_in',
      );

      expect(await eventCount(), 1);
    });

    test('a forgotten clock-out does not block the next day', () async {
      await env.attendance.clockIn(await atKiosk(5, 8, 2));

      final nextDay = await env.attendance.clockIn(await atKiosk(6, 8, 0));

      expect(nextDay.isOk, isTrue);
      final timeline = (await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 6),
      )).unwrap();
      expect(
        timeline.sessions.first.issues.single.type,
        AttendanceIssueType.missingClockOut,
      );
      expect(timeline.sessions.last.status, SessionStatus.open);
    });

    test('a temporary PIN must be changed first', () async {
      final temporary = (await env.pins.issueTemporaryPin(
        admin,
        john.id,
      )).unwrap();
      final verification = (await env.pins.verifyPin(
        john.id,
        temporary,
      )).unwrap();

      expect(
        await ruleOf(env.attendance.clockIn(verification)),
        AttendanceService.pinChangeRequiredRule,
      );
      expect(await eventCount(), 0);
    });

    test('a PIN check expires', () async {
      final verification = await atKiosk(5, 8, 0);
      env.clock.advance(const Duration(minutes: 3));

      final result = await env.attendance.clockIn(verification);

      expect(result.failureOrNull, isA<AuthenticationFailure>());
      expect(await eventCount(), 0);
    });

    test('an employee suspended after the PIN check cannot clock in', () async {
      final verification = await atKiosk(5, 8, 0);
      await env.management.changeStatus(
        admin,
        (await env.management.get(admin, john.id)).unwrap(),
        EmploymentStatus.suspended,
      );

      final result = await env.attendance.clockIn(verification);

      expect(result.failureOrNull, isA<AuthenticationFailure>());
    });

    test('a device clock set back is detected', () async {
      // An event recorded elsewhere at 17:00; this device thinks it is 09:00.
      await env.events.append(
        NewAttendanceEvent(
          employeeId: john.id,
          type: AttendanceEventType.clockIn,
          occurredAt: nairobiTime(5, 17, 0),
          recordedAt: nairobiTime(5, 17, 0),
          source: AttendanceEventSource.kiosk,
          deviceId: 'other-device',
          createdBy: john.id,
        ),
      );

      expect(
        await ruleOf(env.attendance.clockOut(await atKiosk(5, 9, 0))),
        'device_clock_behind',
      );
    });
  });

  group('timeline', () {
    Future<void> day(int day, (int, int) inAt, (int, int) outAt) async {
      await env.attendance.clockIn(await atKiosk(day, inAt.$1, inAt.$2));
      await env.attendance.clockOut(await atKiosk(day, outAt.$1, outAt.$2));
    }

    test('returns sessions by company work date', () async {
      await day(4, (8, 0), (17, 0));
      await day(5, (8, 2), (17, 4));
      await day(6, (8, 0), (16, 30));

      final timeline = (await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 5),
      )).unwrap();

      final session = timeline.sessions.single;
      expect(session.workDate, LocalDate(2026, 10, 5));
      expect(session.payableDuration, const Duration(hours: 9, minutes: 2));
    });

    test('includes a session that starts in range and ends after it', () async {
      await env.attendance.clockIn(await atKiosk(5, 22, 0));
      await env.attendance.clockOut(await atKiosk(6, 6, 0));

      final timeline = (await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 5),
      )).unwrap();

      expect(timeline.sessions.single.end, nairobiTime(6, 6, 0));
      expect(timeline.sessions.single.status, SessionStatus.exception);
    });

    test('needs the attendance permission and the right company', () async {
      final other = (await env.companies.create(
        const CompanyDetails(
          name: 'Other',
          currencyCode: 'KES',
          timezone: 'UTC',
        ),
      )).unwrap();
      final foreign = (await env.employees.create(
        other.id,
        johnDetails(),
      )).unwrap();

      final result = await env.attendance.timeline(
        admin,
        foreign.id,
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 31),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('rejects a reversed date range', () async {
      final result = await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, 31),
        to: LocalDate(2026, 10, 1),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('an unrecognised company timezone fails clearly', () async {
      await (env.db.update(env.db.companies)
            ..where((c) => c.id.equals(admin.companyId)))
          .write(const CompaniesCompanion(timezone: Value('Mars/Olympus')));

      final result = await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 31),
      );

      expect(
        (result.failureOrNull! as BusinessRuleFailure).rule,
        AttendanceService.unknownTimeZoneRule,
      );
    });
  });
}
