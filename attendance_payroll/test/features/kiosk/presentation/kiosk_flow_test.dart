import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_day_screen.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_flow.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/widgets/pin_pad.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

/// Lets database work started by a tap finish, then settles the UI.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

/// Types [pin] on the kiosk keypad and presses its submit key.
Future<void> _enterPin(
  WidgetTester tester,
  String pin, {
  String submit = 'OK',
}) async {
  final pad = find.byType(PinPad);
  for (final digit in pin.split('')) {
    await tester.tap(find.descendant(of: pad, matching: find.text(digit)));
    await tester.pump();
  }
  await _tap(tester, find.descendant(of: pad, matching: find.text(submit)));
}

/// Adds John with a temporary PIN; returns the PIN.
Future<String> _addJohn(
  WidgetTester tester,
  ProviderContainer container,
) async {
  return (await tester.runAsync(() async {
    final admin = container.read(adminSessionProvider)!;
    final john =
        (await container
                .read(employeeManagementServiceProvider)
                .create(admin, johnDetails()))
            .unwrap();
    return (await container
            .read(employeePinServiceProvider)
            .issueTemporaryPin(admin, john.id))
        .unwrap();
  }))!;
}

Future<void> _startKioskFromAttendance(WidgetTester tester) async {
  await tester.tap(find.text('Attendance'));
  await _settle(tester);
  await _tap(tester, find.widgetWithText(FilledButton, 'Start kiosk'));
  expect(find.textContaining('You will be signed out'), findsOneWidget);
  await _tap(
    tester,
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Start kiosk'),
    ),
  );
}

void main() {
  testWidgets('an employee chooses a PIN and clocks in at the kiosk', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    final temporary = await _addJohn(tester, container);
    await _startKioskFromAttendance(tester);

    expect(find.byType(KioskScreen), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing, reason: 'no admin UI');
    expect(container.read(adminSessionProvider), isNull, reason: 'signed out');

    await _tap(tester, find.text('John Kamau'));
    expect(find.text('Hello, John Kamau'), findsOneWidget);
    await _enterPin(tester, temporary);

    // A temporary PIN must be replaced before clocking in.
    expect(find.text('Choose a new PIN'), findsOneWidget);
    await _enterPin(tester, '4826', submit: 'Next');
    expect(find.text('Enter your new PIN again'), findsOneWidget);
    await _enterPin(tester, '4826', submit: 'Save');

    expect(find.text('PIN changed.'), findsOneWidget);
    expect(find.text('You are not clocked in.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Clock in'));

    expect(find.textContaining('Clocked in at'), findsOneWidget);
    await _tap(tester, find.text('Done'));
    expect(find.text('Tap your name'), findsOneWidget);

    // Next time John is clocked in and is offered only clocking out.
    await _tap(tester, find.text('John Kamau'));
    await _enterPin(tester, '4826');
    expect(find.textContaining('Clocked in since'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Clock out'), findsOneWidget);
    expect(find.text('Clock in'), findsNothing);
    await _tap(tester, find.text('Cancel'));
  });

  testWidgets('a wrong PIN is explained and nothing is recorded', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    await _addJohn(tester, container);
    await _startKioskFromAttendance(tester);

    await _tap(tester, find.text('John Kamau'));
    await _enterPin(tester, '9753');

    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(find.text('Hello, John Kamau'), findsOneWidget);
    final db = container.read(appDatabaseProvider);
    final events = await tester.runAsync(
      () => db.select(db.attendanceEvents).get(),
    );
    expect(events, isEmpty);
    await _tap(tester, find.text('Not you? Start again'));
  });

  testWidgets('an unfinished step returns to the start when left alone', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    await _addJohn(tester, container);
    await _startKioskFromAttendance(tester);

    await _tap(tester, find.text('John Kamau'));
    expect(find.text('Hello, John Kamau'), findsOneWidget);

    await tester.pump(KioskFlow.inactivityTimeout + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Tap your name'), findsOneWidget);
  });

  testWidgets('leaving the kiosk needs an administrator password', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize);
    await _startKioskFromAttendance(tester);

    await _tap(tester, find.text('Administrator'));
    expect(find.text('Leave kiosk mode'), findsOneWidget);
    Finder field(String label) => find.widgetWithText(TextFormField, label);

    await tester.enterText(field('Username'), ownerUsername);
    await tester.enterText(field('Password'), 'wrong password');
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Sign in and leave kiosk'),
    );
    expect(find.text('Incorrect username or password.'), findsOneWidget);

    await _tap(tester, find.text('Back to the kiosk'));
    expect(find.byType(KioskScreen), findsOneWidget);

    await _tap(tester, find.text('Administrator'));
    await tester.enterText(field('Username'), ownerUsername);
    await tester.enterText(field('Password'), ownerPassword);
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Sign in and leave kiosk'),
    );

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('the device is still a kiosk after a restart', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = await pumpApp(
      tester,
      size: tabletSize,
      database: database,
    );
    await tester.runAsync(
      () => container.read(authControllerProvider.notifier).startKiosk(),
    );
    await _settle(tester);
    expect(find.byType(KioskScreen), findsOneWidget);

    // Restart: a new app over the same database.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(
      tester,
      size: tabletSize,
      signedIn: false,
      database: database,
    );
    await _settle(tester);

    expect(find.byType(KioskScreen), findsOneWidget);
  });

  testWidgets('the attendance screen shows who clocked in', (tester) async {
    final container = await pumpApp(tester, size: tabletSize);
    final temporary = await _addJohn(tester, container);
    await tester.runAsync(() async {
      final pins = container.read(employeePinServiceProvider);
      final john =
          (await container
                  .read(employeeManagementServiceProvider)
                  .list(container.read(adminSessionProvider)!))
              .unwrap()
              .single;
      await pins.changePin(john.id, currentPin: temporary, newPin: '4826');
    });
    await _startKioskFromAttendance(tester);
    await _tap(tester, find.text('John Kamau'));
    await _enterPin(tester, '4826');
    await _tap(tester, find.widgetWithText(FilledButton, 'Clock in'));
    await _tap(tester, find.text('Done'));

    await _tap(tester, find.text('Administrator'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      ownerUsername,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      ownerPassword,
    );
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Sign in and leave kiosk'),
    );
    await tester.tap(find.text('Attendance'));
    await _settle(tester);

    expect(find.byType(AttendanceDayScreen), findsOneWidget);
    expect(find.text('Working'), findsOneWidget);
    expect(find.textContaining('E001 · '), findsOneWidget);
  });

  testWidgets('the kiosk fits a phone screen', (tester) async {
    final container = await pumpApp(tester, size: tabletSize);
    await _addJohn(tester, container);
    await _startKioskFromAttendance(tester);

    tester.view.physicalSize = phoneSize;
    await tester.pumpAndSettle();
    await _tap(tester, find.text('John Kamau'));

    expect(find.byType(PinPad), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no layout overflow');
    await _tap(tester, find.text('Not you? Start again'));
  });
}
