import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/sync_state.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

// These tests write rows directly, bypassing repository validation, to prove
// the database itself enforces integrity.
void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 10, 5, 8, 2, 3, 456);

  setUp(() => db = openTestDatabase());

  EmployeesCompanion employee(
    String companyId, {
    LocalDate? start,
    LocalDate? end,
  }) {
    return EmployeesCompanion.insert(
      id: 'emp-1',
      companyId: companyId,
      employeeNumber: 'E001',
      firstName: 'John',
      lastName: 'Kamau',
      employmentStatus: 'active',
      employmentStartDate: start ?? LocalDate(2026, 1, 1),
      employmentEndDate: Value(end),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<AppFailure> failureOf(Future<Object?> Function() action) async {
    final result = await guardDatabase(action);
    return result.failureOrNull!;
  }

  test('new rows get version 1 and the local-only sync state', () async {
    final companyId = await insertCompany(db);

    final row = await (db.select(
      db.companies,
    )..where((c) => c.id.equals(companyId))).getSingle();

    expect(row.version, 1);
    expect(row.syncState, SyncState.localOnly);
    expect(row.deletedAt, isNull);
  });

  test('timestamps round-trip as UTC with millisecond precision', () async {
    final companyId = await insertCompany(db);
    await db.into(db.employees).insert(employee(companyId));

    final row = await db.select(db.employees).getSingle();

    expect(row.createdAt, now);
    expect(row.createdAt.isUtc, isTrue);
  });

  test('foreign keys are enforced', () async {
    final failure = await failureOf(
      () => db.into(db.employees).insert(employee('no-such-company')),
    );

    expect(failure, isA<DatabaseFailure>());
  });

  test('an employment end date before the start date is rejected', () async {
    final companyId = await insertCompany(db);

    final failure = await failureOf(
      () => db
          .into(db.employees)
          .insert(employee(companyId, end: LocalDate(2025, 12, 31))),
    );

    expect(failure, isA<DatabaseFailure>());
  });

  test('rate amounts must be positive and periods ordered', () async {
    final companyId = await insertCompany(db);
    await db.into(db.employees).insert(employee(companyId));

    EmployeeRatesCompanion rate(String id, int amount, LocalDate? to) {
      return EmployeeRatesCompanion.insert(
        id: id,
        employeeId: 'emp-1',
        rateType: 'hourly',
        amountMinor: amount,
        currencyCode: 'KES',
        effectiveFrom: LocalDate(2026, 7, 1),
        effectiveTo: Value(to),
        createdAt: now,
        updatedAt: now,
      );
    }

    final zero = await failureOf(
      () => db.into(db.employeeRates).insert(rate('r1', 0, null)),
    );
    final reversed = await failureOf(
      () => db
          .into(db.employeeRates)
          .insert(rate('r2', 100, LocalDate(2026, 6, 30))),
    );

    expect(zero, isA<DatabaseFailure>());
    expect(reversed, isA<DatabaseFailure>());
  });

  test('unique violations become conflicts with a friendly message', () async {
    final companyId = await insertCompany(db);
    await db.into(db.employees).insert(employee(companyId));

    final result = await guardDatabase(
      () => db.into(db.employees).insert(employee(companyId)),
      conflictMessage: 'Already exists.',
    );

    final failure = result.failureOrNull;
    expect(failure, isA<ConflictFailure>());
    expect(failure!.userMessage, 'Already exists.');
    expect(failure.userMessage, isNot(contains('UNIQUE')));
  });

  test('failures thrown on purpose pass through unchanged', () async {
    const thrown = NotFoundFailure(entity: 'employee');

    final failure = await failureOf(() async => throw thrown);

    expect(failure, same(thrown));
  });
}
