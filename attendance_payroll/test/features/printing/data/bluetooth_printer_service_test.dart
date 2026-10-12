import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/printing/data/bluetooth_gateway.dart';
import 'package:attendance_payroll/features/printing/data/bluetooth_printer_service.dart';
import 'package:attendance_payroll/features/printing/domain/printer_failures.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_printers.dart';

void main() {
  late FakeBluetoothGateway bluetooth;
  late BluetoothPrinterService printer;

  const receipt = Receipt([ReceiptText('Hello')]);

  String? ruleOf(Result<Object?> result) {
    final failure = result.failureOrNull;
    return failure is BusinessRuleFailure ? failure.rule : null;
  }

  setUp(() {
    bluetooth = FakeBluetoothGateway();
    printer = BluetoothPrinterService(bluetooth);
  });

  group('status', () {
    test('is connected, disconnected, off or needs permission', () async {
      expect((await printer.status()).unwrap(), PrinterStatus.disconnected);

      bluetooth.connected = true;
      expect((await printer.status()).unwrap(), PrinterStatus.connected);

      bluetooth.enabled = false;
      expect((await printer.status()).unwrap(), PrinterStatus.unavailable);

      // Without permission, Bluetooth's state cannot even be asked.
      bluetooth.permission = false;
      expect((await printer.status()).unwrap(), PrinterStatus.permissionNeeded);
    });
  });

  group('discover', () {
    test(
      'lists paired devices by name, naming unnamed ones by address',
      () async {
        bluetooth.paired = const [
          BluetoothPeer(address: 'AA:AA', name: 'zebra'),
          BluetoothPeer(address: 'BB:BB', name: ' '),
          BluetoothPeer(address: 'CC:CC', name: 'Epson'),
        ];

        final devices = (await printer.discover()).unwrap();

        expect(devices.map((d) => d.name), ['BB:BB', 'Epson', 'zebra']);
        expect(devices.map((d) => d.id), ['BB:BB', 'CC:CC', 'AA:AA']);
        expect(
          devices.every((d) => d.connection == PrinterConnection.bluetooth),
          isTrue,
        );
      },
    );

    test('says what to do when Bluetooth is off or not allowed', () async {
      bluetooth.enabled = false;
      expect(
        ruleOf(await printer.discover()),
        PrinterFailures.bluetoothOffRule,
      );

      bluetooth
        ..enabled = true
        ..permission = false;
      expect(ruleOf(await printer.discover()), PrinterFailures.permissionRule);
    });
  });

  group('connect', () {
    test('opens the connection to the printer', () async {
      expect((await printer.connect(kitchenPrinter)).isOk, isTrue);

      expect(bluetooth.connectCalls, [kitchenPrinter.id]);
      expect(bluetooth.connected, isTrue);
    });

    test('closes a previous connection first', () async {
      bluetooth.connected = true;

      await printer.connect(kitchenPrinter);

      expect(bluetooth.disconnectCalls, 1);
    });

    test('explains a printer that cannot be reached', () async {
      bluetooth.canConnect = false;

      final result = await printer.connect(kitchenPrinter);

      expect(ruleOf(result), PrinterFailures.connectFailedRule);
      expect(result.failureOrNull!.userMessage, contains('RPP02N'));
    });

    test('refuses connections it does not support', () async {
      const usb = PrinterDevice(
        id: 'usb-1',
        name: 'USB printer',
        connection: PrinterConnection.usb,
      );

      expect(
        ruleOf(await printer.connect(usb)),
        PrinterFailures.unsupportedRule,
      );
      expect(bluetooth.connectCalls, isEmpty);
    });
  });

  group('print', () {
    test('sends the encoded receipt', () async {
      bluetooth.connected = true;

      expect((await printer.print(receipt, PaperWidth.mm58)).isOk, isTrue);

      expect(bluetooth.written, hasLength(1));
      // Starts with the ESC/POS reset, and carries the text.
      expect(bluetooth.written.single.take(2), [0x1B, 0x40]);
      expect(String.fromCharCodes(bluetooth.written.single), contains('Hello'));
    });

    test('fails when not connected, without writing', () async {
      expect(
        ruleOf(await printer.print(receipt, PaperWidth.mm58)),
        PrinterFailures.printFailedRule,
      );
      expect(bluetooth.written, isEmpty);
    });

    test('fails when the printer does not take the data', () async {
      bluetooth
        ..connected = true
        ..canWrite = false;

      expect(
        ruleOf(await printer.print(receipt, PaperWidth.mm58)),
        PrinterFailures.printFailedRule,
      );
    });
  });

  test('disconnect closes the connection', () async {
    bluetooth.connected = true;

    expect((await printer.disconnect()).isOk, isTrue);

    expect(bluetooth.connected, isFalse);
  });
}
