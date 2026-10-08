import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final nairobi = CompanyTimeZone('Africa/Nairobi');
  final newYork = CompanyTimeZone('America/New_York');

  test('knows real zone names and rejects others', () {
    expect(CompanyTimeZone.isKnown('Africa/Nairobi'), isTrue);
    expect(CompanyTimeZone.isKnown('UTC'), isTrue);
    expect(CompanyTimeZone.isKnown('Africa/Atlantis'), isFalse);
    expect(CompanyTimeZone.isKnown('Nairobi'), isFalse);
    expect(() => CompanyTimeZone('Africa/Atlantis'), throwsArgumentError);
  });

  test('converts UTC instants to the company date and time', () {
    // 21:30 UTC is 00:30 the next day in Nairobi (UTC+3).
    final wall = nairobi.wallTimeOf(DateTime.utc(2026, 10, 5, 21, 30));

    expect(wall.date, LocalDate(2026, 10, 6));
    expect(wall.timeOfDay, const Duration(minutes: 30));
    expect(
      nairobi.dateOf(DateTime.utc(2026, 10, 5, 20, 59)),
      LocalDate(2026, 10, 5),
    );
  });

  test('the device timezone does not matter', () {
    final instant = DateTime.utc(2026, 10, 5, 5, 2);

    expect(nairobi.wallTimeOf(instant), nairobi.wallTimeOf(instant.toLocal()));
  });

  test('start of day is local midnight in UTC', () {
    expect(
      nairobi.startOfDay(LocalDate(2026, 10, 5)),
      DateTime.utc(2026, 10, 4, 21),
    );
    final range = nairobi.rangeOf(
      LocalDate(2026, 10, 1),
      LocalDate(2026, 10, 31),
    );
    expect(range.start, DateTime.utc(2026, 9, 30, 21));
    expect(range.end, DateTime.utc(2026, 10, 31, 21));
    expect(range.start.isUtc, isTrue);
  });

  test('handles daylight-saving changes', () {
    // New York: EDT (UTC-4) until 1 Nov 2026, then EST (UTC-5).
    expect(
      newYork.startOfDay(LocalDate(2026, 10, 31)),
      DateTime.utc(2026, 10, 31, 4),
    );
    expect(
      newYork.startOfDay(LocalDate(2026, 11, 2)),
      DateTime.utc(2026, 11, 2, 5),
    );
    // The day of the change is 25 hours long.
    final range = newYork.rangeOf(
      LocalDate(2026, 11, 1),
      LocalDate(2026, 11, 1),
    );
    expect(range.end.difference(range.start), const Duration(hours: 25));
    expect(
      newYork.wallTimeOf(DateTime.utc(2026, 11, 1, 12)).timeOfDay,
      const Duration(hours: 7),
    );
  });

  test('a skipped midnight starts the day at the first existing moment', () {
    // Santiago moves clocks from 24:00 to 01:00 on 6 Sep 2026.
    final santiago = CompanyTimeZone('America/Santiago');
    final start = santiago.startOfDay(LocalDate(2026, 9, 6));

    expect(santiago.dateOf(start), LocalDate(2026, 9, 6));
    expect(
      santiago.dateOf(start.subtract(const Duration(seconds: 1))),
      LocalDate(2026, 9, 5),
    );
  });
}
