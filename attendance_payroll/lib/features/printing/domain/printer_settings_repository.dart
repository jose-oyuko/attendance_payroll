import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';

/// Where this device keeps its printer choice.
abstract interface class PrinterSettingsRepository {
  /// The saved choice, or the defaults (no printer, 58 mm) when none exists.
  Future<Result<PrinterSettings>> load();

  Future<Result<void>> save(PrinterSettings settings);
}
