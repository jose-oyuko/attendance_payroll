import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_auth_service.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  Future<AppFailure?> signInFailure(String password) async {
    return (await env.auth.signIn(ownerUsername, password)).failureOrNull;
  }

  group('setUp', () {
    test('creates the company and owner and signs the owner in', () async {
      expect((await env.auth.isSetUp()).valueOrNull, isFalse);

      final session = await env.setUpOwner();

      expect((await env.auth.isSetUp()).valueOrNull, isTrue);
      expect(session.admin.username, ownerUsername);
      expect(session.admin.role, AdminRole.owner);
      expect(session.can(Permission.manageEmployeePins), isTrue);
      expect(await env.auditActions(), ['company.created', 'admin.created']);
    });

    test('stores only a hash of the password', () async {
      await env.setUpOwner();

      final rows = await env.db.select(env.db.credentials).get();

      expect(rows.single.kind, 'adminPassword');
      expect(rows.single.secretHash, isNot(contains(ownerPassword)));
      expect(rows.single.secretHash, startsWith('pbkdf2-sha256\$'));
    });

    test('can only run once', () async {
      await env.setUpOwner();

      final again = await env.auth.setUp(
        company: acmeDetails,
        owner: const NewAdminUser(username: 'second', displayName: 'Second'),
        password: ownerPassword,
      );

      expect(
        (again.failureOrNull! as BusinessRuleFailure).rule,
        AdminAuthService.alreadySetUpRule,
      );
      expect(await env.db.select(env.db.companies).get(), hasLength(1));
    });

    test('rejects a weak password before creating anything', () async {
      final result = await env.auth.setUp(
        company: acmeDetails,
        owner: const NewAdminUser(username: 'owner', displayName: 'Owner'),
        password: 'short',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((await env.auth.isSetUp()).valueOrNull, isFalse);
    });

    test('rejects invalid company details', () async {
      final result = await env.auth.setUp(
        company: const CompanyDetails(
          name: '',
          currencyCode: 'KES',
          timezone: 'UTC',
        ),
        owner: const NewAdminUser(username: 'owner', displayName: 'Owner'),
        password: ownerPassword,
      );

      expect((result.failureOrNull! as ValidationFailure).field, 'name');
    });
  });

  group('signIn', () {
    setUp(() => env.setUpOwner());

    test('accepts the right password, case-insensitive username', () async {
      final result = await env.auth.signIn(' OWNER ', ownerPassword);

      final session = result.valueOrNull!;
      expect(session.admin.username, ownerUsername);
      expect(session.admin.lastLoginAt, isNotNull);
      expect(await env.auditActions(), contains('admin.signed_in'));
    });

    test('wrong password and unknown user fail identically', () async {
      final wrongPassword = await signInFailure('wrong password');
      final unknownUser = (await env.auth.signIn(
        'nobody',
        ownerPassword,
      )).failureOrNull;

      expect(wrongPassword, isA<AuthenticationFailure>());
      expect(unknownUser, isA<AuthenticationFailure>());
      expect(wrongPassword!.userMessage, unknownUser!.userMessage);
    });

    test('locks after five wrong passwords, even for the right one', () async {
      for (var i = 0; i < 4; i++) {
        expect(
          (await signInFailure('wrong password'))?.userMessage,
          'Incorrect username or password.',
        );
      }
      final fifth = await signInFailure('wrong password');
      final whileLocked = await signInFailure(ownerPassword);

      expect(fifth!.userMessage, contains('Try again in 1 minute'));
      expect(whileLocked!.userMessage, contains('Try again'));
      expect(await env.auditActions(), contains('admin.locked_out'));
    });

    test('the lock expires and a success resets the count', () async {
      for (var i = 0; i < 5; i++) {
        await signInFailure('wrong password');
      }

      env.clock.advance(AdminAuthService.lockoutPolicy.baseLockDuration);
      final afterLock = await env.auth.signIn(ownerUsername, ownerPassword);

      expect(afterLock.isOk, isTrue);
      final credential = await env.db.select(env.db.credentials).getSingle();
      expect(credential.failedAttempts, 0);
      expect(credential.lockedUntil, isNull);
    });

    test('fails clearly before setup', () async {
      final fresh = TestEnv();

      final result = await fresh.auth.signIn(ownerUsername, ownerPassword);

      expect(
        (result.failureOrNull! as BusinessRuleFailure).rule,
        AdminAuthService.notSetUpRule,
      );
    });
  });
  group('changePassword', () {
    const newPassword = 'a different long password';

    test(
      'replaces the password: the new one works, the old one does not',
      () async {
        final session = await env.setUpOwner();

        final result = await env.auth.changePassword(
          session,
          currentPassword: ownerPassword,
          newPassword: newPassword,
        );

        expect(result.isOk, isTrue);
        expect(
          (await env.auth.signIn(ownerUsername, newPassword)).isOk,
          isTrue,
        );
        expect(
          await signInFailure(ownerPassword),
          isA<AuthenticationFailure>(),
        );
      },
    );

    test('needs the current password', () async {
      final session = await env.setUpOwner();

      final result = await env.auth.changePassword(
        session,
        currentPassword: 'not my password',
        newPassword: newPassword,
      );

      expect(result.failureOrNull, isA<AuthenticationFailure>());
      expect(result.failureOrNull!.userMessage, contains('current password'));
      expect(
        (await env.auth.signIn(ownerUsername, ownerPassword)).isOk,
        isTrue,
      );
    });

    test('wrong attempts lock it like sign-in', () async {
      final session = await env.setUpOwner();

      for (var i = 0; i < AdminAuthService.lockoutPolicy.maxAttempts; i++) {
        await env.auth.changePassword(
          session,
          currentPassword: 'not my password',
          newPassword: newPassword,
        );
      }
      final locked = await env.auth.changePassword(
        session,
        currentPassword: ownerPassword,
        newPassword: newPassword,
      );

      expect(locked.failureOrNull, isA<AuthenticationFailure>());
      expect(locked.failureOrNull!.userMessage, contains('Try again'));
      expect(await env.auditActions(), contains('admin.locked_out'));
    });

    test('the new password follows the policy and must be new', () async {
      final session = await env.setUpOwner();

      final tooShort = await env.auth.changePassword(
        session,
        currentPassword: ownerPassword,
        newPassword: 'short',
      );
      final same = await env.auth.changePassword(
        session,
        currentPassword: ownerPassword,
        newPassword: ownerPassword,
      );

      expect(tooShort.failureOrNull, isA<ValidationFailure>());
      expect(same.failureOrNull, isA<ValidationFailure>());
      expect(
        (await env.auth.signIn(ownerUsername, ownerPassword)).isOk,
        isTrue,
      );
    });

    test('is audited without either password', () async {
      final session = await env.setUpOwner();

      await env.auth.changePassword(
        session,
        currentPassword: ownerPassword,
        newPassword: newPassword,
      );

      final row = (await env.auditRows()).singleWhere(
        (r) => r.action == 'admin.password_changed',
      );
      expect(row.actorId, session.admin.id);
      final stored = row.metadata ?? '';
      expect(stored, isNot(contains(ownerPassword)));
      expect(stored, isNot(contains(newPassword)));
      final credential = await env.db.select(env.db.credentials).getSingle();
      expect(credential.secretHash, isNot(contains(newPassword)));
    });

    test('an administrator who is no longer active cannot', () async {
      final session = await env.setUpOwner();
      final inactive = AdminSession(
        admin: AdminUser(
          id: session.admin.id,
          companyId: session.companyId,
          username: session.admin.username,
          displayName: session.admin.displayName,
          role: session.admin.role,
          active: false,
          lastLoginAt: null,
          createdAt: session.admin.createdAt,
          updatedAt: session.admin.updatedAt,
          version: session.admin.version,
        ),
        signedInAt: session.signedInAt,
      );

      final result = await env.auth.changePassword(
        inactive,
        currentPassword: ownerPassword,
        newPassword: newPassword,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
