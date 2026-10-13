import 'package:attendance_payroll/features/authentication/presentation/session_timeout_guard.dart';
import 'package:attendance_payroll/features/authentication/presentation/sign_in_screen.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_env.dart';

const _limit = Duration(minutes: 5);

void main() {
  late DateTime now;

  setUp(() => now = DateTime.utc(2026, 10, 12, 9));

  Future<void> open(WidgetTester tester) async {
    await pumpApp(
      tester,
      size: tabletSize,
      overrides: [
        inactivityLimitProvider.overrideWithValue(_limit),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    expect(find.byType(DashboardScreen), findsOneWidget);
  }

  Future<void> idle(WidgetTester tester, Duration time) async {
    await tester.pump(time);
    await tester.pumpAndSettle();
  }

  group('inactivity', () {
    testWidgets('signs the administrator out and says why', (tester) async {
      await open(tester);

      await idle(tester, _limit - const Duration(seconds: 1));
      expect(find.byType(DashboardScreen), findsOneWidget);

      await idle(tester, const Duration(seconds: 2));

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(
        find.textContaining('after 5 minutes without activity'),
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
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('signing in again works and clears the message', (
      tester,
    ) async {
      await open(tester);
      await idle(tester, _limit + const Duration(seconds: 1));
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
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.textContaining('without activity'), findsNothing);
    });

    testWidgets('nothing runs while nobody is signed in', (tester) async {
      await pumpApp(
        tester,
        size: tabletSize,
        signedIn: false,
        overrides: [inactivityLimitProvider.overrideWithValue(_limit)],
      );

      await idle(tester, _limit * 3);

      expect(tester.takeException(), isNull);
      expect(find.byType(SignInScreen), findsNothing);
    });
  });

  group('leaving the app', () {
    void lifecycle(WidgetTester tester, AppLifecycleState state) =>
        tester.binding.handleAppLifecycleStateChanged(state);

    testWidgets('staying away too long signs out on return', (tester) async {
      await open(tester);

      lifecycle(tester, AppLifecycleState.inactive);
      lifecycle(tester, AppLifecycleState.hidden);
      lifecycle(tester, AppLifecycleState.paused);
      // The timer does not run in the background; the clock moves on.
      now = now.add(_limit + const Duration(minutes: 1));
      lifecycle(tester, AppLifecycleState.hidden);
      lifecycle(tester, AppLifecycleState.inactive);
      lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
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
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      // And the wait starts again from the return.
      await idle(tester, _limit - const Duration(seconds: 1));
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
