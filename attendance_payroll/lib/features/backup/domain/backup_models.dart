import 'dart:typed_data';

/// Why a backup was made.
enum BackupKind {
  /// The administrator pressed "Back up now".
  manual,

  /// Made by the app when it was opened and the last backup was old.
  automatic,

  /// Made just before a restore, so the data it replaces can be recovered.
  safety,
}

/// A few counts and dates that say what a backup holds, shown before it is
/// restored. No names or payroll amounts.
final class BackupSummary {
  const BackupSummary({
    required this.employees,
    required this.attendanceEvents,
    required this.payrollPeriods,
    this.latestAttendanceAt,
  });

  final int employees;
  final int attendanceEvents;
  final int payrollPeriods;

  /// When the most recent clock event happened, or `null` if there is none.
  final DateTime? latestAttendanceAt;
}

/// What is written in the clear at the start of a backup file: enough to
/// recognise a backup, and to decide whether this version of the app can
/// read it, before any password is asked for.
final class BackupHeader {
  const BackupHeader({
    required this.backupVersion,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.kind,
    required this.createdBy,
    required this.deviceId,
    required this.companyId,
    required this.companyName,
    required this.summary,
  });

  /// The format of the backup file, so later versions of the app can still
  /// read (and migrate) older backups.
  final int backupVersion;
  final String appVersion;

  /// The database schema version of the data inside.
  final int schemaVersion;
  final DateTime createdAt;
  final BackupKind kind;

  /// Display name of the administrator who made it, or "Automatic".
  final String createdBy;
  final String deviceId;
  final String companyId;
  final String companyName;
  final BackupSummary summary;
}

/// A backup kept by this device.
final class BackupInfo {
  const BackupInfo({
    required this.fileName,
    required this.sizeBytes,
    required this.header,
  });

  final String fileName;
  final int sizeBytes;
  final BackupHeader header;
}

/// The backups kept by this device, newest first.
final class BackupListing {
  const BackupListing({required this.backups, this.unreadable = 0});

  final List<BackupInfo> backups;

  /// Files in the backup folder that are not valid backups.
  final int unreadable;
}

/// A file in a backup store, before its header is read.
final class StoredBackupFile {
  const StoredBackupFile({
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
}

/// A consistent copy of the whole database at one moment.
final class DatabaseSnapshot {
  const DatabaseSnapshot({
    required this.bytes,
    required this.schemaVersion,
    required this.companyId,
    required this.companyName,
    required this.summary,
  });

  /// A complete SQLite database file.
  final Uint8List bytes;
  final int schemaVersion;
  final String companyId;
  final String companyName;
  final BackupSummary summary;
}

/// How backups behave on this device.
final class BackupSettings {
  const BackupSettings({
    this.automaticEnabled = true,
    this.retentionCount = defaultRetention,
    this.reminderDays = defaultReminderDays,
    this.lastAutomaticAttemptAt,
    this.lastAutomaticError,
  });

  static const int defaultRetention = 10;
  static const int defaultReminderDays = 7;
  static const int maxRetention = 100;
  static const int maxReminderDays = 365;

  final bool automaticEnabled;

  /// Automatic backups kept; older ones are deleted.
  final int retentionCount;

  /// Days without any backup before the administrator is reminded.
  final int reminderDays;
  final DateTime? lastAutomaticAttemptAt;

  /// Why the last automatic backup failed, or `null`.
  final String? lastAutomaticError;

  BackupSettings copyWith({
    bool? automaticEnabled,
    int? retentionCount,
    int? reminderDays,
    DateTime? lastAutomaticAttemptAt,
    String? lastAutomaticError,
    bool clearLastAutomaticError = false,
  }) => BackupSettings(
    automaticEnabled: automaticEnabled ?? this.automaticEnabled,
    retentionCount: retentionCount ?? this.retentionCount,
    reminderDays: reminderDays ?? this.reminderDays,
    lastAutomaticAttemptAt:
        lastAutomaticAttemptAt ?? this.lastAutomaticAttemptAt,
    lastAutomaticError: clearLastAutomaticError
        ? null
        : lastAutomaticError ?? this.lastAutomaticError,
  );
}

/// Where backups stand, for the Backup screen.
final class BackupStatus {
  const BackupStatus({
    required this.hasPassword,
    required this.lastBackupAt,
    required this.reminderDue,
    required this.lastAutomaticError,
  });

  final bool hasPassword;

  /// When the newest backup was made, or `null` if there is none.
  final DateTime? lastBackupAt;

  /// No backup yet, or the newest is older than the reminder period.
  final bool reminderDue;
  final String? lastAutomaticError;
}

/// What a restore did.
final class RestoreOutcome {
  const RestoreOutcome({required this.restored, this.safetyBackup});

  /// The backup that is now the data of this device.
  final BackupHeader restored;

  /// The backup of the data that was replaced, or `null` when there was
  /// none to keep (a new installation).
  final BackupInfo? safetyBackup;
}
