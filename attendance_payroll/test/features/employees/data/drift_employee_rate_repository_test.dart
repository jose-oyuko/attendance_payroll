import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_rate_repository.dart';
import 'package:attendance_payroll/features/employees/data/drift_employee_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

/// KSh amounts in cents.
const int _ksh400 = 40000;
const int _ksh500 = 50000;

NewEmployeeRate _hourly(int amountMinor, LocalDate from, {String? currency}) {
  return NewEmployeeRate(
    rateType: RateType.hourly,
    amountMinor: amountMinor,
    currencyCode: currency ?? 'KES',
    effectiveFrom: from,
  );
}

void main() {
  late AppDatabase db;
  late DriftEmployeeRateRepository rates;
  late String employeeId;

  setUp(() async {
    db = openTestDatabase();
    rates = DriftEmployeeRateRepository(db, clock: TestClock().call);
    final companyId = await insertCompany(db);
    employeeId = (await DriftEmployeeRepository(
      db,
    ).create(companyId, johnDetails())).valueOrNull!.id;
  });

  test('a new rate closes the current one the day before it starts', () async {
    await rates.addRate(employeeId, _hourly(_ksh400, LocalDate(2026, 1, 1)));
    await rates.addRate(employeeId, _hourly(_ksh500, LocalDate(2026, 7, 1)));

    final history = (await rates.history(employeeId)).valueOrNull!;

    expect(history, hasLength(2));
    expect(history[0].amountMinor, _ksh400);
    expect(history[0].effectiveTo, LocalDate(2026, 6, 30));
    expect(history[0].version, 2);
    expect(history[1].amountMinor, _ksh500);
    expect(history[1].isCurrent, isTrue);
  });

  test('rateOn selects the rate in force on each date', () async {
    await rates.addRate(employeeId, _hourly(_ksh400, LocalDate(2026, 1, 1)));
    await rates.addRate(employeeId, _hourly(_ksh500, LocalDate(2026, 7, 1)));

    Future<int?> amountOn(LocalDate date) async {
      return (await rates.rateOn(employeeId, date)).valueOrNull?.amountMinor;
    }

    expect(await amountOn(LocalDate(2025, 12, 31)), isNull);
    expect(await amountOn(LocalDate(2026, 1, 1)), _ksh400);
    expect(await amountOn(LocalDate(2026, 6, 30)), _ksh400);
    expect(await amountOn(LocalDate(2026, 7, 1)), _ksh500);
    expect(await amountOn(LocalDate(2030, 1, 1)), _ksh500);
  });

  test('history cannot be rewritten by back-dating a rate', () async {
    await rates.addRate(employeeId, _hourly(_ksh400, LocalDate(2026, 7, 1)));

    for (final from in [LocalDate(2026, 7, 1), LocalDate(2026, 3, 1)]) {
      final result = await rates.addRate(employeeId, _hourly(_ksh500, from));

      final failure = result.failureOrNull;
      expect(failure, isA<BusinessRuleFailure>());
      expect(
        (failure! as BusinessRuleFailure).rule,
        EmployeeRateRules.mustStartAfterLatest,
      );
    }
    final history = (await rates.history(employeeId)).valueOrNull!;
    expect(history.single.isCurrent, isTrue);
  });

  test('rates must use the company currency', () async {
    final result = await rates.addRate(
      employeeId,
      _hourly(_ksh500, LocalDate(2026, 1, 1), currency: 'USD'),
    );

    final failure = result.failureOrNull;
    expect(failure, isA<BusinessRuleFailure>());
    expect(
      (failure! as BusinessRuleFailure).rule,
      EmployeeRateRules.currencyMismatch,
    );
    expect((await rates.history(employeeId)).valueOrNull, isEmpty);
  });

  test('invalid amounts are rejected before touching the database', () async {
    final result = await rates.addRate(
      employeeId,
      _hourly(0, LocalDate(2026, 1, 1)),
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('an unknown employee is reported as not found', () async {
    final result = await rates.addRate(
      'missing',
      _hourly(_ksh500, LocalDate(2026, 1, 1)),
    );

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
