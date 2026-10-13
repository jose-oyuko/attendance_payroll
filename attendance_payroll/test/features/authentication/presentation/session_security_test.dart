import 'package:attendance_payroll/features/authentication/presentation/session_timeout_guard.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_env.dart';

const _limit = Duration(minutes: 5);

void main() {
  late DateTime now;

  setUp(() => now = DateTime.utc(2026, 10, 12, 9));

  Future<void> open(WidgetTester tester, {Duration? limit = _limit}) async {
    await pumpApp(
      tester,
      size: tabletSize,
      overrides: [
        inactivityLimitProvider.overrideWithValue(limit),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    expect(find.byType(DashboardScreen), findsOneWidget);
  }

  /// Lets the real work behind a frame finish (locking writes to the
  /// database) without moving the test's clock.
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> idle(WidgetTester tester, Duration time) async {
    await tester.pump(time);
    await flush(tester);
  }

  /// The administrator's way back in, from the kiosk.
  Future<void> openUnlock(WidgetTester tester) async {
    await tester.tap(find.text('Administrator'));
    await tester.pumpAndSettle();
    expect(find.byType(KioskUnlockScreen), findsOneWidget);
  }

  group('inactivity', () {
    testWidgets('locks the app, showing the kiosk, and says why', (
      tester,
    ) async {
      await open(tester);

      await idle(tester, _limit - const Duration(seconds: 1));
      expect(find.byType(DashboardScreen), findsOneWidget);

      await idle(tester, const Duration(seconds: 2));

      // Employees can use the kiosk straight away.
      expect(find.byType(KioskScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      // The administrator is told why when they come to unlock it.
      await openUnlock(tester);
      expect(
        find.textContaining('locked after 5 minutes without activity'),
        findsOneWidget,
      );
    });

    testWidgets('every touch starts the wait again', (tester) async {
      await open(tester);

      for (var i = 0; i < 3; i++) {
        await idle(tester, _limit - const Duration(minutes: 1));
        await tester.tapAt(const Offset(500, 400));
        await tester.pump();
      }
      expect(find.byType(DashboardScreen), findsOneWidget);

      await idle(tester, _limit + const Duration(seconds: 1));
      expect(find.byType(KioskScreen), findsOneWidget);
    });

    testWidgets('unlocking works and the message goes away', (tester) async {
      await open(tester);
      await idle(tester, _limit + const Duration(seconds: 1));
      await openUnlock(tester);
      expect(find.textContaining('without activity'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        ownerUsername,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        ownerPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await flush(tester);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.textContaining('without activity'), findsNothing);
    });

    testWidgets('after unlocking, it locks again after the same wait', (
      tester,
    ) async {
      await open(tester);
      await idle(tester, _limit + const Duration(seconds: 1));
      await openUnlock(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        ownerUsername,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        ownerPassword,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      await idle(tester, _limit + const Duration(seconds: 1));

      expect(find.byType(KioskScreen), findsOneWidget);
    });

    testWidgets('never locks when the time is set to never', (tester) async {
      await open(tester, limit: null);

      await idle(tester, const Duration(hours: 12));

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('nothing runs on a brand new install', (tester) async {
      await pumpApp(
        tester,
        size: tabletSize,
        signedIn: false,
        overrides: [inactivityLimitProvider.overrideWithValue(_limit)],
      );

      await idle(tester, _limit * 3);

      expect(tester.takeException(), isNull);
      expect(find.byType(KioskScreen), findsNothing);
    });

    testWidgets('the kiosk itself is never locked out', (tester) async {
      await open(tester);
      await idle(tester, _limit + const Duration(seconds: 1));
      expect(find.byType(KioskScreen), findsOneWidget);

      await idle(tester, _limit * 4);

      expect(find.byType(KioskScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('leaving the app', () {
    void lifecycle(WidgetTester tester, AppLifecycleState state) =>
        tester.binding.handleAppLifecycleStateChanged(state);

    testWidgets('staying away too long locks the app on return', (
      tester,
    ) async {
      await open(tester);

      lifecycle(tester, AppLifecycleState.inactive);
      lifecycle(tester, AppLifecycleState.hidden);
      lifecycle(tester, AppLifecycleState.paused);
      // The timer does not run in the background; the clock moves on.
      now = now.add(_limit + const Duration(minutes: 1));
      lifecycle(tester, AppLifecycleState.hidden);
      lifecycle(tester, AppLifecycleState.inactive);
      lifecycle(tester, AppLifecycleState.resumed);
      await flush(tester);

      expect(find.byType(KioskScreen), findsOneWidget);
      await openUnlock(tester);
      expect(find.textContaining('without activity'), findsOneWidget);
    });

    testWidgets('a short absence keeps the session', (tester) async {
      await open(tester);

      lifecycle(tester, AppLifecycleState.inactive);
      lifecycle(tester, AppLifecycleState.hidden);
      lifecycle(tester, AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 1));
      lifecycle(tester, AppLifecycleState.hidden);
      lifecycle(tester, AppLifecycleState.inactive);
      lifecycle(tester, AppLifecycleState.resumed);
      await flush(tester);

      expect(find.byType(DashboardScreen), findsOneWidget);
      // And the wait starts again from the return.
      await idle(tester, _limit - const Duration(seconds: 1));
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('with no limit, being away never locks', (tester) async {
      await open(tester, limit: null);

      lifecycle(tester, AppLifecycleState.paused);
      now = now.add(const Duration(days: 2));
      lifecycle(tester, AppLifecycleState.resumed);
      await flush(tester);

      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('changing the password', () {
    Future<void> openDialog(WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Change password'));
      await tester.pumpAndSettle();
      expect(find.text('Current password'), findsOneWidget);
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      required String current,
      required String next,
      String? confirm,
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        current,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        next,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        confirm ?? next,
      );
    }

    testWidgets('needs the current password', (tester) async {
      await openDialog(tester);

      await fill(
        tester,
        current: 'not my password',
        next: 'brand new password',
      );
      await submit(tester);

      expect(
        find.textContaining('current password is incorrect'),
        findsOneWidget,
      );
      expect(find.text('Current password'), findsOneWidget);
    });

    testWidgets('checks the new password before asking the service', (
      tester,
    ) async {
      await openDialog(tester);

      await fill(tester, current: ownerPassword, next: 'short');
      await submit(tester);
      expect(find.textContaining('at least 8'), findsOneWidget);

      await fill(
        tester,
        current: ownerPassword,
        next: 'brand new password',
        confirm: 'something else',
      );
      await submit(tester);
      expect(find.text('The passwords do not match.'), findsOneWidget);
    });

    testWidgets('changes it and says so', (tester) async {
      await openDialog(tester);

      await fill(tester, current: ownerPassword, next: 'brand new password');
      await submit(tester);

      expect(find.text('Current password'), findsNothing);
      expect(find.text('Password changed.'), findsOneWidget);
    });
  });

  test('the inactivity limit is a sensible default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(inactivityLimitProvider),
      const Duration(minutes: 15),
    );
  });
}
