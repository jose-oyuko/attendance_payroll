import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/validators.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_routes.dart';
import 'package:attendance_payroll/features/employees/presentation/employee_view_providers.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/date_field.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:attendance_payroll/shared/widgets/subpage_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Creates an employee, or edits one when [employeeId] is given.
class EmployeeFormScreen extends ConsumerWidget {
  const EmployeeFormScreen({super.key, this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = employeeId;
    if (id == null) {
      return const _EmployeeForm(existing: null);
    }
    return switch (ref.watch(employeeProvider(id))) {
      AsyncData(:final value) => _EmployeeForm(existing: value),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(employeeProvider(id)),
      ),
      _ => const LoadingState(),
    };
  }
}

class _EmployeeForm extends ConsumerStatefulWidget {
  const _EmployeeForm({required this.existing});

  final Employee? existing;

  @override
  ConsumerState<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _displayName;
  late final TextEditingController _jobTitle;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late LocalDate? _startDate;
  late LocalDate? _endDate;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final details = widget.existing?.details;
    _number = TextEditingController(text: details?.employeeNumber);
    _firstName = TextEditingController(text: details?.firstName);
    _middleName = TextEditingController(text: details?.middleName);
    _lastName = TextEditingController(text: details?.lastName);
    _displayName = TextEditingController(text: details?.displayName);
    _jobTitle = TextEditingController(text: details?.jobTitle);
    _phone = TextEditingController(text: details?.phone);
    _email = TextEditingController(text: details?.email);
    _startDate =
        details?.employmentStartDate ?? LocalDate.fromDateTime(DateTime.now());
    _endDate = details?.employmentEndDate;
    if (_isNew) {
      _suggestNumber();
    }
  }

  Future<void> _suggestNumber() async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    final suggestion = await ref
        .read(employeeManagementServiceProvider)
        .suggestEmployeeNumber(session);
    if (mounted && _number.text.isEmpty) {
      _number.text = suggestion.valueOrNull ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _number,
      _firstName,
      _middleName,
      _lastName,
      _displayName,
      _jobTitle,
      _phone,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    final startDate = _startDate;
    if (_busy ||
        session == null ||
        startDate == null ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final existing = widget.existing;
    final details = EmployeeDetails(
      employeeNumber: _number.text,
      firstName: _firstName.text,
      middleName: _middleName.text,
      lastName: _lastName.text,
      displayName: _displayName.text,
      jobTitle: _jobTitle.text,
      phone: _phone.text,
      email: _email.text,
      employmentStatus:
          existing?.details.employmentStatus ?? EmploymentStatus.active,
      employmentStartDate: startDate,
      employmentEndDate: _endDate,
    );
    final service = ref.read(employeeManagementServiceProvider);
    final result = existing == null
        ? await service.create(session, details)
        : await service.update(
            session,
            existing.id,
            details,
            expectedVersion: existing.version,
          );
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok(:final value):
        ref
          ..invalidate(employeeListProvider)
          ..invalidate(employeeProvider(value.id));
        context.go(EmployeeRoutes.detail(value.id));
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.userMessage;
        });
    }
  }

  String? _required(String? value, String message) {
    return Validators.isBlank(value) ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final error = _error;
    final twoColumns = context.windowSize.isAtLeast(WindowSize.medium);

    return PageContainer(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            SubpageHeader(
              title: existing == null
                  ? 'New employee'
                  : 'Edit ${existing.details.shownName}',
              backLocation: existing == null
                  ? EmployeeRoutes.list
                  : EmployeeRoutes.detail(existing.id),
            ),
            if (error != null) FailureBanner(message: error),
            _FieldRow(
              twoColumns: twoColumns,
              children: [
                TextFormField(
                  controller: _number,
                  decoration: const InputDecoration(
                    labelText: 'Employee number',
                  ),
                  maxLength: EmployeeDetails.maxEmployeeNumberLength,
                  validator: (v) => _required(v, 'Enter an employee number.'),
                ),
                TextFormField(
                  controller: _jobTitle,
                  decoration: const InputDecoration(labelText: 'Job title'),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            _FieldRow(
              twoColumns: twoColumns,
              children: [
                TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _required(v, 'Enter a first name.'),
                ),
                TextFormField(
                  controller: _middleName,
                  decoration: const InputDecoration(
                    labelText: 'Middle name (optional)',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
            _FieldRow(
              twoColumns: twoColumns,
              children: [
                TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _required(v, 'Enter a last name.'),
                ),
                TextFormField(
                  controller: _displayName,
                  decoration: const InputDecoration(
                    labelText: 'Preferred name (optional)',
                    helperText: 'Shown on the attendance kiosk',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
            _FieldRow(
              twoColumns: twoColumns,
              children: [
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) {
                    final email = Validators.optional(v);
                    return email == null || Validators.isEmail(email)
                        ? null
                        : 'Enter a valid email address.';
                  },
                ),
              ],
            ),
            _FieldRow(
              twoColumns: twoColumns,
              children: [
                DateField(
                  label: 'Start date',
                  value: _startDate,
                  onChanged: (date) => setState(() => _startDate = date),
                  validator: (date) =>
                      date == null ? 'Choose a start date.' : null,
                ),
                DateField(
                  label: 'End date (optional)',
                  value: _endDate,
                  allowClear: true,
                  onChanged: (date) => setState(() => _endDate = date),
                  validator: (date) {
                    final start = _startDate;
                    return date != null && start != null && date.isBefore(start)
                        ? 'The end date cannot be before the start date.'
                        : null;
                  },
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: BusyButton(
                label: existing == null ? 'Add employee' : 'Save changes',
                busy: _busy,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Places fields side by side when there is room, otherwise stacks them.
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.twoColumns, required this.children});

  final bool twoColumns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!twoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: children,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [for (final child in children) Expanded(child: child)],
    );
  }
}
