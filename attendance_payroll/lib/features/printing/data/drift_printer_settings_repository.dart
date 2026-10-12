import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/tables.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printer_settings_repository.dart';
import 'package:drift/drift.dart';

final class DriftPrinterSettingsRepository
    implements PrinterSettingsRepository {
  DriftPrinterSettingsRepository(this._db, {this._clock = systemClockUtc});

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<PrinterSettings>> load() {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.printerSettingsTable)
                ..where((s) => s.id.equals(PrinterSettingsTable.singletonId)))
              .getSingleOrNull();
      if (row == null) {
        return const PrinterSettings();
      }
      final connection = PrinterConnection.values.asNameMap()[row.connection];
      return PrinterSettings(
        // A connection kind this version does not know (a newer version wrote
        // it) is treated as no printer rather than guessed.
        device: connection == null || row.deviceId == null
            ? null
            : PrinterDevice(
                id: row.deviceId!,
                name: row.deviceName ?? row.deviceId!,
                connection: connection,
              ),
        paperWidth:
            PaperWidth.values.asNameMap()[row.paperWidth] ?? PaperWidth.mm58,
      );
    });
  }

  @override
  Future<Result<void>> save(PrinterSettings settings) {
    return guardDatabase(() async {
      final device = settings.device;
      await _db
          .into(_db.printerSettingsTable)
          .insertOnConflictUpdate(
            PrinterSettingsTableCompanion.insert(
              id: PrinterSettingsTable.singletonId,
              connection: Value(device?.connection.name),
              deviceId: Value(device?.id),
              deviceName: Value(device?.name),
              paperWidth: settings.paperWidth.name,
              updatedAt: _clock(),
            ),
          );
    });
  }
}
