import 'package:attendance_payroll/core/constants/app_constants.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

/// Shows an [AppFailure] to the user. Only [AppFailure.userMessage] is ever
/// displayed; technical detail stays in the logs.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.failure,
    super.key,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final AppFailure failure;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.messageMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.error_outline,
                  size: AppSpacing.xxl,
                  color: context.colors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                failure.userMessage,
                style: context.textStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
