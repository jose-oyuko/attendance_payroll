import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/domain/backup_service.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for the password backups are encrypted with. Resolves to `true`
/// when it was saved.
Future<bool> showSetBackupPasswordDialog(
  BuildContext context, {
  required bool changing,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _SetBackupPasswordDialog(changing: changing),
  );
  return saved ?? false;
}

class _SetBackupPasswordDialog extends ConsumerStatefulWidget {
  const _SetBackupPasswordDialog({required this.changing});

  final bool changing;

  @override
  ConsumerState<_SetBackupPasswordDialog> createState() =>
      _SetBackupPasswordDialogState();
}

class _SetBackupPasswordDialogState
    extends ConsumerState<_SetBackupPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
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
        .read(backupServiceProvider)
        .setPassword(session, _password.text);
    if (!mounted) {
      return;
    }
    if (result.failureOrNull case final failure?) {
      setState(() {
        _busy = false;
        _error = failure.userMessage;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.changing ? 'Change backup password' : 'Set a backup password',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Text(
                'Backups are encrypted with this password, so anyone who '
                'gets a backup file cannot read your payroll data.',
                style: context.textStyles.bodyMedium,
              ),
              Text(
                'Write it down and keep it safe. It cannot be recovered: '
                'without it, a backup cannot be restored, not even by us.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
              if (widget.changing)
                Text(
                  'Backups you already made keep the password they were '
                  'made with.',
                  style: context.textStyles.bodySmall,
                ),
              if (_error case final message?) FailureBanner(message: message),
              PasswordField(
                controller: _password,
                label: 'Backup password',
                autofillHints: const <String>[],
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value ?? '').length < BackupService.minPasswordLength
                    ? 'Use at least ${BackupService.minPasswordLength} '
                          'characters.'
                    : null,
              ),
              PasswordField(
                controller: _confirm,
                label: 'Confirm the password',
                autofillHints: const <String>[],
                onSubmitted: (_) => _save(),
                validator: (value) =>
                    value != _password.text ? 'The passwords differ.' : null,
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
        BusyButton(label: 'Save password', busy: _busy, onPressed: _save),
      ],
    );
  }
}
