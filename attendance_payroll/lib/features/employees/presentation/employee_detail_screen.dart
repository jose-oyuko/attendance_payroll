import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_view_providers.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/employee_pin_card.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/employee_rate_card.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/employee_status_card.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/section_card.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:attendance_payroll/shared/widgets/subpage_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(employeeProvider(employeeId))) {
      AsyncData(:final value) => _EmployeeDetail(employee: value),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        retryLabel: 'Back to employees',
        onRetry: () => context.go(EmployeeRoutes.list),
      ),
      _ => const LoadingState(),
    };
  }
}

class _EmployeeDetail extends StatelessWidget {
  const _EmployeeDetail({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final details = _DetailsCard(employee: employee);
    final side = [
      SectionCard(
        title: 'Attendance',
        action: FilledButton.tonal(
          onPressed: () => context.go(EmployeeRoutes.attendance(employee.id)),
          child: const Text('View attendance'),
        ),
        child: const SectionNote(
          'Clock-ins and clock-outs, issues to review, and corrections.',
        ),
      ),
      EmployeePinCard(employee: employee),
      EmployeeRateCard(employee: employee),
      EmployeeStatusCard(employee: employee),
    ];
    final twoColumns = context.windowSize.isAtLeast(WindowSize.expanded);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SubpageHeader(
            title: employee.details.shownName,
            backLocation: EmployeeRoutes.list,
            actions: [
              FilledButton.tonalIcon(
                onPressed: () => context.go(EmployeeRoutes.edit(employee.id)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
          ),
          if (twoColumns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                Expanded(child: details),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.md,
                    children: side,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [details, ...side],
            ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final d = employee.details;
    final end = d.employmentEndDate;
    final rows = <(String, String?)>[
      ('Employee number', d.employeeNumber),
      ('Full name', d.fullName),
      ('Preferred name', d.displayName),
      ('Job title', d.jobTitle),
      ('Phone', d.phone),
      ('Email', d.email),
      ('Start date', formatLocalDate(context, d.employmentStartDate)),
      ('End date', end == null ? null : formatLocalDate(context, end)),
    ];
    return SectionCard(
      title: 'Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          for (final (label, value) in rows)
            if (value != null)
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      child: Text(
                        label,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static const double _labelWidth = 140;
}
