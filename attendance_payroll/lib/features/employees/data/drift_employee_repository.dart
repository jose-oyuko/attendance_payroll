import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';
import 'package:drift/drift.dart';

final class DriftEmployeeRepository implements EmployeeRepository {
  DriftEmployeeRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<Employee>> create(
    String companyId,
    EmployeeDetails details,
  ) async {
    final normalized = details.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireCompany(companyId);
        final now = _clock();
        final row = await _db
            .into(_db.employees)
            .insertReturning(
              _companion(normalized).copyWith(
                id: Value(_newId()),
                companyId: Value(companyId),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        return _toDomain(row);
      }),
      conflictMessage: _numberTakenMessage(normalized),
    );
  }

  @override
  Future<Result<Employee>> getById(String id) {
    return guardDatabase(() async => _toDomain(await _db.requireEmployee(id)));
  }

  @override
  Future<Result<List<Employee>>> listByCompany(
    String companyId, {
    bool includeArchived = false,
  }) {
    return guardDatabase(() async {
      final query = _db.select(_db.employees)
        ..where((e) => e.companyId.equals(companyId) & e.deletedAt.isNull())
        ..orderBy([
          (e) => OrderingTerm.asc(e.lastName),
          (e) => OrderingTerm.asc(e.firstName),
        ]);
      if (!includeArchived) {
        query.where(
          (e) =>
              e.employmentStatus.equals(EmploymentStatus.archived.name).not(),
        );
      }
      final rows = await query.get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<Employee>> update(
    String id,
    EmployeeDetails details, {
    required int expectedVersion,
  }) async {
    final normalized = details.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await updateVersioned(
          _db,
          _db.employees,
          id: id,
          expectedVersion: expectedVersion,
          entity: 'employee',
          changes: _companion(normalized).copyWith(
            updatedAt: Value(_clock()),
            version: Value(expectedVersion + 1),
          ),
        );
        return _toDomain(await _db.requireEmployee(id));
      }),
      conflictMessage: _numberTakenMessage(normalized),
    );
  }

  String _numberTakenMessage(EmployeeDetails details) {
    return 'Employee number ${details.employeeNumber} is already in use.';
  }

  EmployeesCompanion _companion(EmployeeDetails d) {
    return EmployeesCompanion(
      employeeNumber: Value(d.employeeNumber),
      firstName: Value(d.firstName),
      middleName: Value(d.middleName),
      lastName: Value(d.lastName),
      displayName: Value(d.displayName),
      phone: Value(d.phone),
      email: Value(d.email),
      jobTitle: Value(d.jobTitle),
      employmentStatus: Value(d.employmentStatus.name),
      employmentStartDate: Value(d.employmentStartDate),
      employmentEndDate: Value(d.employmentEndDate),
    );
  }

  Employee _toDomain(EmployeeRow row) {
    return Employee(
      id: row.id,
      companyId: row.companyId,
      details: EmployeeDetails(
        employeeNumber: row.employeeNumber,
        firstName: row.firstName,
        middleName: row.middleName,
        lastName: row.lastName,
        displayName: row.displayName,
        phone: row.phone,
        email: row.email,
        jobTitle: row.jobTitle,
        employmentStatus: EmploymentStatus.values.byName(row.employmentStatus),
        employmentStartDate: row.employmentStartDate,
        employmentEndDate: row.employmentEndDate,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
