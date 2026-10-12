import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/printing/domain/printer_failures.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printer_service.dart';
import 'package:attendance_payroll/features/printing/domain/printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';

/// The printer this device uses, and printing on it: choosing and
/// connecting a printer, then sending receipts to it. Knows nothing about
/// what a receipt says or how the printer is reached.
final class PrintingService {
  PrintingService({
    required this._printer,
    required this._settings,
    required this._audit,
    required this._transactions,
  });

  static const String settingsEntityType = 'printer_settings';

  /// The only settings row of a device.
  static const String settingsEntityId = 'this_device';

  final PrinterService _printer;
  final PrinterSettingsRepository _settings;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;

  /// The printer and paper chosen on this device.
  Future<Result<PrinterSettings>> settings(AdminSession session) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    return _settings.load();
  }

  Future<Result<PrinterStatus>> status(AdminSession session) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    return _printer.status();
  }

  /// Printers this device can see (for Bluetooth, the paired ones).
  Future<Result<List<PrinterDevice>>> discover(AdminSession session) async {
    if (session.check(Permission.managePrinter) case final denied?) {
      return Err(denied);
    }
    return _printer.discover();
  }

  /// Connects to [device] and, only if that works, makes it this device's
  /// printer. A printer that cannot be reached is never saved.
  Future<Result<PrinterSettings>> selectPrinter(
    AdminSession session,
    PrinterDevice device,
  ) async {
    if (session.check(Permission.managePrinter) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      (await _printer.connect(device)).unwrap();
      final current = (await _settings.load()).unwrap();
      final next = current.copyWith(device: device);
      await _save(session, next, changed: const ['printer']);
      return next;
    });
  }

  Future<Result<PrinterSettings>> setPaperWidth(
    AdminSession session,
    PaperWidth width,
  ) async {
    if (session.check(Permission.managePrinter) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final current = (await _settings.load()).unwrap();
      if (current.paperWidth == width) {
        return current;
      }
      final next = current.copyWith(paperWidth: width);
      await _save(session, next, changed: const ['paperWidth']);
      return next;
    });
  }

  /// Forgets the chosen printer and drops the connection.
  Future<Result<PrinterSettings>> forgetPrinter(AdminSession session) async {
    if (session.check(Permission.managePrinter) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final current = (await _settings.load()).unwrap();
      final next = current.copyWith(clearDevice: true);
      (await _printer.disconnect()).unwrap();
      await _save(session, next, changed: const ['printer']);
      return next;
    });
  }

  /// Prints [receipt] on the chosen printer, connecting first when needed.
  /// A dropped connection is reopened once before giving up.
  Future<Result<void>> print(AdminSession session, Receipt receipt) async {
    if (session.check(Permission.viewPayroll) case final denied?) {
      return Err(denied);
    }
    return Result.guard(() async {
      final settings = (await _settings.load()).unwrap();
      final device = settings.device ?? (throw PrinterFailures.notConfigured);
      if ((await _printer.status()).unwrap() != PrinterStatus.connected) {
        (await _printer.connect(device)).unwrap();
      }
      final first = await _printer.print(receipt, settings.paperWidth);
      if (first.isOk) {
        return;
      }
      // The link may have dropped since the last receipt (printer switched
      // off, out of range): reconnect and try once more.
      (await _printer.connect(device)).unwrap();
      (await _printer.print(receipt, settings.paperWidth)).unwrap();
    });
  }

  /// A short receipt that shows the printer works and the paper width fits.
  Future<Result<void>> printTest(AdminSession session) async {
    if (session.check(Permission.managePrinter) case final denied?) {
      return Err(denied);
    }
    final width =
        (await _settings.load()).valueOrNull?.paperWidth ?? PaperWidth.mm58;
    return print(session, testReceipt(width));
  }

  /// The test receipt: a ruler as wide as the paper, so a wrong paper width
  /// shows up as wrapped or short lines.
  static Receipt testReceipt(PaperWidth width) {
    final ruler = List.generate(
      width.characters,
      (i) => (i + 1) % 10 == 0 ? '${((i + 1) ~/ 10) % 10}' : '.',
    ).join();
    return Receipt([
      const ReceiptText('Printer test', align: ReceiptAlign.center, bold: true),
      const ReceiptRule(),
      ReceiptText(ruler),
      ReceiptColumns('Paper', '${width.characters} characters'),
      const ReceiptColumns('Bold', 'Regular', bold: true),
      const ReceiptText('Large', large: true),
      const ReceiptRule(double: true),
      const ReceiptText(
        'If this prints clearly, the printer is ready.',
        align: ReceiptAlign.center,
      ),
      const ReceiptCut(),
    ]);
  }

  Future<void> _save(
    AdminSession session,
    PrinterSettings settings, {
    required List<String> changed,
  }) async {
    final result = await _transactions.run(() async {
      (await _settings.save(settings)).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.printerSettingsChanged,
          entityType: settingsEntityType,
          entityId: settingsEntityId,
          metadata: {'fields': changed},
        ),
      )).unwrap();
    });
    result.unwrap();
  }
}
