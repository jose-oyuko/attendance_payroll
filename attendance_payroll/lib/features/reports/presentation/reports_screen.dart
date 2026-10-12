import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:attendance_payroll/features/reports/presentation/widgets/report_options_dialog.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The printable documents. Choosing one asks for its period or dates, then
/// opens the preview, where it can be printed or shared.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _open(BuildContext context, ReportKind kind) async {
    final request = await showReportOptionsDialog(context, kind);
    if (request != null && context.mounted) {
      await context.push(ReportRoutes.previewOf(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Text('Payroll', style: context.textStyles.titleMedium),
          AdaptiveGrid(
            maxColumns: 3,
            children: [
              for (final kind in ReportKind.values.where((k) => k.isPayroll))
                _ReportCard(kind: kind, onOpen: () => _open(context, kind)),
            ],
          ),
          Text('Attendance', style: context.textStyles.titleMedium),
          AdaptiveGrid(
            maxColumns: 3,
            children: [
              for (final kind in ReportKind.values.where((k) => !k.isPayroll))
                _ReportCard(kind: kind, onOpen: () => _open(context, kind)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.kind, required this.onOpen});

  final ReportKind kind;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Icon(kind.icon),
        title: Text(kind.title, style: context.textStyles.titleMedium),
        subtitle: Text(kind.description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
