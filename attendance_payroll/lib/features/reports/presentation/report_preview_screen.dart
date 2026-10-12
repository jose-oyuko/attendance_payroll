import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/printing/presentation/receipt_print_button.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:attendance_payroll/features/reports/presentation/report_view_providers.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shows a document with the platform's print and share actions. Opened on
/// top of the screen it came from; back returns there.
class ReportPreviewScreen extends ConsumerWidget {
  const ReportPreviewScreen({required this.request, super.key});

  /// `null` when the location did not describe a document.
  final ReportRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = this.request;
    final file = request == null
        ? null
        : ref.watch(reportFileProvider(request));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(ReportRoutes.list),
        ),
        title: Text(file?.value?.title ?? 'Document'),
        actions: [
          if (request != null && hasReceipt(request.kind))
            ReceiptPrintButton(request: request),
        ],
      ),
      body: switch (file) {
        null => ErrorState(
          failure: const NotFoundFailure(entity: 'document'),
          retryLabel: 'Go to reports',
          onRetry: () => context.go(ReportRoutes.list),
        ),
        AsyncData(:final value) => ref.watch(documentViewerProvider)(value),
        AsyncError(:final error) => ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.invalidate(reportFileProvider(request!)),
        ),
        _ => const LoadingState(),
      },
    );
  }
}
