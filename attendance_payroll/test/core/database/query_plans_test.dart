import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/attendance_fixtures.dart';
import '../../support/test_env.dart';

/// Records every SELECT the app runs, with its arguments.
final class _Recorder extends QueryInterceptor {
  final Map<String, List<Object?>> selects = {};

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects.putIfAbsent(statement, () => args);
    return super.runSelect(executor, statement, args);
  }
}

/// Tables that grow without bound (years of events and payroll). Reading
/// them by scanning the whole table gets slower every month.
const _growing = {
  'attendance_events',
  'attendance_corrections',
  'audit_log',
  'exception_reviews',
  'payroll_lines',
  'payroll_items',
  'payroll_runs',
  'payroll_run_issues',
  'payroll_adjustments',
  'payroll_periods',
};

/// Runs the screens' and reports' queries on a realistic workload and checks
/// the database answers each of them from an index (spec §46: "analyze query
/// patterns"), instead of listing which indexes exist.
void main() {
  test('no query on a growing table scans the whole table', () async {
    final recorder = _Recorder();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(recorder));
    addTearDown(db.close);
    final env = TestEnv(database: db);
    final admin = await env.setUpOwner();
    final john = await env.addEmployee(admin);
    final amina = await env.addEmployee(admin, employeeNumber: 'E0002');
    for (final who in [john, amina]) {
      (await env.management.addRate(
        admin,
        who.id,
        NewEmployeeRate(
          rateType: RateType.hourly,
          amountMinor: 50000,
          currencyCode: 'KES',
          effectiveFrom: LocalDate(2026, 1, 1),
        ),
      )).unwrap();
    }
    env.clock.jumpTo(nairobiTime(31, 23, 0).add(const Duration(days: 2)));
    for (final who in [john, amina]) {
      for (var day = 1; day <= 12; day++) {
        for (final (type, hour) in [
          (AttendanceEventType.clockIn, 8),
          (AttendanceEventType.clockOut, 16),
        ]) {
          (await env.attendanceCorrections.addMissingEntry(
            admin,
            who.id,
            type: type,
            occurredAt: nairobiTime(day, hour, 0),
            reason: 'Paper register',
          )).unwrap();
        }
      }
    }
    final period = (await env.payroll.createPeriod(
      admin,
      NewPayrollPeriod(
        name: 'October 2026',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 31),
      ),
    )).unwrap();

    // What the screens and reports ask for.
    (await env.payroll.calculate(admin, period.id)).unwrap();
    (await env.payroll.currentRun(admin, period.id)).unwrap();
    (await env.payroll.history(admin, period.id)).unwrap();
    (await env.payroll.periods(admin)).unwrap();
    (await env.payroll.adjustments(admin, period.id)).unwrap();
    (await env.payroll.approve(admin, period.id)).unwrap();
    (await env.payroll.finalize(admin, period.id)).unwrap();
    (await env.attendance.day(admin, LocalDate(2026, 10, 5))).unwrap();
    (await env.attendance.range(
      admin,
      from: LocalDate(2026, 10, 1),
      to: LocalDate(2026, 10, 31),
    )).unwrap();
    (await env.attendance.timeline(
      admin,
      john.id,
      from: LocalDate(2026, 10, 1),
      to: LocalDate(2026, 10, 31),
    )).unwrap();
    (await env.exceptions.list(
      admin,
      from: LocalDate(2026, 10, 1),
      to: LocalDate(2026, 10, 31),
    )).unwrap();
    (await env.reports.payslips(admin, period.id)).unwrap();
    (await env.reports.exceptionReport(
      admin,
      from: LocalDate(2026, 10, 1),
      to: LocalDate(2026, 10, 31),
    )).unwrap();

    expect(recorder.selects, isNotEmpty);
    final scans = <String>[];
    final asked = {
      for (final e in recorder.selects.entries)
        if (e.key.trimLeft().toUpperCase().startsWith('SELECT')) e.key: e.value,
    };
    expect(asked, isNotEmpty);
    for (final MapEntry(key: sql, value: args) in asked.entries) {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN $sql',
            variables: [for (final a in args) Variable<Object>(a)],
          )
          .get();
      for (final row in plan) {
        final detail = row.read<String>('detail');
        final scan = RegExp(r'^SCAN (\w+)').firstMatch(detail);
        if (scan != null && _growing.contains(scan.group(1))) {
          scans.add('$detail  <=  $sql');
        }
      }
    }

    expect(scans, isEmpty, reason: scans.join('\n'));
  });
}
