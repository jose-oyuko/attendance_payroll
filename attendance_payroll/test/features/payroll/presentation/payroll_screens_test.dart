import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/data/payroll_providers.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_period_screen.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_view_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_database.dart';

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

Finder _inDialog(Finder finder) =>
    find.descendant(of: find.byType(AlertDialog), matching: finder);

/// 08:00–16:00 in Nairobi (UTC+3) on [day] September 2026.
DateTime _september(int day, int hour) => DateTime.utc(2026, 9, day, hour - 3);

/// John, optionally with an hourly rate of KES 500, who worked eight hours
/// on 8 September 2026, and a September 2026 payroll period.
Future<void> _seed(
  WidgetTester tester,
  ProviderContainer c, {
  bool withRate = true,
}) async {
  await tester.runAsync(() async {
    final admin = c.read(adminSessionProvider)!;
    final john =
        (await c
                .read(employeeManagementServiceProvider)
                .create(admin, johnDetails()))
            .unwrap();
    if (withRate) {
      (await c
              .read(employeeManagementServiceProvider)
              .addRate(
                admin,
                john.id,
                NewEmployeeRate(
                  rateType: RateType.hourly,
                  amountMinor: 50000,
                  currencyCode: 'KES',
                  effectiveFrom: LocalDate(2026, 1, 1),
                ),
              ))
          .unwrap();
    }
    for (final (type, hour) in [
      (AttendanceEventType.clockIn, 8),
      (AttendanceEventType.clockOut, 16),
    ]) {
      (await c
              .read(attendanceCorrectionServiceProvider)
              .addMissingEntry(
                admin,
                john.id,
                type: type,
                occurredAt: _september(8, hour),
                reason: 'Paper register',
              ))
          .unwrap();
    }
    (await c
            .read(payrollServiceProvider)
            .createPeriod(
              admin,
              NewPayrollPeriod(
                name: 'September 2026',
                startDate: LocalDate(2026, 9, 1),
                endDate: LocalDate(2026, 9, 30),
              ),
            ))
        .unwrap();
  });
  c.read(payrollRevisionProvider.notifier).changed();
}

void main() {
  testWidgets('a full payroll cycle, from calculation to reopening', (
    tester,
  ) async {
    final c = await pumpApp(tester, size: tabletSize);
    await _seed(tester, c);
    await _tap(tester, find.text('Payroll'));

    expect(find.text('September 2026'), findsOneWidget);
    expect(find.textContaining('Not calculated'), findsOneWidget);
    await _tap(tester, find.text('September 2026'));
    expect(find.byType(PayrollPeriodScreen), findsOneWidget);
    expect(find.text('Not calculated yet.'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'Calculate'));
    expect(find.text('In review'), findsOneWidget);
    expect(find.text('John Kamau'), findsWidgets);
    expect(find.text('${const Money(400000, 'KES')}'), findsWidgets);

    // A transport allowance, then a recalculation picks it up.
    await _tap(tester, find.widgetWithText(TextButton, 'Add'));
    await _tap(tester, _inDialog(find.byType(DropdownButtonFormField<String>)));
    await _tap(tester, find.text('John Kamau').last);
    await tester.enterText(
      _inDialog(find.widgetWithText(TextFormField, 'Amount')),
      '250',
    );
    await tester.enterText(
      _inDialog(find.widgetWithText(TextFormField, 'Description')),
      'Transport',
    );
    await _tap(tester, _inDialog(find.widgetWithText(FilledButton, 'Add')));
    expect(find.textContaining('Allowance · Transport'), findsOneWidget);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Recalculate'));
    expect(find.text('${const Money(425000, 'KES')}'), findsWidgets);

    // The pay breakdown explains the figures.
    await _tap(tester, find.widgetWithText(ListTile, 'John Kamau').first);
    expect(_inDialog(find.text('8.00 h × KES 500.00')), findsOneWidget);
    expect(_inDialog(find.text('Net pay')), findsOneWidget);
    await _tap(tester, _inDialog(find.text('Close')));

    await _tap(tester, find.widgetWithText(FilledButton, 'Approve'));
    expect(find.text('Payroll approved.'), findsOneWidget);
    expect(find.textContaining('This payroll is approved.'), findsOneWidget);
    expect(find.byTooltip('Remove adjustment'), findsNothing);

    await _tap(tester, find.widgetWithText(FilledButton, 'Finalize'));
    expect(find.textContaining('requires reopening'), findsOneWidget);
    await _tap(
      tester,
      _inDialog(find.widgetWithText(FilledButton, 'Finalize')),
    );
    expect(find.textContaining('This payroll is finalized.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Recalculate'), findsNothing);

    // Reopening needs a reason, which the history keeps.
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Reopen'));
    await _tap(tester, _inDialog(find.widgetWithText(FilledButton, 'Reopen')));
    expect(find.text('Give a reason.'), findsOneWidget);
    await tester.enterText(
      _inDialog(find.widgetWithText(TextFormField, 'Reason')),
      'Missed overtime',
    );
    await _tap(tester, _inDialog(find.widgetWithText(FilledButton, 'Reopen')));

    expect(find.text('Reopened'), findsWidgets);
    expect(find.textContaining('Missed overtime'), findsOneWidget);
    expect(find.text('Finalized'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Recalculate'), findsOneWidget);
  });

  testWidgets('blocking problems prevent approval', (tester) async {
    final c = await pumpApp(tester, size: phoneSize);
    await _seed(tester, c, withRate: false);
    await _tap(tester, find.byTooltip('Open navigation menu'));
    await _tap(tester, find.text('Payroll'));
    await _tap(tester, find.text('September 2026'));

    await _tap(tester, find.widgetWithText(FilledButton, 'Calculate'));

    expect(find.text('Problems to resolve'), findsOneWidget);
    expect(find.textContaining('Blocking'), findsOneWidget);
    final approve = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Approve'),
    );
    expect(approve.onPressed, isNull);
  });

  testWidgets('a new period defaults to the current month', (tester) async {
    final c = await pumpApp(tester, size: phoneSize);
    await _tap(tester, find.byTooltip('Open navigation menu'));
    await _tap(tester, find.text('Payroll'));
    expect(find.text('No payroll periods have been created.'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'New period'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Create period'));

    expect(find.byType(PayrollPeriodScreen), findsOneWidget);
    final periods = (await tester.runAsync(
      () =>
          c.read(payrollServiceProvider).periods(c.read(adminSessionProvider)!),
    ))!.unwrap();
    final period = periods.single;
    expect(period.startDate.day, 1);
    expect(period.endDate.month, period.startDate.month);
    expect(period.endDate.addDays(1).day, 1);
    expect(find.text(period.name), findsWidgets);
  });

  testWidgets('overtime rules are saved', (tester) async {
    final c = await pumpApp(tester, size: tabletSize);
    await _tap(tester, find.text('Payroll'));

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Overtime rules'));
    await _tap(tester, find.widgetWithText(SwitchListTile, 'Daily overtime'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Overtime after, each day'),
      '8',
    );
    await _tap(tester, _inDialog(find.widgetWithText(FilledButton, 'Save')));

    expect(find.byType(AlertDialog), findsNothing);
    final stored = (await tester.runAsync(
      () => c
          .read(payrollServiceProvider)
          .settings(c.read(adminSessionProvider)!),
    ))!.unwrap();
    expect(stored.settings.dailyOvertimeAfter, const Duration(hours: 8));
  });
}
