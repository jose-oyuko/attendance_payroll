import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_view_providers.dart';
import 'package:attendance_payroll/features/employees/presentation/widgets/employment_status_chip.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final _search = TextEditingController();
  bool _includeArchived = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Employee> _filter(List<Employee> employees) {
    final query = _search.text.trim().toLowerCase();
    return [
      for (final employee in employees)
        if ((_includeArchived ||
                employee.details.employmentStatus !=
                    EmploymentStatus.archived) &&
            (employee.details.shownName.toLowerCase().contains(query) ||
                employee.details.fullName.toLowerCase().contains(query) ||
                employee.details.employeeNumber.toLowerCase().contains(query)))
          employee,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Loads archived employees too, so they stay reachable through the
    // filter even when nobody else is left.
    final employees = ref.watch(employeeListProvider(true));
    return switch (employees) {
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(employeeListProvider),
      ),
      AsyncData(:final value) when value.isEmpty => EmptyState(
        icon: Icons.people_outline,
        title: 'No employees yet.',
        message: 'Add your first employee to start tracking attendance.',
        action: FilledButton.icon(
          onPressed: () => context.go(EmployeeRoutes.newEmployee),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add employee'),
        ),
      ),
      AsyncData(:final value) => PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            _Toolbar(
              search: _search,
              includeArchived: _includeArchived,
              onSearchChanged: () => setState(() {}),
              onIncludeArchivedChanged: (value) =>
                  setState(() => _includeArchived = value),
            ),
            _EmployeeList(
              employees: _filter(value),
              emptyMessage: _search.text.trim().isEmpty
                  ? 'No active employees. Turn on "Show archived" to see '
                        'archived ones.'
                  : 'No employees match.',
            ),
          ],
        ),
      ),
      _ => const LoadingState(),
    };
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.includeArchived,
    required this.onSearchChanged,
    required this.onIncludeArchivedChanged,
  });

  final TextEditingController search;
  final bool includeArchived;
  final VoidCallback onSearchChanged;
  final ValueChanged<bool> onIncludeArchivedChanged;

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      controller: search,
      onChanged: (_) => onSearchChanged(),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search by name or number',
      ),
    );
    final archivedFilter = FilterChip(
      label: const Text('Show archived'),
      selected: includeArchived,
      onSelected: onIncludeArchivedChanged,
    );
    final addButton = FilledButton.icon(
      onPressed: () => context.go(EmployeeRoutes.newEmployee),
      icon: const Icon(Icons.person_add_alt),
      label: const Text('Add employee'),
    );

    if (context.windowSize == WindowSize.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          searchField,
          Row(children: [archivedFilter, const Spacer(), addButton]),
        ],
      );
    }
    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(child: searchField),
        archivedFilter,
        addButton,
      ],
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees, required this.emptyMessage});

  final List<Employee> employees;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(emptyMessage, textAlign: TextAlign.center),
      );
    }
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, employee) in employees.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _EmployeeTile(employee: employee),
          ],
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final details = employee.details;
    final jobTitle = details.jobTitle;
    return ListTile(
      onTap: () => context.go(EmployeeRoutes.detail(employee.id)),
      leading: CircleAvatar(child: Text(_initials(details))),
      title: Text(details.shownName),
      subtitle: Text(
        jobTitle == null
            ? details.employeeNumber
            : '${details.employeeNumber} · $jobTitle',
      ),
      trailing: EmploymentStatusChip(status: details.employmentStatus),
    );
  }

  static String _initials(EmployeeDetails details) {
    return '${details.firstName.characters.first}'
            '${details.lastName.characters.first}'
        .toUpperCase();
  }
}
