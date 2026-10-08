import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/logging/logging_providers.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
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

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final setUp = (await ref.watch(adminAuthServiceProvider).isSetUp())
        .unwrap();
    return setUp ? const SignedOut() : const NeedsSetup();
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
