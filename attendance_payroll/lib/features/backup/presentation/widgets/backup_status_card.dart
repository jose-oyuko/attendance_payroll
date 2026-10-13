import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_formatting.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_view_providers.dart';
import 'package:attendance_payroll/features/backup/presentation/widgets/set_backup_password_dialog.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When the last backup was made, whether one is overdue, the backup
/// password, and "Back up now".
class BackupStatusCard extends ConsumerStatefulWidget {
  const BackupStatusCard({super.key});

  @override
  ConsumerState<BackupStatusCard> createState() => _BackupStatusCardState();
}

class _BackupStatusCardState extends ConsumerState<BackupStatusCard> {
  bool _busy = false;
  String? _error;

  Future<void> _backUp() async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(backupServiceProvider).create(session);
    if (!mounted) {
      return;
    }
    refreshBackups(ref);
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.userMessage;
    });
    if (result.valueOrNull case final info?) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Backup saved (${formatBytes(info.sizeBytes)}).'),
          ),
        );
    }
  }

  Future<void> _setPassword({required bool changing}) async {
    await showSetBackupPasswordDialog(context, changing: changing);
    if (mounted) {
      refreshBackups(ref);
    }
  }

  /// Back to standard protection for new backups. Asks first: a password is
  /// the stronger choice, and the old backups keep needing it.
  Future<void> _removePassword() async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Stop using a backup password?',
      message:
          'New backups will use standard protection: they are encrypted, but '
          'anyone who has this app and the backup file can open them. Backups '
          'you already made keep their password and still need it.',
      confirmLabel: 'Use standard protection',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final result = await ref
        .read(backupServiceProvider)
        .removePassword(session);
    if (!mounted) {
      return;
    }
    refreshBackups(ref);
    setState(() => _error = result.failureOrNull?.userMessage);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(backupStatusProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: switch (status) {
          AsyncData(:final value) => _content(context, value),
          AsyncError(:final error) => FailureBanner(
            message: AppFailure.from(error).userMessage,
          ),
          _ => const LinearProgressIndicator(),
        },
      ),
    );
  }

  Widget _content(BuildContext context, BackupStatus status) {
    final semantic = context.semanticColors;
    final last = status.lastBackupAt;
    final warn = status.reminderDue;
    final color = warn ? semantic.warning : semantic.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Icon(
              warn ? Icons.warning_amber_outlined : Icons.check_circle_outline,
              color: color.color,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    last == null
                        ? 'No backup yet'
                        : 'Last backup ${formatAgo(last, DateTime.now())}',
                    style: context.textStyles.titleMedium,
                  ),
                  if (last != null) Text(formatBackupTime(last)),
                  if (warn)
                    Text(
                      last == null
                          ? 'Back up now so your attendance and payroll are '
                                'safe if this device is lost or damaged.'
                          : 'It is time for a new backup.',
                    ),
                ],
              ),
            ),
          ],
        ),
        if (status.lastAutomaticError case final message?)
          FailureBanner(message: 'The last automatic backup failed. $message'),
        if (_error case final message?) FailureBanner(message: message),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            BusyButton(label: 'Back up now', busy: _busy, onPressed: _backUp),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _setPassword(changing: status.hasPassword),
              icon: const Icon(Icons.key_outlined),
              label: Text(
                status.hasPassword
                    ? 'Change backup password'
                    : 'Add a backup password',
              ),
            ),
            if (status.hasPassword)
              TextButton(
                onPressed: _busy ? null : _removePassword,
                child: const Text('Use standard protection'),
              ),
          ],
        ),
        Text(
          status.hasPassword
              ? 'Backups are encrypted and protected with your backup '
                    'password.'
              : 'Backups are always encrypted. With standard protection '
                    '(no password) they cannot be read as a plain file, but '
                    'anyone who has this app and the backup file can open '
                    'them. Add a password if backups leave this device.',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          'Backups are kept on this device. To be safe if the device is lost, '
          'export a backup and keep the file somewhere else, such as Google '
          'Drive or email.',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
