import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/settings/presentation/theme_mode_provider.dart';
import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:attendance_payroll/shared/widgets/page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard: company and environment summary for now. Attendance and payroll
/// cards are added in the phases that build those features.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final semantic = context.semanticColors;
    final company = ref.watch(currentCompanyProvider).value;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance and payroll summaries will appear here as those '
            'features are built.',
            style: context.textStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveGrid(
            children: [
              _StatusCard(
                icon: Icons.layers_outlined,
                title: 'Environment',
                value: config.environment.label,
                accent: semantic.info,
              ),
              _StatusCard(
                icon: Icons.devices,
                title: 'Window size',
                value: context.windowSize.label,
                accent: semantic.neutral,
              ),
              _StatusCard(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                value: _themeLabel(themeMode),
                accent: semantic.neutral,
              ),
              _StatusCard(
                icon: Icons.business_outlined,
                title: 'Company',
                value: company?.details.name ?? '…',
                caption: company == null
                    ? null
                    : '${company.details.currencyCode} · '
                          '${company.details.timezone}',
                accent: semantic.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.caption,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? caption;
  final SemanticColorSet accent;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.container,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: accent.onContainer),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(value, style: context.textStyles.titleMedium),
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      caption,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
