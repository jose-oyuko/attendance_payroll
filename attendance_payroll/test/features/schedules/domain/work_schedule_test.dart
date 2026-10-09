import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/day_schedule.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/schedule_fixtures.dart';

const _h = Duration.new;

void main() {
  group('validation', () {
    test('a standard schedule is valid', () {
      expect(dayShift().validate(), isNull);
    });

    test('each rule reports its field', () {
      final cases = <String, WorkScheduleDetails>{
        'name': dayShift(name: ' '),
        'days': dayShift(weekdays: []),
        'tolerance': dayShift(lateTolerance: _h(hours: 3)),
        'break': dayShift(
          automaticBreak: const AutomaticBreak(
            after: Duration(minutes: 20),
            deduct: Duration(minutes: 30),
          ),
        ),
      };
      cases.forEach((field, details) {
        expect(details.validate()?.field, field, reason: field);
      });
    });

    test('rejects repeated weekdays and empty shifts', () {
      expect(dayShift(weekdays: [1, 1]).validate()?.field, 'days');
      expect(
        dayShift(start: _h(hours: 8), end: _h(hours: 8)).validate()?.field,
        'days',
      );
      expect(dayShift(end: _h(hours: 24)).validate()?.field, 'days');
    });

    test('normalising sorts days and trims the name', () {
      final normalized = dayShift(
        name: '  Day shift ',
        weekdays: [5, 1, 3],
      ).normalized();

      expect(normalized.name, 'Day shift');
      expect(normalized.days.map((d) => d.weekday), [1, 3, 5]);
    });
  });

  group('what a schedule expects on a date', () {
    test('a working day gives the shift in UTC', () {
      // 5 Oct 2026 is a Monday.
      final shift =
          dayShift().dayScheduleOn(LocalDate(2026, 10, 5), nairobi)
              as ScheduledShift;

      expect(shift.start, nairobiTime(5, 8, 0));
      expect(shift.end, nairobiTime(5, 17, 0));
      expect(shift.crossesMidnight, isFalse);
      expect(shift.lateTolerance, _h(minutes: 10));
      expect(shift.scheduleName, 'Day shift');
    });

    test('other days are days off', () {
      // 10 Oct 2026 is a Saturday.
      final saturday = dayShift().dayScheduleOn(
        LocalDate(2026, 10, 10),
        nairobi,
      );

      expect(saturday, isA<DayOff>());
    });

    test('a night shift ends the next day', () {
      final night = dayShift(start: _h(hours: 22), end: _h(hours: 6));

      final shift =
          night.dayScheduleOn(LocalDate(2026, 10, 5), nairobi)
              as ScheduledShift;

      expect(night.days.first.length, _h(hours: 8));
      expect(shift.crossesMidnight, isTrue);
      expect(shift.start, nairobiTime(5, 22, 0));
      expect(shift.end, nairobiTime(6, 6, 0));
    });

    test('shift times follow daylight-saving changes', () {
      final newYork = CompanyTimeZone('America/New_York');
      final schedule = dayShift(weekdays: [5, 1]);

      // Friday 30 Oct (EDT, UTC-4) and Monday 2 Nov (EST, UTC-5).
      final before =
          schedule.dayScheduleOn(LocalDate(2026, 10, 30), newYork)
              as ScheduledShift;
      final after =
          schedule.dayScheduleOn(LocalDate(2026, 11, 2), newYork)
              as ScheduledShift;

      expect(before.start, DateTime.utc(2026, 10, 30, 12));
      expect(after.start, DateTime.utc(2026, 11, 2, 13));
    });
  });

  test('reports which settings changed', () {
    final before = dayShift();
    final after = dayShift(weekdays: [1, 2, 3, 4, 5, 6], lateTolerance: _h());

    expect(after.changedFieldsFrom(before), ['days', 'lateTolerance']);
    expect(before.changedFieldsFrom(dayShift()), isEmpty);
  });

  test('assignments apply between their dates', () {
    final assignment = ScheduleAssignment(
      id: 'a',
      employeeId: 'e',
      scheduleId: 's',
      effectiveFrom: LocalDate(2026, 10, 1),
      effectiveTo: LocalDate(2026, 10, 31),
    );

    expect(assignment.appliesOn(LocalDate(2026, 9, 30)), isFalse);
    expect(assignment.appliesOn(LocalDate(2026, 10, 1)), isTrue);
    expect(assignment.appliesOn(LocalDate(2026, 10, 31)), isTrue);
    expect(assignment.appliesOn(LocalDate(2026, 11, 1)), isFalse);
  });
}
