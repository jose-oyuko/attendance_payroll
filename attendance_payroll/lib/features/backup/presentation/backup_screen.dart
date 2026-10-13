import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_view_providers.dart';
import 'package:attendance_payroll/features/backup/presentation/widgets/backup_settings_card.dart';
import 'package:attendance_payroll/features/backup/presentation/widgets/backup_status_card.dart';
import 'package:attendance_payroll/features/backup/presentation/widgets/backups_card.dart';
import 'package:attendance_payroll/features/backup/presentation/widgets/restore_backup_dialog.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Back up, restore and import the company's data.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          BackupStatusCard(),
          BackupsCard(),
          AdaptiveGrid(
            maxColumns: 2,
            children: [_ImportCard(), BackupSettingsCard()],
          ),
        ],
      ),
    );
  }
}

/// Restores from a file that is not in the list: one exported earlier, or
/// brought from another device.
class _ImportCard extends ConsumerStatefulWidget {
  const _ImportCard();

  @override
  ConsumerState<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends ConsumerState<_ImportCard> {
  bool _busy = false;

  Future<void> _import() async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    final service = ref.read(backupServiceProvider);
    setState(() => _busy = true);
    final bytes = await ref.read(backupFilePickerProvider)();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (bytes == null) {
      return;
    }
    final header = service.inspect(bytes);
    if (header.failureOrNull case final failure?) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(failure.userMessage)));
      return;
    }
    final info = header.unwrap();
    final different =
        (await service.isDifferentCompany(info)).valueOrNull ?? false;
    if (!mounted) {
      return;
    }
    final restored = await showRestoreBackupDialog(
      context,
      header: info,
      differentCompany: different,
      askPassword: info.passwordProtected,
      passwordRequired: info.passwordProtected,
      restore: (password, allow) => service.restore(
        session,
        bytes,
        password: password,
        allowDifferentCompany: allow,
      ),
    );
    if (restored) {
      // The administrators come from the restored data: sign in again.
      await ref
          .read(authControllerProvider.notifier)
          .lock(
            reason: 'The backup was restored. Sign in to continue.',
            system: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text('Restore from a file', style: context.textStyles.titleMedium),
            Text(
              'Use a backup file you exported earlier, or one from another '
              'device. You will need the password it was made with.',
              style: context.textStyles.bodyMedium,
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Choose backup file'),
            ),
          ],
        ),
      ),
    );
  }
}
