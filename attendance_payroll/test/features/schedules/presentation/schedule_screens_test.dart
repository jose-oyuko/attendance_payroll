import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:attendance_payroll/features/schedules/data/schedule_providers.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/schedule_fixtures.dart';
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

Future<Employee> _addJohn(WidgetTester tester, ProviderContainer c) async {
  return (await tester.runAsync(
    () async =>
        (await c
                .read(employeeManagementServiceProvider)
                .create(c.read(adminSessionProvider)!, johnDetails()))
            .unwrap(),
  ))!;
}

void main() {
  testWidgets('create a schedule from the defaults, then edit it', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize);
    await tester.tap(find.text('Schedules'));
    await _settle(tester);
    expect(find.text('No schedules yet.'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'New schedule'));
    expect(find.byType(ScheduleFormScreen), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Day shift',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Create schedule'));

    expect(find.text('Day shift'), findsOneWidget);
    expect(find.textContaining('Mon–Fri'), findsOneWidget);
    expect(find.textContaining('Late after 10 min'), findsOneWidget);

    // Friday becomes a day off.
    await _tap(tester, find.text('Day shift'));
    await _tap(tester, find.widgetWithText(CheckboxListTile, 'Fri'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Save changes'));

    expect(find.textContaining('Mon–Thu'), findsOneWidget);
  });

  testWidgets('a schedule needs a name and a working day', (tester) async {
    await pumpApp(tester, size: phoneSize);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(appRouterProvider).go('/schedules/new');
    await _settle(tester);

    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']) {
      await _tap(tester, find.widgetWithText(CheckboxListTile, day));
    }
    await _tap(tester, find.widgetWithText(FilledButton, 'Create schedule'));

    expect(find.text('Enter a name.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Empty');
    await _tap(tester, find.widgetWithText(FilledButton, 'Create schedule'));
    expect(find.text('Choose at least one working day.'), findsOneWidget);
  });

  testWidgets("assign a schedule from the employee's page", (tester) async {
    final container = await pumpApp(tester, size: tabletSize);
    final john = await _addJohn(tester, container);
    await tester.runAsync(
      () => container
          .read(workScheduleServiceProvider)
          .create(container.read(adminSessionProvider)!, dayShift()),
    );
    container.read(appRouterProvider).go(EmployeeRoutes.detail(john.id));
    await _settle(tester);
    expect(
      find.text('No schedule. Lateness and absence are not checked.'),
      findsOneWidget,
    );

    await _tap(tester, find.widgetWithText(FilledButton, 'Assign schedule'));
    await _tap(tester, find.byType(DropdownButtonFormField<String?>));
    await _tap(tester, find.text('Day shift').last);
    await _tap(tester, find.widgetWithText(FilledButton, 'Assign'));

    expect(find.text('Day shift'), findsOneWidget);
    expect(find.textContaining('Since '), findsOneWidget);
  });

  testWidgets('an absent employee shows in the day and the exceptions', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    final john = await _addJohn(tester, container);
    await tester.runAsync(() async {
      final admin = container.read(adminSessionProvider)!;
      final schedules = container.read(workScheduleServiceProvider);
      // Every day from midnight, no tolerance: absent from 00:00.
      final always = (await schedules.create(
        admin,
        WorkScheduleDetails(
          name: 'Every day',
          days: [
            for (var d = 1; d <= 7; d++)
              ScheduleDay(
                weekday: d,
                start: Duration.zero,
                end: const Duration(minutes: 30),
              ),
          ],
          lateTolerance: Duration.zero,
          earlyDepartureTolerance: Duration.zero,
        ),
      )).unwrap();
      final today = CompanyTimeZone('Africa/Nairobi').dateOf(DateTime.now());
      (await schedules.assign(
        admin,
        john.id,
        always.id,
        effectiveFrom: today.addDays(-3),
      )).unwrap();
    });

    // Seeding bypasses the screens, so announce the change as they would.
    container.read(attendanceRevisionProvider.notifier).changed();
    container.read(appRouterProvider).go(AttendanceRoutes.day);
    await _settle(tester);
    expect(find.text('Absent'), findsWidgets);

    container.read(appRouterProvider).go(AttendanceRoutes.exceptions);
    await _settle(tester);
    // Yesterday's shift is over, so it is an exception to review.
    expect(find.text('John Kamau · Absent on a scheduled day'), findsWidgets);
  });
}
