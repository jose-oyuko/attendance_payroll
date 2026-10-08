import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter/material.dart';

extension EmploymentStatusLabel on EmploymentStatus {
  String get label => switch (this) {
    EmploymentStatus.active => 'Active',
    EmploymentStatus.inactive => 'Inactive',
    EmploymentStatus.suspended => 'Suspended',
    EmploymentStatus.archived => 'Archived',
  };
}

/// Compact, colour-coded employment status. The text carries the meaning, so
/// it does not rely on colour alone.
class EmploymentStatusChip extends StatelessWidget {
  const EmploymentStatusChip({required this.status, super.key});

  final EmploymentStatus status;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colors = switch (status) {
      EmploymentStatus.active => semantic.success,
      EmploymentStatus.suspended => semantic.warning,
      EmploymentStatus.inactive ||
      EmploymentStatus.archived => semantic.neutral,
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
