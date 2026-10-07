import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/app/shell/admin_shell.dart';
import 'package:attendance_payroll/app/shell/planned_feature_screen.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/settings/presentation/settings_screen.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The application router.
///
/// One shell branch per [AdminDestination] keeps each area's navigation state
/// alive while the user switches between areas. Kiosk mode gets its own route
/// tree in Phase 4.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AdminDestination.dashboard.path,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AdminDestination.dashboard.path,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          for (final destination in AdminDestination.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: destination.path,
                  name: destination.name,
                  builder: (context, state) => _screenFor(destination),
                ),
              ],
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: ErrorState(
        failure: const NotFoundFailure(entity: 'page'),
        retryLabel: 'Go to dashboard',
        onRetry: () => context.go(AdminDestination.dashboard.path),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

Widget _screenFor(AdminDestination destination) {
  return switch (destination) {
    AdminDestination.dashboard => const DashboardScreen(),
    AdminDestination.settings => const SettingsScreen(),
    _ => PlannedFeatureScreen(destination: destination),
  };
}
