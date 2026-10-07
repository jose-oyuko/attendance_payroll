import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Central Material 3 theme definition. Colours come from a single seed and
/// the [SemanticColors] extension; widgets must not hard-code colours.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF1565C0);

  static ThemeData light() => _build(Brightness.light, SemanticColors.light);

  static ThemeData dark() => _build(Brightness.dark, SemanticColors.dark);

  static ThemeData _build(Brightness brightness, SemanticColors semantic) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    const buttonMinimumSize = Size(
      AppConstants.minButtonWidth,
      AppConstants.minTouchTarget,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonMinimumSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: buttonMinimumSize),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: buttonMinimumSize),
      ),
      extensions: <ThemeExtension<dynamic>>[semantic],
    );
  }
}
