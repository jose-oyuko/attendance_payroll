import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Read models for the employee screens. Each goes through an application
// service with the current session, so permissions are checked below the UI.
// After a change, invalidate the affected providers to refresh the screens.

final employeeListProvider = FutureProvider.autoDispose
    .family<List<Employee>, bool>((ref, includeArchived) async {
      final session = requireSession(ref);
      return (await ref
              .watch(employeeManagementServiceProvider)
              .list(session, includeArchived: includeArchived))
          .unwrap();
    });

final employeeProvider = FutureProvider.autoDispose.family<Employee, String>((
  ref,
  id,
) async {
  final session = requireSession(ref);
  return (await ref.watch(employeeManagementServiceProvider).get(session, id))
      .unwrap();
});

final employeeRatesProvider = FutureProvider.autoDispose
    .family<List<EmployeeRate>, String>((ref, employeeId) async {
      final session = requireSession(ref);
      return (await ref
              .watch(employeeManagementServiceProvider)
              .rateHistory(session, employeeId))
          .unwrap();
    });

final employeePinStatusProvider = FutureProvider.autoDispose
    .family<PinStatus, String>((ref, employeeId) async {
      final session = requireSession(ref);
      return (await ref
              .watch(employeePinServiceProvider)
              .status(session, employeeId))
          .unwrap();
    });
