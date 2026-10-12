import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/printing/data/drift_printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/domain/printer_failures.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printing_service.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_printers.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late FakePrinterService printer;
  late DriftPrinterSettingsRepository settings;
  late PrintingService printing;

  const receipt = Receipt([ReceiptText('Payslip')]);

  String? ruleOf(Result<Object?> result) {
    final failure = result.failureOrNull;
    return failure is BusinessRuleFailure ? failure.rule : null;
  }

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    printer = FakePrinterService();
    settings = DriftPrinterSettingsRepository(env.db, clock: env.clock.call);
    printing = PrintingService(
      printer: printer,
      settings: settings,
      audit: env.audit,
      transactions: env.transactions,
    );
  });

  group('selecting a printer', () {
    test('connects, then keeps the printer and audits the change', () async {
      final chosen = (await printing.selectPrinter(
        admin,
        kitchenPrinter,
      )).unwrap();

      expect(chosen.device, kitchenPrinter);
      expect(printer.connected, [kitchenPrinter]);
      expect((await settings.load()).unwrap().device, kitchenPrinter);
      expect(await env.auditActions(), contains('printer.settings_changed'));
    });

    test('keeps nothing when the printer cannot be reached', () async {
      printer.canConnect = false;

      final result = await printing.selectPrinter(admin, kitchenPrinter);

      expect(ruleOf(result), PrinterFailures.connectFailedRule);
      expect((await settings.load()).unwrap().device, isNull);
      expect(
        await env.auditActions(),
        isNot(contains('printer.settings_changed')),
      );
    });

    test('keeps the paper width chosen earlier', () async {
      (await printing.setPaperWidth(admin, PaperWidth.mm80)).unwrap();

      final chosen = (await printing.selectPrinter(
        admin,
        kitchenPrinter,
      )).unwrap();

      expect(chosen.paperWidth, PaperWidth.mm80);
    });
  });

  group('paper width', () {
    test('is saved and audited, without the values', () async {
      (await printing.setPaperWidth(admin, PaperWidth.mm80)).unwrap();

      expect((await settings.load()).unwrap().paperWidth, PaperWidth.mm80);
      final row = (await env.auditRows()).singleWhere(
        (r) => r.action == 'printer.settings_changed',
      );
      expect(row.entityType, 'printer_settings');
      expect(row.metadata, contains('paperWidth'));
      expect(row.metadata, isNot(contains('mm80')));
    });

    test('choosing the current width changes and audits nothing', () async {
      final before = (await env.auditRows()).length;

      (await printing.setPaperWidth(admin, PaperWidth.mm58)).unwrap();

      expect((await env.auditRows()).length, before);
    });
  });

  test('forgetting the printer disconnects and clears the choice', () async {
    (await printing.selectPrinter(admin, kitchenPrinter)).unwrap();

    (await printing.forgetPrinter(admin)).unwrap();

    expect((await settings.load()).unwrap().device, isNull);
    expect(printer.disconnects, 1);
  });

  group('print', () {
    test('needs a chosen printer', () async {
      final result = await printing.print(admin, receipt);

      expect(ruleOf(result), PrinterFailures.notConfiguredRule);
      expect(printer.printAttempts, 0);
    });

    test('connects to the chosen printer when not connected', () async {
      (await settings.save(
        const PrinterSettings(device: kitchenPrinter),
      )).unwrap();

      (await printing.print(admin, receipt)).unwrap();

      expect(printer.connected, [kitchenPrinter]);
      expect(printer.printed, [receipt]);
    });

    test('does not reconnect while already connected', () async {
      (await settings.save(
        const PrinterSettings(device: kitchenPrinter),
      )).unwrap();
      printer.currentStatus = PrinterStatus.connected;

      (await printing.print(admin, receipt)).unwrap();

      expect(printer.connected, isEmpty);
      expect(printer.printed, [receipt]);
    });

    test('reconnects once when the link has dropped', () async {
      (await settings.save(
        const PrinterSettings(device: kitchenPrinter),
      )).unwrap();
      printer
        ..currentStatus = PrinterStatus.connected
        ..printOutcomes = [false, true];

      (await printing.print(admin, receipt)).unwrap();

      expect(printer.printAttempts, 2);
      expect(printer.connected, [kitchenPrinter]);
      expect(printer.printed, [receipt]);
    });

    test('gives up after the second failure', () async {
      (await settings.save(
        const PrinterSettings(device: kitchenPrinter),
      )).unwrap();
      printer.printOutcomes = [false, false];

      final result = await printing.print(admin, receipt);

      expect(ruleOf(result), PrinterFailures.printFailedRule);
      expect(printer.printAttempts, 2);
    });

    test('reports a printer that cannot be reached', () async {
      (await settings.save(
        const PrinterSettings(device: kitchenPrinter),
      )).unwrap();
      printer.canConnect = false;

      expect(
        ruleOf(await printing.print(admin, receipt)),
        PrinterFailures.connectFailedRule,
      );
    });
  });

  group('test page', () {
    test('is laid out for the paper in use', () async {
      (await printing.setPaperWidth(admin, PaperWidth.mm80)).unwrap();
      (await printing.selectPrinter(admin, kitchenPrinter)).unwrap();

      (await printing.printTest(admin)).unwrap();

      final ruler = printer.printed.single.lines
          .whereType<ReceiptText>()
          .map((t) => t.text)
          .firstWhere((t) => t.startsWith('.'));
      expect(ruler.length, PaperWidth.mm80.characters);
    });
  });

  test('every operation checks the session', () async {
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

    expect(
      (await printing.settings(stranger)).failureOrNull,
      isA<PermissionFailure>(),
    );
    expect(
      (await printing.discover(stranger)).failureOrNull,
      isA<PermissionFailure>(),
    );
    expect(
      (await printing.selectPrinter(stranger, kitchenPrinter)).failureOrNull,
      isA<PermissionFailure>(),
    );
    expect(
      (await printing.print(stranger, receipt)).failureOrNull,
      isA<PermissionFailure>(),
    );
    expect(printer.connected, isEmpty);
  });
}
