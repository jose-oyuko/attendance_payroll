import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/exceptions_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
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

/// Records John's attendance yesterday (company time) through corrections:
/// each `(type, hour, minute)` becomes an entry.
Future<void> _seedYesterday(
  WidgetTester tester,
  ProviderContainer container,
  List<(AttendanceEventType, int, int)> entries,
) async {
  await tester.runAsync(() async {
    final admin = container.read(adminSessionProvider)!;
    final zone = CompanyTimeZone('Africa/Nairobi');
    final yesterday = zone.dateOf(DateTime.now()).addDays(-1);
    final john =
        (await container
                .read(employeeManagementServiceProvider)
                .create(admin, johnDetails()))
            .unwrap();
    for (final (type, hour, minute) in entries) {
      (await container
              .read(attendanceCorrectionServiceProvider)
              .addMissingEntry(
                admin,
                john.id,
                type: type,
                occurredAt: zone.instantAt(
                  yesterday,
                  Duration(hours: hour, minutes: minute),
                ),
                reason: 'From the paper register',
              ))
          .unwrap();
    }
  });
  // Seeding bypasses the screens, so announce the change as they would.
  container.read(attendanceRevisionProvider.notifier).changed();
  await _settle(tester);
}

Future<void> _openExceptions(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(appRouterProvider).go(AttendanceRoutes.exceptions);
  await _settle(tester);
  expect(find.byType(ExceptionsScreen), findsOneWidget);
}

void main() {
  testWidgets('tablet: accept a long day as recorded in the split view', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    await _seedYesterday(tester, container, [
      (AttendanceEventType.clockIn, 8, 0),
      (AttendanceEventType.clockOut, 23, 30),
    ]);
    await _openExceptions(tester, container);

    expect(find.text('John Kamau · Unusually long'), findsOneWidget);
    expect(
      find.text('Select an exception to see the details.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('John Kamau · Unusually long'));
    expect(
      find.textContaining("longer than the company's limit"),
      findsOneWidget,
    );

    await _tap(tester, find.widgetWithText(FilledButton, 'Accept as recorded'));
    expect(find.text('Accept as recorded?'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Stocktaking; confirmed by the supervisor',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Accept'));

    expect(find.text('Everything looks good.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(ChoiceChip, 'Settled'));
    await _tap(tester, find.text('John Kamau · Unusually long'));
    expect(find.text('Resolved'), findsWidgets);
    expect(
      find.textContaining('Stocktaking; confirmed by the supervisor'),
      findsOneWidget,
    );
  });

  testWidgets('phone: a correction from the exception resolves it', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: phoneSize);
    // Clocked in by mistake and never worked: remove the clock-in.
    await _seedYesterday(tester, container, [
      (AttendanceEventType.clockIn, 8, 0),
    ]);
    await _openExceptions(tester, container);

    await _tap(tester, find.text('John Kamau · No clock-out recorded'));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Accept as recorded'), findsNothing);
    await _tap(tester, find.widgetWithText(FilledButton, 'Remove clock-in'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Tapped in by mistake on a day off',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Remove entry'));

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Everything looks good.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(ChoiceChip, 'Settled'));
    await _tap(tester, find.text('John Kamau · No clock-out recorded'));
    expect(find.text('Resolved by a correction'), findsOneWidget);
    expect(find.textContaining('Fixed by a correction'), findsOneWidget);
  });

  testWidgets('the dashboard counts open exceptions and links to them', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    await _seedYesterday(tester, container, [
      (AttendanceEventType.clockIn, 8, 0),
    ]);
    container.read(appRouterProvider).go('/dashboard');
    await _settle(tester);

    expect(find.text('Open exceptions'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    await _tap(tester, find.text('Open exceptions'));

    expect(find.byType(ExceptionsScreen), findsOneWidget);
    expect(find.text('John Kamau · No clock-out recorded'), findsOneWidget);
  });

  testWidgets('a correction on another screen refreshes the dashboard', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    await _seedYesterday(tester, container, [
      (AttendanceEventType.clockIn, 8, 0),
    ]);
    final router = container.read(appRouterProvider);
    router.go('/dashboard');
    await _settle(tester);
    expect(find.text('Everything looks good.'), findsNothing);

    // Fix it from the employee's own attendance page.
    final johnId = (await tester.runAsync(
      () async =>
          (await container
                  .read(employeeManagementServiceProvider)
                  .list(container.read(adminSessionProvider)!))
              .unwrap()
              .single
              .id,
    ))!;
    router.go(AttendanceRoutes.employee(johnId));
    await _settle(tester);
    await _tap(tester, find.textContaining('In 8:00'));
    await _tap(tester, find.text('Remove'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Clocked in by mistake',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Remove entry'));

    router.go('/dashboard');
    await _settle(tester);
    expect(find.text('Everything looks good.'), findsOneWidget);
  });
}
