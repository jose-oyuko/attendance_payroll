import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/app/shell/admin_shell.dart';
import 'package:attendance_payroll/app/shell/planned_feature_screen.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/authentication/presentation/setup_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/sign_in_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/startup_screen.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_detail_screen.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_form_screen.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:attendance_payroll/features/employees/presentation/employees_screen.dart';
import 'package:attendance_payroll/features/settings/presentation/settings_screen.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Locations outside the administrator shell.
abstract final class AppRoutes {
  static const String starting = '/starting';
  static const String setup = '/setup';
  static const String signIn = '/sign-in';

  static const Set<String> signedOut = {starting, setup, signIn};
}

/// Where the router must send the user for [auth], or `null` to stay at
/// [location]. Administrator screens are only reachable while signed in.
String? redirectForAuth(AsyncValue<AuthState> auth, String location) {
  final required = switch (auth) {
    AsyncData(value: NeedsSetup()) => AppRoutes.setup,
    AsyncData(value: SignedOut()) => AppRoutes.signIn,
    AsyncData(value: SignedIn()) => null,
    _ => AppRoutes.starting,
  };
  if (required == null) {
    return AppRoutes.signedOut.contains(location)
        ? AdminDestination.dashboard.path
        : null;
  }
  return location == required ? null : required;
}

/// The application router.
///
/// One shell branch per [AdminDestination] keeps each area's navigation state
/// alive while the user switches between areas. Kiosk mode gets its own route
/// tree in Phase 4.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => authChanges.value++)
    ..onDispose(authChanges.dispose);

  final router = GoRouter(
    initialLocation: AdminDestination.dashboard.path,
    refreshListenable: authChanges,
    redirect: (context, state) => redirectForAuth(
      ref.read(authControllerProvider),
      state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AdminDestination.dashboard.path,
      ),
      GoRoute(
        path: AppRoutes.starting,
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
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
                  routes: _childRoutesFor(destination),
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
    AdminDestination.employees => const EmployeesScreen(),
    AdminDestination.settings => const SettingsScreen(),
    _ => PlannedFeatureScreen(destination: destination),
  };
}

List<RouteBase> _childRoutesFor(AdminDestination destination) {
  return switch (destination) {
    AdminDestination.employees => [
      GoRoute(
        path: EmployeeRoutes.newSegment,
        builder: (context, state) => const EmployeeFormScreen(),
      ),
      GoRoute(
        path: EmployeeRoutes.detailSegment,
        builder: (context, state) => EmployeeDetailScreen(
          employeeId: state.pathParameters[EmployeeRoutes.idParameter]!,
        ),
        routes: [
          GoRoute(
            path: EmployeeRoutes.editSegment,
            builder: (context, state) => EmployeeFormScreen(
              employeeId: state.pathParameters[EmployeeRoutes.idParameter],
            ),
          ),
        ],
      ),
    ],
    _ => const <RouteBase>[],
  };
}
