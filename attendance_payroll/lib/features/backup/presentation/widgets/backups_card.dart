import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_formatting.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_view_providers.dart';
import 'package:attendance_payroll/features/backup/presentation/widgets/restore_backup_dialog.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _TileAction { export, restore, delete }

/// The backups kept on this device, with export, restore and delete.
class BackupsCard extends ConsumerStatefulWidget {
  const BackupsCard({super.key});

  @override
  ConsumerState<BackupsCard> createState() => _BackupsCardState();
}

class _BackupsCardState extends ConsumerState<BackupsCard> {
  bool _busy = false;
  String? _error;

  Future<void> _perform(BackupInfo info, _TileAction action) async {
    switch (action) {
      case _TileAction.export:
        await _export(info);
      case _TileAction.restore:
        await _restore(info);
      case _TileAction.delete:
        await _delete(info);
    }
  }

  Future<void> _export(BackupInfo info) async {
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
        .export(session, info.fileName);
    if (result.valueOrNull case final bytes?) {
      try {
        await ref.read(backupFileSharerProvider)(info.fileName, bytes);
      } on Object {
        if (mounted) {
          _error = 'Could not open the share sheet. Please try again.';
        }
      }
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error ??= result.failureOrNull?.userMessage;
      });
    }
  }

  Future<void> _restore(BackupInfo info) async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    final service = ref.read(backupServiceProvider);
    final different =
        (await service.isDifferentCompany(info.header)).valueOrNull ?? false;
    if (!mounted) {
      return;
    }
    final restored = await showRestoreBackupDialog(
      context,
      header: info.header,
      differentCompany: different,
      passwordRequired: false,
      restore: (password, allow) => service.restoreStored(
        session,
        info.fileName,
        password: password,
        allowDifferentCompany: allow,
      ),
    );
    if (restored) {
      // The administrators come from the restored data: sign in again.
      ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _delete(BackupInfo info) async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this backup?',
      message:
          'The backup from ${formatBackupTime(info.header.createdAt)} will be '
          'deleted from this device. Copies you exported elsewhere are not '
          'affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(backupServiceProvider)
        .delete(session, info.fileName);
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
    final listing = ref.watch(backupListingProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Text(
              'Backups on this device',
              style: context.textStyles.titleMedium,
            ),
            if (_error case final message?) FailureBanner(message: message),
            switch (listing) {
              AsyncData(:final value) => _list(context, value),
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

  Widget _list(BuildContext context, BackupListing listing) {
    if (listing.backups.isEmpty && listing.unreadable == 0) {
      return Text(
        'No backups yet. Choose "Back up now" to make the first one.',
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }
    return Column(
      children: [
        for (final info in listing.backups)
          _BackupTile(
            info: info,
            enabled: !_busy,
            onSelected: (action) => _perform(info, action),
          ),
        if (listing.unreadable > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '${listing.unreadable} '
              '${listing.unreadable == 1 ? 'file in the backup folder is' : 'files in the backup folder are'} '
              'not valid backups and are ignored.',
              style: context.textStyles.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({
    required this.info,
    required this.enabled,
    required this.onSelected,
  });

  final BackupInfo info;
  final bool enabled;
  final ValueChanged<_TileAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final header = info.header;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(switch (header.kind) {
        BackupKind.manual => Icons.touch_app_outlined,
        BackupKind.automatic => Icons.autorenew,
        BackupKind.safety => Icons.history,
      }),
      title: Text(formatBackupTime(header.createdAt)),
      subtitle: Text(
        '${header.kind.label} · ${header.createdBy} · '
        '${formatBytes(info.sizeBytes)}\n${describeContents(header.summary)}',
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<_TileAction>(
        tooltip: 'Backup actions',
        enabled: enabled,
        onSelected: onSelected,
        itemBuilder: (_) => const [
          PopupMenuItem(value: _TileAction.export, child: Text('Export')),
          PopupMenuItem(value: _TileAction.restore, child: Text('Restore')),
          PopupMenuItem(value: _TileAction.delete, child: Text('Delete')),
        ],
      ),
    );
  }
}
