import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/printing/data/printing_providers.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The printer and paper chosen on this device.
final printerSettingsProvider = FutureProvider.autoDispose<PrinterSettings>((
  ref,
) async {
  final session = requireSession(ref);
  return (await ref.watch(printingServiceProvider).settings(session)).unwrap();
});

/// Whether the printer can be printed to now. Read when the screen opens and
/// on refresh only: on Android, finding out may show a permission prompt.
final printerStatusProvider = FutureProvider.autoDispose<PrinterStatus>((
  ref,
) async {
  final session = requireSession(ref);
  return (await ref.watch(printingServiceProvider).status(session)).unwrap();
});

/// Printers the device can see. Waits for the status first, so the
/// permission prompt is shown once, not once per question.
final pairedPrintersProvider = FutureProvider.autoDispose<List<PrinterDevice>>((
  ref,
) async {
  final session = requireSession(ref);
  final status = await ref.watch(printerStatusProvider.future);
  if (status == PrinterStatus.permissionNeeded ||
      status == PrinterStatus.unavailable) {
    return const [];
  }
  return (await ref.watch(printingServiceProvider).discover(session)).unwrap();
});
