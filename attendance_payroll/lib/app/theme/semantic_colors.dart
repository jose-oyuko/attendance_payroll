import 'package:flutter/material.dart';

/// A foreground/background colour pair for one semantic meaning, following
/// the Material 3 `color` / `onColor` / `container` / `onContainer` pattern.
@immutable
class SemanticColorSet {
  const SemanticColorSet({
    required this.color,
    required this.onColor,
    required this.container,
    required this.onContainer,
  });

  final Color color;
  final Color onColor;
  final Color container;
  final Color onContainer;

  static SemanticColorSet lerp(SemanticColorSet a, SemanticColorSet b, double t) {
    return SemanticColorSet(
      color: Color.lerp(a.color, b.color, t)!,
      onColor: Color.lerp(a.onColor, b.onColor, t)!,
      container: Color.lerp(a.container, b.container, t)!,
      onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
    );
  }
}

/// Status colours that Material's [ColorScheme] does not provide.
///
/// Error uses `ColorScheme.error`; everything else lives here so widgets never
/// hard-code colours. Access through `context.semanticColors`.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.neutral,
  });

  final SemanticColorSet success;
  final SemanticColorSet warning;
  final SemanticColorSet info;
  final SemanticColorSet neutral;

  static const SemanticColors light = SemanticColors(
    success: SemanticColorSet(
      color: Color(0xFF2E7D32),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFD7F0D9),
      onContainer: Color(0xFF0A3D12),
    ),
    warning: SemanticColorSet(
      color: Color(0xFF9A5B00),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFFFE8C2),
      onContainer: Color(0xFF3A2200),
    ),
    info: SemanticColorSet(
      color: Color(0xFF0B6BA8),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFD3E9F9),
      onContainer: Color(0xFF00263F),
    ),
    neutral: SemanticColorSet(
      color: Color(0xFF5F6368),
      onColor: Color(0xFFFFFFFF),
      container: Color(0xFFE3E5E8),
      onContainer: Color(0xFF1F2124),
    ),
  );

  static const SemanticColors dark = SemanticColors(
    success: SemanticColorSet(
      color: Color(0xFF8FD694),
      onColor: Color(0xFF00390F),
      container: Color(0xFF1B5E20),
      onContainer: Color(0xFFD7F0D9),
    ),
    warning: SemanticColorSet(
      color: Color(0xFFFFB955),
      onColor: Color(0xFF4A2A00),
      container: Color(0xFF6B4000),
      onContainer: Color(0xFFFFE8C2),
    ),
    info: SemanticColorSet(
      color: Color(0xFF8CCDF7),
      onColor: Color(0xFF00344F),
      container: Color(0xFF004B71),
      onContainer: Color(0xFFD3E9F9),
    ),
    neutral: SemanticColorSet(
      color: Color(0xFFBFC3C8),
      onColor: Color(0xFF2A2D31),
      container: Color(0xFF3A3D42),
      onContainer: Color(0xFFE3E5E8),
    ),
  );

  @override
  SemanticColors copyWith({
    SemanticColorSet? success,
    SemanticColorSet? warning,
    SemanticColorSet? info,
    SemanticColorSet? neutral,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) {
      return this;
    }
    return SemanticColors(
      success: SemanticColorSet.lerp(success, other.success, t),
      warning: SemanticColorSet.lerp(warning, other.warning, t),
      info: SemanticColorSet.lerp(info, other.info, t),
      neutral: SemanticColorSet.lerp(neutral, other.neutral, t),
    );
  }
}

extension SemanticColorsContextX on BuildContext {
  /// Semantic status colours for the current theme.
  SemanticColors get semanticColors {
    final theme = Theme.of(this);
    return theme.extension<SemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? SemanticColors.dark
            : SemanticColors.light);
  }
}
