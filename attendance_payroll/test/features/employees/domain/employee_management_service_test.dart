import 'dart:convert';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_management_service.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

/// Fails every write, to prove changes roll back with their audit entry.
class _FailingAudit implements AuditLogRepository {
  @override
  Future<Result<void>> record(AuditEntry entry) async {
    return const Err(DatabaseFailure());
  }
}

void main() {
  late TestEnv env;
  late AdminSession session;

  setUp(() async {
    env = TestEnv();
    session = await env.setUpOwner();
  });

  Future<Map<String, Object?>> lastMetadata() async {
    final row = (await env.auditRows()).last;
    return jsonDecode(row.metadata!) as Map<String, Object?>;
  }

  test('create stores the employee and audits it', () async {
    final employee = await env.addEmployee(session);

    final listed = (await env.management.list(session)).unwrap();
    expect(listed.single.id, employee.id);
    final row = (await env.auditRows()).last;
    expect(row.action, 'employee.created');
    expect(row.actorId, session.admin.id);
    expect(row.entityId, employee.id);
    expect(row.deviceId, isNotEmpty);
  });

  test('update audits which fields changed, not their values', () async {
    final employee = await env.addEmployee(session);
    final edited = EmployeeDetails(
      employeeNumber: employee.details.employeeNumber,
      firstName: employee.details.firstName,
      lastName: employee.details.lastName,
      employmentStartDate: employee.details.employmentStartDate,
      jobTitle: 'Supervisor',
      phone: '+254700000001',
    );

    final updated = await env.management.update(
      session,
      employee.id,
      edited,
      expectedVersion: employee.version,
    );

    expect(updated.unwrap().version, 2);
    expect(await lastMetadata(), {
      'fields': ['phone', 'jobTitle'],
    });
    expect((await env.auditRows()).last.metadata, isNot(contains('+2547')));
  });

  test('status changes are audited with from and to', () async {
    final employee = await env.addEmployee(session);

    final archived = await env.management.changeStatus(
      session,
      employee,
      EmploymentStatus.archived,
    );

    expect(
      archived.unwrap().details.employmentStatus,
      EmploymentStatus.archived,
    );
    expect((await env.auditRows()).last.action, 'employee.status_changed');
    expect(await lastMetadata(), {'from': 'active', 'to': 'archived'});
    expect((await env.management.list(session)).unwrap(), isEmpty);
  });

  test('a stale edit fails and leaves no audit entry', () async {
    final employee = await env.addEmployee(session);
    await env.management.changeStatus(
      session,
      employee,
      EmploymentStatus.suspended,
    );
    final auditCount = (await env.auditRows()).length;

    final stale = await env.management.changeStatus(
      session,
      employee,
      EmploymentStatus.archived,
    );

    expect(stale.failureOrNull, isA<ConflictFailure>());
    expect(await env.auditRows(), hasLength(auditCount));
  });

  test('a change whose audit entry fails is rolled back', () async {
    final unaudited = EmployeeManagementService(
      employees: env.employees,
      rates: env.rates,
      audit: _FailingAudit(),
      transactions: env.transactions,
    );

    final result = await unaudited.create(session, johnDetails());

    expect(result.failureOrNull, isA<DatabaseFailure>());
    expect(await env.db.select(env.db.employees).get(), isEmpty);
  });

  test('suggests the next number in the E0001 sequence', () async {
    expect(
      (await env.management.suggestEmployeeNumber(session)).unwrap(),
      'E0001',
    );
    await env.addEmployee(session, employeeNumber: 'E0007');
    await env.addEmployee(session, employeeNumber: 'X-99');

    expect(
      (await env.management.suggestEmployeeNumber(session)).unwrap(),
      'E0008',
    );
  });

  test('employees of another company are not visible', () async {
    final other = await env.companies.create(
      const CompanyDetails(name: 'Other', currencyCode: 'KES', timezone: 'UTC'),
    );
    final foreign = (await env.employees.create(
      other.unwrap().id,
      johnDetails(),
    )).unwrap();

    final result = await env.management.get(session, foreign.id);

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('adding a rate is audited without the amount', () async {
    final employee = await env.addEmployee(session);

    await env.management.addRate(
      session,
      employee.id,
      NewEmployeeRate(
        rateType: RateType.hourly,
        amountMinor: 50000,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 7, 1),
      ),
    );

    expect((await env.auditRows()).last.action, 'employee.rate_added');
    expect(await lastMetadata(), {
      'rateType': 'hourly',
      'effectiveFrom': '2026-07-01',
    });
    expect(
      (await env.management.rateHistory(session, employee.id)).unwrap(),
      hasLength(1),
    );
  });
}
