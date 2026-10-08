import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('settings: attendance rules can be changed and are kept', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    await tester.tap(find.text('Settings'));
    await _settle(tester);

    final field = find.widgetWithText(
      TextFormField,
      'Flag sessions longer than (hours)',
    );
    expect(find.text('Attendance rules'), findsOneWidget);
    await tester.enterText(field, '10');
    final save = find.widgetWithText(FilledButton, 'Save rules');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await _settle(tester);

    expect(find.text('Attendance rules saved.'), findsOneWidget);
    final stored = await tester.runAsync(
      () => container
          .read(attendanceSettingsServiceProvider)
          .get(container.read(adminSessionProvider)!),
    );
    expect(
      stored!.unwrap().policy.excessiveDurationAfter,
      const Duration(hours: 10),
    );
  });

  testWidgets('settings: an out-of-range rule is explained', (tester) async {
    await pumpApp(tester, size: tabletSize);
    await tester.tap(find.text('Settings'));
    await _settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Flag sessions longer than (hours)'),
      '30',
    );
    final save = find.widgetWithText(FilledButton, 'Save rules');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await _settle(tester);

    expect(
      find.text('Long sessions must be flagged after 1 to 24 hours.'),
      findsOneWidget,
    );
  });

  testWidgets('attendance: a mistaken entry is removed with a reason', (
    tester,
  ) async {
    final container = await pumpApp(tester, size: tabletSize);
    final admin = container.read(adminSessionProvider)!;
    final zone = CompanyTimeZone('Africa/Nairobi');
    final yesterday = zone.dateOf(DateTime.now()).addDays(-1);
    DateTime at(int hour, int minute) =>
        zone.instantAt(yesterday, Duration(hours: hour, minutes: minute));

    final employeeId = (await tester.runAsync(() async {
      final employee =
          (await container
                  .read(employeeManagementServiceProvider)
                  .create(admin, johnDetails()))
              .unwrap();
      final corrections = container.read(attendanceCorrectionServiceProvider);
      // The day as recorded: in at 08:00, an accidental out at 08:30, out at
      // 17:00 (which then has no matching clock-in).
      for (final (type, time) in [
        (AttendanceEventType.clockIn, at(8, 0)),
        (AttendanceEventType.clockOut, at(8, 30)),
        (AttendanceEventType.clockOut, at(17, 0)),
      ]) {
        (await corrections.addMissingEntry(
          admin,
          employee.id,
          type: type,
          occurredAt: time,
          reason: 'Imported from paper register',
        )).unwrap();
      }
      return employee.id;
    }))!;

    container.read(appRouterProvider).go(EmployeeRoutes.attendance(employeeId));
    await _settle(tester);

    expect(find.text('Attendance · John Kamau'), findsOneWidget);
    expect(find.text('Clock-out with no clock-in'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);

    await tester.tap(find.textContaining('Out 8:30'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.textContaining('will no longer count'), findsOneWidget);

    // A reason is required.
    await tester.tap(find.widgetWithText(FilledButton, 'Remove entry'));
    await _settle(tester);
    expect(find.text('Give a reason for the correction.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Pressed clock-out by mistake',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Remove entry'));
    await _settle(tester);

    expect(find.text('Attendance corrected.'), findsOneWidget);
    expect(find.text('9h'), findsOneWidget);
    expect(find.text('Clock-out with no clock-in'), findsNothing);
    expect(find.textContaining('Removed clock-out at 8:30'), findsOneWidget);
    expect(find.textContaining('Pressed clock-out by mistake'), findsOneWidget);
  });
}
