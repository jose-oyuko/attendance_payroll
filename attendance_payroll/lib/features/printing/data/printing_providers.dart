import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/printing/data/bluetooth_gateway.dart';
import 'package:attendance_payroll/features/printing/data/bluetooth_printer_service.dart';
import 'package:attendance_payroll/features/printing/data/drift_printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/domain/printer_service.dart';
import 'package:attendance_payroll/features/printing/domain/printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/domain/printing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform's Bluetooth. Replaced in tests, which have none.
final bluetoothGatewayProvider = Provider<BluetoothGateway>(
  (ref) => const PluginBluetoothGateway(),
);

/// The printer connection in use. Bluetooth today; choosing USB or network
/// printers later changes only this provider.
final printerServiceProvider = Provider<PrinterService>(
  (ref) => BluetoothPrinterService(ref.watch(bluetoothGatewayProvider)),
);

final printerSettingsRepositoryProvider = Provider<PrinterSettingsRepository>(
  (ref) => DriftPrinterSettingsRepository(ref.watch(appDatabaseProvider)),
);

final printingServiceProvider = Provider<PrintingService>(
  (ref) => PrintingService(
    printer: ref.watch(printerServiceProvider),
    settings: ref.watch(printerSettingsRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  ),
);
