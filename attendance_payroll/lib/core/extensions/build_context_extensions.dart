import 'package:flutter/material.dart';

/// Shortcuts for the theme values used throughout presentation code.
extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;
}
