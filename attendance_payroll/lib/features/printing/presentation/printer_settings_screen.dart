import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/printing/data/printing_providers.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/printing_service.dart';
import 'package:attendance_payroll/features/printing/presentation/printer_view_providers.dart';
import 'package:attendance_payroll/shared/widgets/confirm_dialog.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:attendance_payroll/shared/widgets/subpage_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension PaperWidthLabel on PaperWidth {
  String get label => switch (this) {
    PaperWidth.mm58 => '58 mm',
    PaperWidth.mm80 => '80 mm',
  };
}

extension PrinterStatusLabel on PrinterStatus {
  String get label => switch (this) {
    PrinterStatus.connected => 'Connected',
    PrinterStatus.disconnected => 'Not connected',
    PrinterStatus.unavailable => 'Bluetooth is off',
    PrinterStatus.permissionNeeded => 'Permission needed',
  };
}

/// Choose, connect and test the thermal printer of this device.
class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  bool _busy = false;
  String? _error;

  /// Runs [action] with the busy state and error banner, then refreshes what
  /// the screen shows. [done] is shown on success.
  Future<void> _run(
    Future<Result<Object?>> Function(PrintingService, AdminSession) action, {
    String? done,
  }) async {
    final session = ref.read(adminSessionProvider);
    if (session == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action(ref.read(printingServiceProvider), session);
    if (!mounted) {
      return;
    }
    ref
      ..invalidate(printerSettingsProvider)
      ..invalidate(printerStatusProvider)
      ..invalidate(pairedPrintersProvider);
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.userMessage;
    });
    if (done != null && result.isOk) {
      // Replace an older message instead of queueing behind it.
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(done)));
    }
  }

  Future<void> _forget(PrinterSettings settings) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Forget this printer?',
      message:
          '${settings.device?.name} will no longer be used for receipts. '
          'You can choose it again later.',
      confirmLabel: 'Forget',
    );
    if (confirmed && mounted) {
      await _run((service, session) => service.forgetPrinter(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printerSettingsProvider);
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          SubpageHeader(
            title: 'Printer',
            backLocation: AdminDestination.settings.path,
          ),
          if (_error case final message?) FailureBanner(message: message),
          switch (settings) {
            AsyncData(:final value) => _content(value),
            AsyncError(:final error) => FailureBanner(
              message: AppFailure.from(error).userMessage,
            ),
            _ => const LinearProgressIndicator(),
          },
        ],
      ),
    );
  }

  Widget _content(PrinterSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        _CurrentPrinterCard(
          settings: settings,
          busy: _busy,
          onTest: () => _run(
            (service, session) => service.printTest(session),
            done: 'Test page sent to the printer.',
          ),
          onForget: () => _forget(settings),
        ),
        _PaperCard(
          selected: settings.paperWidth,
          busy: _busy,
          onSelected: (width) =>
              _run((service, session) => service.setPaperWidth(session, width)),
        ),
        _PairedPrintersCard(
          current: settings.device,
          busy: _busy,
          onUse: (device) => _run(
            (service, session) => service.selectPrinter(session, device),
            done: 'Connected to ${device.name}.',
          ),
          onRefresh: () {
            setState(() => _error = null);
            ref
              ..invalidate(printerStatusProvider)
              ..invalidate(pairedPrintersProvider);
          },
        ),
      ],
    );
  }
}

class _CurrentPrinterCard extends ConsumerWidget {
  const _CurrentPrinterCard({
    required this.settings,
    required this.busy,
    required this.onTest,
    required this.onForget,
  });

  final PrinterSettings settings;
  final bool busy;
  final VoidCallback onTest;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = settings.device;
    final status = ref.watch(printerStatusProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Receipt printer',
                    style: context.textStyles.titleMedium,
                  ),
                ),
                if (device != null && status.value != null)
                  _StatusChip(status: status.value!),
              ],
            ),
            if (device == null)
              const Text(
                'No printer chosen. Pair your thermal printer in the '
                "phone's Bluetooth settings, then choose it below.",
              )
            else ...[
              Text(device.name, style: context.textStyles.titleSmall),
              Text(
                device.id,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : onTest,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print test page'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onForget,
                    child: const Text('Forget printer'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Colour-coded printer status. The text carries the meaning, so it does not
/// rely on colour alone.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PrinterStatus status;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colors = switch (status) {
      PrinterStatus.connected => semantic.success,
      PrinterStatus.disconnected => semantic.neutral,
      PrinterStatus.unavailable ||
      PrinterStatus.permissionNeeded => semantic.warning,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          status.label,
          style: context.textStyles.labelMedium?.copyWith(
            color: colors.onContainer,
          ),
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.selected,
    required this.busy,
    required this.onSelected,
  });

  final PaperWidth selected;
  final bool busy;
  final ValueChanged<PaperWidth> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text('Paper width', style: context.textStyles.titleMedium),
            SegmentedButton<PaperWidth>(
              segments: [
                for (final width in PaperWidth.values)
                  ButtonSegment<PaperWidth>(
                    value: width,
                    label: Text(width.label),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: busy
                  ? null
                  : (selection) => onSelected(selection.first),
            ),
            Text(
              'Match the roll in the printer. Most handheld printers use '
              '58 mm; desktop receipt printers use 80 mm.',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairedPrintersCard extends ConsumerWidget {
  const _PairedPrintersCard({
    required this.current,
    required this.busy,
    required this.onUse,
    required this.onRefresh,
  });

  final PrinterDevice? current;
  final bool busy;
  final ValueChanged<PrinterDevice> onUse;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(printerStatusProvider);
    final paired = ref.watch(pairedPrintersProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Paired printers',
                    style: context.textStyles.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh printers',
                  onPressed: busy ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            switch ((status, paired)) {
              (AsyncData(value: PrinterStatus.permissionNeeded), _) =>
                const _Hint(
                  'This app needs permission to use nearby devices. Allow it '
                  'in the phone settings, then refresh.',
                ),
              (AsyncData(value: PrinterStatus.unavailable), _) => const _Hint(
                'Bluetooth is switched off. Turn it on, then refresh.',
              ),
              (_, AsyncError(:final error)) => FailureBanner(
                message: AppFailure.from(error).userMessage,
              ),
              (_, AsyncData(:final value)) when value.isEmpty => const _Hint(
                'No paired printers found. Pair the printer in the '
                "phone's Bluetooth settings (the PIN is usually 0000 or "
                '1234), then refresh.',
              ),
              (_, AsyncData(:final value)) => Column(
                children: [
                  for (final device in value)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      trailing: device == current
                          ? const Chip(label: Text('In use'))
                          : FilledButton.tonal(
                              onPressed: busy ? null : () => onUse(device),
                              child: const Text('Use'),
                            ),
                    ),
                ],
              ),
              _ => const LinearProgressIndicator(),
            },
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}
