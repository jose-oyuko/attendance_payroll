import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDate', () {
    test('formats and parses ISO dates with zero padding', () {
      final date = LocalDate(2026, 7, 1);

      expect(date.toIsoString(), '2026-07-01');
      expect(LocalDate.parse('2026-07-01'), date);
    });

    test('rejects dates that do not exist', () {
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate(0, 1, 1), throwsArgumentError);
      expect(LocalDate(2028, 2, 29).toIsoString(), '2028-02-29');
    });

    test('parse rejects malformed and impossible input', () {
      for (final input in ['', '2026-7-1', '2026/07/01', '2026-02-30']) {
        expect(
          () => LocalDate.parse(input),
          throwsFormatException,
          reason: input,
        );
      }
    });

    test('addDays crosses month and year boundaries', () {
      expect(LocalDate(2026, 7, 1).addDays(-1), LocalDate(2026, 6, 30));
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2028, 2, 28).addDays(1), LocalDate(2028, 2, 29));
    });

    test('fromDateTime keeps the calendar date of the given zone', () {
      expect(
        LocalDate.fromDateTime(DateTime.utc(2026, 10, 5, 23, 59)),
        LocalDate(2026, 10, 5),
      );
    });

    test('ISO text order matches chronological order', () {
      final dates = [
        LocalDate(2026, 10, 1),
        LocalDate(2025, 12, 31),
        LocalDate(2026, 2, 3),
        LocalDate(2026, 10, 10),
      ];
      final byValue = [...dates]..sort();
      final byText = [...dates]
        ..sort((a, b) => a.toIsoString().compareTo(b.toIsoString()));

      expect(byText, byValue);
      expect(byValue.first.isBefore(byValue.last), isTrue);
      expect(byValue.last.isAfter(byValue.first), isTrue);
    });
  });
}
