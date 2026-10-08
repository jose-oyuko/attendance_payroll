import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/company/data/drift_company_repository.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fresh in-memory database, closed automatically after the test.
AppDatabase openTestDatabase() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// Deterministic clock: starts at [start] and advances one second per reading.
class TestClock {
  TestClock([DateTime? start]) : _next = start ?? DateTime.utc(2026, 10, 1, 8);

  DateTime _next;

  DateTime call() {
    final now = _next;
    _next = _next.add(const Duration(seconds: 1));
    return now;
  }
}

/// Deterministic ids: `<prefix>-1`, `<prefix>-2`, ...
class SequentialIds {
  SequentialIds([this.prefix = 'id']);

  final String prefix;
  int _count = 0;

  String call() => '$prefix-${++_count}';
}

const CompanyDetails acmeDetails = CompanyDetails(
  name: 'Acme Ltd',
  currencyCode: 'KES',
  timezone: 'Africa/Nairobi',
);

/// Inserts a company and returns its id.
Future<String> insertCompany(
  AppDatabase db, {
  CompanyDetails details = acmeDetails,
}) async {
  final result = await DriftCompanyRepository(db).create(details);
  return result.valueOrNull!.id;
}

EmployeeDetails johnDetails({
  String employeeNumber = 'E001',
  EmploymentStatus status = EmploymentStatus.active,
}) {
  return EmployeeDetails(
    employeeNumber: employeeNumber,
    firstName: 'John',
    lastName: 'Kamau',
    employmentStartDate: LocalDate(2026, 1, 1),
    employmentStatus: status,
  );
}
