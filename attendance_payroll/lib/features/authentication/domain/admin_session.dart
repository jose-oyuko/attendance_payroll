import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';

/// A signed-in administrator. Application services take a session and check
/// permissions themselves; hiding UI is never the only protection.
final class AdminSession {
  const AdminSession({required this.admin, required this.signedInAt});

  final AdminUser admin;
  final DateTime signedInAt;

  String get companyId => admin.companyId;

  bool can(Permission permission) {
    return admin.active && admin.role.permissions.contains(permission);
  }

  /// A [PermissionFailure] unless the session may perform [permission].
  PermissionFailure? check(Permission permission) {
    return can(permission) ? null : const PermissionFailure();
  }
}
