import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';

/// The header of a backup file as JSON. Field names are part of the file
/// format: renaming one needs a new `backupVersion`.
Map<String, Object?> headerToJson(BackupHeader header) => {
  'backupVersion': header.backupVersion,
  'appVersion': header.appVersion,
  'schemaVersion': header.schemaVersion,
  'createdAt': header.createdAt.toUtc().toIso8601String(),
  'kind': header.kind.name,
  'createdBy': header.createdBy,
  'deviceId': header.deviceId,
  'companyId': header.companyId,
  'companyName': header.companyName,
  'summary': {
    'employees': header.summary.employees,
    'attendanceEvents': header.summary.attendanceEvents,
    'payrollPeriods': header.summary.payrollPeriods,
    'latestAttendanceAt': header.summary.latestAttendanceAt
        ?.toUtc()
        .toIso8601String(),
  },
};

/// The header in [json], or an `invalidFile` failure when a field is
/// missing or of the wrong kind. A `backupVersion` newer than [supported] is
/// a `newerFormat` failure, checked first because a newer format may have
/// renamed anything else.
BackupHeader headerFromJson(
  Map<String, Object?> json, {
  required int supported,
}) {
  final version = json['backupVersion'];
  if (version is! int) {
    throw BackupFailures.invalidFile;
  }
  if (version > supported) {
    throw BackupFailures.newerFormat;
  }
  T field<T>(Map<String, Object?> from, String name) {
    final value = from[name];
    if (value is! T) {
      throw BackupFailures.invalidFile;
    }
    return value;
  }

  DateTime? date(Object? value) {
    if (value == null) {
      return null;
    }
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) {
      throw BackupFailures.invalidFile;
    }
    return parsed.toUtc();
  }

  final kind = BackupKind.values.asNameMap()[field<String>(json, 'kind')];
  final summary = field<Map<String, Object?>>(json, 'summary');
  final createdAt = date(field<String>(json, 'createdAt'));
  if (kind == null || createdAt == null) {
    throw BackupFailures.invalidFile;
  }
  return BackupHeader(
    backupVersion: version,
    appVersion: field<String>(json, 'appVersion'),
    schemaVersion: field<int>(json, 'schemaVersion'),
    createdAt: createdAt,
    kind: kind,
    createdBy: field<String>(json, 'createdBy'),
    deviceId: field<String>(json, 'deviceId'),
    companyId: field<String>(json, 'companyId'),
    companyName: field<String>(json, 'companyName'),
    summary: BackupSummary(
      employees: field<int>(summary, 'employees'),
      attendanceEvents: field<int>(summary, 'attendanceEvents'),
      payrollPeriods: field<int>(summary, 'payrollPeriods'),
      latestAttendanceAt: date(summary['latestAttendanceAt']),
    ),
  );
}
