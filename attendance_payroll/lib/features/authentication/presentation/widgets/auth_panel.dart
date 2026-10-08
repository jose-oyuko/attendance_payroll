import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

/// Centred, width-limited panel for the signed-out screens. Scrolls when the
/// keyboard or a large text scale leaves too little room.
class AuthPanel extends StatelessWidget {
  const AuthPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  static const double maxWidth = 480;

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: context.textStyles.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
