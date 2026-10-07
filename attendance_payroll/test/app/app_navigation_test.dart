import 'package:attendance_payroll/app/app.dart';
import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  group('adaptive navigation', () {
    testWidgets('phones get an app bar and a drawer', (tester) async {
      await pumpApp(tester, size: phoneSize);

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('phone drawer navigates and closes', (tester) async {
      await pumpApp(tester, size: phoneSize);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Employees'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phase 2'), findsOneWidget);
      expect(find.byType(NavigationDrawer), findsNothing);
    });

    testWidgets('small tablets get a compact rail', (tester) async {
      await pumpApp(tester, size: smallTabletSize);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('large tablets get an extended rail', (tester) async {
      await pumpApp(tester, size: tabletSize);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('rail navigation switches the visible area', (tester) async {
      await pumpApp(tester, size: tabletSize);

      await tester.tap(find.text('Payroll'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phase 8'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('choosing Dark switches the app theme mode', (tester) async {
      await pumpApp(tester, size: tabletSize);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    });
  });

  group('routing', () {
    testWidgets('unknown locations show a friendly error', (tester) async {
      await pumpApp(tester, size: phoneSize);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AttendancePayrollApp)),
      );

      container.read(appRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(
        find.text('The requested page could not be found.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Go to dashboard'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('the root path redirects to the dashboard', (tester) async {
      await pumpApp(tester, size: phoneSize);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AttendancePayrollApp)),
      );

      container.read(appRouterProvider).go('/');
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
