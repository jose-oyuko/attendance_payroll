import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/kiosk/domain/app_lock_service.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_screen.dart';
import 'package:attendance_payroll/features/settings/presentation/app_lock_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';

void main() {
  /// Lets the real work behind a frame finish (settings are saved in the
  /// database) without moving the test's clock.
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> openSettings(WidgetTester tester) async {
    await pumpApp(tester, size: tabletSize);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await flush(tester);
    expect(find.text('App lock'), findsOneWidget);
  }

  Future<void> choose(WidgetTester tester, String label) async {
    final dropdown = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
    await flush(tester);
  }

  testWidgets('starts at fifteen minutes', (tester) async {
    await openSettings(tester);

    expect(find.text('15 minutes'), findsOneWidget);
    expect(find.textContaining('shows the attendance kiosk'), findsOneWidget);
  });

  testWidgets('the administrator can choose another time', (tester) async {
    await openSettings(tester);

    await choose(tester, '1 minute');

    expect(find.text('1 minute'), findsOneWidget);
    expect(find.text('15 minutes'), findsNothing);
  });

  testWidgets('every time on offer is described in words', (tester) async {
    await openSettings(tester);

    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();

    for (final label in [
      '1 minute',
      '2 minutes',
      '5 minutes',
      '10 minutes',
      '30 minutes',
      '1 hour',
      '2 hours',
      'Never (not recommended)',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });

  testWidgets('choosing never warns about leaving it open', (tester) async {
    await openSettings(tester);
    expect(find.textContaining('stays open until someone locks'), findsNothing);

    await choose(tester, 'Never (not recommended)');

    expect(
      find.textContaining('stays open until someone locks'),
      findsOneWidget,
    );
  });

  testWidgets('the time chosen is the time the app waits before locking', (
    tester,
  ) async {
    await openSettings(tester);
    await choose(tester, '1 minute');

    // Not yet.
    await tester.pump(const Duration(seconds: 50));
    await flush(tester);
    expect(find.byType(KioskScreen), findsNothing);

    // Touching the screen starts the minute again.
    await tester.tapAt(const Offset(500, 500));
    await tester.pump(const Duration(seconds: 50));
    await flush(tester);
    expect(find.byType(KioskScreen), findsNothing);

    // A minute with no touch: locked, and the kiosk is showing.
    await tester.pump(const Duration(seconds: 11));
    await flush(tester);
    expect(find.byType(KioskScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('never means the app never locks by itself', (tester) async {
    await openSettings(tester);
    await choose(tester, 'Never (not recommended)');

    await tester.pump(const Duration(hours: 10));
    await flush(tester);

    expect(find.byType(KioskScreen), findsNothing);
    expect(find.text('App lock'), findsOneWidget);
  });

  test('times are described in plain words', () {
    expect(describeLockTime(1), '1 minute');
    expect(describeLockTime(15), '15 minutes');
    expect(describeLockTime(60), '1 hour');
    expect(describeLockTime(120), '2 hours');
    expect(describeLockTime(AppLockService.neverMinutes), 'Never');
  });
}
