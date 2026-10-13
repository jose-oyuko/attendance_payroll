/// Framework-agnostic layout and interaction constants shared across features.
abstract final class AppConstants {
  /// The app version, written into backups. Must equal the version in
  /// pubspec.yaml (a test checks).
  static const String appVersion = '1.0.0';

  /// Minimum interactive target size (Material guideline).
  static const double minTouchTarget = 48;

  /// Minimum width of a button, so short labels never produce tiny targets.
  static const double minButtonWidth = 64;

  /// Maximum width of page content on very wide screens.
  static const double maxContentWidth = 1400;

  /// Maximum width of centred messages such as empty and error states.
  static const double messageMaxWidth = 420;
}
