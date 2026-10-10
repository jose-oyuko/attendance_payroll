/// Locations inside the Attendance area.
abstract final class AttendanceRoutes {
  static const String day = '/attendance';
  static const String exceptions = '$day/$exceptionsSegment';
  static const String range = '$day/$rangeSegment';

  /// Route segments, relative to [day].
  static const String exceptionsSegment = 'exceptions';
  static const String rangeSegment = 'range';
  static const String employeeSegment = 'employees/:employeeId';
  static const String idParameter = 'employeeId';

  static String employee(String id) => '$day/employees/$id';
}
