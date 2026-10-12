import 'dart:typed_data';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/platform/device_identity_repository.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';

/// Backing up and restoring the company's data.
///
/// A backup is a verified, encrypted copy of the whole database kept in a
/// [BackupStorage]. A restore validates the file first, keeps a safety
/// backup of the data it replaces, then replaces the data in one
/// transaction, so it either completes or leaves the data as it was.
final class BackupService {
  BackupService({
    required this._storage,
    required this._codec,
    required this._database,
    required this._settings,
    required this._secrets,
    required this._kiosk,
    required this._devices,
    required this._audit,
    required this._appVersion,
    this._clock = systemClockUtc,
  });

  /// The backup file format this version writes and reads.
  static const int backupVersion = 1;

  static const int minPasswordLength = 8;

  /// File extension of backups.
  static const String extension = '.apbackup';

  /// What a backup made by the app (rather than a person) says made it.
  static const String automaticAuthor = 'Automatic backup';

  /// An automatic backup is made when the newest backup is older than this.
  static const Duration automaticInterval = Duration(hours: 24);

  /// After a failed automatic backup, wait this long before trying again.
  static const Duration automaticRetryDelay = Duration(hours: 1);

  /// Safety backups kept (the ones made before restores).
  static const int safetyBackupsKept = 3;

  final BackupStorage _storage;
  final BackupCodec _codec;
  final BackupDatabase _database;
  final BackupSettingsRepository _settings;
  final BackupSecretStore _secrets;
  final KioskModeRepository _kiosk;
  final DeviceIdentityRepository _devices;
  final AuditLogRepository _audit;
  final String _appVersion;
  final Clock _clock;

  // Backups ------------------------------------------------------------

  /// The backups on this device, newest first.
  Future<Result<BackupListing>> list(AdminSession session) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return Result.guard(_listing);
  }

  /// Where backups stand: is there a password, when was the last backup,
  /// and is a reminder due.
  Future<Result<BackupStatus>> status(AdminSession session) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      // An unreadable backup folder must not hide the rest of the status
      // (such as why the last automatic backup failed).
      final BackupListing listing;
      try {
        listing = await _listing();
      } on AppFailure {
        return _statusOf(const BackupListing(backups: []));
      }
      return _statusOf(listing);
    });
  }

  Future<BackupStatus> _statusOf(BackupListing listing) async {
    final settings = (await _settings.load()).unwrap();
    final last = listing.backups.isEmpty
        ? null
        : listing.backups.first.header.createdAt;
    return BackupStatus(
      hasPassword: await _secrets.read() != null,
      lastBackupAt: last,
      reminderDue:
          last == null ||
          _clock().difference(last) > Duration(days: settings.reminderDays),
      lastAutomaticError: settings.lastAutomaticError,
    );
  }

  /// Makes a verified, encrypted backup of everything now.
  Future<Result<BackupInfo>> create(
    AdminSession session, {
    BackupKind kind = BackupKind.manual,
  }) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final password =
          await _secrets.read() ?? (throw BackupFailures.noPassword);
      final info = await _write(
        password: password,
        kind: kind,
        createdBy: kind == BackupKind.automatic
            ? automaticAuthor
            : session.admin.displayName,
      );
      (await _audit.record(
        AuditEntry(
          companyId: info.header.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.backupCreated,
          entityType: 'backup',
          entityId: info.fileName,
          metadata: {'kind': kind.name},
        ),
      )).unwrap();
      await _prune();
      return info;
    });
  }

  /// Makes an automatic backup if the newest is older than a day, automatic
  /// backups are on, and a password is set. `null` when none was due.
  /// Failures are remembered for the Backup screen, not thrown at whoever
  /// opened the app.
  Future<Result<BackupInfo?>> runAutomaticIfDue(AdminSession session) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    final due = await Result.guard<bool>(() async {
      final settings = (await _settings.load()).unwrap();
      if (!settings.automaticEnabled || await _secrets.read() == null) {
        return false;
      }
      final now = _clock();
      final attempt = settings.lastAutomaticAttemptAt;
      if (attempt != null && now.difference(attempt) < automaticRetryDelay) {
        return false;
      }
      final newest = (await _listing()).backups
          .where((b) => b.header.kind != BackupKind.safety)
          .firstOrNull;
      return newest == null ||
          now.difference(newest.header.createdAt) >= automaticInterval;
    });
    if (due case Err(:final failure)) {
      await _rememberAutomaticFailure(failure);
      return Err(failure);
    }
    if (due case Ok(value: false)) {
      return const Ok(null);
    }
    final attempted = (await _settings.load()).unwrap().copyWith(
      lastAutomaticAttemptAt: _clock(),
    );
    (await _settings.save(attempted)).unwrap();
    final made = await create(session, kind: BackupKind.automatic);
    final latest = (await _settings.load()).unwrap();
    switch (made) {
      case Ok(:final value):
        (await _settings.save(
          latest.copyWith(clearLastAutomaticError: true),
        )).unwrap();
        return Ok(value);
      case Err(:final failure):
        await _rememberAutomaticFailure(failure);
        return Err(failure);
    }
  }

  /// Keeps why the last automatic backup failed for the Backup screen, and
  /// when, so it is not retried straight away.
  Future<void> _rememberAutomaticFailure(AppFailure failure) async {
    final current = await _settings.load();
    if (current case Ok(:final value)) {
      await _settings.save(
        value.copyWith(
          lastAutomaticAttemptAt: _clock(),
          lastAutomaticError: failure.userMessage,
        ),
      );
    }
  }

  /// The bytes of a stored backup, to export it. Recorded in the audit log:
  /// the file leaves the device (still encrypted).
  Future<Result<Uint8List>> export(
    AdminSession session,
    String fileName,
  ) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final bytes = await _storage.read(_checkName(fileName));
      final header = _codec.readHeader(bytes);
      (await _audit.record(
        AuditEntry(
          companyId: header.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.backupExported,
          entityType: 'backup',
          entityId: fileName,
        ),
      )).unwrap();
      return bytes;
    });
  }

  Future<Result<void>> delete(AdminSession session, String fileName) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final name = _checkName(fileName);
      final header = _codec.readHeader(
        await _storage.readPrefix(name, BackupCodec.headerPrefixBytes),
      );
      await _storage.delete(name);
      (await _audit.record(
        AuditEntry(
          companyId: header.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.backupDeleted,
          entityType: 'backup',
          entityId: name,
        ),
      )).unwrap();
    });
  }

  // Restore ------------------------------------------------------------

  /// What a backup file is, from its readable header: no password needed
  /// and nothing on this device is read or changed.
  Result<BackupHeader> inspect(Uint8List file) {
    try {
      return Ok(_codec.readHeader(file));
    } on Object catch (error, stackTrace) {
      return Err(AppFailure.from(error, stackTrace));
    }
  }

  /// Whether restoring [header] would replace another company's data on
  /// this device (nothing to replace on a new installation).
  Future<Result<bool>> isDifferentCompany(BackupHeader header) {
    return Result.guard(() async {
      final current = await _database.currentCompanyId();
      return current != null && current != header.companyId;
    });
  }

  /// Replaces the data on this device with the backup in [file].
  ///
  /// [password] is the backup's password; without it this device's backup
  /// password is tried. Restoring a backup of another company needs
  /// [allowDifferentCompany]. The data being replaced is first saved as a
  /// safety backup.
  Future<Result<RestoreOutcome>> restore(
    AdminSession session,
    Uint8List file, {
    String? password,
    bool allowDifferentCompany = false,
  }) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      if (await _kiosk.kioskCompanyId().then((r) => r.unwrap()) != null) {
        throw BackupFailures.kioskActive;
      }
      return _restore(
        file,
        password: password,
        allowDifferentCompany: allowDifferentCompany,
        actor: (type: AuditActorType.admin, id: session.admin.id),
        safetyAuthor: session.admin.displayName,
      );
    });
  }

  /// Restores the backup kept as [fileName]; see [restore].
  Future<Result<RestoreOutcome>> restoreStored(
    AdminSession session,
    String fileName, {
    String? password,
    bool allowDifferentCompany = false,
  }) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    final Uint8List file;
    try {
      file = await _storage.read(_checkName(fileName));
    } on Object catch (error, stackTrace) {
      return Err(AppFailure.from(error, stackTrace));
    }
    return restore(
      session,
      file,
      password: password,
      allowDifferentCompany: allowDifferentCompany,
    );
  }

  /// Restores [file] on a new installation, before any administrator
  /// exists. Refused once the device has company data: from then on only
  /// a signed-in administrator can restore.
  Future<Result<RestoreOutcome>> restoreOnNewInstallation(
    Uint8List file, {
    required String password,
  }) {
    return Result.guard(() async {
      if (await _database.currentCompanyId() != null) {
        throw BackupFailures.notFresh;
      }
      return _restore(
        file,
        password: password,
        allowDifferentCompany: true,
        actor: (type: AuditActorType.system, id: null),
        safetyAuthor: automaticAuthor,
      );
    });
  }

  Future<RestoreOutcome> _restore(
    Uint8List file, {
    required String? password,
    required bool allowDifferentCompany,
    required ({AuditActorType type, String? id}) actor,
    required String safetyAuthor,
  }) async {
    final header = _codec.readHeader(file);
    final current = await _database.currentCompanyId();
    if (current != null &&
        current != header.companyId &&
        !allowDifferentCompany) {
      throw BackupFailures.differentCompany;
    }
    final stored = await _secrets.read();
    final key = password ?? stored ?? (throw BackupFailures.noPassword);
    // Everything that can be checked without touching the data is checked
    // before anything is changed.
    final snapshot = await _codec.decode(file, key);
    await _database.check(snapshot);

    BackupInfo? safety;
    if (current != null) {
      safety = await _write(
        password: stored ?? key,
        kind: BackupKind.safety,
        createdBy: safetyAuthor,
      );
    }
    try {
      await _database.restore(
        snapshot,
        inside: (companyId) async {
          (await _audit.record(
            AuditEntry(
              companyId: companyId,
              actorType: actor.type,
              actorId: actor.id,
              action: AuditAction.backupRestored,
              entityType: 'backup',
              entityId: null,
              metadata: {
                'backupCreatedAt': header.createdAt.toIso8601String(),
                'backupKind': header.kind.name,
              },
            ),
          )).unwrap();
        },
      );
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw BackupFailures.restoreFailed(error);
    }
    await _pruneSafety();
    return RestoreOutcome(restored: header, safetyBackup: safety);
  }

  // Password and settings ----------------------------------------------

  /// Sets the password future backups are encrypted with. Existing backups
  /// keep the password they were made with. The password is never stored in
  /// the database or the audit log.
  Future<Result<void>> setPassword(
    AdminSession session,
    String password,
  ) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    if (password.length < minPasswordLength) {
      return const Err(
        ValidationFailure(
          field: 'password',
          userMessage:
              'Use at least $minPasswordLength characters for the backup '
              'password.',
        ),
      );
    }
    return Result.guard(() async {
      await _secrets.write(password);
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.backupPasswordChanged,
          entityType: 'backup_settings',
          entityId: null,
        ),
      )).unwrap();
    });
  }

  Future<Result<BackupSettings>> settings(AdminSession session) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    return _settings.load();
  }

  /// Saves the routine. The record of the last automatic attempt is kept.
  Future<Result<BackupSettings>> updateSettings(
    AdminSession session, {
    required bool automaticEnabled,
    required int retentionCount,
    required int reminderDays,
  }) async {
    if (session.check(Permission.manageBackups) case final denied?) {
      return Err(denied);
    }
    if (retentionCount < 1 || retentionCount > BackupSettings.maxRetention) {
      return const Err(
        ValidationFailure(
          field: 'retentionCount',
          userMessage:
              'Keep between 1 and ${BackupSettings.maxRetention} backups.',
        ),
      );
    }
    if (reminderDays < 1 || reminderDays > BackupSettings.maxReminderDays) {
      return const Err(
        ValidationFailure(
          field: 'reminderDays',
          userMessage:
              'Remind between 1 and ${BackupSettings.maxReminderDays} days.',
        ),
      );
    }
    return Result.guard(() async {
      final before = (await _settings.load()).unwrap();
      final after = before.copyWith(
        automaticEnabled: automaticEnabled,
        retentionCount: retentionCount,
        reminderDays: reminderDays,
      );
      (await _settings.save(after)).unwrap();
      final changed = [
        if (before.automaticEnabled != after.automaticEnabled) 'automatic',
        if (before.retentionCount != after.retentionCount) 'retention',
        if (before.reminderDays != after.reminderDays) 'reminder',
      ];
      if (changed.isNotEmpty) {
        (await _audit.record(
          AuditEntry(
            companyId: session.companyId,
            actorType: AuditActorType.admin,
            actorId: session.admin.id,
            action: AuditAction.backupSettingsChanged,
            entityType: 'backup_settings',
            entityId: null,
            metadata: {'fields': changed},
          ),
        )).unwrap();
      }
      await _prune();
      return after;
    });
  }

  // Internals ----------------------------------------------------------

  /// Takes a snapshot, encrypts it, checks that the result really decrypts
  /// to a sound database, and only then keeps it.
  Future<BackupInfo> _write({
    required String password,
    required BackupKind kind,
    required String createdBy,
  }) async {
    final snapshot = await _database.snapshot();
    final header = BackupHeader(
      backupVersion: backupVersion,
      appVersion: _appVersion,
      schemaVersion: snapshot.schemaVersion,
      createdAt: _clock(),
      kind: kind,
      createdBy: createdBy,
      deviceId: (await _devices.currentDeviceId()).unwrap(),
      companyId: snapshot.companyId,
      companyName: snapshot.companyName,
      summary: snapshot.summary,
    );
    final file = await _codec.encode(
      header: header,
      snapshot: snapshot.bytes,
      password: password,
    );
    final decoded = await _codec.decode(file, password);
    if (decoded.length != snapshot.bytes.length) {
      throw BackupFailures.verificationFailed;
    }
    await _database.check(decoded);
    final name = fileName(header.createdAt, kind);
    await _storage.write(name, file);
    return BackupInfo(fileName: name, sizeBytes: file.length, header: header);
  }

  Future<BackupListing> _listing() async {
    final backups = <BackupInfo>[];
    var unreadable = 0;
    for (final file in await _storage.list()) {
      try {
        final prefix = await _storage.readPrefix(
          file.name,
          BackupCodec.headerPrefixBytes,
        );
        backups.add(
          BackupInfo(
            fileName: file.name,
            sizeBytes: file.sizeBytes,
            header: _codec.readHeader(prefix),
          ),
        );
      } on AppFailure {
        unreadable++;
      }
    }
    backups.sort((a, b) => b.header.createdAt.compareTo(a.header.createdAt));
    return BackupListing(backups: backups, unreadable: unreadable);
  }

  /// Keeps the newest [BackupSettings.retentionCount] automatic backups.
  /// Manual backups are never deleted by the app.
  Future<void> _prune() async {
    final settings = (await _settings.load()).unwrap();
    await _deleteBeyond(BackupKind.automatic, settings.retentionCount);
  }

  Future<void> _pruneSafety() =>
      _deleteBeyond(BackupKind.safety, safetyBackupsKept);

  Future<void> _deleteBeyond(BackupKind kind, int keep) async {
    final ofKind = [
      for (final b in (await _listing()).backups)
        if (b.header.kind == kind) b,
    ];
    for (final old in ofKind.skip(keep)) {
      await _storage.delete(old.fileName);
    }
  }

  /// "attendance-payroll-20261012-153000-manual.apbackup" (UTC).
  static String fileName(DateTime createdAt, BackupKind kind) {
    String two(int n) => n.toString().padLeft(2, '0');
    final t = createdAt.toUtc();
    return 'attendance-payroll-${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}-${kind.name}'
        '$extension';
  }

  /// [name] if it is a backup file name; never a path.
  static String _checkName(String name) {
    final valid =
        RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name) &&
        name.endsWith(extension) &&
        !name.contains('..');
    if (!valid) {
      throw BackupFailures.invalidFile;
    }
    return name;
  }
}
