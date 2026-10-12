import 'package:attendance_payroll/features/printing/data/printing_providers.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/presentation/printer_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_printers.dart';
import '../../../support/pump_app.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  late FakeBluetoothGateway bluetooth;

  setUp(() => bluetooth = FakeBluetoothGateway());

  Future<void> openPrinterSettings(
    WidgetTester tester, {
    Size size = tabletSize,
  }) async {
    await pumpApp(
      tester,
      size: size,
      overrides: [bluetoothGatewayProvider.overrideWithValue(bluetooth)],
    );
    if (size == phoneSize) {
      await _tap(tester, find.byTooltip('Open navigation menu'));
    }
    await _tap(tester, find.text('Settings'));
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Set up'));
  }

  testWidgets('settings offers the printer, with nothing chosen at first', (
    tester,
  ) async {
    await pumpApp(
      tester,
      size: tabletSize,
      overrides: [bluetoothGatewayProvider.overrideWithValue(bluetooth)],
    );
    await _tap(tester, find.text('Settings'));

    expect(find.text('Printer'), findsOneWidget);
    expect(find.text('No printer chosen.'), findsOneWidget);
  });

  testWidgets('lists the paired printers and connects to the chosen one', (
    tester,
  ) async {
    await openPrinterSettings(tester);

    expect(find.byType(PrinterSettingsScreen), findsOneWidget);
    expect(find.text('RPP02N'), findsOneWidget);
    expect(find.textContaining('No printer chosen'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'Use'));

    expect(bluetooth.connectCalls, [kitchenPrinter.id]);
    expect(find.text('In use'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Print test page'), findsOneWidget);
    expect(find.text('Connected to RPP02N.'), findsOneWidget);
  });

  testWidgets('the chosen printer is remembered on the settings page', (
    tester,
  ) async {
    await openPrinterSettings(tester);
    await _tap(tester, find.widgetWithText(FilledButton, 'Use'));

    await _tap(tester, find.byType(BackButton));

    expect(find.text('RPP02N, 58 mm paper.'), findsOneWidget);
  });

  testWidgets('prints a test page on the connected printer', (tester) async {
    await openPrinterSettings(tester);
    await _tap(tester, find.widgetWithText(FilledButton, 'Use'));

    await _tap(tester, find.text('Print test page'));

    expect(bluetooth.written, hasLength(1));
    expect(
      String.fromCharCodes(bluetooth.written.single),
      contains('Printer test'),
    );
    expect(find.text('Test page sent to the printer.'), findsOneWidget);
  });

  testWidgets('the paper width is saved and used for printing', (tester) async {
    await openPrinterSettings(tester);
    await _tap(tester, find.widgetWithText(FilledButton, 'Use'));

    await _tap(tester, find.text('80 mm'));
    await _tap(tester, find.text('Print test page'));

    // The ruler fills the 48 characters of an 80 mm roll.
    expect(
      String.fromCharCodes(bluetooth.written.single),
      contains('.' * 9 + '1'),
    );
    expect(
      String.fromCharCodes(bluetooth.written.single),
      contains('=' * PaperWidth.mm80.characters),
    );
  });

  testWidgets('forgetting the printer asks first', (tester) async {
    await openPrinterSettings(tester);
    await _tap(tester, find.widgetWithText(FilledButton, 'Use'));

    await _tap(tester, find.text('Forget printer'));
    expect(find.text('Forget this printer?'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Forget'));

    expect(find.text('Print test page'), findsNothing);
    expect(find.textContaining('No printer chosen'), findsOneWidget);
  });

  testWidgets('a printer that cannot be reached is not kept', (tester) async {
    bluetooth.canConnect = false;
    await openPrinterSettings(tester);

    await _tap(tester, find.widgetWithText(FilledButton, 'Use'));

    expect(find.textContaining('Could not connect to RPP02N'), findsOneWidget);
    expect(find.text('In use'), findsNothing);
    expect(find.text('Print test page'), findsNothing);
  });

  testWidgets('explains when Bluetooth is off', (tester) async {
    bluetooth.enabled = false;
    await openPrinterSettings(tester);

    expect(find.textContaining('Bluetooth is switched off'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Use'), findsNothing);
  });

  testWidgets('explains when the app may not use Bluetooth', (tester) async {
    bluetooth.permission = false;
    await openPrinterSettings(tester);

    expect(find.textContaining('needs permission'), findsOneWidget);
  });

  testWidgets('explains how to pair when nothing is paired', (tester) async {
    bluetooth.paired = const [];
    await openPrinterSettings(tester);

    expect(find.textContaining('No paired printers found'), findsOneWidget);
  });

  testWidgets('works on a phone', (tester) async {
    await openPrinterSettings(tester, size: phoneSize);

    expect(find.text('RPP02N'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
