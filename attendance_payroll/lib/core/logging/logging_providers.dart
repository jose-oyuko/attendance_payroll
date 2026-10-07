import 'package:attendance_payroll/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The application logger.
///
/// Defaults to a silent logger so tests stay quiet; `bootstrap()` overrides it
/// with a real one.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.silent());
