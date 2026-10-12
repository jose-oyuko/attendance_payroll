import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/shared/formatting/document_formatting.dart';

extension BackupKindLabel on BackupKind {
  String get label => switch (this) {
    BackupKind.manual => 'Manual',
    BackupKind.automatic => 'Automatic',
    BackupKind.safety => 'Before a restore',
  };
}

/// "12 Oct 2026, 15:30" in the device's local time.
String formatBackupTime(DateTime instant) {
  final local = instant.toLocal();
  return '${formatDocumentDate(LocalDate(local.year, local.month, local.day))}, '
      '${formatDocumentTime(Duration(hours: local.hour, minutes: local.minute))}';
}

/// "just now", "5 minutes ago", "3 hours ago", "2 days ago".
String formatAgo(DateTime then, DateTime now) {
  final elapsed = now.difference(then);
  String unit(int n, String name) => '$n $name${n == 1 ? '' : 's'} ago';
  if (elapsed.inMinutes < 1) {
    return 'just now';
  }
  if (elapsed.inHours < 1) {
    return unit(elapsed.inMinutes, 'minute');
  }
  if (elapsed.inDays < 1) {
    return unit(elapsed.inHours, 'hour');
  }
  return unit(elapsed.inDays, 'day');
}

/// "812 B", "48.2 KB", "12.3 MB".
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// "12 employees, 3,400 clock events, 6 payroll periods".
String describeContents(BackupSummary summary) {
  String count(int n, String singular, [String? plural]) =>
      '$n ${n == 1 ? singular : plural ?? '${singular}s'}';
  return '${count(summary.employees, 'employee')}, '
      '${count(summary.attendanceEvents, 'clock event')}, '
      '${count(summary.payrollPeriods, 'payroll period')}';
}
