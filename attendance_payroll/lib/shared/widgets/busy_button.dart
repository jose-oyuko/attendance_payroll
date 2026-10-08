import 'package:flutter/material.dart';

/// A filled button that shows progress and ignores taps while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    super.key,
  });

  static const double _indicatorSize = 18;

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox.square(
              dimension: _indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: '$label in progress',
              ),
            )
          : Text(label),
    );
  }
}
