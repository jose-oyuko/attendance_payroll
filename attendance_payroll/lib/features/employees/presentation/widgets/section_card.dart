import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

/// Titled card used for each section of the employee detail screen.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    super.key,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: context.textStyles.titleMedium),
                  ),
                ),
                ?action,
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Secondary explanatory text inside a [SectionCard].
class SectionNote extends StatelessWidget {
  const SectionNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}
