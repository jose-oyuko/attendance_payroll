import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/printing/data/bluetooth_gateway.dart';
import 'package:attendance_payroll/features/printing/data/esc_pos_encoder.dart';
import 'package:attendance_payroll/features/printing/domain/printer_failures.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printer_service.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';

/// [PrinterService] for Bluetooth thermal printers speaking ESC/POS.
///
/// Printers are paired in the phone's Bluetooth settings; this lists the
/// paired devices and opens the connection to the chosen one. USB and
/// network printers would be further implementations of [PrinterService]
/// that reuse [EscPosEncoder].
final class BluetoothPrinterService implements PrinterService {
  BluetoothPrinterService(this._bluetooth);

  final BluetoothGateway _bluetooth;

  @override
  Future<Result<PrinterStatus>> status() {
    return Result.guard(() async {
      if (!await _bluetooth.ensurePermission()) {
        return PrinterStatus.permissionNeeded;
      }
      if (!await _bluetooth.isEnabled()) {
        return PrinterStatus.unavailable;
      }
      return await _bluetooth.isConnected()
          ? PrinterStatus.connected
          : PrinterStatus.disconnected;
    });
  }

  @override
  Future<Result<List<PrinterDevice>>> discover() {
    return Result.guard(() async {
      _requireUsable(await status().then((r) => r.unwrap()));
      final peers = await _bluetooth.pairedDevices();
      return [
        for (final peer in peers)
          PrinterDevice(
            id: peer.address,
            name: peer.name.trim().isEmpty ? peer.address : peer.name,
            connection: PrinterConnection.bluetooth,
          ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  @override
  Future<Result<void>> connect(PrinterDevice device) {
    return Result.guard(() async {
      if (device.connection != PrinterConnection.bluetooth) {
        throw PrinterFailures.unsupported;
      }
      _requireUsable(await status().then((r) => r.unwrap()));
      // Only one printer at a time; a half-open link to another printer (or
      // a stale one to this printer) would make the new connection fail.
      await _bluetooth.disconnect();
      if (!await _bluetooth.connect(device.id)) {
        throw PrinterFailures.connectFailed(device.name);
      }
    });
  }

  @override
  Future<Result<void>> disconnect() {
    return Result.guard(() async {
      await _bluetooth.disconnect();
    });
  }

  @override
  Future<Result<void>> print(Receipt receipt, PaperWidth paperWidth) {
    return Result.guard(() async {
      if (!await _bluetooth.isConnected()) {
        throw PrinterFailures.printFailed;
      }
      final bytes = EscPosEncoder(paperWidth).encode(receipt);
      if (!await _bluetooth.write(bytes)) {
        throw PrinterFailures.printFailed;
      }
    });
  }

  static void _requireUsable(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.permissionNeeded:
        throw PrinterFailures.permissionNeeded;
      case PrinterStatus.unavailable:
        throw PrinterFailures.bluetoothOff;
      case PrinterStatus.disconnected:
      case PrinterStatus.connected:
        return;
    }
  }
}
