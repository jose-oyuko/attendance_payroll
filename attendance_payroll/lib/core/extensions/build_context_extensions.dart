import 'package:flutter/material.dart';

/// Shortcuts for the theme values used throughout presentation code.
extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Whether the person reads with enlarged text. Layouts that put things
  /// side by side stack them instead, because there is no room left beside
  /// text that big.
  bool get largeText => MediaQuery.textScalerOf(this).scale(1) > 1.3;
}
