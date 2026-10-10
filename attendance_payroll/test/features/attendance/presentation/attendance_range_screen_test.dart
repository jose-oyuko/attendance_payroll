import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:attendance_payroll/features/attendance/presentation/widgets/attendance_range_views.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
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

/// John worked a completed session earlier this month (the default range):
/// yesterday, or just after midnight when today is the 1st.
Future<void> _seed(WidgetTester tester, ProviderContainer c) async {
  final zone = CompanyTimeZone('Africa/Nairobi');
  final today = zone.dateOf(DateTime.now());
  final (day, start) = today.day == 1
      ? (today, const Duration(minutes: 5))
      : (today.addDays(-1), const Duration(hours: 8));
  await tester.runAsync(() async {
    final admin = c.read(adminSessionProvider)!;
    final john =
        (await c
                .read(employeeManagementServiceProvider)
                .create(admin, johnDetails()))
            .unwrap();
    for (final (type, at) in [
      (AttendanceEventType.clockIn, start),
      (AttendanceEventType.clockOut, start + const Duration(minutes: 30)),
    ]) {
      (await c
              .read(attendanceCorrectionServiceProvider)
              .addMissingEntry(
                admin,
                john.id,
                type: type,
                occurredAt: zone.instantAt(day, at),
                reason: 'Paper register',
              ))
          .unwrap();
    }
  });
  c.read(attendanceRevisionProvider.notifier).changed();
}

void main() {
  testWidgets('tablets show a table with a total per employee', (tester) async {
    final c = await pumpApp(tester, size: tabletSize);
    await _seed(tester, c);
    await _tap(tester, find.text('Attendance'));
    await _tap(tester, find.text('Range'));

    expect(find.byType(AttendanceRangeTable), findsOneWidget);
    expect(find.text('Clock in'), findsOneWidget);
    expect(find.text('John Kamau'), findsWidgets);
    expect(find.text('Total · John Kamau'), findsOneWidget);
    expect(find.text('30m'), findsWidgets);

    // A completed session is not a problem.
    await _tap(tester, find.text('Only days with problems'));
    expect(find.text('Everything looks good.'), findsOneWidget);
    expect(find.byType(AttendanceRangeTable), findsNothing);
  });

  testWidgets('phones show cards grouped by employee', (tester) async {
    final c = await pumpApp(tester, size: phoneSize);
    await _seed(tester, c);
    await _tap(tester, find.byTooltip('Open navigation menu'));
    await _tap(tester, find.text('Attendance'));
    await _tap(tester, find.text('Range'));

    expect(find.byType(AttendanceRangeTable), findsNothing);
    expect(find.byType(AttendanceRangeList), findsOneWidget);
    expect(find.text('John Kamau'), findsOneWidget);
    expect(find.textContaining('30m worked · 1 present'), findsOneWidget);
  });
}
