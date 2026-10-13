import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/kiosk/data/drift_app_lock_settings_repository.dart';
import 'package:attendance_payroll/features/kiosk/domain/app_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late AppLockService service;

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    service = AppLockService(
      settings: DriftAppLockSettingsRepository(env.db, clock: env.clock.call),
      audit: env.audit,
      transactions: env.transactions,
    );
  });

  test('locks after fifteen minutes until someone chooses otherwise', () async {
    expect((await service.current()).unwrap(), 15);
    expect(AppLockService.defaultMinutes, 15);
  });

  test('an administrator can choose any time, or never', () async {
    for (final minutes in [1, 5, 30, 120, 480, AppLockService.neverMinutes]) {
      (await service.setMinutes(admin, minutes)).unwrap();

      expect((await service.current()).unwrap(), minutes);
    }
  });

  test('the time is kept after the app restarts', () async {
    (await service.setMinutes(admin, 5)).unwrap();

    final again = AppLockService(
      settings: DriftAppLockSettingsRepository(env.db),
      audit: env.audit,
      transactions: env.transactions,
    );

    expect((await again.current()).unwrap(), 5);
  });

  test('times that make no sense are refused', () async {
    for (final minutes in [-1, -30, 481, 100000]) {
      final result = await service.setMinutes(admin, minutes);

      expect(
        result.failureOrNull,
        isA<ValidationFailure>(),
        reason: '$minutes',
      );
    }
    expect((await service.current()).unwrap(), 15);
  });

  test('the choices on screen are all allowed', () async {
    for (final minutes in AppLockService.choices) {
      expect((await service.setMinutes(admin, minutes)).isOk, isTrue);
    }
  });

  test('changing it is audited, without leaking more than needed', () async {
    (await service.setMinutes(admin, 5)).unwrap();
    (await service.setMinutes(admin, AppLockService.neverMinutes)).unwrap();

    final rows = (await env.auditRows()).where(
      (r) => r.action == 'app.lock_changed',
    );
    expect(rows, hasLength(2));
    expect(rows.last.metadata, contains('"never":true'));
    expect(rows.first.actorId, admin.admin.id);
  });

  test('choosing the time it already is changes and audits nothing', () async {
    (await service.setMinutes(admin, 15)).unwrap();

    expect(await env.auditActions(), isNot(contains('app.lock_changed')));
  });

  test('only someone allowed to manage the kiosk can change it', () async {
    final stranger = AdminSession(
      admin: AdminUser(
        id: 'x',
        companyId: admin.companyId,
        username: 'gone',
        displayName: 'Gone',
        role: AdminRole.owner,
        active: false,
        lastLoginAt: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        version: 1,
      ),
      signedInAt: DateTime.utc(2026),
    );

    final result = await service.setMinutes(stranger, 1);

    expect(result.failureOrNull, isA<PermissionFailure>());
    expect((await service.current()).unwrap(), 15);
  });

  test(
    'setting the time leaves the kiosk setting alone, and the reverse',
    () async {
      (await env.kioskMode.setKioskCompany(admin.companyId)).unwrap();

      (await service.setMinutes(admin, 5)).unwrap();
      expect((await env.kioskMode.kioskCompanyId()).unwrap(), admin.companyId);

      (await env.kioskMode.setKioskCompany(null)).unwrap();
      expect((await service.current()).unwrap(), 5);
    },
  );
}
