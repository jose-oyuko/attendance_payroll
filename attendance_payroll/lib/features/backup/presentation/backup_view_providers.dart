import 'dart:typed_data';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The backups on this device, newest first.
final backupListingProvider = FutureProvider.autoDispose<BackupListing>((
  ref,
) async {
  final session = requireSession(ref);
  return (await ref.watch(backupServiceProvider).list(session)).unwrap();
});

final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((
  ref,
) async {
  final session = requireSession(ref);
  return (await ref.watch(backupServiceProvider).status(session)).unwrap();
});

final backupSettingsProvider = FutureProvider.autoDispose<BackupSettings>((
  ref,
) async {
  final session = requireSession(ref);
  return (await ref.watch(backupServiceProvider).settings(session)).unwrap();
});

/// Refreshes what the Backup screen shows after something changed.
void refreshBackups(WidgetRef ref) {
  ref
    ..invalidate(backupListingProvider)
    ..invalidate(backupStatusProvider)
    ..invalidate(backupSettingsProvider);
}

/// Makes an automatic backup once per sign-in when the newest is over a day
/// old. Watched by the administrator shell. A failure is remembered by the
/// service and shown on the Backup screen; it never interrupts whoever
/// opened the app.
final automaticBackupProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(adminSessionProvider);
  if (session == null) {
    return;
  }
  final result = await ref
      .read(backupServiceProvider)
      .runAutomaticIfDue(session);
  if (result case Ok(value: != null)) {
    ref
      ..invalidate(backupListingProvider)
      ..invalidate(backupStatusProvider);
  }
});

/// Lets the administrator choose a backup file. Resolves to its bytes, or
/// `null` when nothing was chosen. Replaced in tests, which have no system
/// file picker.
typedef BackupFilePicker = Future<Uint8List?> Function();

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => () async {
    // No type filter: Android cannot filter by an unknown extension, and
    // the file is checked when it is read.
    final file = await openFile();
    return file?.readAsBytes();
  },
);

/// Hands a backup file to the system share sheet (Drive, email, ...).
typedef BackupFileSharer = Future<void> Function(String name, Uint8List bytes);

final backupFileSharerProvider = Provider<BackupFileSharer>(
  (ref) => (name, bytes) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: name,
            mimeType: 'application/octet-stream',
          ),
        ],
        fileNameOverrides: [name],
      ),
    );
  },
);
