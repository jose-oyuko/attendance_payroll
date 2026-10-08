import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/domain/credential.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late CredentialOwner owner;

  setUp(() async {
    env = TestEnv();
    final session = await env.setUpOwner();
    owner = CredentialOwner.employee((await env.addEmployee(session)).id);
  });

  test('replacing a secret clears attempts and the lock', () async {
    await env.credentials.replaceSecret(owner, 'hash-1', isTemporary: true);
    await env.credentials.recordAttempts(
      owner,
      failedAttempts: 5,
      lockedUntil: DateTime.utc(2030),
    );

    await env.credentials.replaceSecret(owner, 'hash-2', isTemporary: false);

    final stored = (await env.credentials.find(owner)).unwrap()!;
    expect(stored.secretHash, 'hash-2');
    expect(stored.isTemporary, isFalse);
    expect(stored.failedAttempts, 0);
    expect(stored.lockedUntil, isNull);
    expect(
      await (env.db.select(
        env.db.credentials,
      )..where((c) => c.employeeId.equals(owner.id))).get(),
      hasLength(1),
    );
  });

  test('a credential belongs to exactly one owner', () async {
    final now = DateTime.utc(2026, 10, 8);
    final admin = await env.db.select(env.db.adminUsers).getSingle();

    final both = await guardDatabase(
      () => env.db
          .into(env.db.credentials)
          .insert(
            CredentialsCompanion.insert(
              id: 'x',
              kind: 'employeePin',
              adminUserId: Value(admin.id),
              employeeId: Value(owner.id),
              secretHash: 'h',
              changedAt: now,
              updatedAt: now,
            ),
          ),
    );
    final neither = await guardDatabase(
      () => env.db
          .into(env.db.credentials)
          .insert(
            CredentialsCompanion.insert(
              id: 'y',
              kind: 'employeePin',
              secretHash: 'h',
              changedAt: now,
              updatedAt: now,
            ),
          ),
    );

    expect(both.failureOrNull, isA<DatabaseFailure>());
    expect(neither.failureOrNull, isA<DatabaseFailure>());
  });
}
