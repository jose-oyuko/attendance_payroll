import 'dart:io';

import 'package:attendance_payroll/core/constants/app_constants.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sizes are shown in the unit that reads best', () {
    expect(formatBytes(812), '812 B');
    expect(formatBytes(49356), '48.2 KB');
    expect(formatBytes(12900000), '12.3 MB');
  });

  test('how long ago is said in plain words', () {
    final now = DateTime.utc(2026, 10, 12, 12);

    expect(
      formatAgo(now.subtract(const Duration(seconds: 20)), now),
      'just now',
    );
    expect(
      formatAgo(now.subtract(const Duration(minutes: 1)), now),
      '1 minute ago',
    );
    expect(
      formatAgo(now.subtract(const Duration(minutes: 5)), now),
      '5 minutes ago',
    );
    expect(
      formatAgo(now.subtract(const Duration(hours: 3)), now),
      '3 hours ago',
    );
    expect(formatAgo(now.subtract(const Duration(days: 1)), now), '1 day ago');
    expect(formatAgo(now.subtract(const Duration(days: 9)), now), '9 days ago');
  });

  test('contents are counted with the right plurals', () {
    expect(
      describeContents(
        const BackupSummary(
          employees: 1,
          attendanceEvents: 1,
          payrollPeriods: 1,
        ),
      ),
      '1 employee, 1 clock event, 1 payroll period',
    );
    expect(
      describeContents(
        const BackupSummary(
          employees: 12,
          attendanceEvents: 3400,
          payrollPeriods: 0,
        ),
      ),
      '12 employees, 3400 clock events, 0 payroll periods',
    );
  });

  test('backup kinds have readable names', () {
    expect(BackupKind.safety.label, 'Before a restore');
    expect(BackupKind.automatic.label, 'Automatic');
    expect(BackupKind.manual.label, 'Manual');
  });

  test('the version written into backups is the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);

    expect(AppConstants.appVersion, version);
  });
}
