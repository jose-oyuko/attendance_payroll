import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown while the app checks whether it has been set up, or if that check
/// fails (for example the database cannot be opened).
class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: switch (auth) {
        AsyncError(:final error) => ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.invalidate(authControllerProvider),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
