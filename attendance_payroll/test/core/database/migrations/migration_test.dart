import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

// When the schema changes: bump `schemaVersion`, write the migration step,
// then run `dart run drift_dev make-migrations`. That exports the new snapshot,
// regenerates `generated/` and adds step-by-step upgrade tests next to this
// file.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a fresh install matches the exported snapshot', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  test('upgrading from v1 yields the current schema', () async {
    final db = AppDatabase((await verifier.schemaAt(1)).newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, db.schemaVersion);
  });
}
