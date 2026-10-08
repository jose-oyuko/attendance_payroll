import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/data/drift_admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftAdminUserRepository repository;
  late String companyId;

  setUp(() async {
    db = openTestDatabase();
    repository = DriftAdminUserRepository(db, clock: TestClock().call);
    companyId = await insertCompany(db);
  });

  const owner = NewAdminUser(username: 'Owner', displayName: 'Jane Owner');

  test('creates an active owner with a normalised username', () async {
    final created = (await repository.create(companyId, owner)).valueOrNull!;
    final loaded = (await repository.getById(created.id)).valueOrNull!;

    expect(loaded.username, 'owner');
    expect(loaded.displayName, 'Jane Owner');
    expect(loaded.role, AdminRole.owner);
    expect(loaded.active, isTrue);
    expect(loaded.lastLoginAt, isNull);
  });

  test('usernames are unique per company, ignoring case', () async {
    await repository.create(companyId, owner);

    final result = await repository.create(
      companyId,
      const NewAdminUser(username: 'OWNER', displayName: 'Someone else'),
    );

    expect(result.failureOrNull, isA<ConflictFailure>());
  });

  test('findByUsername ignores case and returns null when absent', () async {
    await repository.create(companyId, owner);

    final found = await repository.findByUsername(companyId, ' OWNER ');
    final missing = await repository.findByUsername(companyId, 'nobody');

    expect(found.valueOrNull?.displayName, 'Jane Owner');
    expect(missing.isOk, isTrue);
    expect(missing.valueOrNull, isNull);
  });

  test('listByCompany orders by username', () async {
    await repository.create(companyId, owner);
    await repository.create(
      companyId,
      const NewAdminUser(username: 'alice', displayName: 'Alice'),
    );

    final users = (await repository.listByCompany(companyId)).valueOrNull!;

    expect(users.map((u) => u.username), ['alice', 'owner']);
  });

  test('an unknown company is reported as not found', () async {
    final result = await repository.create('missing', owner);

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
