import 'package:attendance_payroll/features/authentication/presentation/setup_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/sign_in_screen.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
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
    expect(find.text('Acme Ltd'), findsOneWidget);
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

  testWidgets('sign out, then sign back in', (tester) async {
    await pumpApp(tester, size: tabletSize);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Signed in as Jane Owner'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.enterText(_field('Username'), ownerUsername);
    await tester.enterText(_field('Password'), 'wrong password');
    await _tapButton(tester, 'Sign in');
    expect(find.text('Incorrect username or password.'), findsOneWidget);

    await tester.enterText(_field('Password'), ownerPassword);
    await _tapButton(tester, 'Sign in');
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
