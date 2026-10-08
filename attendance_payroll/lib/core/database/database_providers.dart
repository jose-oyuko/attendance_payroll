import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/core/database/drift_transaction_runner.dart';
import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/platform/device_identity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The open [AppDatabase]. Must be overridden at the root `ProviderScope`
/// (`bootstrap()` opens the on-device database; tests use an in-memory one).
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError(
    'appDatabaseProvider must be overridden in the root ProviderScope.',
  ),
);

final transactionRunnerProvider = Provider<TransactionRunner>(
  (ref) => DriftTransactionRunner(ref.watch(appDatabaseProvider)),
);

final deviceIdentityRepositoryProvider = Provider<DeviceIdentityRepository>(
  (ref) => DriftDeviceIdentityRepository(ref.watch(appDatabaseProvider)),
);
