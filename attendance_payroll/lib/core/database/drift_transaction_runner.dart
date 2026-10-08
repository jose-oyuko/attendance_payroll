import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/result/result.dart';

/// Drift transactions are zone-scoped: every repository using the same
/// [AppDatabase] inside [run] joins the transaction automatically, and their
/// own transactions become nested savepoints.
final class DriftTransactionRunner implements TransactionRunner {
  const DriftTransactionRunner(this._db);

  final AppDatabase _db;

  @override
  Future<Result<T>> run<T>(Future<T> Function() action) {
    return guardDatabase(() => _db.transaction(action));
  }
}
