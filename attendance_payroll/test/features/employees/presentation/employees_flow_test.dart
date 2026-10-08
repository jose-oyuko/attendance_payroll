import 'package:attendance_payroll/features/employees/presentation/employee_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Lets database work started by a tap finish, then settles the UI.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _addJohn(WidgetTester tester) async {
  await tester.tap(find.text('Employees'));
  await tester.pumpAndSettle();
  await _tap(tester, find.widgetWithText(FilledButton, 'Add employee'));

  expect(find.text('New employee'), findsOneWidget);
  expect(find.text('E0001'), findsOneWidget, reason: 'suggested number');
  await tester.enterText(_field('First name'), 'John');
  await tester.enterText(_field('Last name'), 'Kamau');
  await tester.enterText(_field('Job title'), 'Cashier');
  await _tap(tester, find.widgetWithText(FilledButton, 'Add employee'));
}

void main() {
  testWidgets('adding an employee opens their record and lists them', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize);

    await _addJohn(tester);

    expect(find.byType(EmployeeDetailScreen), findsOneWidget);
    expect(find.text('John Kamau'), findsWidgets);
    expect(
      find.text('No PIN yet. Issue one so John Kamau can clock in.'),
      findsOneWidget,
    );

    await _tap(tester, find.byType(BackButton));
    expect(find.text('E0001 · Cashier'), findsOneWidget);
  });

  testWidgets('the form requires names', (tester) async {
    await pumpApp(tester, size: phoneSize);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employees'));
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(FilledButton, 'Add employee'));

    await _tap(tester, find.widgetWithText(FilledButton, 'Add employee'));

    expect(find.text('Enter a first name.'), findsOneWidget);
    expect(find.text('Enter a last name.'), findsOneWidget);
  });

  testWidgets('issuing a PIN shows it once and marks it temporary', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize);
    await _addJohn(tester);

    await _tap(tester, find.widgetWithText(FilledButton, 'Issue PIN'));

    expect(find.text('Temporary PIN for John Kamau'), findsOneWidget);
    final pin = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(pin.data, matches(RegExp(r'^\d{6}$')));

    await _tap(tester, find.text('Done'));
    expect(find.textContaining('A temporary PIN was issued'), findsOneWidget);
    expect(find.text(pin.data!), findsNothing);

    await _tap(tester, find.widgetWithText(FilledButton, 'Reset PIN'));
    expect(find.text('Reset PIN?'), findsOneWidget, reason: 'confirmation');
    await _tap(tester, find.text('Cancel'));
  });

  testWidgets('archiving asks first, then hides the employee', (tester) async {
    await pumpApp(tester, size: tabletSize);
    await _addJohn(tester);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Archive'));
    expect(find.textContaining('history is kept'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Archive'));
    expect(find.widgetWithText(OutlinedButton, 'Restore'), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(find.text('No employees yet.'), findsNothing);
    expect(find.textContaining('No active employees.'), findsOneWidget);
    expect(find.text('E0001 · Cashier'), findsNothing);

    await _tap(tester, find.text('Show archived'));
    expect(find.text('E0001 · Cashier'), findsOneWidget);
  });

  testWidgets('setting a pay rate shows it as current', (tester) async {
    await pumpApp(tester, size: tabletSize);
    await _addJohn(tester);

    await _tap(tester, find.widgetWithText(FilledButton, 'Set rate'));
    await tester.enterText(_field('Amount per hour'), '500');
    await _tap(tester, find.widgetWithText(FilledButton, 'Save rate'));

    expect(find.text('KES 500.00 per hour'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Change rate'), findsOneWidget);
  });
}
