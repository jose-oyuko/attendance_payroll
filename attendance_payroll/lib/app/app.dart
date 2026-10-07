import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/app/theme/app_theme.dart';
import 'package:attendance_payroll/features/settings/presentation/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget. Holds no logic of its own: it wires configuration, theme and
/// routing together.
class AttendancePayrollApp extends ConsumerWidget {
  const AttendancePayrollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appConfigProvider.select((c) => c.appName));
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
