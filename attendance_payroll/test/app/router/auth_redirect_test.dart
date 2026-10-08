import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8);
  final signedIn = AsyncData<AuthState>(
    SignedIn(
      AdminSession(
        admin: AdminUser(
          id: 'a',
          companyId: 'c',
          username: 'owner',
          displayName: 'Owner',
          role: AdminRole.owner,
          active: true,
          lastLoginAt: now,
          createdAt: now,
          updatedAt: now,
          version: 1,
        ),
        signedInAt: now,
      ),
    ),
  );
  const employees = '/employees/abc';

  test('while loading, everything goes to the startup screen', () {
    expect(
      redirectForAuth(const AsyncLoading<AuthState>(), employees),
      AppRoutes.starting,
    );
    expect(
      redirectForAuth(const AsyncLoading<AuthState>(), AppRoutes.starting),
      isNull,
    );
  });

  test('before setup, everything goes to setup', () {
    const auth = AsyncData<AuthState>(NeedsSetup());

    expect(redirectForAuth(auth, employees), AppRoutes.setup);
    expect(redirectForAuth(auth, AppRoutes.signIn), AppRoutes.setup);
    expect(redirectForAuth(auth, AppRoutes.setup), isNull);
  });

  test('signed out, administrator screens are unreachable', () {
    const auth = AsyncData<AuthState>(SignedOut());

    expect(redirectForAuth(auth, employees), AppRoutes.signIn);
    expect(redirectForAuth(auth, AppRoutes.setup), AppRoutes.signIn);
    expect(redirectForAuth(auth, AppRoutes.signIn), isNull);
  });

  test('signed in, signed-out screens lead to the dashboard', () {
    expect(redirectForAuth(signedIn, employees), isNull);
    expect(
      redirectForAuth(signedIn, AppRoutes.signIn),
      AdminDestination.dashboard.path,
    );
    expect(
      redirectForAuth(signedIn, AppRoutes.setup),
      AdminDestination.dashboard.path,
    );
  });

  group('kiosk mode', () {
    final kiosk = AsyncData<AuthState>(
      KioskMode(
        KioskContext(
          companyId: 'c',
          companyName: 'Acme',
          timeZone: CompanyTimeZone('Africa/Nairobi'),
        ),
      ),
    );

    test('only kiosk locations are reachable', () {
      expect(redirectForAuth(kiosk, AppRoutes.kiosk), isNull);
      expect(redirectForAuth(kiosk, AppRoutes.kioskUnlock), isNull);
      for (final location in [
        AdminDestination.dashboard.path,
        employees,
        AppRoutes.signIn,
        AppRoutes.setup,
        '/kioskx',
      ]) {
        expect(
          redirectForAuth(kiosk, location),
          AppRoutes.kiosk,
          reason: location,
        );
      }
    });

    test('kiosk locations need kiosk mode', () {
      expect(
        redirectForAuth(signedIn, AppRoutes.kiosk),
        AdminDestination.dashboard.path,
      );
      expect(
        redirectForAuth(
          const AsyncData<AuthState>(SignedOut()),
          AppRoutes.kiosk,
        ),
        AppRoutes.signIn,
      );
    });
  });
}
