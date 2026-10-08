import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/security/lockout_policy.dart';
import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/credential.dart';
import 'package:attendance_payroll/features/authentication/domain/credential_verifier.dart';
import 'package:attendance_payroll/features/authentication/domain/password_policy.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';

/// First-run setup and administrator sign-in. Separate from employee PIN
/// authentication, which has its own service and policy.
final class AdminAuthService {
  AdminAuthService({
    required this._companies,
    required this._admins,
    required this._credentials,
    required this._audit,
    required this._transactions,
    required SecretHasher passwordHasher,
    this._clock = systemClockUtc,
  }) : _hasher = passwordHasher,
       _verifier = CredentialVerifier(
         credentials: _credentials,
         hasher: passwordHasher,
         policy: lockoutPolicy,
         clock: _clock,
       );

  /// Five wrong passwords lock sign-in for 1 minute, doubling per further
  /// lock up to an hour.
  static const LockoutPolicy lockoutPolicy = LockoutPolicy(
    maxAttempts: 5,
    baseLockDuration: Duration(minutes: 1),
    maxLockDuration: Duration(hours: 1),
  );

  static const String alreadySetUpRule = 'already_set_up';
  static const String notSetUpRule = 'not_set_up';
  static const String _wrongCredentials = 'Incorrect username or password.';

  final CompanyRepository _companies;
  final AdminUserRepository _admins;
  final CredentialRepository _credentials;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;
  final SecretHasher _hasher;
  final Clock _clock;
  final CredentialVerifier _verifier;

  /// Whether first-run setup has been completed on this installation.
  Future<Result<bool>> isSetUp() async {
    return (await _companies.list()).map((companies) => companies.isNotEmpty);
  }

  /// Creates the company and its owner account, then signs the owner in.
  /// Only allowed once per installation.
  Future<Result<AdminSession>> setUp({
    required CompanyDetails company,
    required NewAdminUser owner,
    required String password,
  }) async {
    final invalid =
        company.normalized().validate() ??
        owner.normalized().validate() ??
        PasswordPolicy.validate(password);
    if (invalid != null) {
      return Err(invalid);
    }
    // Hash before the transaction: it is slow and needs no database lock.
    final passwordHash = await _hasher.hash(password);

    return _transactions.run(() async {
      if ((await _companies.list()).unwrap().isNotEmpty) {
        throw const BusinessRuleFailure(
          rule: alreadySetUpRule,
          userMessage: 'This device is already set up. Sign in instead.',
        );
      }
      final created = (await _companies.create(company)).unwrap();
      final admin = (await _admins.create(created.id, owner)).unwrap();
      (await _credentials.replaceSecret(
        CredentialOwner.admin(admin.id),
        passwordHash,
        isTemporary: false,
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: created.id,
          actorType: AuditActorType.admin,
          actorId: admin.id,
          action: AuditAction.companyCreated,
          entityType: 'company',
          entityId: created.id,
        ),
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: created.id,
          actorType: AuditActorType.admin,
          actorId: admin.id,
          action: AuditAction.adminCreated,
          entityType: 'admin_user',
          entityId: admin.id,
          metadata: {'role': admin.role.name},
        ),
      )).unwrap();
      return AdminSession(admin: admin, signedInAt: _clock());
    });
  }

  /// Signs an administrator in. Every failure gives the same message so the
  /// response does not reveal whether a username exists.
  Future<Result<AdminSession>> signIn(String username, String password) async {
    final companies = await _companies.list();
    if (companies case Err(:final failure)) {
      return Err(failure);
    }
    final company = companies.valueOrNull!.firstOrNull;
    if (company == null) {
      return const Err(
        BusinessRuleFailure(
          rule: notSetUpRule,
          userMessage: 'This device has not been set up yet.',
        ),
      );
    }

    // V1 has one company per installation.
    final found = await _admins.findByUsername(company.id, username);
    if (found case Err(:final failure)) {
      return Err(failure);
    }
    final admin = found.valueOrNull;
    if (admin == null || !admin.active) {
      await _hasher.verifyAgainstDummy(password);
      return const Err(AuthenticationFailure(userMessage: _wrongCredentials));
    }

    final verified = await _verifier.verify(
      CredentialOwner.admin(admin.id),
      password,
      wrongSecretMessage: _wrongCredentials,
      onLockedOut: () => _audit.record(
        AuditEntry(
          companyId: admin.companyId,
          actorType: AuditActorType.system,
          actorId: null,
          action: AuditAction.adminLockedOut,
          entityType: 'admin_user',
          entityId: admin.id,
        ),
      ),
    );
    if (verified case Err(:final failure)) {
      return Err(failure);
    }

    final now = _clock();
    return _transactions.run(() async {
      final signedIn = (await _admins.recordSignIn(admin.id, now)).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: admin.companyId,
          actorType: AuditActorType.admin,
          actorId: admin.id,
          action: AuditAction.adminSignedIn,
          entityType: 'admin_user',
          entityId: admin.id,
        ),
      )).unwrap();
      return AdminSession(admin: signedIn, signedInAt: now);
    });
  }
}
