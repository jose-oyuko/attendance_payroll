import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/domain/pin_policy.dart';
import 'package:flutter/material.dart';

/// Large on-screen keypad for PIN entry. Digits are never shown, only dots.
class PinPad extends StatefulWidget {
  const PinPad({
    required this.onSubmitted,
    super.key,
    this.onActivity,
    this.enabled = true,
    this.submitLabel = 'OK',
  });

  /// Kiosk keys are deliberately larger than the 48 dp minimum.
  static const double keySize = 76;

  final ValueChanged<String> onSubmitted;

  /// Called on every key press, e.g. to postpone an inactivity timeout.
  final VoidCallback? onActivity;
  final bool enabled;
  final String submitLabel;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _type(String digit) {
    widget.onActivity?.call();
    if (_pin.length < PinPolicy.maxLength) {
      setState(() => _pin += digit);
    }
  }

  void _delete() {
    widget.onActivity?.call();
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _submit() {
    final pin = _pin;
    setState(() => _pin = '');
    widget.onSubmitted(pin);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final canSubmit = enabled && _pin.length >= PinPolicy.minLength;
    Widget key(String digit) => _Key(
      label: digit,
      semanticLabel: digit,
      onPressed: enabled ? () => _type(digit) : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.md,
      children: [
        Semantics(
          liveRegion: true,
          label: '${_pin.length} digits entered',
          excludeSemantics: true,
          child: SizedBox(
            height: AppSpacing.lg,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: [
                for (var i = 0; i < PinPolicy.maxLength; i++)
                  _Dot(filled: i < _pin.length),
              ],
            ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.md,
            children: [for (final digit in row) key(digit)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            _Key(
              icon: Icons.backspace_outlined,
              semanticLabel: 'Delete',
              onPressed: enabled ? _delete : null,
            ),
            key('0'),
            _Key(
              label: widget.submitLabel,
              semanticLabel: widget.submitLabel,
              primary: true,
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.semanticLabel,
    required this.onPressed,
    this.label,
    this.icon,
    this.primary = false,
  });

  final String? label;
  final IconData? icon;
  final String semanticLabel;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = icon != null
        ? Icon(icon)
        : Text(label!, style: context.textStyles.headlineSmall);
    final style = ButtonStyle(
      fixedSize: const WidgetStatePropertyAll(Size.square(PinPad.keySize)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: primary
          ? FilledButton(onPressed: onPressed, style: style, child: content)
          : FilledButton.tonal(
              onPressed: onPressed,
              style: style,
              child: content,
            ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: AppSpacing.md,
      height: AppSpacing.md,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.primary : null,
        border: Border.all(color: colors.outline),
      ),
    );
  }
}
