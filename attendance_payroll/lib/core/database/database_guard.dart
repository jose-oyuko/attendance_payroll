import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
// drift marks this library experimental only because its cross-isolate wire
// protocol may change between versions; the DriftRemoteException API itself is
// documented as stable. Both isolates always run the same drift version here.
// `package:drift/isolate.dart` re-exports it too, but imports dart:isolate,
// which would break the web build.
// ignore: experimental_member_use
import 'package:drift/remote.dart';
// The platform-neutral library, so this file also compiles for the web.
import 'package:sqlite3/common.dart';

/// Runs a database [action] and converts anything it throws into a [Result].
///
/// Raw SQLite errors never leave the data layer:
/// - a unique or primary-key violation becomes a [ConflictFailure] carrying
///   [conflictMessage];
/// - any other error becomes a [DatabaseFailure] that keeps the original as
///   its technical cause.
///
/// [AppFailure]s thrown on purpose inside [action] (typically to roll back a
/// transaction) are returned unchanged.
Future<Result<T>> guardDatabase<T>(
  Future<T> Function() action, {
  String conflictMessage = 'This record already exists.',
}) async {
  try {
    return Ok<T>(await action());
  } on Object catch (error, stackTrace) {
    return Err<T>(
      mapDatabaseError(error, stackTrace, conflictMessage: conflictMessage),
    );
  }
}

/// Converts a database error into an [AppFailure]. See [guardDatabase].
AppFailure mapDatabaseError(
  Object error,
  StackTrace stackTrace, {
  String conflictMessage = 'This record already exists.',
}) {
  // Errors raised on drift's background isolate arrive wrapped.
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  if (cause is AppFailure) {
    return cause;
  }
  if (cause is SqliteException &&
      (cause.extendedResultCode == SqlExtendedError.SQLITE_CONSTRAINT_UNIQUE ||
          cause.extendedResultCode ==
              SqlExtendedError.SQLITE_CONSTRAINT_PRIMARYKEY)) {
    return ConflictFailure(
      userMessage: conflictMessage,
      cause: cause,
      stackTrace: stackTrace,
    );
  }
  return DatabaseFailure(cause: cause, stackTrace: stackTrace);
}
