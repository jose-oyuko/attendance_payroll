import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
  });

  String? ruleOf(AppFailure? failure) =>
      failure is BusinessRuleFailure ? failure.rule : null;

  test('a device is not a kiosk until an administrator starts it', () async {
    expect((await env.kiosk.current()).unwrap(), isNull);
    expect(
      ruleOf((await env.kiosk.employees()).failureOrNull),
      KioskService.kioskOffRule,
    );

    (await env.kiosk.start(admin)).unwrap();

    final context = (await env.kiosk.current()).unwrap()!;
    expect(context.companyId, admin.companyId);
    expect(context.companyName, acmeDetails.name);
    expect(context.timeZone.name, 'Africa/Nairobi');
  });

  test('kiosk mode survives a restart of the app', () async {
    await env.kiosk.start(admin);

    // A new repository over the same database, as after a restart.
    final again = (await env.kioskMode.kioskCompanyId()).unwrap();

    expect(again, admin.companyId);
  });

  test('stopping is audited and turns the kiosk off', () async {
    await env.kiosk.start(admin);
    await env.kiosk.stop(admin);

    expect((await env.kiosk.current()).unwrap(), isNull);
    expect(
      await env.auditActions(),
      containsAllInOrder(['kiosk.started', 'kiosk.stopped']),
    );
  });

  test('lists only active employees, by name', () async {
    await env.addEmployee(admin);
    await env.management.create(
      admin,
      johnDetails(employeeNumber: 'E0002').withStatus(EmploymentStatus.active),
    );
    final archived = (await env.management.create(
      admin,
      EmployeeDetails(
        employeeNumber: 'E0003',
        firstName: 'Alice',
        lastName: 'Achieng',
        employmentStartDate: johnDetails().employmentStartDate,
        employmentStatus: EmploymentStatus.archived,
      ),
    )).unwrap();
    await env.management.create(
      admin,
      EmployeeDetails(
        employeeNumber: 'E0004',
        firstName: 'Brian',
        lastName: 'Otieno',
        employmentStartDate: johnDetails().employmentStartDate,
      ),
    );
    await env.kiosk.start(admin);

    final names = (await env.kiosk.employees()).unwrap();

    expect(names.map((e) => e.name), [
      'Brian Otieno',
      'John Kamau',
      'John Kamau',
    ]);
    expect(names.any((e) => e.id == archived.id), isFalse);
  });

  test('PINs can be checked only for the kiosk company', () async {
    final john = await env.addEmployee(admin);
    final other = (await env.companies.create(
      const CompanyDetails(name: 'Other', currencyCode: 'KES', timezone: 'UTC'),
    )).unwrap();
    final foreign = (await env.employees.create(
      other.id,
      johnDetails(),
    )).unwrap();
    await env.signInAtKiosk(admin, john);

    final beforeKiosk = await env.kiosk.verifyPin(john.id, '2580');
    await env.kiosk.start(admin);
    final atKiosk = await env.kiosk.verifyPin(john.id, '2580');
    final elsewhere = await env.kiosk.verifyPin(foreign.id, '2580');

    expect(ruleOf(beforeKiosk.failureOrNull), KioskService.kioskOffRule);
    expect(atKiosk.isOk, isTrue);
    expect(elsewhere.failureOrNull, isA<NotFoundFailure>());
  });

  test('an employee can change their PIN at the kiosk', () async {
    final john = await env.addEmployee(admin);
    final temporary = (await env.pins.issueTemporaryPin(
      admin,
      john.id,
    )).unwrap();
    await env.kiosk.start(admin);

    final changed = await env.kiosk.changePin(
      john.id,
      currentPin: temporary,
      newPin: '4826',
    );

    expect(changed.isOk, isTrue);
    final verified = (await env.kiosk.verifyPin(john.id, '4826')).unwrap();
    expect(verified.mustChangePin, isFalse);
  });
  group('locking the app', () {
    test('an administrator locks it, and it is recorded as theirs', () async {
      final context = (await env.kiosk.lock(by: admin)).unwrap();

      expect(context.companyId, admin.companyId);
      expect((await env.kiosk.current()).unwrap(), isNotNull);
      final row = (await env.auditRows()).singleWhere(
        (r) => r.action == 'kiosk.started',
      );
      expect(row.actorType, 'admin');
      expect(row.actorId, admin.admin.id);
    });

    test(
      'the app can lock itself, and is then recorded as the actor',
      () async {
        (await env.kiosk.lock()).unwrap();

        final row = (await env.auditRows()).singleWhere(
          (r) => r.action == 'kiosk.started',
        );
        expect(row.actorType, 'system');
        expect(row.actorId, isNull);
        expect((await env.kiosk.employees()).isOk, isTrue);
      },
    );

    test('starting the app locks it, once', () async {
      final first = (await env.kiosk.lockIfNeeded()).unwrap();
      final second = (await env.kiosk.lockIfNeeded()).unwrap();

      expect(first.companyId, admin.companyId);
      expect(second.companyId, admin.companyId);
      final starts = (await env.auditActions()).where(
        (a) => a == 'kiosk.started',
      );
      expect(starts, hasLength(1));
    });

    test('unlocking turns it off, and the next start locks it again', () async {
      (await env.kiosk.lockIfNeeded()).unwrap();
      (await env.kiosk.stop(admin)).unwrap();
      expect((await env.kiosk.current()).unwrap(), isNull);

      (await env.kiosk.lockIfNeeded()).unwrap();

      expect((await env.kiosk.current()).unwrap(), isNotNull);
    });

    test('there is nothing to lock before the company is set up', () async {
      final fresh = TestEnv();

      final result = await fresh.kiosk.lockIfNeeded();

      expect(ruleOf(result.failureOrNull), KioskService.notSetUpRule);
    });
  });
}
