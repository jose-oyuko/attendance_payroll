import 'package:attendance_payroll/core/result/result.dart';

/// Kinds of secret. Administrator passwords and employee PINs are verified by
/// separate services with separate policies.
enum CredentialKind { adminPassword, employeePin }

/// Whose secret a credential is.
final class CredentialOwner {
  const CredentialOwner.admin(this.id) : kind = CredentialKind.adminPassword;

  const CredentialOwner.employee(this.id) : kind = CredentialKind.employeePin;

  final CredentialKind kind;

  /// Admin user id or employee id.
  final String id;
}

/// A stored secret hash and its guessing protection state.
final class StoredCredential {
  const StoredCredential({
    required this.secretHash,
    required this.isTemporary,
    required this.failedAttempts,
    required this.lockedUntil,
    required this.changedAt,
  });

  final String secretHash;

  /// Issued by an administrator; must be replaced by its owner.
  final bool isTemporary;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime changedAt;
}

abstract interface class CredentialRepository {
  /// The owner's credential, or `null` when none was ever set.
  Future<Result<StoredCredential?>> find(CredentialOwner owner);

  /// Stores [secretHash] as the owner's secret, creating the credential if
  /// needed. Clears failed attempts and any lock.
  Future<Result<void>> replaceSecret(
    CredentialOwner owner,
    String secretHash, {
    required bool isTemporary,
  });

  /// Saves the guessing-protection state after an attempt.
  Future<Result<void>> recordAttempts(
    CredentialOwner owner, {
    required int failedAttempts,
    required DateTime? lockedUntil,
  });
}
