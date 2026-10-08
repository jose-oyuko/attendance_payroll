import 'package:attendance_payroll/app/app.dart';
import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/core/errors/global_error_handler.dart';
import 'package:attendance_payroll/core/logging/app_logger.dart';
import 'package:attendance_payroll/core/logging/log_sink.dart';
import 'package:attendance_payroll/core/logging/logging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Initialises configuration, logging, global error handling and the
/// database, then starts
/// the app. Everything that must exist before the first frame lives here so
/// `main()` stays trivial and tests can bypass it entirely.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final logger = AppLogger(
    minLevel: config.logLevel,
    sinks: const <LogSink>[ConsoleLogSink()],
  );
  installGlobalErrorHandlers(logger);

  logger.info(
    'bootstrap',
    'Starting application',
    fields: <String, Object?>{'environment': config.environment.name},
  );

  // The connection opens lazily on the first query, off the UI isolate.
  final database = AppDatabase.onDevice();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appLoggerProvider.overrideWithValue(logger),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const AttendancePayrollApp(),
    ),
  );
}
