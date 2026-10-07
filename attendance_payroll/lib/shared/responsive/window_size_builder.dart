import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:flutter/widgets.dart';

/// Builds its child from the [WindowSize] of the space it is given.
class WindowSizeBuilder extends StatelessWidget {
  const WindowSizeBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, WindowSize size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, WindowSize.fromWidth(constraints.maxWidth)),
    );
  }
}
