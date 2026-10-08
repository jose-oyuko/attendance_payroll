import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/settings/presentation/theme_mode_provider.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [const _AccountCard(), _appearance(context, ref, mode)],
      ),
    );
  }

  Widget _appearance(BuildContext context, WidgetRef ref, ThemeMode mode) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: context.textStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: <ThemeMode>{mode},
              onSelectionChanged: (selection) {
                ref.read(themeModeProvider.notifier).select(selection.first);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This choice is not saved between launches yet.',
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

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminSessionProvider)?.admin;
    if (admin == null) {
      return const SizedBox.shrink();
    }
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text('Account', style: context.textStyles.titleMedium),
                  Text('Signed in as ${admin.displayName} (${admin.username})'),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
