/// Locations inside the Employees area.
abstract final class EmployeeRoutes {
  static const String list = '/employees';
  static const String newEmployee = '$list/new';

  /// Route segments, relative to [list].
  static const String newSegment = 'new';
  static const String detailSegment = ':employeeId';
  static const String editSegment = 'edit';
  static const String attendanceSegment = 'attendance';
  static const String idParameter = 'employeeId';

  static String detail(String id) => '$list/$id';

  static String edit(String id) => '$list/$id/$editSegment';

  static String attendance(String id) => '$list/$id/$attendanceSegment';
}
