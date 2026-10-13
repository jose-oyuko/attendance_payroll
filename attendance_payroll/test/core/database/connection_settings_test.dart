import 'dart:io';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late AppDatabase db;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('connection-settings');
    db = AppDatabase(
      NativeDatabase(
        File('${directory.path}/app.sqlite'),
        setup: AppDatabase.configureConnection,
      ),
    );
    addTearDown(() async {
      await db.close();
      directory.deleteSync(recursive: true);
    });
  });

  Future<Object?> pragma(String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).data.values.first;

  test('the database file is crash-safe and fully synchronous', () async {
    expect(await pragma('journal_mode'), 'wal');
    // 2 is FULL.
    expect(await pragma('synchronous'), 2);
  });

  test('foreign keys are enforced', () async {
    expect(await pragma('foreign_keys'), 1);
  });

  test('a fresh file has the whole schema and passes its own checks', () async {
    expect(await pragma('user_version'), db.schemaVersion);
    expect(await pragma('integrity_check'), 'ok');
    expect((await db.customSelect('PRAGMA foreign_key_check').get()), isEmpty);
  });
}
