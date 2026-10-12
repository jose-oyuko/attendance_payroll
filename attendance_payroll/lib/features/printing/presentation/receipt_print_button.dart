import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/printing/data/payroll_receipts.dart';
import 'package:attendance_payroll/features/printing/data/printing_providers.dart';
import 'package:attendance_payroll/features/printing/domain/printer_failures.dart';
import 'package:attendance_payroll/features/printing/domain/printing_service.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:attendance_payroll/features/printing/presentation/printer_routes.dart';
import 'package:attendance_payroll/features/reports/data/report_providers.dart';
import 'package:attendance_payroll/features/reports/domain/report_service.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether [kind] can be printed on a receipt printer. Attendance reports
/// are wide tables that only make sense on a page.
bool hasReceipt(ReportKind kind) =>
    kind == ReportKind.payslips || kind == ReportKind.payrollSummary;

/// Prints the document of [request] on the thermal printer: gathers the
/// same data as the PDF, lays it out as a receipt and sends it.
Future<Result<void>> printReceipt({
  required ReportService reports,
  required PrintingService printing,
  required AdminSession session,
  required ReportRequest request,
}) {
  return Result.guard(() async {
    final Receipt receipt;
    switch (request.kind) {
      case ReportKind.payslips:
        receipt = payslipsReceipt(
          (await reports.payslips(
            session,
            request.periodId!,
            employeeId: request.employeeId,
          )).unwrap(),
        );
      case ReportKind.payrollSummary:
        receipt = payrollSummaryReceipt(
          (await reports.payrollSummary(session, request.periodId!)).unwrap(),
        );
      case ReportKind.attendance ||
          ReportKind.timesheet ||
          ReportKind.exceptions:
        throw const ValidationFailure(
          userMessage: 'This document cannot be printed on a receipt printer.',
        );
    }
    (await printing.print(session, receipt)).unwrap();
  });
}

/// App bar action printing a payroll document on the thermal printer.
class ReceiptPrintButton extends ConsumerStatefulWidget {
  const ReceiptPrintButton({required this.request, super.key});

  final ReportRequest request;

  @override
  ConsumerState<ReceiptPrintButton> createState() => _ReceiptPrintButtonState();
}

class _ReceiptPrintButtonState extends ConsumerState<ReceiptPrintButton> {
  bool _busy = false;

  Future<void> _print() async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    setState(() => _busy = true);
    final result = await printReceipt(
      reports: ref.read(reportServiceProvider),
      printing: ref.read(printingServiceProvider),
      session: session,
      request: widget.request,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    switch (result) {
      case Ok():
        messenger.showSnackBar(
          const SnackBar(content: Text('Sent to the receipt printer.')),
        );
      case Err(:final failure):
        final needsSetup =
            failure is BusinessRuleFailure &&
            failure.rule == PrinterFailures.notConfiguredRule;
        messenger.showSnackBar(
          SnackBar(
            content: Text(failure.userMessage),
            action: needsSetup
                ? SnackBarAction(
                    label: 'Printer settings',
                    onPressed: () => context.push(PrinterRoutes.settings),
                  )
                : null,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Printing receipt',
          ),
        ),
      );
    }
    return IconButton(
      tooltip: 'Print receipt',
      onPressed: _print,
      icon: const Icon(Icons.receipt_long_outlined),
    );
  }
}
