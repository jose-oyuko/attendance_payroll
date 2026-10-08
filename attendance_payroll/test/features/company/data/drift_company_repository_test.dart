import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/company/data/drift_company_repository.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftCompanyRepository repository;

  setUp(() {
    db = openTestDatabase();
    repository = DriftCompanyRepository(
      db,
      clock: TestClock().call,
      newId: SequentialIds('co').call,
    );
  });

  test('creates a company and reads it back', () async {
    final created = (await repository.create(acmeDetails)).valueOrNull!;
    final loaded = (await repository.getById(created.id)).valueOrNull!;

    expect(created.id, 'co-1');
    expect(created.version, 1);
    expect(loaded.details, acmeDetails);
  });

  test('rejects invalid details', () async {
    final result = await repository.create(
      const CompanyDetails(name: 'Acme', currencyCode: 'KE', timezone: 'UTC'),
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('update bumps the version and rejects stale versions', () async {
    final created = (await repository.create(acmeDetails)).valueOrNull!;
    const renamed = CompanyDetails(
      name: 'Acme Holdings',
      currencyCode: 'KES',
      timezone: 'Africa/Nairobi',
    );

    final updated = (await repository.update(
      created.id,
      renamed,
      expectedVersion: 1,
    )).valueOrNull!;
    final stale = await repository.update(
      created.id,
      acmeDetails,
      expectedVersion: 1,
    );

    expect(updated.version, 2);
    expect(updated.details.name, 'Acme Holdings');
    expect(stale.failureOrNull, isA<ConflictFailure>());
  });

  test('list returns companies oldest first', () async {
    await repository.create(acmeDetails);
    await repository.create(
      const CompanyDetails(name: 'Beta', currencyCode: 'KES', timezone: 'UTC'),
    );

    final names = (await repository.list()).valueOrNull!.map(
      (c) => c.details.name,
    );

    expect(names, ['Acme Ltd', 'Beta']);
  });

  test('an unknown id is reported as not found', () async {
    expect(
      (await repository.getById('missing')).failureOrNull,
      isA<NotFoundFailure>(),
    );
  });
}
