import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:attendance_payroll/features/kiosk/presentation/kiosk_flow.dart';
import 'package:attendance_payroll/features/kiosk/presentation/widgets/kiosk_steps.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:attendance_payroll/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The attendance kiosk. Shows no administrative features; the only way out
/// is the administrator unlock, which needs a password.
class KioskScreen extends ConsumerWidget {
  const KioskScreen({required this.unlockLocation, super.key});

  final String unlockLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kiosk = switch (ref.watch(authControllerProvider)) {
      AsyncData(value: KioskMode(:final kiosk)) => kiosk,
      _ => null,
    };
    if (kiosk == null) {
      return const Scaffold(body: LoadingState());
    }
    final flow = ref.watch(kioskFlowProvider);
    return PopScope(
      // The system back button returns to the start, never out of the kiosk.
      canPop: false,
      onPopInvokedWithResult: (_, _) =>
          ref.read(kioskFlowProvider.notifier).reset(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(kiosk.companyName),
          actions: [
            TextButton.icon(
              onPressed: () {
                ref.read(kioskFlowProvider.notifier).reset();
                context.go(unlockLocation);
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('Administrator'),
            ),
          ],
        ),
        body: SafeArea(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => ref.read(kioskFlowProvider.notifier).touch(),
            child: switch (flow.step) {
              ChoosingEmployee() => const _EmployeePicker(),
              final EnteringPin step => PinEntryStep(
                step: step,
                busy: flow.busy,
              ),
              final ChoosingNewPin step => NewPinStep(
                step: step,
                busy: flow.busy,
              ),
              final Confirming step => ConfirmStep(
                step: step,
                busy: flow.busy,
                timeZone: kiosk.timeZone,
              ),
              final Finished step => FinishedStep(
                step: step,
                timeZone: kiosk.timeZone,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _EmployeePicker extends ConsumerStatefulWidget {
  const _EmployeePicker();

  @override
  ConsumerState<_EmployeePicker> createState() => _EmployeePickerState();
}

class _EmployeePickerState extends ConsumerState<_EmployeePicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(kioskEmployeesProvider);
    return switch (employees) {
      AsyncData(:final value) when value.isEmpty => const EmptyState(
        icon: Icons.people_outline,
        title: 'No employees yet.',
        message: 'Ask your manager to add employees before using the kiosk.',
      ),
      AsyncData(:final value) => _picker(value),
      AsyncError(:final error) => ErrorState(
        failure: AppFailure.from(error),
        onRetry: () => ref.invalidate(kioskEmployeesProvider),
      ),
      _ => const LoadingState(),
    };
  }

  Widget _picker(List<KioskEmployee> employees) {
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final e in employees)
        if (e.name.toLowerCase().contains(query)) e,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Tap your name',
              style: context.textStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (employees.length > _searchThreshold)
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search your name',
              ),
            ),
          AdaptiveGrid(
            children: [
              for (final employee in shown)
                _NameTile(
                  employee: employee,
                  onTap: () => ref
                      .read(kioskFlowProvider.notifier)
                      .selectEmployee(employee),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Above this many names, a search box helps more than scrolling.
  static const int _searchThreshold = 12;
}

class _NameTile extends StatelessWidget {
  const _NameTile({required this.employee, required this.onTap});

  static const double height = 88;

  final KioskEmployee employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = [
      for (final part in employee.name.split(' '))
        if (part.isNotEmpty) part.characters.first.toUpperCase(),
    ].take(2).join();
    return SizedBox(
      height: height,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            CircleAvatar(child: Text(initials)),
            Expanded(
              child: Text(
                employee.name,
                style: context.textStyles.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
