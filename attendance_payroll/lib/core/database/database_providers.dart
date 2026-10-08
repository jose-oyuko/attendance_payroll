import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The open [AppDatabase]. Must be overridden at the root `ProviderScope`
/// (`bootstrap()` opens the on-device database; tests use an in-memory one).
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError(
    'appDatabaseProvider must be overridden in the root ProviderScope.',
  ),
);
