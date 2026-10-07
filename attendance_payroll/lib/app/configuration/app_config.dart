import 'package:attendance_payroll/core/logging/log_level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deployment environment, chosen at build time with
/// `--dart-define=APP_ENV=<development|staging|production>`.
enum AppEnvironment {
  development('Development'),
  staging('Staging'),
  production('Production');

  const AppEnvironment(this.label);

  final String label;

  /// Parses an `APP_ENV` value.
  ///
  /// Throws a [FormatException] for unknown values so a typo in a build script
  /// fails at startup instead of silently running with the wrong settings.
  static AppEnvironment parse(String value) {
    for (final environment in AppEnvironment.values) {
      if (environment.name == value.trim().toLowerCase()) {
        return environment;
      }
    }
    throw FormatException('Unknown APP_ENV value', value);
  }
}

/// Immutable, build-time application configuration.
@immutable
final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.logLevel,
  });

  /// Defaults for [environment].
  factory AppConfig.forEnvironment(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.development => const AppConfig(
        environment: AppEnvironment.development,
        appName: 'Attendance & Payroll',
        logLevel: LogLevel.debug,
      ),
      AppEnvironment.staging => const AppConfig(
        environment: AppEnvironment.staging,
        appName: 'Attendance & Payroll',
        logLevel: LogLevel.info,
      ),
      AppEnvironment.production => const AppConfig(
        environment: AppEnvironment.production,
        appName: 'Attendance & Payroll',
        logLevel: LogLevel.warning,
      ),
    };
  }

  /// Reads `APP_ENV` from `--dart-define` (default: development).
  factory AppConfig.fromEnvironment() {
    return AppConfig.forEnvironment(AppEnvironment.parse(_environmentName));
  }

  static const String _environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  final AppEnvironment environment;
  final String appName;
  final LogLevel logLevel;

  bool get isProduction => environment == AppEnvironment.production;
}

/// The active [AppConfig]. Must be overridden at the root `ProviderScope`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError(
    'appConfigProvider must be overridden in the root ProviderScope.',
  ),
);
