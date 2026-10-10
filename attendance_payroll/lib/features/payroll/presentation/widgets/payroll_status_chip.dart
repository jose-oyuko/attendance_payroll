import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/presentation/payroll_formatting.dart';
import 'package:flutter/material.dart';

/// Compact, colour-coded payroll period status. The text carries the
/// meaning, so it does not rely on colour alone.
class PayrollStatusChip extends StatelessWidget {
  const PayrollStatusChip({required this.status, super.key});

  final PayrollPeriodStatus status;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colors = switch (status) {
      PayrollPeriodStatus.finalized => semantic.success,
      PayrollPeriodStatus.approved => semantic.info,
      PayrollPeriodStatus.review ||
      PayrollPeriodStatus.reopened => semantic.warning,
      PayrollPeriodStatus.draft ||
      PayrollPeriodStatus.open ||
      PayrollPeriodStatus.processing => semantic.neutral,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          status.label,
          style: context.textStyles.labelMedium?.copyWith(
            color: colors.onContainer,
          ),
        ),
      ),
    );
  }
}
