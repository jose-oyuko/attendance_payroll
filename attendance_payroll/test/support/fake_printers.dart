import 'dart:typed_data';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/printing/data/bluetooth_gateway.dart';
import 'package:attendance_payroll/features/printing/domain/printer_failures.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printer_service.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';

const PrinterDevice kitchenPrinter = PrinterDevice(
  id: '66:02:BD:06:18:7B',
  name: 'RPP02N',
  connection: PrinterConnection.bluetooth,
);

/// The platform's Bluetooth, scripted: a test host has none.
class FakeBluetoothGateway implements BluetoothGateway {
  bool permission = true;
  bool enabled = true;
  bool connected = false;

  /// Whether [connect] succeeds.
  bool canConnect = true;

  /// Whether [write] succeeds.
  bool canWrite = true;
  List<BluetoothPeer> paired = const [
    BluetoothPeer(address: '66:02:BD:06:18:7B', name: 'RPP02N'),
  ];

  final List<String> connectCalls = [];
  final List<Uint8List> written = [];
  int disconnectCalls = 0;

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<List<BluetoothPeer>> pairedDevices() async => paired;

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<bool> connect(String address) async {
    connectCalls.add(address);
    connected = canConnect;
    return canConnect;
  }

  @override
  Future<bool> disconnect() async {
    disconnectCalls++;
    connected = false;
    return true;
  }

  @override
  Future<bool> write(Uint8List bytes) async {
    if (!canWrite) {
      return false;
    }
    written.add(bytes);
    return true;
  }
}

/// A [PrinterService] that records what it is asked and answers from a
/// script, to test the code that uses a printer without any transport.
class FakePrinterService implements PrinterService {
  PrinterStatus currentStatus = PrinterStatus.disconnected;
  bool canConnect = true;

  /// Results of successive [print] calls; `true` once the list runs out.
  List<bool> printOutcomes = [];

  final List<PrinterDevice> connected = [];
  final List<Receipt> printed = [];
  int printAttempts = 0;
  int disconnects = 0;

  @override
  Future<Result<PrinterStatus>> status() async => Ok(currentStatus);

  @override
  Future<Result<List<PrinterDevice>>> discover() async =>
      const Ok([kitchenPrinter]);

  @override
  Future<Result<void>> connect(PrinterDevice device) async {
    if (!canConnect) {
      return Err(PrinterFailures.connectFailed(device.name));
    }
    connected.add(device);
    currentStatus = PrinterStatus.connected;
    return const Ok(null);
  }

  @override
  Future<Result<void>> disconnect() async {
    disconnects++;
    currentStatus = PrinterStatus.disconnected;
    return const Ok(null);
  }

  @override
  Future<Result<void>> print(Receipt receipt, PaperWidth paperWidth) async {
    printAttempts++;
    final succeeds = printOutcomes.isEmpty ? true : printOutcomes.removeAt(0);
    if (!succeeds) {
      return const Err(PrinterFailures.printFailed);
    }
    printed.add(receipt);
    return const Ok(null);
  }
}
