import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';

/// A thermal printer reached over some connection (spec §39). Payroll code
/// only ever sees this interface, so USB or network printers are new
/// implementations, not changes to payroll.
abstract interface class PrinterService {
  /// Whether a printer can be printed to right now.
  Future<Result<PrinterStatus>> status();

  /// Printers the platform already knows (for Bluetooth, the paired ones).
  Future<Result<List<PrinterDevice>>> discover();

  /// Opens the connection to [device], replacing any other.
  Future<Result<void>> connect(PrinterDevice device);

  Future<Result<void>> disconnect();

  /// Prints [receipt] on the connected printer, laid out for [paperWidth].
  Future<Result<void>> print(Receipt receipt, PaperWidth paperWidth);
}
