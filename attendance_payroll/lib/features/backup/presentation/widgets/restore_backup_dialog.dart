import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_formatting.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';

/// Does the restore with the password typed (or `null` to use this
/// device's backup password) and the permission to replace another
/// company's data.
typedef RestoreAction =
    Future<Result<RestoreOutcome>> Function(
      String? password,
      bool allowDifferentCompany,
    );

/// Shows what a backup holds, explains what restoring does, asks for
/// confirmation and the backup password, runs the restore and reports the
/// result. Resolves to `true` once the data has been replaced.
Future<bool> showRestoreBackupDialog(
  BuildContext context, {
  required BackupHeader header,
  required RestoreAction restore,
  required bool differentCompany,
  required bool passwordRequired,
  bool newInstallation = false,
}) async {
  final restored = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RestoreBackupDialog(
      header: header,
      restore: restore,
      differentCompany: differentCompany,
      passwordRequired: passwordRequired,
      newInstallation: newInstallation,
    ),
  );
  return restored ?? false;
}

class _RestoreBackupDialog extends StatefulWidget {
  const _RestoreBackupDialog({
    required this.header,
    required this.restore,
    required this.differentCompany,
    required this.passwordRequired,
    required this.newInstallation,
  });

  final BackupHeader header;
  final RestoreAction restore;
  final bool differentCompany;
  final bool passwordRequired;
  final bool newInstallation;

  @override
  State<_RestoreBackupDialog> createState() => _RestoreBackupDialogState();
}

class _RestoreBackupDialogState extends State<_RestoreBackupDialog> {
  final _password = TextEditingController();
  bool _acknowledged = false;
  bool _busy = false;
  String? _error;
  RestoreOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    // Restore is enabled once a password is typed.
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _canRestore =>
      !_busy &&
      (!widget.differentCompany || _acknowledged || widget.newInstallation) &&
      (!widget.passwordRequired || _password.text.isNotEmpty);

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final password = _password.text.isEmpty ? null : _password.text;
    final result = await widget.restore(
      password,
      widget.differentCompany && (_acknowledged || widget.newInstallation),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      switch (result) {
        case Ok(:final value):
          _outcome = value;
        case Err(:final failure):
          _error = failure.userMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    if (outcome != null) {
      return _done(context, outcome);
    }
    final header = widget.header;
    return AlertDialog(
      title: Text(
        widget.newInstallation ? 'Restore this backup?' : 'Replace all data?',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            _details(context, header),
            if (!widget.newInstallation)
              Text(
                'Everything in the app now will be replaced by this backup. '
                'Anything recorded after ${formatBackupTime(header.createdAt)} '
                'will no longer be in the app. A safety backup of the current '
                'data is saved first, so this can be undone.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            if (widget.differentCompany && !widget.newInstallation) ...[
              Text(
                BackupFailures.differentCompany.userMessage,
                style: context.textStyles.bodyMedium,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _acknowledged,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _acknowledged = value ?? false),
                title: Text(
                  'I understand this replaces the company on this device.',
                  style: context.textStyles.bodyMedium,
                ),
              ),
            ],
            if (_error case final message?) FailureBanner(message: message),
            PasswordField(
              controller: _password,
              label: widget.passwordRequired
                  ? 'Password of this backup'
                  : 'Password of this backup (optional)',
              autofillHints: const <String>[],
              onSubmitted: (_) => _canRestore ? _restore() : null,
              validator: null,
            ),
            if (!widget.passwordRequired)
              Text(
                "Leave it empty to use this device's backup password.",
                style: context.textStyles.bodySmall,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: widget.newInstallation
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                ),
          onPressed: _canRestore ? _restore : null,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Restoring',
                  ),
                )
              : const Text('Restore'),
        ),
      ],
    );
  }

  Widget _details(BuildContext context, BackupHeader header) {
    final style = context.textStyles.bodyMedium;
    final latest = header.summary.latestAttendanceAt;
    Widget row(String label, String value) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: style?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        Expanded(child: Text(value, style: style)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        row('Company', header.companyName),
        row('Made', formatBackupTime(header.createdAt)),
        row('By', header.createdBy),
        row('Contains', describeContents(header.summary)),
        if (latest != null) row('Latest clock', formatBackupTime(latest)),
        row('App version', header.appVersion),
      ],
    );
  }

  Widget _done(BuildContext context, RestoreOutcome outcome) {
    return AlertDialog(
      icon: const Icon(Icons.check_circle_outline),
      title: const Text('Backup restored'),
      content: Text(
        'The data from ${formatBackupTime(outcome.restored.createdAt)} is now '
        'in the app. ${outcome.safetyBackup == null ? '' : 'The data it '
                  'replaced was saved as a backup called "Before a restore". '}'
        'Sign in again with an administrator account from the backup.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
