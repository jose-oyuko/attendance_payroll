import 'package:attendance_payroll/features/printing/data/drift_printer_settings_repository.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_printers.dart';
import '../../../support/test_database.dart';

void main() {
  late DriftPrinterSettingsRepository repository;

  setUp(() {
    repository = DriftPrinterSettingsRepository(openTestDatabase());
  });

  test('defaults to no printer on 58 mm paper', () async {
    final settings = (await repository.load()).unwrap();

    expect(settings.device, isNull);
    expect(settings.paperWidth, PaperWidth.mm58);
  });

  test('keeps the chosen printer and paper', () async {
    (await repository.save(
      const PrinterSettings(
        device: kitchenPrinter,
        paperWidth: PaperWidth.mm80,
      ),
    )).unwrap();

    final settings = (await repository.load()).unwrap();

    expect(settings.device, kitchenPrinter);
    expect(settings.paperWidth, PaperWidth.mm80);
  });

  test('saving again replaces the single row', () async {
    (await repository.save(
      const PrinterSettings(device: kitchenPrinter),
    )).unwrap();
    (await repository.save(
      const PrinterSettings(paperWidth: PaperWidth.mm80),
    )).unwrap();

    final settings = (await repository.load()).unwrap();

    expect(settings.device, isNull);
    expect(settings.paperWidth, PaperWidth.mm80);
  });
}
