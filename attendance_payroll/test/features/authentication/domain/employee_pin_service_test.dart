import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/authentication/domain/pin_policy.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession session;
  late Employee employee;

  setUp(() async {
    env = TestEnv();
    session = await env.setUpOwner();
    employee = await env.addEmployee(session);
  });

  Future<String> issue() async {
    return (await env.pins.issueTemporaryPin(session, employee.id)).unwrap();
  }

  Future<PinState> state() async {
    return (await env.pins.status(session, employee.id)).unwrap().state;
  }

  test('a new employee has no PIN and cannot sign in', () async {
    expect(await state(), PinState.notSet);
    expect(
      (await env.pins.verifyPin(employee.id, '2468')).failureOrNull,
      isA<AuthenticationFailure>(),
    );
  });

  test(
    'an issued PIN is valid, temporary, and stored only as a hash',
    () async {
      final pin = await issue();

      expect(PinPolicy.validate(pin), isNull);
      expect(await state(), PinState.temporary);
      final row = await (env.db.select(
        env.db.credentials,
      )..where((c) => c.employeeId.equals(employee.id))).getSingle();
      expect(row.kind, 'employeePin');
      expect(row.secretHash, isNot(contains(pin)));

      final verified = (await env.pins.verifyPin(employee.id, pin)).unwrap();
      expect(verified.mustChangePin, isTrue);
      expect(verified.employee.id, employee.id);
    },
  );

  test('the employee replaces a temporary PIN with their own', () async {
    final temporary = await issue();

    final changed = await env.pins.changePin(
      employee.id,
      currentPin: temporary,
      newPin: '2580',
    );

    expect(changed.isOk, isTrue);
    expect(await state(), PinState.active);
    expect((await env.pins.verifyPin(employee.id, temporary)).isErr, isTrue);
    final verified = (await env.pins.verifyPin(employee.id, '2580')).unwrap();
    expect(verified.mustChangePin, isFalse);
  });

  test('changing requires the current PIN and a good new one', () async {
    final temporary = await issue();

    final wrongCurrent = await env.pins.changePin(
      employee.id,
      currentPin: '9999',
      newPin: '2580',
    );
    final trivial = await env.pins.changePin(
      employee.id,
      currentPin: temporary,
      newPin: '1234',
    );
    final same = await env.pins.changePin(
      employee.id,
      currentPin: temporary,
      newPin: temporary,
    );

    expect(wrongCurrent.failureOrNull, isA<AuthenticationFailure>());
    expect(trivial.failureOrNull, isA<ValidationFailure>());
    expect(same.failureOrNull, isA<ValidationFailure>());
    expect(await state(), PinState.temporary);
  });

  test('five wrong PINs lock it; an administrator reset unlocks it', () async {
    final pin = await issue();
    for (var i = 0; i < 5; i++) {
      await env.pins.verifyPin(employee.id, '9753');
    }

    expect(await state(), PinState.locked);
    expect(
      (await env.pins.verifyPin(employee.id, pin)).failureOrNull!.userMessage,
      contains('Try again'),
    );
    expect(await env.auditActions(), contains('employee.pin_locked_out'));

    final newPin = await issue();
    expect(await state(), PinState.temporary);
    expect((await env.pins.verifyPin(employee.id, newPin)).isOk, isTrue);
  });

  test('only active employees can sign in', () async {
    final pin = await issue();
    await env.management.changeStatus(
      session,
      employee,
      EmploymentStatus.suspended,
    );

    final result = await env.pins.verifyPin(employee.id, pin);

    expect(result.failureOrNull, isA<AuthenticationFailure>());
  });

  test('resetting needs permission', () async {
    final inactiveAdmin = AdminSession(
      admin: AdminUser(
        id: session.admin.id,
        companyId: session.companyId,
        username: 'owner',
        displayName: 'Owner',
        role: AdminRole.owner,
        active: false,
        lastLoginAt: null,
        createdAt: session.admin.createdAt,
        updatedAt: session.admin.updatedAt,
        version: 1,
      ),
      signedInAt: session.signedInAt,
    );

    final result = await env.pins.issueTemporaryPin(inactiveAdmin, employee.id);

    expect(result.failureOrNull, isA<PermissionFailure>());
    expect(await state(), PinState.notSet);
  });

  test('audit records PIN events without the PIN', () async {
    final temporary = await issue();
    await env.pins.changePin(
      employee.id,
      currentPin: temporary,
      newPin: '2580',
    );

    final rows = await env.auditRows();
    final pinRows = rows.where((r) => r.action.startsWith('employee.pin'));

    expect(pinRows.map((r) => r.action), [
      'employee.pin_reset',
      'employee.pin_changed',
    ]);
    expect(pinRows.map((r) => r.actorType), ['admin', 'employee']);
    for (final row in rows) {
      expect(row.metadata ?? '', isNot(contains(temporary)));
      expect(row.metadata ?? '', isNot(contains('2580')));
    }
  });
}
