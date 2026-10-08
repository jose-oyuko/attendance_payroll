import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_state.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_flow.dart';
import 'package:attendance_payroll/features/kiosk/presentation/widgets/pin_pad.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centred, width-limited column used by every step after the name.
class _StepFrame extends StatelessWidget {
  const _StepFrame({required this.children});

  static const double maxWidth = 520;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Column(
      spacing: AppSpacing.sm,
      children: [
        Semantics(
          header: true,
          child: Text(
            text,
            style: context.textStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: context.textStyles.titleMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.colors});

  final String text;
  final SemanticColorSet colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.textStyles.titleMedium?.copyWith(
              color: colors.onContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends ConsumerWidget {
  const _BackButton({this.label = 'Not you? Start again'});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(kioskFlowProvider.notifier).reset(),
      child: Text(label),
    );
  }
}

class PinEntryStep extends ConsumerWidget {
  const PinEntryStep({required this.step, required this.busy, super.key});

  final EnteringPin step;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(kioskFlowProvider.notifier);
    final error = step.error;
    return _StepFrame(
      children: [
        _Title('Hello, ${step.employee.name}', subtitle: 'Enter your PIN'),
        if (error != null)
          _Message(error, colors: context.semanticColors.warning),
        Center(
          child: PinPad(
            enabled: !busy,
            onActivity: flow.touch,
            onSubmitted: flow.submitPin,
          ),
        ),
        const _BackButton(),
      ],
    );
  }
}

class NewPinStep extends ConsumerWidget {
  const NewPinStep({required this.step, required this.busy, super.key});

  final ChoosingNewPin step;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(kioskFlowProvider.notifier);
    final confirming = step.firstEntry != null;
    final error = step.error;
    return _StepFrame(
      children: [
        _Title(
          confirming ? 'Enter your new PIN again' : 'Choose a new PIN',
          subtitle: step.isRequired && !confirming
              ? 'Your PIN was set by your manager. Choose your own '
                    '4 to 6 digit PIN to continue.'
              : '4 to 6 digits. Avoid repeated or consecutive digits.',
        ),
        if (error != null)
          _Message(error, colors: context.semanticColors.warning),
        Center(
          child: PinPad(
            // A new pad for each entry, so the first PIN is not shown again.
            key: ValueKey(confirming),
            enabled: !busy,
            onActivity: flow.touch,
            onSubmitted: flow.submitNewPin,
            submitLabel: confirming ? 'Save' : 'Next',
          ),
        ),
        const _BackButton(label: 'Cancel'),
      ],
    );
  }
}

class ConfirmStep extends ConsumerWidget {
  const ConfirmStep({
    required this.step,
    required this.busy,
    required this.timeZone,
    super.key,
  });

  /// Primary actions are taller than standard buttons for easy tapping.
  static const double actionHeight = 72;

  final Confirming step;
  final bool busy;
  final CompanyTimeZone timeZone;

  String _greeting() {
    final hour = timeZone.wallTimeOf(DateTime.now()).timeOfDay.inHours;
    if (hour < 12) {
      return 'Good morning';
    }
    return hour < 17 ? 'Good afternoon' : 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(kioskFlowProvider.notifier);
    final semantic = context.semanticColors;
    final state = step.state;
    final (status, primary, secondary) = switch (state) {
      NotClockedIn() => (
        'You are not clocked in.',
        AttendanceEventType.clockIn,
        null,
      ),
      ClockedIn(isStale: false, :final since) => (
        'Clocked in since ${formatCompanyTime(context, timeZone, since)}.',
        AttendanceEventType.clockOut,
        null,
      ),
      ClockedIn(isStale: true, :final since) => (
        'Your last clock-in (${formatCompanyTime(context, timeZone, since)}) '
            'has no clock-out. Your manager will review it.',
        AttendanceEventType.clockIn,
        AttendanceEventType.clockOut,
      ),
    };
    final message = step.message;
    final error = step.error;

    Widget action(AttendanceEventType type, {required bool main}) {
      final label = type == AttendanceEventType.clockIn
          ? 'Clock in'
          : 'Clock out';
      final icon = type == AttendanceEventType.clockIn
          ? Icons.login
          : Icons.logout;
      final onPressed = busy ? null : () => flow.clock(type);
      final style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(actionHeight),
        ),
        textStyle: WidgetStatePropertyAll(context.textStyles.titleLarge),
      );
      return main
          ? FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon),
              label: Text(label),
            );
    }

    return _StepFrame(
      children: [
        _Title('${_greeting()}, ${step.employee.name}', subtitle: status),
        if (message != null) _Message(message, colors: semantic.success),
        if (error != null) _Message(error, colors: semantic.warning),
        action(primary, main: true),
        if (secondary != null) action(secondary, main: false),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _BackButton(label: 'Cancel'),
            TextButton(
              onPressed: busy ? null : flow.startPinChange,
              child: const Text('Change my PIN'),
            ),
          ],
        ),
      ],
    );
  }
}

class FinishedStep extends ConsumerWidget {
  const FinishedStep({required this.step, required this.timeZone, super.key});

  static const double iconSize = 96;

  final Finished step;
  final CompanyTimeZone timeZone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = step.event;
    final time = formatCompanyTime(context, timeZone, event.occurredAt);
    final clockedIn = event.type == AttendanceEventType.clockIn;
    final semantic = context.semanticColors;
    return _StepFrame(
      children: [
        Icon(Icons.check_circle, size: iconSize, color: semantic.success.color),
        _Title(
          clockedIn ? 'Clocked in at $time' : 'Clocked out at $time',
          subtitle: clockedIn
              ? 'Have a good day, ${step.employee.name}.'
              : 'Goodbye, ${step.employee.name}.',
        ),
        FilledButton(
          onPressed: () => ref.read(kioskFlowProvider.notifier).reset(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
