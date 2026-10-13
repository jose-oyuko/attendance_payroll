import 'dart:io';

import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/settings/presentation/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/attendance_fixtures.dart';
import '../support/fake_backups.dart';
import '../support/pump_app.dart';
import '../support/test_database.dart';
import '../support/test_env.dart';

/// Every screen of the administrator experience, filled with realistic data,
/// at the phone and tablet sizes and at the largest text size a person can
/// choose. A screen that overflows, or has a control that is too small to
/// press or is unlabeled, fails here instead of in somebody's hand.
void main() {
  late Directory temp;
  late AppDatabase db;
  late String employeeId;
  late String periodId;
  late InMemoryBackupStorage storage;

  const sizes = {
    'phone': phoneSize,
    'small tablet': smallTabletSize,
    'tablet': tabletSize,
  };

  Future<void> seed() async {
    final env = TestEnv(database: db);
    final admin = await env.setUpOwner();
    final ids = <String>[];
    for (final (number, first, last) in [
      ('E0001', 'John', 'Kamau'),
      ('E0002', 'Amina', 'Odhiambo'),
      ('E0003', 'Wanjiru', 'Mwangi-Kariuki'),
    ]) {
      final e = (await env.management.create(
        admin,
        EmployeeDetails(
          employeeNumber: number,
          firstName: first,
          lastName: last,
          jobTitle: 'Senior customer service representative',
          employmentStartDate: LocalDate(2026, 1, 1),
        ),
      )).unwrap();
      (await env.management.addRate(
        admin,
        e.id,
        NewEmployeeRate(
          rateType: RateType.hourly,
          amountMinor: 50000,
          currencyCode: 'KES',
          effectiveFrom: LocalDate(2026, 1, 1),
        ),
      )).unwrap();
      ids.add(e.id);
    }
    env.clock.jumpTo(nairobiTime(31, 23, 0));
    for (final id in ids) {
      for (var day = 1; day <= 12; day++) {
        for (final (type, hour) in [
          (AttendanceEventType.clockIn, 8),
          (AttendanceEventType.clockOut, 16),
        ]) {
          (await env.attendanceCorrections.addMissingEntry(
            admin,
            id,
            type: type,
            occurredAt: nairobiTime(day, hour, 0),
            reason: 'Paper register',
          )).unwrap();
        }
      }
    }
    // Someone who never clocked out: an exception to review.
    (await env.attendanceCorrections.addMissingEntry(
      admin,
      ids.first,
      type: AttendanceEventType.clockIn,
      occurredAt: nairobiTime(14, 8, 0),
      reason: 'Paper register',
    )).unwrap();
    env.clock.jumpTo(nairobiTime(31, 23, 0).add(const Duration(days: 2)));
    final period = (await env.payroll.createPeriod(
      admin,
      NewPayrollPeriod(
        name: 'October 2026',
        startDate: LocalDate(2026, 10, 1),
        endDate: LocalDate(2026, 10, 31),
      ),
    )).unwrap();
    (await env.payroll.calculate(admin, period.id)).unwrap();
    employeeId = ids.first;
    periodId = period.id;
    final device = BackupTestDevice(env, temp);
    storage = device.storage;
    (await device.service.create(admin)).unwrap();
  }

  setUpAll(() async {
    temp = Directory.systemTemp.createTempSync('a11y-sweep');
    db = openTestDatabase();
    await seed();
  });

  tearDownAll(() => temp.deleteSync(recursive: true));

  /// Lets data load and animations finish. Bounded on purpose:
  /// `pumpAndSettle` waits for every spinner in every tab of the app, and a
  /// tab that is not showing may reload for a long time.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (i >= 2 && find.byType(ProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<ProviderContainer> open(WidgetTester tester, Size size) async {
    final c = await pumpApp(
      tester,
      size: size,
      signedIn: false,
      database: db,
      overrides: [
        backupStorageProvider.overrideWithValue(storage),
        backupSecretStoreProvider.overrideWithValue(
          InMemorySecretStore('backup-pass-123'),
        ),
      ],
    );
    final failure = await tester.runAsync(
      () => c
          .read(authControllerProvider.notifier)
          .signIn(ownerUsername, ownerPassword),
    );
    expect(failure, isNull);
    await settle(tester);
    return c;
  }

  Map<String, String> routes() => {
    'dashboard': '/dashboard',
    'employees': '/employees',
    'new employee': '/employees/new',
    'employee': '/employees/$employeeId',
    'employee attendance': '/employees/$employeeId/attendance',
    'attendance day': '/attendance',
    'attendance range': '/attendance/range',
    'exceptions': '/attendance/exceptions',
    'schedules': '/schedules',
    'new schedule': '/schedules/new',
    'payroll': '/payroll',
    'payroll period': '/payroll/$periodId',
    'reports': '/reports',
    'backup': '/backup',
    'settings': '/settings',
    'printer': '/settings/printer',
  };

  for (final scale in [1.0, 2.0]) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('every screen fits at $sizeName, text $scale×', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = await open(tester, size);
        final router = c.read(appRouterProvider);

        final problems = <String>[];
        final original = FlutterError.onError;
        late String where;
        FlutterError.onError = (details) {
          // The first line says what happened; the widget line says where in
          // the code.
          final lines = details.toDiagnosticsNode().toStringDeep().split('\n');
          final place = lines.firstWhere(
            (l) => l.contains('/lib/'),
            orElse: () => '',
          );
          problems.add(
            '$where: ${details.exceptionAsString().split('\n').first} '
            '${place.trim()}',
          );
        };
        try {
          for (final MapEntry(key: name, value: path) in routes().entries) {
            where = name;
            router.go(path);
            await settle(tester);
          }
        } finally {
          // The framework checks this when the test body ends.
          FlutterError.onError = original;
        }

        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }

  group('controls can be pressed and are labeled', () {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('on the main screens at $sizeName', (tester) async {
        final handle = tester.ensureSemantics();
        final problems = <String>[];
        try {
          final c = await open(tester, size);
          final router = c.read(appRouterProvider);
          for (final path in [
            '/dashboard',
            '/employees',
            '/attendance',
            '/payroll',
            '/reports',
            '/backup',
            '/settings',
          ]) {
            router.go(path);
            await settle(tester);
            for (final (name, guideline) in [
              ('too small', androidTapTargetGuideline),
              ('unlabeled', labeledTapTargetGuideline),
            ]) {
              final result = await guideline.evaluate(tester);
              if (!result.passed) {
                problems.add('$path ($name): ${result.reason}');
              }
            }
          }
        } finally {
          // The framework checks this when the test body ends.
          handle.dispose();
        }

        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });
  group('text can be read', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'the main screens have enough contrast in ${mode.name} mode',
        (tester) async {
          final handle = tester.ensureSemantics();
          final problems = <String>[];
          try {
            final c = await open(tester, tabletSize);
            c.read(themeModeProvider.notifier).select(mode);
            final router = c.read(appRouterProvider);
            for (final path in [
              '/dashboard',
              '/employees',
              '/payroll',
              '/backup',
              '/settings',
            ]) {
              router.go(path);
              await settle(tester);
              final result = await textContrastGuideline.evaluate(tester);
              if (!result.passed) {
                problems.add('$path: ${result.reason}');
              }
            }
          } finally {
            handle.dispose();
          }

          expect(problems, isEmpty, reason: problems.join('\n'));
        },
      );
    }
  });
}
