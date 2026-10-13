import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/password_policy.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for the current password and a new one. Resolves to `true` once the
/// password was changed.
Future<bool> showChangePasswordDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
  return changed ?? false;
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(adminAuthServiceProvider)
        .changePassword(
          session,
          currentPassword: _current.text,
          newPassword: _new.text,
        );
    if (!mounted) {
      return;
    }
    if (result.failureOrNull case final failure?) {
      setState(() {
        _busy = false;
        _error = failure.userMessage;
      });
      _current.clear();
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (_error case final message?) FailureBanner(message: message),
              PasswordField(
                controller: _current,
                label: 'Current password',
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your current password.' : null,
              ),
              PasswordField(
                controller: _new,
                label: 'New password',
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (v) => PasswordPolicy.validate(v ?? '')?.userMessage,
              ),
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _save(),
                validator: (v) =>
                    v == _new.text ? null : 'The passwords do not match.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        BusyButton(label: 'Change password', busy: _busy, onPressed: _save),
      ],
    );
  }
}
