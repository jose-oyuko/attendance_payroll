import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/backup/data/local_backup_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late LocalBackupStorage storage;

  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('backup-storage-test');
    addTearDown(() => directory.deleteSync(recursive: true));
    // A folder that does not exist yet: created on first use.
    storage = LocalBackupStorage(
      () async => Directory('${directory.path}/backups'),
    );
  });

  test('keeps and returns a file', () async {
    await storage.write('one.apbackup', bytes([1, 2, 3, 4, 5]));

    expect(await storage.read('one.apbackup'), [1, 2, 3, 4, 5]);
    final files = await storage.list();
    expect(files.single.name, 'one.apbackup');
    expect(files.single.sizeBytes, 5);
  });

  test('reads just the start of a file', () async {
    await storage.write('one.apbackup', bytes(List.generate(100, (i) => i)));

    expect(await storage.readPrefix('one.apbackup', 4), [0, 1, 2, 3]);
    expect((await storage.readPrefix('one.apbackup', 1000)).length, 100);
  });

  test('replaces a file of the same name', () async {
    await storage.write('one.apbackup', bytes([1]));
    await storage.write('one.apbackup', bytes([2, 2]));

    expect(await storage.read('one.apbackup'), [2, 2]);
    expect(await storage.list(), hasLength(1));
  });

  test('deletes a file, and deleting a missing one is fine', () async {
    await storage.write('one.apbackup', bytes([1]));

    await storage.delete('one.apbackup');
    await storage.delete('one.apbackup');

    expect(await storage.list(), isEmpty);
  });

  test('an empty folder lists nothing', () async {
    expect(await storage.list(), isEmpty);
  });

  test('a half-written file never appears in the list', () async {
    await storage.write('one.apbackup', bytes([1]));
    File(
      '${directory.path}/backups/two.apbackup.partial',
    ).writeAsBytesSync([9]);
    File('${directory.path}/backups/notes.txt').writeAsStringSync('hi');

    expect((await storage.list()).map((f) => f.name), ['one.apbackup']);
  });

  test('refuses names that point outside the folder', () async {
    for (final name in [
      '../escape.apbackup',
      'sub/dir.apbackup',
      r'..\escape.apbackup',
      'no-extension',
      '/absolute.apbackup',
      '',
    ]) {
      await expectLater(
        storage.write(name, bytes([1])),
        throwsA(isA<BusinessRuleFailure>()),
        reason: name,
      );
      await expectLater(
        storage.read(name),
        throwsA(isA<BusinessRuleFailure>()),
      );
      await expectLater(
        storage.delete(name),
        throwsA(isA<BusinessRuleFailure>()),
      );
    }
    expect(File('${directory.path}/escape.apbackup').existsSync(), isFalse);
  });

  test('reading a missing file says it was not found', () async {
    await expectLater(
      storage.read('missing.apbackup'),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
