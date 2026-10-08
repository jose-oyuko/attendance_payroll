import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/responsive/window_size_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Adaptive navigation chrome for the administrator experience.
///
/// - compact: app bar with a navigation drawer (phones)
/// - medium: navigation rail showing the selected label (small tablets)
/// - expanded and larger: extended navigation rail (tablets, large screens)
class AdminShell extends ConsumerWidget {
  const AdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(
      appConfigProvider.select((config) => config.appName),
    );
    final current = AdminDestination.values[navigationShell.currentIndex];

    return WindowSizeBuilder(
      builder: (context, size) {
        if (size == WindowSize.compact) {
          return _CompactLayout(
            appName: appName,
            current: current,
            onSelected: _onSelected,
            body: navigationShell,
          );
        }
        return _RailLayout(
          current: current,
          extended: size.isAtLeast(WindowSize.expanded),
          onSelected: _onSelected,
          body: navigationShell,
        );
      },
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.appName,
    required this.current,
    required this.onSelected,
    required this.body,
  });

  final String appName;
  final AdminDestination current;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(current.label)),
      drawer: Builder(
        builder: (drawerContext) => NavigationDrawer(
          selectedIndex: current.index,
          onDestinationSelected: (index) {
            Scaffold.of(drawerContext).closeDrawer();
            onSelected(index);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg + AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(appName, style: context.textStyles.titleSmall),
            ),
            for (final destination in AdminDestination.values)
              NavigationDrawerDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: Text(destination.label),
              ),
          ],
        ),
      ),
      body: body,
    );
  }
}

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.current,
    required this.extended,
    required this.onSelected,
    required this.body,
  });

  final AdminDestination current;
  final bool extended;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: current.index,
              onDestinationSelected: onSelected,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              destinations: [
                for (final destination in AdminDestination.values)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageTitle(label: current.label),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return WindowSizeBuilder(
      builder: (context, size) => Padding(
        padding: EdgeInsets.fromLTRB(
          size.pageGutter,
          AppSpacing.lg,
          size.pageGutter,
          0,
        ),
        child: Semantics(
          header: true,
          child: Text(label, style: context.textStyles.headlineSmall),
        ),
      ),
    );
  }
}
