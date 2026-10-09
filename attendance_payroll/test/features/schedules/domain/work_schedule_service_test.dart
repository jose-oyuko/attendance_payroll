import 'dart:convert';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/schedules/domain/schedule_repositories.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/schedule_fixtures.dart';
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

  Future<WorkSchedule> office() async => (await env.scheduleService.create(
    admin,
    dayShift(name: 'Office'),
  )).unwrap();

  group('schedules', () {
    test('are created, listed and changed with an audit trail', () async {
      final created = await office();
      final updated = (await env.scheduleService.update(
        admin,
        created.id,
        dayShift(name: 'Office', weekdays: [1, 2, 3, 4, 5, 6]),
        expectedVersion: created.version,
      )).unwrap();

      final listed = (await env.scheduleService.list(admin)).unwrap();
      expect(listed.single.details.days, hasLength(6));
      expect(updated.version, 2);
      final actions = await env.auditActions();
      expect(
        actions,
        containsAllInOrder(['schedule.created', 'schedule.updated']),
      );
      expect(jsonDecode((await env.auditRows()).last.metadata!), {
        'fields': ['days'],
      });
    });

    test('names are unique within the company', () async {
      await office();

      final again = await env.scheduleService.create(
        admin,
        dayShift(name: 'Office'),
      );

      expect(again.failureOrNull, isA<ConflictFailure>());
    });

    test('a stale edit is a conflict', () async {
      final created = await office();
      await env.scheduleService.update(
        admin,
        created.id,
        dayShift(name: 'Office 2'),
        expectedVersion: 1,
      );

      final stale = await env.scheduleService.update(
        admin,
        created.id,
        dayShift(name: 'Office 3'),
        expectedVersion: 1,
      );

      expect(stale.failureOrNull, isA<ConflictFailure>());
    });
  });

  group('assignments', () {
    test('a new schedule closes the previous one', () async {
      final day = await office();
      final night = (await env.scheduleService.create(
        admin,
        dayShift(
          name: 'Nights',
          start: const Duration(hours: 22),
          end: const Duration(hours: 6),
        ),
      )).unwrap();

      await env.scheduleService.assign(
        admin,
        john.id,
        day.id,
        effectiveFrom: LocalDate(2026, 10, 1),
      );
      await env.scheduleService.assign(
        admin,
        john.id,
        night.id,
        effectiveFrom: LocalDate(2026, 11, 1),
      );
      await env.scheduleService.assign(
        admin,
        john.id,
        null,
        effectiveFrom: LocalDate(2026, 12, 1),
      );

      final history = (await env.scheduleService.history(
        admin,
        john.id,
      )).unwrap();
      expect(history.map((a) => a.scheduleId), [day.id, night.id, null]);
      expect(history.first.effectiveTo, LocalDate(2026, 10, 31));
      expect(history[1].effectiveTo, LocalDate(2026, 11, 30));
      expect(history.last.effectiveTo, isNull);
      expect(
        (await env.auditActions()).where(
          (a) => a == 'employee.schedule_assigned',
        ),
        hasLength(3),
      );
    });

    test('history cannot be rewritten by back-dating', () async {
      final day = await office();
      await env.scheduleService.assign(
        admin,
        john.id,
        day.id,
        effectiveFrom: LocalDate(2026, 10, 1),
      );

      final result = await env.scheduleService.assign(
        admin,
        john.id,
        null,
        effectiveFrom: LocalDate(2026, 9, 1),
      );

      expect(
        (result.failureOrNull! as BusinessRuleFailure).rule,
        ScheduleAssignmentRules.mustStartAfterLatest,
      );
    });

    test("another company's schedule cannot be assigned", () async {
      final other = (await env.companies.create(
        const CompanyDetails(
          name: 'Other',
          currencyCode: 'KES',
          timezone: 'UTC',
        ),
      )).unwrap();
      final foreign = (await env.schedulesRepo.create(
        other.id,
        dayShift(name: 'Theirs'),
      )).unwrap();

      final result = await env.scheduleService.assign(
        admin,
        john.id,
        foreign.id,
        effectiveFrom: LocalDate(2026, 10, 1),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(
        (await env.scheduleService.history(admin, john.id)).unwrap(),
        isEmpty,
      );
    });
  });

  group('attendance against the schedule', () {
    late Employee mary;

    setUp(() async {
      mary = await env.addEmployee(admin, employeeNumber: 'E0002');
      final schedule = await office();
      for (final employee in [john, mary]) {
        await env.scheduleService.assign(
          admin,
          employee.id,
          schedule.id,
          effectiveFrom: LocalDate(2026, 10, 1),
        );
      }
    });

    Future<void> entry(Employee who, AttendanceEventType type, int h, int m) =>
        env.attendanceCorrections
            .addMissingEntry(
              admin,
              who.id,
              type: type,
              occurredAt: nairobiTime(5, h, m),
              reason: 'Paper register',
            )
            .then((r) => r.unwrap());

    Future<DailyAttendance> monday() async =>
        (await env.attendance.day(admin, LocalDate(2026, 10, 5))).unwrap();

    DayStatus statusOf(DailyAttendance day, Employee e) =>
        day.employees.singleWhere((d) => d.employee.id == e.id).status;

    test('before the start everyone is expected; after it, absent', () async {
      env.clock.jumpTo(nairobiTime(5, 8, 5));
      expect(statusOf(await monday(), mary), DayStatus.expected);

      env.clock.jumpTo(nairobiTime(5, 8, 11));
      final day = await monday();
      expect(statusOf(day, mary), DayStatus.absent);
      expect(day.absent, 2);
    });

    test('a late arrival is counted and listed, but paid', () async {
      env.clock.jumpTo(nairobiTime(5, 12, 0));
      await entry(john, AttendanceEventType.clockIn, 8, 30);

      final day = await monday();
      final johnsDay = day.employees.singleWhere(
        (d) => d.employee.id == john.id,
      );
      expect(johnsDay.status, DayStatus.working);
      expect(johnsDay.isLate, isTrue);
      expect(day.late, 1);
      expect(statusOf(day, mary), DayStatus.absent);
      expect(day.dayOff, 0);
    });

    test('a finished day without attendance becomes an exception', () async {
      env.clock.jumpTo(nairobiTime(6, 9, 0));
      await entry(john, AttendanceEventType.clockIn, 8, 30);
      await entry(john, AttendanceEventType.clockOut, 16, 0);

      final exceptions = (await env.exceptions.list(
        admin,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 5),
      )).unwrap();

      expect(
        {for (final e in exceptions) '${e.employee.id}:${e.type.name}'},
        {
          '${john.id}:lateArrival',
          '${john.id}:earlyDeparture',
          '${mary.id}:missingAttendance',
        },
      );
      final session = (await env.attendance.timeline(
        admin,
        john.id,
        from: LocalDate(2026, 10, 5),
        to: LocalDate(2026, 10, 5),
      )).unwrap().sessions.single;
      expect(session.status, SessionStatus.completed);
      expect(session.payableDuration, const Duration(hours: 7, minutes: 30));
    });

    test('absence can be excused, or fixed by adding the attendance', () async {
      env.clock.jumpTo(nairobiTime(6, 9, 0));
      AttendanceException absence(List<AttendanceException> all, Employee e) =>
          all.singleWhere(
            (x) =>
                x.employee.id == e.id &&
                x.type == AttendanceIssueType.missingAttendance,
          );
      Future<List<AttendanceException>> list() async =>
          (await env.exceptions.list(
            admin,
            from: LocalDate(2026, 10, 5),
            to: LocalDate(2026, 10, 5),
          )).unwrap();

      final excused = await env.exceptions.decide(
        admin,
        absence(await list(), mary),
        decision: ReviewDecision.dismissed,
        reason: 'Annual leave',
      );
      final fixed = await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockIn,
        occurredAt: nairobiTime(5, 8, 0),
        reason: 'Worked; the kiosk was off',
        resolves: absence(await list(), john).issue,
      );

      expect(excused.isOk, isTrue);
      expect(fixed.isOk, isTrue);
      final after = await list();
      expect(absence(after, mary).status, ExceptionStatus.dismissed);
      expect(absence(after, john).status, ExceptionStatus.resolved);
      expect(absence(after, john).stillDetected, isFalse);
    });

    test('no schedule from a date means no expectations', () async {
      await env.scheduleService.assign(
        admin,
        mary.id,
        null,
        effectiveFrom: LocalDate(2026, 10, 5),
      );
      env.clock.jumpTo(nairobiTime(5, 12, 0));

      expect(statusOf(await monday(), mary), DayStatus.notClockedIn);
    });

    test('a day off is a day off', () async {
      env.clock.jumpTo(nairobiTime(10, 12, 0));

      final saturday = (await env.attendance.day(
        admin,
        LocalDate(2026, 10, 10),
      )).unwrap();

      expect(saturday.dayOff, 2);
      expect(saturday.absent, 0);
    });
  });
}
