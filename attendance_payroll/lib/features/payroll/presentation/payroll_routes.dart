/// Locations inside the Payroll area.
abstract final class PayrollRoutes {
  static const String list = '/payroll';

  /// Route segments, relative to [list].
  static const String periodSegment = ':periodId';
  static const String idParameter = 'periodId';

  static String period(String id) => '$list/$id';
}
