import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// Material 3 window size classes, based on available width.
///
/// Prefer measuring the space a widget actually has (`LayoutBuilder` or
/// `WindowSizeBuilder`) over the screen width, so the same widget works inside
/// panes and split views.
enum WindowSize {
  compact('Compact'),
  medium('Medium'),
  expanded('Expanded'),
  large('Large'),
  extraLarge('Extra large');

  const WindowSize(this.label);

  final String label;

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;
  static const double largeBreakpoint = 1200;
  static const double extraLargeBreakpoint = 1600;

  static WindowSize fromWidth(double width) {
    if (width >= extraLargeBreakpoint) {
      return WindowSize.extraLarge;
    }
    if (width >= largeBreakpoint) {
      return WindowSize.large;
    }
    if (width >= expandedBreakpoint) {
      return WindowSize.expanded;
    }
    if (width >= mediumBreakpoint) {
      return WindowSize.medium;
    }
    return WindowSize.compact;
  }

  /// Whether this size is [other] or larger.
  bool isAtLeast(WindowSize other) => index >= other.index;

  /// Number of columns for card grids.
  int get gridColumns => switch (this) {
    WindowSize.compact => 1,
    WindowSize.medium => 2,
    WindowSize.expanded => 3,
    WindowSize.large => 4,
    WindowSize.extraLarge => 4,
  };

  /// Horizontal page padding.
  double get pageGutter => switch (this) {
    WindowSize.compact => AppSpacing.md,
    WindowSize.medium => AppSpacing.lg,
    WindowSize.expanded => AppSpacing.xl,
    WindowSize.large => AppSpacing.xl,
    WindowSize.extraLarge => AppSpacing.xl,
  };
}

extension WindowSizeContextX on BuildContext {
  /// Window size class of the whole screen.
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
