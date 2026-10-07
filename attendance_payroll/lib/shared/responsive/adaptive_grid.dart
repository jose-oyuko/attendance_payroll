import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:flutter/widgets.dart';

/// Lays out [children] in equal-width columns, choosing the column count from
/// the width available to the grid. Items keep their natural height.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    required this.children,
    super.key,
    this.spacing = AppSpacing.md,
    this.maxColumns,
  });

  final List<Widget> children;
  final double spacing;

  /// Optional upper bound on the column count.
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'AdaptiveGrid needs a bounded width.',
        );
        final cap = maxColumns;
        var columns = WindowSize.fromWidth(constraints.maxWidth).gridColumns;
        if (cap != null && columns > cap) {
          columns = cap;
        }
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
