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

final class SignedIn extends AuthState {
  const SignedIn(this.session);

  final AdminSession session;
}

/// The app is locked, which means the attendance kiosk is showing: employees
/// can clock in and out, and nothing else is reachable until an
/// administrator signs in. This is where the app starts, and where it goes
/// when it locks itself or is locked.
final class KioskMode extends AuthState {
  const KioskMode(this.kiosk, {this.notice});

  final KioskContext kiosk;

  /// Why the app locked, when the administrator did not ask for it (for
  /// example after a period without activity). Shown where they sign in.
  final String? notice;
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final setUp = (await ref.watch(adminAuthServiceProvider).isSetUp())
        .unwrap();
    if (!setUp) {
      return const NeedsSetup();
    }
    // Locked until an administrator signs in, whatever state the app was
    // left in.
    return KioskMode(
      (await ref.watch(kioskServiceProvider).lockIfNeeded()).unwrap(),
    );
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

  /// Locks the app: the kiosk is shown and the administrator's session ends.
  /// [reason] is shown where they sign in again. A lock the administrator did
  /// not ask for ([system], such as after a restore, when their session may
  /// no longer be valid) is recorded as the app's own. Returns the failure to
  /// show, or `null` on success.
  Future<AppFailure?> lock({String? reason, bool system = false}) async {
    final session = switch (state) {
      AsyncData(value: SignedIn(:final session)) when !system => session,
      _ => null,
    };
    final locked = await ref.read(kioskServiceProvider).lock(by: session);
    switch (locked) {
      case Ok(:final value):
        state = AsyncData(KioskMode(value, notice: reason));
        return null;
      case Err(:final failure):
        ref
            .read(appLoggerProvider)
            .warning(
              'auth',
              'Locking the app failed',
              fields: {'code': failure.code},
              error: failure.cause,
              stackTrace: failure.stackTrace,
            );
        return failure;
    }
  }

  /// Unlocks the app after an administrator signs in. Returns the failure to
  /// show, or `null` on success; on failure the app stays locked.
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
/// (for example right after the app locked).
AdminSession requireSession(Ref ref) {
  return ref.watch(adminSessionProvider) ??
      (throw const AuthenticationFailure(
        userMessage: 'The app is locked. Sign in again to continue.',
      ));
}
