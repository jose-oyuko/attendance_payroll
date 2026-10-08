import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/validators.dart';

/// Operations that require authorisation. Services check these, not roles.
enum Permission {
  viewEmployees,
  manageEmployees,
  manageEmployeePins,
  viewAttendance,
  correctAttendance,
  manageAttendanceSettings,
  manageKiosk,
}

/// What an administrator may do. V1 has a single all-powerful role; finer
/// roles (payroll administrator, HR administrator, attendance manager,
/// supervisor, auditor) are added here with their permission sets. Roles are
/// stored by name, so adding one needs no migration.
enum AdminRole {
  owner;

  Set<Permission> get permissions => switch (this) {
    AdminRole.owner => Permission.values.toSet(),
  };
}

/// A person who administers the application. Not an employee.
final class AdminUser {
  const AdminUser({
    required this.id,
    required this.companyId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.active,
    required this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String companyId;

  /// Lower-case login name, unique within the company.
  final String username;
  final String displayName;
  final AdminRole role;
  final bool active;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

/// Data needed to create an [AdminUser].
final class NewAdminUser {
  const NewAdminUser({
    required this.username,
    required this.displayName,
    this.role = AdminRole.owner,
  });

  final String username;
  final String displayName;
  final AdminRole role;

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9._-]{3,32}$');

  /// Usernames are case-insensitive, so they are stored lower-case.
  static String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  NewAdminUser normalized() {
    return NewAdminUser(
      username: normalizeUsername(username),
      displayName: displayName.trim(),
      role: role,
    );
  }

  /// The first rule this data breaks, or `null` when it is valid.
  ValidationFailure? validate() {
    if (!_usernamePattern.hasMatch(username)) {
      return const ValidationFailure(
        field: 'username',
        userMessage:
            'Usernames are 3–32 characters: letters, numbers, dots, '
            'dashes or underscores.',
      );
    }
    if (Validators.isBlank(displayName)) {
      return const ValidationFailure(
        field: 'displayName',
        userMessage: 'Enter a display name.',
      );
    }
    return null;
  }
}
