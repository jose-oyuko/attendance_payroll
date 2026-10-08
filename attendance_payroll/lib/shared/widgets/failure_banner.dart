import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

/// Inline error message for forms. Announced to screen readers when shown.
class FailureBanner extends StatelessWidget {
  const FailureBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: context.colors.onErrorContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: context.colors.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
