import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/logging/logging_providers.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/kiosk/data/kiosk_providers.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the administrator experience stands. The router redirects on it.
sealed class AuthState {
  const AuthState();
}

/// First run: no company or owner exists yet.
final class NeedsSetup extends AuthState {
  const NeedsSetup();
}

final class SignedOut extends AuthState {
  const SignedOut();
}

final class SignedIn extends AuthState {
  const SignedIn(this.session);

  final AdminSession session;
}

/// This device is an attendance kiosk: only the kiosk is reachable, and
/// leaving it needs an administrator's password.
final class KioskMode extends AuthState {
  const KioskMode(this.kiosk);

  final KioskContext kiosk;
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final setUp = (await ref.watch(adminAuthServiceProvider).isSetUp())
        .unwrap();
    if (!setUp) {
      return const NeedsSetup();
    }
    final kiosk = (await ref.watch(kioskServiceProvider).current()).unwrap();
    return kiosk == null ? const SignedOut() : KioskMode(kiosk);
  }

  /// Completes first-run setup and signs the owner in. Returns the failure to
  /// show, or `null` on success.
  Future<AppFailure?> setUp({
    required CompanyDetails company,
    required NewAdminUser owner,
    required String password,
  }) async {
    final result = await ref
        .read(adminAuthServiceProvider)
        .setUp(company: company, owner: owner, password: password);
    return _apply(result);
  }

  /// Returns the failure to show, or `null` on success.
  Future<AppFailure?> signIn(String username, String password) async {
    final result = await ref
        .read(adminAuthServiceProvider)
        .signIn(username, password);
    return _apply(result);
  }

  void signOut() => state = const AsyncData(SignedOut());

  /// Turns this device into the attendance kiosk and signs the administrator
  /// out. Returns the failure to show, or `null` on success.
  Future<AppFailure?> startKiosk() async {
    final session = switch (state) {
      AsyncData(value: SignedIn(:final session)) => session,
      _ => null,
    };
    if (session == null) {
      return const AuthenticationFailure(
        userMessage: 'Sign in as an administrator first.',
      );
    }
    final kiosk = ref.read(kioskServiceProvider);
    final started = await kiosk.start(session);
    if (started case Err(:final failure)) {
      return failure;
    }
    final context = (await kiosk.current()).valueOrNull;
    if (context == null) {
      return const UnexpectedFailure();
    }
    state = AsyncData(KioskMode(context));
    return null;
  }

  /// Leaves kiosk mode after an administrator signs in. Returns the failure
  /// to show, or `null` on success; on failure the kiosk stays locked.
  Future<AppFailure?> unlockKiosk(String username, String password) async {
    final signedIn = await ref
        .read(adminAuthServiceProvider)
        .signIn(username, password);
    switch (signedIn) {
      case Err(:final failure):
        return failure;
      case Ok(value: final session):
        final stopped = await ref.read(kioskServiceProvider).stop(session);
        if (stopped case Err(:final failure)) {
          return failure;
        }
        state = AsyncData(SignedIn(session));
        return null;
    }
  }

  AppFailure? _apply(Result<AdminSession> result) {
    switch (result) {
      case Ok(:final value):
        state = AsyncData(SignedIn(value));
        return null;
      case Err(:final failure):
        if (failure is! ValidationFailure &&
            failure is! AuthenticationFailure) {
          ref
              .read(appLoggerProvider)
              .warning(
                'auth',
                'Authentication request failed',
                fields: {'code': failure.code},
                error: failure.cause,
                stackTrace: failure.stackTrace,
              );
        }
        return failure;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in administrator, or `null`. The router only shows
/// administrator screens while signed in.
final adminSessionProvider = Provider<AdminSession?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AsyncData(value: SignedIn(:final session)) => session,
    _ => null,
  };
});

/// For providers that need a session: fails cleanly if it has gone away
/// (for example right after signing out).
AdminSession requireSession(Ref ref) {
  return ref.watch(adminSessionProvider) ??
      (throw const AuthenticationFailure(
        userMessage: 'Your session has ended. Please sign in again.',
      ));
}
