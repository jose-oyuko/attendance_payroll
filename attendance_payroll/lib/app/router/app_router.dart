import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/app/shell/admin_shell.dart';
import 'package:attendance_payroll/app/shell/planned_feature_screen.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_day_screen.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/features/attendance/presentation/employee_attendance_screen.dart';
import 'package:attendance_payroll/features/attendance/presentation/exceptions_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/authentication/presentation/setup_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/sign_in_screen.dart';
import 'package:attendance_payroll/features/authentication/presentation/startup_screen.dart';
import 'package:attendance_payroll/features/dashboard/presentation/dashboard_screen.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_detail_screen.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_form_screen.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:attendance_payroll/features/employees/presentation/employees_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_screen.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_unlock_screen.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_period_screen.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_routes.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_screen.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_form_screen.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedule_routes.dart';
import 'package:attendance_payroll/features/schedules/presentation/schedules_screen.dart';
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
  static const String kiosk = '/kiosk';
  static const String kioskUnlock = '/kiosk/unlock';

  static const Set<String> signedOut = {starting, setup, signIn};

  static bool isKiosk(String location) =>
      location == kiosk || location.startsWith('$kiosk/');
}

/// Where the router must send the user for [auth], or `null` to stay at
/// [location]. Administrator screens are only reachable while signed in, and
/// a kiosk can reach nothing but the kiosk.
String? redirectForAuth(AsyncValue<AuthState> auth, String location) {
  if (auth case AsyncData(value: KioskMode())) {
    return AppRoutes.isKiosk(location) ? null : AppRoutes.kiosk;
  }
  final required = switch (auth) {
    AsyncData(value: NeedsSetup()) => AppRoutes.setup,
    AsyncData(value: SignedOut()) => AppRoutes.signIn,
    AsyncData(value: SignedIn()) => null,
    _ => AppRoutes.starting,
  };
  if (required == null) {
    return AppRoutes.signedOut.contains(location) || AppRoutes.isKiosk(location)
        ? AdminDestination.dashboard.path
        : null;
  }
  return location == required ? null : required;
}

/// The application router.
///
/// One shell branch per [AdminDestination] keeps each area's navigation state
/// alive while the user switches between areas. Kiosk mode has its own route
/// tree outside the shell, so no administrator screen is reachable from it.
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
      GoRoute(
        path: AppRoutes.kiosk,
        builder: (context, state) =>
            const KioskScreen(unlockLocation: AppRoutes.kioskUnlock),
        routes: [
          GoRoute(
            path: 'unlock',
            builder: (context, state) =>
                const KioskUnlockScreen(kioskLocation: AppRoutes.kiosk),
          ),
        ],
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
    AdminDestination.attendance => const AttendanceDayScreen(),
    AdminDestination.schedules => const SchedulesScreen(),
    AdminDestination.payroll => const PayrollScreen(),
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
          GoRoute(
            path: EmployeeRoutes.attendanceSegment,
            builder: (context, state) {
              final id = state.pathParameters[EmployeeRoutes.idParameter]!;
              return EmployeeAttendanceScreen(
                employeeId: id,
                backLocation: EmployeeRoutes.detail(id),
              );
            },
          ),
        ],
      ),
    ],
    AdminDestination.attendance => [
      GoRoute(
        path: AttendanceRoutes.exceptionsSegment,
        builder: (context, state) => const ExceptionsScreen(),
      ),
      GoRoute(
        path: AttendanceRoutes.employeeSegment,
        builder: (context, state) => EmployeeAttendanceScreen(
          employeeId: state.pathParameters[AttendanceRoutes.idParameter]!,
          backLocation: AttendanceRoutes.day,
        ),
      ),
    ],
    AdminDestination.schedules => [
      GoRoute(
        path: ScheduleRoutes.newSegment,
        builder: (context, state) => const ScheduleFormScreen(),
      ),
      GoRoute(
        path: ScheduleRoutes.editSegment,
        builder: (context, state) => ScheduleFormScreen(
          scheduleId: state.pathParameters[ScheduleRoutes.idParameter],
        ),
      ),
    ],
    AdminDestination.payroll => [
      GoRoute(
        path: PayrollRoutes.periodSegment,
        builder: (context, state) => PayrollPeriodScreen(
          periodId: state.pathParameters[PayrollRoutes.idParameter]!,
        ),
      ),
    ],
    _ => const <RouteBase>[],
  };
}
