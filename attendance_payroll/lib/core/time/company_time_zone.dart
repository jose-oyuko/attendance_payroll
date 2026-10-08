import 'package:attendance_payroll/core/utils/local_date.dart';
// The full database, including aliases such as `UTC` and older names.
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A moment as seen on a wall clock in a particular timezone.
final class WallTime {
  const WallTime({required this.date, required this.timeOfDay});

  final LocalDate date;

  /// Time since local midnight.
  final Duration timeOfDay;

  @override
  bool operator ==(Object other) {
    return other is WallTime &&
        other.date == date &&
        other.timeOfDay == timeOfDay;
  }

  @override
  int get hashCode => Object.hash(date, timeOfDay);

  @override
  String toString() => '$date +$timeOfDay';
}

/// An IANA timezone (for example `Africa/Nairobi`) used to interpret
/// attendance. Instants are stored in UTC; this converts them to the
/// company's calendar dates and wall-clock times, including daylight-saving
/// changes, independently of the device's own timezone setting.
final class CompanyTimeZone {
  CompanyTimeZone._(this._location);

  /// The zone called [name]. Throws an [ArgumentError] if the name is not in
  /// the timezone database; check with [isKnown] first.
  factory CompanyTimeZone(String name) {
    _ensureDatabase();
    try {
      return CompanyTimeZone._(tz.getLocation(name));
    } on tz.LocationNotFoundException {
      throw ArgumentError.value(name, 'name', 'Unknown timezone');
    }
  }

  static bool _initialised = false;

  final tz.Location _location;

  String get name => _location.name;

  /// Whether [name] is a timezone in the database, such as `Africa/Nairobi`
  /// or `UTC`.
  static bool isKnown(String name) {
    _ensureDatabase();
    return tz.timeZoneDatabase.locations.containsKey(name);
  }

  /// The company's calendar date at [instant].
  LocalDate dateOf(DateTime instant) => wallTimeOf(instant).date;

  /// The company's wall-clock date and time at [instant].
  WallTime wallTimeOf(DateTime instant) {
    final local = tz.TZDateTime.from(instant, _location);
    return WallTime(
      date: LocalDate(local.year, local.month, local.day),
      timeOfDay: Duration(
        hours: local.hour,
        minutes: local.minute,
        seconds: local.second,
        milliseconds: local.millisecond,
      ),
    );
  }

  /// The UTC instant at which [date] begins in this zone. Where a
  /// daylight-saving change skips midnight, this is the first moment that
  /// exists on that date.
  DateTime startOfDay(LocalDate date) {
    final local = tz.TZDateTime(_location, date.year, date.month, date.day);
    return DateTime.fromMicrosecondsSinceEpoch(
      local.microsecondsSinceEpoch,
      isUtc: true,
    );
  }

  /// The UTC instant of the wall-clock [timeOfDay] on [date] in this zone.
  /// A time skipped by a daylight-saving change resolves to the equivalent
  /// moment after the change.
  DateTime instantAt(LocalDate date, Duration timeOfDay) {
    final wall = tz.TZDateTime(
      _location,
      date.year,
      date.month,
      date.day,
      timeOfDay.inHours,
      timeOfDay.inMinutes % Duration.minutesPerHour,
      timeOfDay.inSeconds % Duration.secondsPerMinute,
    );
    return DateTime.fromMicrosecondsSinceEpoch(
      wall.microsecondsSinceEpoch,
      isUtc: true,
    );
  }

  /// The half-open UTC range `[start, end)` covering the dates [from] to
  /// [to] inclusive.
  ({DateTime start, DateTime end}) rangeOf(LocalDate from, LocalDate to) {
    return (start: startOfDay(from), end: startOfDay(to.addDays(1)));
  }

  static void _ensureDatabase() {
    if (!_initialised) {
      tz_data.initializeTimeZones();
      _initialised = true;
    }
  }
}
