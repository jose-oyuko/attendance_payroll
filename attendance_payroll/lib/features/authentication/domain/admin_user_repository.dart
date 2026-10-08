import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';

abstract interface class AdminUserRepository {
  /// Fails with a `ConflictFailure` when the username is already taken in the
  /// company.
  Future<Result<AdminUser>> create(String companyId, NewAdminUser user);

  Future<Result<AdminUser>> getById(String id);

  /// The administrator with [username] (case-insensitive), or `null`.
  Future<Result<AdminUser?>> findByUsername(String companyId, String username);

  /// Administrators of the company, ordered by username.
  Future<Result<List<AdminUser>>> listByCompany(String companyId);
}
