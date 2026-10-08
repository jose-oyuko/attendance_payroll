import 'package:attendance_payroll/core/database/tables.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:drift/drift.dart';

/// Writes [changes] to the live row [id] only if it is still at
/// [expectedVersion] (optimistic concurrency).
///
/// [changes] must set `version` to `expectedVersion + 1` and refresh
/// `updatedAt`. Throws a [NotFoundFailure] when the row does not exist (or is
/// deleted) and a [ConflictFailure] when someone else updated it first. Call it
/// inside a transaction so the follow-up check sees the same state.
Future<void> updateVersioned<T extends EntityColumns, D>(
  DatabaseConnectionUser db,
  TableInfo<T, D> table, {
  required String id,
  required int expectedVersion,
  required Insertable<D> changes,
  required String entity,
}) async {
  final updatedRows =
      await (db.update(table)..where(
            (t) =>
                t.id.equals(id) &
                t.version.equals(expectedVersion) &
                t.deletedAt.isNull(),
          ))
          .write(changes);
  if (updatedRows == 1) {
    return;
  }
  final current = await (db.select(
    table,
  )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  if (current == null) {
    throw NotFoundFailure(entity: entity);
  }
  throw ConflictFailure(
    userMessage:
        'This $entity was changed by someone else. Reload it and try again.',
  );
}
