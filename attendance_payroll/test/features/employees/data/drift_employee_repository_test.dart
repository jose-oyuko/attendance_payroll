import 'dart:io';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;
  late DriftEmployeeRepository repository;
  late String companyId;

  setUp(() async {
    db = openTestDatabase();
    clock = TestClock();
    repository = DriftEmployeeRepository(
      db,
      clock: clock.call,
      newId: SequentialIds('emp').call,
    );
    companyId = await insertCompany(db);
  });

  group('create', () {
    test('stores the employee and reads it back unchanged', () async {
      final details = EmployeeDetails(
        employeeNumber: 'E001',
        firstName: 'John',
        middleName: 'Mwangi',
        lastName: 'Kamau',
        displayName: 'Johnny',
        phone: '+254700000000',
        email: 'john@example.com',
        jobTitle: 'Cashier',
        employmentStartDate: LocalDate(2026, 1, 1),
        employmentEndDate: LocalDate(2026, 12, 31),
      );

      final created = (await repository.create(
        companyId,
        details,
      )).valueOrNull!;
      final loaded = (await repository.getById(created.id)).valueOrNull!;

      expect(created.id, 'emp-1');
      expect(created.version, 1);
      expect(loaded.companyId, companyId);
      expect(loaded.details, details);
      expect(loaded.createdAt, created.createdAt);
      expect(loaded.createdAt.isUtc, isTrue);
    });

    test('stores normalised details', () async {
      final created = (await repository.create(
        companyId,
        EmployeeDetails(
          employeeNumber: ' E001 ',
          firstName: ' John ',
          lastName: 'Kamau',
          email: '',
          employmentStartDate: LocalDate(2026, 1, 1),
        ),
      )).valueOrNull!;

      expect(created.details.employeeNumber, 'E001');
      expect(created.details.firstName, 'John');
      expect(created.details.email, isNull);
    });

    test('rejects invalid details without writing anything', () async {
      final result = await repository.create(
        companyId,
        johnDetails(employeeNumber: ' '),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await db.select(db.employees).get(), isEmpty);
    });

    test('a duplicate employee number in the company is a conflict', () async {
      await repository.create(companyId, johnDetails());

      final result = await repository.create(companyId, johnDetails());

      final failure = result.failureOrNull;
      expect(failure, isA<ConflictFailure>());
      expect(failure!.userMessage, 'Employee number E001 is already in use.');
    });

    test('the same employee number is allowed in another company', () async {
      final otherCompany = await insertCompany(db);
      await repository.create(companyId, johnDetails());

      final result = await repository.create(otherCompany, johnDetails());

      expect(result.isOk, isTrue);
    });

    test('an unknown company is reported as not found', () async {
      final result = await repository.create('missing', johnDetails());

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('update', () {
    test('replaces details, bumps the version and keeps createdAt', () async {
      final created = (await repository.create(
        companyId,
        johnDetails(),
      )).valueOrNull!;
      final edited = EmployeeDetails(
        employeeNumber: 'E001',
        firstName: 'John',
        lastName: 'Kamau',
        jobTitle: 'Supervisor',
        employmentStartDate: LocalDate(2026, 1, 1),
      );

      final updated = (await repository.update(
        created.id,
        edited,
        expectedVersion: created.version,
      )).valueOrNull!;

      expect(updated.details.jobTitle, 'Supervisor');
      expect(updated.version, 2);
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    });

    test('a stale version is a conflict and changes nothing', () async {
      final created = (await repository.create(
        companyId,
        johnDetails(),
      )).valueOrNull!;
      await repository.update(
        created.id,
        johnDetails(status: EmploymentStatus.suspended),
        expectedVersion: 1,
      );

      final result = await repository.update(
        created.id,
        johnDetails(status: EmploymentStatus.inactive),
        expectedVersion: 1,
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      final current = (await repository.getById(created.id)).valueOrNull!;
      expect(current.details.employmentStatus, EmploymentStatus.suspended);
      expect(current.version, 2);
    });

    test('an unknown employee is reported as not found', () async {
      final result = await repository.update(
        'missing',
        johnDetails(),
        expectedVersion: 1,
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('taking another employee number is a conflict', () async {
      await repository.create(companyId, johnDetails());
      final second = (await repository.create(
        companyId,
        johnDetails(employeeNumber: 'E002'),
      )).valueOrNull!;

      final result = await repository.update(
        second.id,
        johnDetails(),
        expectedVersion: second.version,
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
    });
  });

  group('listByCompany', () {
    test('orders by name and hides archived employees by default', () async {
      Future<void> add(String number, String first, String last) async {
        await repository.create(
          companyId,
          EmployeeDetails(
            employeeNumber: number,
            firstName: first,
            lastName: last,
            employmentStartDate: LocalDate(2026, 1, 1),
            employmentStatus: number == 'E3'
                ? EmploymentStatus.archived
                : EmploymentStatus.active,
          ),
        );
      }

      await add('E1', 'Mary', 'Wanjiku');
      await add('E2', 'Alice', 'Achieng');
      await add('E3', 'Peter', 'Otieno');

      final active = (await repository.listByCompany(companyId)).valueOrNull!;
      final all = (await repository.listByCompany(
        companyId,
        includeArchived: true,
      )).valueOrNull!;

      expect(active.map((e) => e.details.employeeNumber), ['E2', 'E1']);
      expect(all.map((e) => e.details.employeeNumber), ['E2', 'E3', 'E1']);
    });

    test('does not include other companies', () async {
      final otherCompany = await insertCompany(db);
      await repository.create(otherCompany, johnDetails());

      expect((await repository.listByCompany(companyId)).valueOrNull, isEmpty);
    });
  });

  group('on-device file database', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('attendance_payroll');
      addTearDown(() => directory.delete(recursive: true));
    });

    // Same configuration as the app: a file on a background isolate.
    AppDatabase openFile() {
      return AppDatabase(
        NativeDatabase.createInBackground(File('${directory.path}/app.db')),
      );
    }

    test('employees persist across a restart', () async {
      final first = openFile();
      final company = await insertCompany(first);
      final created = (await DriftEmployeeRepository(
        first,
      ).create(company, johnDetails())).valueOrNull!;
      await first.close();

      final reopened = openFile();
      addTearDown(reopened.close);
      final loaded = (await DriftEmployeeRepository(
        reopened,
      ).getById(created.id)).valueOrNull!;

      expect(loaded.details, johnDetails());
      expect(loaded.createdAt, created.createdAt);
    });

    test('constraint errors from the background isolate are mapped', () async {
      final database = openFile();
      addTearDown(database.close);
      final company = await insertCompany(database);
      final repo = DriftEmployeeRepository(database);
      await repo.create(company, johnDetails());

      final result = await repo.create(company, johnDetails());

      expect(result.failureOrNull, isA<ConflictFailure>());
    });
  });
}
