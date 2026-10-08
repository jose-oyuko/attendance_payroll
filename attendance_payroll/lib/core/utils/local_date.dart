/// A calendar date with no time of day and no timezone, such as an employment
/// start date or the first day a pay rate applies.
///
/// Holding such values in a `DateTime` invites timezone bugs: midnight in one
/// zone is the previous day in another. A [LocalDate] is persisted as an
/// ISO-8601 `YYYY-MM-DD` string, which also sorts and compares correctly as
/// text inside SQLite.
final class LocalDate implements Comparable<LocalDate> {
  /// Creates a date. Throws an [ArgumentError] for dates that do not exist,
  /// such as 2026-02-30, and for years outside 1–9999.
  LocalDate(this.year, this.month, this.day) {
    if (!_isValid(year, month, day)) {
      throw ArgumentError('Invalid calendar date: $year-$month-$day');
    }
  }

  /// The calendar date of [dateTime] in the timezone it is expressed in.
  factory LocalDate.fromDateTime(DateTime dateTime) {
    return LocalDate(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Parses `YYYY-MM-DD`. Throws a [FormatException] for anything else.
  factory LocalDate.parse(String value) {
    final match = _isoPattern.firstMatch(value);
    if (match == null) {
      throw FormatException('Expected a YYYY-MM-DD date', value);
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (!_isValid(year, month, day)) {
      throw FormatException('Invalid calendar date', value);
    }
    return LocalDate(year, month, day);
  }

  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static bool _isValid(int year, int month, int day) {
    if (year < 1 || year > 9999) {
      return false;
    }
    final normalized = DateTime.utc(year, month, day);
    return normalized.year == year &&
        normalized.month == month &&
        normalized.day == day;
  }

  final int year;
  final int month;
  final int day;

  /// The date [days] days later (or earlier, when negative).
  LocalDate addDays(int days) {
    return LocalDate.fromDateTime(DateTime.utc(year, month, day + days));
  }

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// `YYYY-MM-DD`.
  String toIsoString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIsoString();
}
