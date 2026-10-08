import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user_repository.dart';
import 'package:drift/drift.dart';

final class DriftAdminUserRepository implements AdminUserRepository {
  DriftAdminUserRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<AdminUser>> create(String companyId, NewAdminUser user) async {
    final normalized = user.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireCompany(companyId);
        final now = _clock();
        final row = await _db
            .into(_db.adminUsers)
            .insertReturning(
              AdminUsersCompanion.insert(
                id: _newId(),
                companyId: companyId,
                username: normalized.username,
                displayName: normalized.displayName,
                role: normalized.role.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return _toDomain(row);
      }),
      conflictMessage: 'The username ${normalized.username} is already taken.',
    );
  }

  @override
  Future<Result<AdminUser>> getById(String id) {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.adminUsers)
                ..where((u) => u.id.equals(id) & u.deletedAt.isNull()))
              .getSingleOrNull();
      return _toDomain(
        row ?? (throw const NotFoundFailure(entity: 'administrator')),
      );
    });
  }

  @override
  Future<Result<AdminUser?>> findByUsername(String companyId, String username) {
    final normalized = NewAdminUser.normalizeUsername(username);
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.adminUsers)..where(
                (u) =>
                    u.companyId.equals(companyId) &
                    u.username.equals(normalized) &
                    u.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      return row == null ? null : _toDomain(row);
    });
  }

  @override
  Future<Result<List<AdminUser>>> listByCompany(String companyId) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.adminUsers)
                ..where(
                  (u) => u.companyId.equals(companyId) & u.deletedAt.isNull(),
                )
                ..orderBy([(u) => OrderingTerm.asc(u.username)]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<AdminUser>> recordSignIn(String id, DateTime at) {
    return guardDatabase(() async {
      final rows =
          await (_db.update(_db.adminUsers)
                ..where((u) => u.id.equals(id) & u.deletedAt.isNull()))
              .writeReturning(AdminUsersCompanion(lastLoginAt: Value(at)));
      if (rows.isEmpty) {
        throw const NotFoundFailure(entity: 'administrator');
      }
      return _toDomain(rows.single);
    });
  }

  AdminUser _toDomain(AdminUserRow row) {
    return AdminUser(
      id: row.id,
      companyId: row.companyId,
      username: row.username,
      displayName: row.displayName,
      role: AdminRole.values.byName(row.role),
      active: row.active,
      lastLoginAt: row.lastLoginAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
