import 'package:attendance_payroll/features/authentication/presentation/setup_screen.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a fresh install sets up the company, then the dashboard', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize, signedIn: false);
    expect(find.byType(SetupScreen), findsOneWidget);

    await tester.enterText(_field('Company name'), 'Acme Ltd');
    await tester.enterText(_field('Your name'), 'Jane Owner');
    await tester.enterText(_field('Username'), 'owner');
    await tester.enterText(_field('Password'), ownerPassword);
    await tester.enterText(_field('Confirm password'), ownerPassword);
    await _tapButton(tester, 'Create company');

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Acme Ltd'), findsOneWidget);
  });

  testWidgets('setup checks the form before submitting', (tester) async {
    await pumpApp(tester, size: tabletSize, signedIn: false);

    await tester.enterText(_field('Password'), ownerPassword);
    await tester.enterText(_field('Confirm password'), 'something else');
    await _tapButton(tester, 'Create company');

    expect(find.text('Enter the company name.'), findsOneWidget);
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(find.byType(SetupScreen), findsOneWidget);
  });

  testWidgets('lock the app, then unlock it as an administrator', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Signed in as Jane Owner'), findsOneWidget);
    await tester.tap(find.text('Lock app'));
    await tester.pumpAndSettle();
    // Locked means the kiosk: employees can clock in and out.
    expect(find.byType(KioskScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);

    await tester.tap(find.text('Administrator'));
    await tester.pumpAndSettle();
    expect(find.byType(KioskUnlockScreen), findsOneWidget);

    await tester.enterText(_field('Username'), ownerUsername);
    await tester.enterText(_field('Password'), 'wrong password');
    await _tapButton(tester, 'Sign in');
    expect(find.text('Incorrect username or password.'), findsOneWidget);
    expect(find.byType(KioskUnlockScreen), findsOneWidget);

    await tester.enterText(_field('Password'), ownerPassword);
    await _tapButton(tester, 'Sign in');
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('the app always starts locked, showing the kiosk', (
    tester,
  ) async {
    // A company that already exists, as after the app was closed.
    final db = openTestDatabase();
    await tester.runAsync(() => TestEnv(database: db).setUpOwner());

    await pumpApp(tester, size: tabletSize, signedIn: false, database: db);

    expect(find.byType(KioskScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.text('Administrator'), findsOneWidget);
  });

  testWidgets('a brand new install asks for setup, not the kiosk', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize, signedIn: false);

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.byType(KioskScreen), findsNothing);
  });
}
