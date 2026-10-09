/// Locations inside the Schedules area.
abstract final class ScheduleRoutes {
  static const String list = '/schedules';
  static const String newSchedule = '$list/$newSegment';

  /// Route segments, relative to [list].
  static const String newSegment = 'new';
  static const String editSegment = ':scheduleId';
  static const String idParameter = 'scheduleId';

  static String edit(String id) => '$list/$id';
}
