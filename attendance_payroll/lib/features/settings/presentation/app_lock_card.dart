import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/kiosk/data/kiosk_providers.dart';
import 'package:attendance_payroll/features/kiosk/domain/app_lock_service.dart';
import 'package:attendance_payroll/features/kiosk/presentation/app_lock_providers.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "1 minute", "15 minutes", "1 hour", "Never".
String describeLockTime(int minutes) {
  if (minutes == AppLockService.neverMinutes) {
    return 'Never';
  }
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}

/// How long the app may sit untouched before it locks and shows the
/// kiosk. A setting of this device; changing it takes effect at once.
class AppLockCard extends ConsumerStatefulWidget {
  const AppLockCard({super.key});

  @override
  ConsumerState<AppLockCard> createState() => _AppLockCardState();
}

class _AppLockCardState extends ConsumerState<AppLockCard> {
  bool _busy = false;
  String? _error;

  Future<void> _choose(int minutes) async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(appLockServiceProvider)
        .setMinutes(session, minutes);
    if (!mounted) {
      return;
    }
    ref.invalidate(appLockMinutesProvider);
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.userMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = ref.watch(appLockMinutesProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text('App lock', style: context.textStyles.titleMedium),
            Text(
              'When nobody touches the app for this long, it locks and shows '
              'the attendance kiosk. Employees can still clock in and out; an '
              'administrator signs in to unlock it. The app is also locked '
              'whenever it starts.',
              style: context.textStyles.bodyMedium,
            ),
            if (_error case final message?) FailureBanner(message: message),
            switch (minutes) {
              AsyncData(:final value) => _picker(context, value),
              AsyncError(:final error) => FailureBanner(
                message: AppFailure.from(error).userMessage,
              ),
              _ => const LinearProgressIndicator(),
            },
          ],
        ),
      ),
    );
  }

  Widget _picker(BuildContext context, int current) {
    final times = {...AppLockService.choices, if (current > 0) current}.toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('lock-$current'),
          isExpanded: true,
          initialValue: current,
          decoration: const InputDecoration(labelText: 'Lock the app after'),
          items: [
            for (final time in times)
              DropdownMenuItem(
                value: time,
                child: Text(describeLockTime(time)),
              ),
            const DropdownMenuItem(
              value: AppLockService.neverMinutes,
              child: Text('Never (not recommended)'),
            ),
          ],
          onChanged: _busy
              ? null
              : (value) => value == null ? null : _choose(value),
        ),
        if (current == AppLockService.neverMinutes)
          Text(
            'The app stays open until someone locks it. Anyone who picks up '
            'the device can see attendance and payroll.',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
      ],
    );
  }
}
