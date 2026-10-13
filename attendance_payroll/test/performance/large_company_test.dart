import 'dart:io';

import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backups.dart';
import '../support/test_env.dart';

/// A company the size the spec asks the design to survive ("hundreds of
/// employees and years of payroll history"): 300 employees, each with a
/// clock-in and clock-out on every weekday of a year. These are guard rails,
/// not micro-benchmarks: the limits are several times what a mid-range
/// laptop needs, so they fail on an algorithmic regression (a query that
/// scans, work repeated per employee) and not on a slow CI machine.
void main() {
  const employees = 300;
  final year = [
    for (
      var d = LocalDate(2025, 11, 1);
      !d.isAfter(LocalDate(2026, 10, 31));
      d = d.addDays(1)
    )
      d,
  ];
  late TestEnv env;
  late AdminSession admin;
  late PayrollPeriod october;
  late Directory temp;

  Future<void> seed() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    final db = env.db;
    final company = admin.companyId;
    const at = '2026-01-01T00:00:00.000Z';
    final device = (await DriftDeviceIdentityRepository(
      db,
    ).currentDeviceId()).unwrap();

    await db.transaction(() async {
      for (var e = 0; e < employees; e++) {
        final number = 'E${(e + 1).toString().padLeft(4, '0')}';
        await db.customStatement(
          'INSERT INTO employees (id, created_at, updated_at, version, '
          'sync_state, company_id, employee_number, first_name, last_name, '
          'display_name, employment_status, employment_start_date) '
          "VALUES (?, ?, ?, 1, 'localOnly', ?, ?, 'Emp', ?, ?, 'active', "
          "'2025-01-01')",
          ['emp-$e', at, at, company, number, number, 'Emp $number'],
        );
        await db.customStatement(
          'INSERT INTO employee_rates (id, created_at, updated_at, version, '
          'sync_state, employee_id, rate_type, amount_minor, currency_code, '
          "effective_from) VALUES (?, ?, ?, 1, 'localOnly', ?, 'hourly', "
          "50000, 'KES', '2025-01-01')",
          ['rate-$e', at, at, 'emp-$e'],
        );
      }
      // 08:00-17:00 in Nairobi (UTC+3) is 05:00-14:00 UTC, weekdays only.
      var rows = <List<Object?>>[];
      Future<void> flush() async {
        if (rows.isEmpty) {
          return;
        }
        final marks = List.filled(
          rows.length,
          '(?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?)',
        ).join(', ');
        await db.customStatement(
          'INSERT INTO attendance_events (id, created_at, updated_at, '
          'version, sync_state, employee_id, event_type, occurred_at, '
          'recorded_at, source, device_id, created_by) VALUES $marks',
          [for (final row in rows) ...row],
        );
        rows = [];
      }

      var n = 0;
      for (var e = 0; e < employees; e++) {
        for (final day in year) {
          final weekday = DateTime.utc(day.year, day.month, day.day).weekday;
          if (weekday > DateTime.friday) {
            continue;
          }
          final date = day.toIsoString();
          for (final (type, time) in [
            ('clockIn', '05:00'),
            ('clockOut', '14:00'),
          ]) {
            final instant = '${date}T$time:00.000Z';
            rows.add([
              'ev-${n++}',
              instant,
              instant,
              'localOnly',
              'emp-$e',
              type,
              instant,
              instant,
              'kiosk',
              device,
              'emp-$e',
            ]);
          }
          if (rows.length >= 2000) {
            await flush();
          }
        }
      }
      await flush();
    });
    env.clock.jumpTo(DateTime.utc(2026, 11, 2, 8));
    october = (await env.payroll.createPeriod(
      admin,
      NewPayrollPeriod(
        name: 'October 2026',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 31),
      ),
    )).unwrap();
  }

  Future<Duration> timed(String what, Future<void> Function() action) async {
    final watch = Stopwatch()..start();
    await action();
    watch.stop();
    // ignore: avoid_print
    print('PERF $what: ${watch.elapsedMilliseconds} ms');
    return watch.elapsed;
  }

  setUpAll(() async {
    temp = Directory.systemTemp.createTempSync('perf-test');
    await seed();
  });

  tearDownAll(() => temp.deleteSync(recursive: true));

  test('the data is what the test says it is', () async {
    final count =
        (await env.db
                .customSelect('SELECT count(*) AS c FROM attendance_events')
                .getSingle())
            .read<int>('c');

    expect(count, greaterThan(employees * 2 * 250));
  });

  test('a month of payroll for 300 employees is calculated quickly', () async {
    final took = await timed('payroll calculate', () async {
      (await env.payroll.calculate(admin, october.id)).unwrap();
    });

    final run = (await env.payroll.currentRun(admin, october.id)).unwrap()!;
    expect(run.result.lines, hasLength(employees));
    expect(took, lessThan(const Duration(seconds: 60)));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('recalculating gives exactly the same figures', () async {
    final first = (await env.payroll.currentRun(admin, october.id)).unwrap()!;

    (await env.payroll.calculate(admin, october.id)).unwrap();

    final second = (await env.payroll.currentRun(admin, october.id)).unwrap()!;
    expect(second.result.fingerprint, first.result.fingerprint);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a month of attendance for everyone is read quickly', () async {
    final took = await timed('attendance report (31 days)', () async {
      final report = (await env.reports.attendanceReport(
        admin,
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 31),
      )).unwrap();
      expect(report.groups, hasLength(employees));
    });

    expect(took, lessThan(const Duration(seconds: 60)));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a whole year of attendance for everyone can be reported', () async {
    final took = await timed('attendance report (366 days)', () async {
      final report = (await env.reports.attendanceReport(
        admin,
        from: LocalDate(2025, 11, 1),
        to: LocalDate(2026, 10, 31),
      )).unwrap();
      expect(report.groups, hasLength(employees));
    });

    expect(took, lessThan(const Duration(minutes: 4)));
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('backing up and restoring it works and is not slow', () async {
    final device = BackupTestDevice(env, temp);
    final service = device.service;
    late int size;

    final backupTook = await timed('backup', () async {
      final info = (await service.create(admin)).unwrap();
      size = info.sizeBytes;
    });
    // ignore: avoid_print
    print('PERF backup size: ${(size / 1024).round()} KB');

    final file = device.storage.files.values.single;
    final restoreTook = await timed('restore', () async {
      (await service.restore(admin, file)).unwrap();
    });

    expect(backupTook, lessThan(const Duration(seconds: 90)));
    expect(restoreTook, lessThan(const Duration(seconds: 120)));
    final count =
        (await env.db
                .customSelect('SELECT count(*) AS c FROM employees')
                .getSingle())
            .read<int>('c');
    expect(count, employees);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
