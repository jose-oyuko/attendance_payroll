import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_view_providers.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/section_card.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PIN status and the issue/reset action. The PIN itself is never shown,
/// except a newly issued temporary PIN, once.
class EmployeePinCard extends ConsumerStatefulWidget {
  const EmployeePinCard({required this.employee, super.key});

  final Employee employee;

  @override
  ConsumerState<EmployeePinCard> createState() => _EmployeePinCardState();
}

class _EmployeePinCardState extends ConsumerState<EmployeePinCard> {
  bool _busy = false;

  Future<void> _issue(PinState state) async {
    final session = ref.read(adminSessionProvider);
    final name = widget.employee.details.shownName;
    if (session == null) {
      return;
    }
    if (state != PinState.notSet) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Reset PIN?',
        message:
            "$name's current PIN stops working immediately. A new temporary "
            'PIN will be shown once; give it to $name, who must change it the '
            'first time they use it.',
        confirmLabel: 'Reset PIN',
        destructive: true,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }
    setState(() => _busy = true);
    final result = await ref
        .read(employeePinServiceProvider)
        .issueTemporaryPin(session, widget.employee.id);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ref.invalidate(employeePinStatusProvider(widget.employee.id));
    switch (result) {
      case Ok(:final value):
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _PinRevealDialog(employeeName: name, pin: value),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.employee.details.shownName;
    final status = ref.watch(employeePinStatusProvider(widget.employee.id));
    final state = status.value?.state;
    return SectionCard(
      title: 'PIN',
      action: state == null
          ? null
          : FilledButton.tonal(
              onPressed: _busy ? null : () => _issue(state),
              child: Text(state == PinState.notSet ? 'Issue PIN' : 'Reset PIN'),
            ),
      child: switch (status) {
        AsyncData(:final value) => SectionNote(_describe(value, name)),
        AsyncError(:final error) => SectionNote(
          AppFailure.from(error).userMessage,
        ),
        _ => const LinearProgressIndicator(),
      },
    );
  }

  String _describe(PinStatus status, String name) {
    return switch (status.state) {
      PinState.notSet => 'No PIN yet. Issue one so $name can clock in.',
      PinState.active => 'A PIN is set. Only $name knows it.',
      PinState.temporary =>
        'A temporary PIN was issued. $name must change it on first use.',
      PinState.locked =>
        'Locked after too many incorrect attempts until '
            '${formatTimeOfDay(context, status.lockedUntil!)}. Resetting the '
            'PIN unlocks it.',
    };
  }
}

class _PinRevealDialog extends StatelessWidget {
  const _PinRevealDialog({required this.employeeName, required this.pin});

  final String employeeName;
  final String pin;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Temporary PIN for $employeeName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          Semantics(
            label: 'PIN ${pin.split('').join(' ')}',
            excludeSemantics: true,
            child: SelectableText(
              pin,
              textAlign: TextAlign.center,
              style: context.textStyles.displaySmall?.copyWith(
                letterSpacing: AppSpacing.sm,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Text(
            'Give this PIN to the employee now. It will not be shown again. '
            'They must change it the first time they use it.',
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
