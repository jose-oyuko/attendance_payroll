import 'dart:typed_data';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';

/// Where backup files are kept (spec §26: backup provider). The local
/// folder is the first implementation; Google Drive or another cloud
/// provider is another implementation of this interface, with no change to
/// the backup rules. Files are opaque encrypted bytes to a store.
///
/// Methods throw an `AppFailure` when the store cannot be used.
abstract interface class BackupStorage {
  Future<List<StoredBackupFile>> list();

  /// The first [maxBytes] of the file (its header), without reading it all.
  Future<Uint8List> readPrefix(String name, int maxBytes);

  Future<Uint8List> read(String name);

  /// Stores [bytes] as [name], completely or not at all: a half-written
  /// file never appears in [list].
  Future<void> write(String name, Uint8List bytes);

  Future<void> delete(String name);
}

/// The backup file format: a readable header, then the data encrypted with a
/// key derived from the backup password. Throws an `AppFailure` (see
/// `BackupFailures`) for files it cannot read.
abstract interface class BackupCodec {
  /// Bytes from the start of a file that always contain its whole header.
  static const int headerPrefixBytes = 16 * 1024;

  /// Reads the header of [file], or of its first [headerPrefixBytes].
  BackupHeader readHeader(Uint8List file);

  Future<Uint8List> encode({
    required BackupHeader header,
    required Uint8List snapshot,
    required String password,
  });

  /// The database snapshot inside [file]. Fails with
  /// `BackupFailures.wrongPassword` if the password is wrong or any byte of
  /// the file was changed.
  Future<Uint8List> decode(Uint8List file, String password);
}

/// The live database, as far as backups are concerned.
abstract interface class BackupDatabase {
  /// The company on this device, or `null` before first-run setup.
  Future<String?> currentCompanyId();

  /// A consistent copy of everything, taken while the app keeps running.
  /// Fails with `BackupFailures.nothingToBackUp` before setup.
  Future<DatabaseSnapshot> snapshot();

  /// Checks that [snapshot] is a sound database this version can restore
  /// (not damaged, not from a newer version), and says what it holds.
  Future<BackupSummary> check(Uint8List snapshot);

  /// Replaces the company data with [snapshot] in one transaction: either
  /// all of it is replaced or none is. Data that belongs to this device
  /// (its identity, kiosk, printer and backup settings) is kept. [inside]
  /// runs in the same transaction after the data is replaced, with the
  /// restored company id, so what it writes is part of the restored data
  /// (used for the audit entry).
  Future<void> restore(
    Uint8List snapshot, {
    required Future<void> Function(String companyId) inside,
  });
}

/// The backup password, kept in the platform's secure storage so automatic
/// backups can encrypt without asking. It is never shown or logged.
abstract interface class BackupSecretStore {
  Future<String?> read();

  Future<void> write(String password);
}

/// The backup routine of this device.
abstract interface class BackupSettingsRepository {
  /// The saved settings, or the defaults when none exist.
  Future<Result<BackupSettings>> load();

  Future<Result<void>> save(BackupSettings settings);
}
