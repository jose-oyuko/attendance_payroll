import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/authentication/domain/credential.dart';
import 'package:drift/drift.dart';

final class DriftCredentialRepository implements CredentialRepository {
  DriftCredentialRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<StoredCredential?>> find(CredentialOwner owner) {
    return guardDatabase(() async {
      final row = await _select(owner).getSingleOrNull();
      return row == null ? null : _toDomain(row);
    });
  }

  @override
  Future<Result<void>> replaceSecret(
    CredentialOwner owner,
    String secretHash, {
    required bool isTemporary,
  }) {
    return guardDatabase(
      () => _db.transaction(() async {
        final now = _clock();
        final changes = CredentialsCompanion(
          secretHash: Value(secretHash),
          isTemporary: Value(isTemporary),
          failedAttempts: const Value(0),
          lockedUntil: const Value(null),
          changedAt: Value(now),
          updatedAt: Value(now),
        );
        final existing = await _select(owner).getSingleOrNull();
        if (existing != null) {
          await (_db.update(
            _db.credentials,
          )..where((c) => c.id.equals(existing.id))).write(changes);
          return;
        }
        await _db
            .into(_db.credentials)
            .insert(
              changes.copyWith(
                id: Value(_newId()),
                kind: Value(owner.kind.name),
                adminUserId: Value(
                  owner.kind == CredentialKind.adminPassword ? owner.id : null,
                ),
                employeeId: Value(
                  owner.kind == CredentialKind.employeePin ? owner.id : null,
                ),
              ),
            );
      }),
    );
  }

  @override
  Future<Result<void>> recordAttempts(
    CredentialOwner owner, {
    required int failedAttempts,
    required DateTime? lockedUntil,
  }) {
    return guardDatabase(() async {
      await (_db.update(
        _db.credentials,
      )..where((c) => _matches(c, owner))).write(
        CredentialsCompanion(
          failedAttempts: Value(failedAttempts),
          lockedUntil: Value(lockedUntil),
          updatedAt: Value(_clock()),
        ),
      );
    });
  }

  SimpleSelectStatement<$CredentialsTable, CredentialRow> _select(
    CredentialOwner owner,
  ) {
    return _db.select(_db.credentials)..where((c) => _matches(c, owner));
  }

  Expression<bool> _matches($CredentialsTable c, CredentialOwner owner) {
    return switch (owner.kind) {
      CredentialKind.adminPassword => c.adminUserId.equals(owner.id),
      CredentialKind.employeePin => c.employeeId.equals(owner.id),
    };
  }

  StoredCredential _toDomain(CredentialRow row) {
    return StoredCredential(
      secretHash: row.secretHash,
      isTemporary: row.isTemporary,
      failedAttempts: row.failedAttempts,
      lockedUntil: row.lockedUntil,
      changedAt: row.changedAt,
    );
  }
}
