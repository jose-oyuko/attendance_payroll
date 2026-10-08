import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee_management_service.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => DriftEmployeeRepository(ref.watch(appDatabaseProvider)),
);

final employeeRateRepositoryProvider = Provider<EmployeeRateRepository>(
  (ref) => DriftEmployeeRateRepository(ref.watch(appDatabaseProvider)),
);

final employeeManagementServiceProvider = Provider<EmployeeManagementService>(
  (ref) => EmployeeManagementService(
    employees: ref.watch(employeeRepositoryProvider),
    rates: ref.watch(employeeRateRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  ),
);
