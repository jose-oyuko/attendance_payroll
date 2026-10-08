import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';

abstract interface class EmployeeRepository {
  /// Fails with a `ConflictFailure` when the employee number is already used
  /// in the company (including by an archived employee).
  Future<Result<Employee>> create(String companyId, EmployeeDetails details);

  Future<Result<Employee>> getById(String id);

  /// Employees of the company ordered by last then first name. Archived
  /// employees are left out unless [includeArchived] is set.
  Future<Result<List<Employee>>> listByCompany(
    String companyId, {
    bool includeArchived = false,
  });

  /// Replaces the employee's details (archiving is a status change). Fails
  /// with a `ConflictFailure` when [expectedVersion] is stale.
  Future<Result<Employee>> update(
    String id,
    EmployeeDetails details, {
    required int expectedVersion,
  });
}

extension CompanyScopedEmployees on EmployeeRepository {
  /// The employee, if it belongs to [companyId]. Employees of other companies
  /// are reported as not found rather than forbidden.
  Future<Result<Employee>> getInCompany(String companyId, String id) async {
    final found = await getById(id);
    return switch (found) {
      Ok(:final value) when value.companyId != companyId => const Err(
        NotFoundFailure(entity: 'employee'),
      ),
      _ => found,
    };
  }
}
