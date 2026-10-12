import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_view_providers.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Automatic backups, how many to keep and when to remind. Changes save
/// at once.
class BackupSettingsCard extends ConsumerStatefulWidget {
  const BackupSettingsCard({super.key});

  static const List<int> retentionChoices = [5, 10, 20, 30, 50];
  static const List<int> reminderChoices = [3, 7, 14, 30];

  @override
  ConsumerState<BackupSettingsCard> createState() => _BackupSettingsCardState();
}

class _BackupSettingsCardState extends ConsumerState<BackupSettingsCard> {
  bool _busy = false;
  String? _error;

  Future<void> _save(
    BackupSettings current, {
    bool? automatic,
    int? keep,
    int? remindAfter,
  }) async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(backupServiceProvider)
        .updateSettings(
          session,
          automaticEnabled: automatic ?? current.automaticEnabled,
          retentionCount: keep ?? current.retentionCount,
          reminderDays: remindAfter ?? current.reminderDays,
        );
    if (!mounted) {
      return;
    }
    refreshBackups(ref);
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.userMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(backupSettingsProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text('Backup settings', style: context.textStyles.titleMedium),
            if (_error case final message?) FailureBanner(message: message),
            switch (settings) {
              AsyncData(:final value) => _form(context, value),
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

  Widget _form(BuildContext context, BackupSettings settings) {
    List<int> choices(List<int> base, int current) =>
        {...base, current}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Automatic backups'),
          subtitle: const Text(
            'Make a backup when the app is opened and the last one is more '
            'than a day old.',
          ),
          value: settings.automaticEnabled,
          onChanged: _busy ? null : (on) => _save(settings, automatic: on),
        ),
        DropdownButtonFormField<int>(
          key: ValueKey('keep-${settings.retentionCount}'),
          initialValue: settings.retentionCount,
          decoration: const InputDecoration(
            labelText: 'Automatic backups to keep',
            helperText:
                'Older automatic backups are deleted. Manual backups '
                'are never deleted.',
            helperMaxLines: 2,
          ),
          items: [
            for (final n in choices(
              BackupSettingsCard.retentionChoices,
              settings.retentionCount,
            ))
              DropdownMenuItem(value: n, child: Text('$n')),
          ],
          onChanged: _busy
              ? null
              : (n) => n == null ? null : _save(settings, keep: n),
        ),
        DropdownButtonFormField<int>(
          key: ValueKey('remind-${settings.reminderDays}'),
          initialValue: settings.reminderDays,
          decoration: const InputDecoration(
            labelText: 'Remind me after',
            helperText: 'Days without any backup before a reminder shows.',
            helperMaxLines: 2,
          ),
          items: [
            for (final n in choices(
              BackupSettingsCard.reminderChoices,
              settings.reminderDays,
            ))
              DropdownMenuItem(value: n, child: Text('$n days')),
          ],
          onChanged: _busy
              ? null
              : (n) => n == null ? null : _save(settings, remindAfter: n),
        ),
      ],
    );
  }
}
