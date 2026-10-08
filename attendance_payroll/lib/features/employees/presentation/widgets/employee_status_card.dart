import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_view_providers.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/employment_status_chip.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/section_card.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Employment status and the transitions allowed from it.
class EmployeeStatusCard extends ConsumerStatefulWidget {
  const EmployeeStatusCard({required this.employee, super.key});

  final Employee employee;

  @override
  ConsumerState<EmployeeStatusCard> createState() => _EmployeeStatusCardState();
}

class _EmployeeStatusCardState extends ConsumerState<EmployeeStatusCard> {
  bool _busy = false;

  static List<(EmploymentStatus, String)> _transitions(EmploymentStatus from) {
    return switch (from) {
      EmploymentStatus.active => [
        (EmploymentStatus.inactive, 'Deactivate'),
        (EmploymentStatus.suspended, 'Suspend'),
        (EmploymentStatus.archived, 'Archive'),
      ],
      EmploymentStatus.inactive || EmploymentStatus.suspended => [
        (EmploymentStatus.active, 'Activate'),
        (EmploymentStatus.archived, 'Archive'),
      ],
      EmploymentStatus.archived => [(EmploymentStatus.active, 'Restore')],
    };
  }

  static String _consequence(EmploymentStatus to, String name) {
    return switch (to) {
      EmploymentStatus.active => '$name will be able to clock in again.',
      EmploymentStatus.inactive =>
        '$name will not be able to clock in until activated again. Their '
            'attendance and payroll history is kept.',
      EmploymentStatus.suspended =>
        '$name will not be able to clock in while suspended. Their '
            'attendance and payroll history is kept.',
      EmploymentStatus.archived =>
        '$name will be hidden from the employee list and will not be able to '
            'clock in. Attendance and payroll history is kept, and you can '
            'restore them later.',
    };
  }

  Future<void> _change(EmploymentStatus to, String label) async {
    final session = ref.read(adminSessionProvider);
    final employee = widget.employee;
    if (session == null) {
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: '$label ${employee.details.shownName}?',
      message: _consequence(to, employee.details.shownName),
      confirmLabel: label,
      destructive: to != EmploymentStatus.active,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(employeeManagementServiceProvider)
        .changeStatus(session, employee, to);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ref
      ..invalidate(employeeProvider(employee.id))
      ..invalidate(employeeListProvider);
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.employee.details.employmentStatus;
    return SectionCard(
      title: 'Employment status',
      action: EmploymentStatusChip(status: status),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (target, label) in _transitions(status))
            OutlinedButton(
              onPressed: _busy ? null : () => _change(target, label),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
