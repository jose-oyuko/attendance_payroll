import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    // It is 5 October, 12:00 in Nairobi.
    env.clock.jumpTo(nairobiTime(5, 12, 0));
  });

  Future<Employee> employee(String number, String first) async {
    return (await env.management.create(
      admin,
      EmployeeDetails(
        employeeNumber: number,
        firstName: first,
        lastName: 'Test',
        employmentStartDate: LocalDate(2026, 1, 1),
      ),
    )).unwrap();
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
      reason: 'Test data',
    )).unwrap();
  }

  test('each employee gets a status and the day gets counts', () async {
    final present = await employee('E1', 'Amina');
    final working = await employee('E2', 'Brian');
    final forgot = await employee('E3', 'Carol');
    await employee('E4', 'David');
    final archived = await employee('E5', 'Esther');

    await entry(present, AttendanceEventType.clockIn, 5, 6);
    await entry(present, AttendanceEventType.clockOut, 5, 11);
    await entry(forgot, AttendanceEventType.clockIn, 4, 8);
    await entry(archived, AttendanceEventType.clockIn, 5, 9);
    await entry(archived, AttendanceEventType.clockOut, 5, 10);
    await env.management.changeStatus(
      admin,
      (await env.management.get(admin, archived.id)).unwrap(),
      EmploymentStatus.archived,
    );
    // Brian clocked in at 07:00 and has not clocked out yet.
    await entry(working, AttendanceEventType.clockIn, 5, 7);

    final day = (await env.attendance.day(
      admin,
      LocalDate(2026, 10, 5),
    )).unwrap();
    DayStatus statusOf(Employee e) =>
        day.employees.singleWhere((d) => d.employee.id == e.id).status;

    expect(day.employees.map((d) => d.employee.details.firstName), [
      'Amina',
      'Brian',
      'Carol',
      'David',
      'Esther',
    ]);
    expect(statusOf(present), DayStatus.present);
    expect(statusOf(working), DayStatus.working);
    // Carol's forgotten clock-out was on the 4th; on the 5th she simply
    // has no attendance.
    expect(statusOf(forgot), DayStatus.notClockedIn);
    expect(statusOf(archived), DayStatus.present);
    expect(
      day.employees.singleWhere((d) => d.employee.id == present.id).payable,
      const Duration(hours: 5),
    );
    expect(day.present, 3);
    expect(day.working, 1);
    expect(day.needsReview, 0);
    expect(day.notClockedIn, 2);
  });

  test('a forgotten clock-out shows as needing review on its day', () async {
    final carol = await employee('E3', 'Carol');
    await entry(carol, AttendanceEventType.clockIn, 4, 8);
    env.clock.jumpTo(nairobiTime(6, 9, 0));

    final day = (await env.attendance.day(
      admin,
      LocalDate(2026, 10, 4),
    )).unwrap();

    expect(day.employees.single.status, DayStatus.needsReview);
    expect(day.needsReview, 1);
  });

  test('archived employees without attendance are left out', () async {
    final archived = await employee('E5', 'Esther');
    await env.management.changeStatus(
      admin,
      archived,
      EmploymentStatus.archived,
    );

    final day = (await env.attendance.day(
      admin,
      LocalDate(2026, 10, 5),
    )).unwrap();

    expect(day.employees, isEmpty);
  });

  group('range', () {
    final from = LocalDate(2026, 10, 3);
    final to = LocalDate(2026, 10, 5);

    test('one row per employee per date, by name then date', () async {
      final brian = await employee('E2', 'Brian');
      final amina = await employee('E1', 'Amina');
      final esther = await employee('E5', 'Esther');
      await entry(amina, AttendanceEventType.clockIn, 3, 8);
      await entry(amina, AttendanceEventType.clockOut, 3, 16);
      await entry(amina, AttendanceEventType.clockIn, 5, 8);
      await entry(amina, AttendanceEventType.clockOut, 5, 11);
      // Brian forgot to clock out on the 4th.
      await entry(brian, AttendanceEventType.clockIn, 4, 8);
      await entry(esther, AttendanceEventType.clockIn, 4, 9);
      await entry(esther, AttendanceEventType.clockOut, 4, 10);
      await env.management.changeStatus(
        admin,
        (await env.management.get(admin, esther.id)).unwrap(),
        EmploymentStatus.archived,
      );

      final range = (await env.attendance.range(
        admin,
        from: from,
        to: to,
      )).unwrap();

      // Archived Esther appears only on the day she has attendance.
      expect(
        range.rows.map((r) => (r.employee.details.firstName, r.date.day)),
        [
          ('Amina', 3),
          ('Amina', 4),
          ('Amina', 5),
          ('Brian', 3),
          ('Brian', 4),
          ('Brian', 5),
          ('Esther', 4),
        ],
      );
      final aminaTotals = AttendanceTotals(range.byEmployee[amina.id]!);
      expect(aminaTotals.present, 2);
      expect(aminaTotals.payable, const Duration(hours: 11));
      final brianDays = range.byEmployee[brian.id]!;
      expect(brianDays[1].status, DayStatus.needsReview);
      expect(brianDays.where((d) => d.hasProblem), hasLength(1));
      expect(AttendanceTotals(brianDays).needsReview, 1);
    });

    test('each row matches the daily view of its date', () async {
      final amina = await employee('E1', 'Amina');
      final brian = await employee('E2', 'Brian');
      await entry(amina, AttendanceEventType.clockIn, 4, 8);
      await entry(amina, AttendanceEventType.clockOut, 4, 17);
      await entry(brian, AttendanceEventType.clockIn, 4, 22);
      await entry(brian, AttendanceEventType.clockOut, 5, 6);

      final range = (await env.attendance.range(
        admin,
        from: from,
        to: to,
      )).unwrap();

      for (var date = from; !date.isAfter(to); date = date.addDays(1)) {
        final day = (await env.attendance.day(admin, date)).unwrap();
        final rows = range.rows.where((r) => r.date == date).toList();
        expect(
          rows.map((r) => (r.employee.id, r.status, r.payable)),
          day.employees.map((d) => (d.employee.id, d.status, d.payable)),
          reason: '$date',
        );
      }
    });

    test('is limited to ${AttendanceService.maxRangeDays} days', () async {
      await employee('E1', 'Amina');
      final start = LocalDate(2026, 8, 1);

      final longest = await env.attendance.range(
        admin,
        from: start,
        to: start.addDays(AttendanceService.maxRangeDays - 1),
      );
      final tooLong = await env.attendance.range(
        admin,
        from: start,
        to: start.addDays(AttendanceService.maxRangeDays),
      );
      final reversed = await env.attendance.range(admin, from: to, to: from);

      expect(longest.unwrap().rows, hasLength(AttendanceService.maxRangeDays));
      expect(tooLong.failureOrNull, isA<ValidationFailure>());
      expect(reversed.failureOrNull, isA<ValidationFailure>());
    });
  });
}
