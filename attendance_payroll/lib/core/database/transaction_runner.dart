import 'package:attendance_payroll/core/result/result.dart';

/// Runs several repository calls atomically.
///
/// Domain services depend on this interface, not on the database. Inside
/// [run], a failing step must throw (see `Result.unwrap`), which rolls back
/// every write made by [action]; the failure is returned as an `Err`.
abstract interface class TransactionRunner {
  Future<Result<T>> run<T>(Future<T> Function() action);
}
