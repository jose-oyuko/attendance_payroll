import 'dart:convert';
import 'dart:typed_data';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/backup/data/apbackup_codec.dart';
import 'package:attendance_payroll/features/backup/data/backup_header_json.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_backups.dart';

void main() {
  final codec = fastCodec();
  final snapshot = Uint8List.fromList(
    List.generate(50000, (i) => (i * 7 + i ~/ 13) % 251),
  );
  const password = 'correct horse battery';

  BackupHeader header({int version = 1}) => BackupHeader(
    backupVersion: version,
    appVersion: '0.1.0',
    schemaVersion: 10,
    createdAt: DateTime.utc(2026, 10, 12, 15, 30),
    kind: BackupKind.manual,
    createdBy: 'Jane Owner',
    deviceId: 'device-1',
    companyId: 'company-1',
    companyName: 'Acme Ltd',
    summary: BackupSummary(
      employees: 12,
      attendanceEvents: 3400,
      payrollPeriods: 6,
      latestAttendanceAt: DateTime.utc(2026, 10, 11, 17),
    ),
  );

  Future<Uint8List> encoded({int version = 1}) => codec.encode(
    header: header(version: version),
    snapshot: snapshot,
    password: password,
  );

  /// A copy of [file] with the byte at [index] changed.
  Uint8List flipped(Uint8List file, int index) {
    final copy = Uint8List.fromList(file);
    copy[index] ^= 0x01;
    return copy;
  }

  Future<String?> failureRule(Future<Object?> Function() action) async {
    try {
      await action();
    } on BusinessRuleFailure catch (failure) {
      return failure.rule;
    }
    return null;
  }

  test('a backup decrypts back to exactly the database that went in', () async {
    final file = await encoded();

    expect(await codec.decode(file, password), snapshot);
  });

  test(
    'the data is compressed and encrypted, not readable in the file',
    () async {
      final text = Uint8List.fromList(utf8.encode('SECRET PAYROLL ' * 2000));
      final file = await codec.encode(
        header: header(),
        snapshot: text,
        password: password,
      );

      expect(file.length, lessThan(text.length));
      expect(latin1.decode(file), isNot(contains('SECRET PAYROLL')));
    },
  );

  test('the header is readable without the password', () async {
    final file = await encoded();

    final read = codec.readHeader(file);

    expect(read.backupVersion, 1);
    expect(read.companyName, 'Acme Ltd');
    expect(read.createdAt, DateTime.utc(2026, 10, 12, 15, 30));
    expect(read.kind, BackupKind.manual);
    expect(read.createdBy, 'Jane Owner');
    expect(read.schemaVersion, 10);
    expect(read.summary.employees, 12);
    expect(read.summary.latestAttendanceAt, DateTime.utc(2026, 10, 11, 17));
  });

  test('the header can be read from just the start of the file', () async {
    final file = await encoded();

    final prefix = file.sublist(
      0,
      BackupCodec.headerPrefixBytes.clamp(0, file.length),
    );

    expect(codec.readHeader(prefix).companyId, 'company-1');
  });

  test('the password is not in the header or the file', () async {
    final file = await encoded();

    expect(latin1.decode(file), isNot(contains(password)));
  });

  test('each backup uses a new salt and nonce', () async {
    final a = await encoded();
    final b = await encoded();

    expect(a, isNot(b));
    expect(await codec.decode(a, password), await codec.decode(b, password));
  });

  test('a wrong password is refused', () async {
    final file = await encoded();

    expect(
      await failureRule(() => codec.decode(file, 'not the password')),
      BackupFailures.wrongPasswordRule,
    );
  });

  test('a changed byte in the data is refused', () async {
    final file = await encoded();

    expect(
      await failureRule(
        () => codec.decode(flipped(file, file.length - 20), password),
      ),
      BackupFailures.wrongPasswordRule,
    );
  });

  test('a changed byte in the header is refused', () async {
    final file = await encoded();
    // Inside the company name: valid JSON, but not what was signed.
    final at = latin1.decode(file).indexOf('Acme');

    expect(
      await failureRule(() => codec.decode(flipped(file, at), password)),
      BackupFailures.wrongPasswordRule,
    );
  });

  test('a truncated file is refused', () async {
    final file = await encoded();

    expect(
      await failureRule(
        () => codec.decode(file.sublist(0, file.length - 1), password),
      ),
      BackupFailures.wrongPasswordRule,
    );
    expect(
      await failureRule(() async => codec.readHeader(file.sublist(0, 6))),
      BackupFailures.invalidFileRule,
    );
  });

  test('files that are not backups are refused', () async {
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList(utf8.encode('just some text, long enough to try')),
      Uint8List.fromList([
        0x50,
        0x4B,
        0x03,
        0x04,
        1,
        0,
        0,
        0,
        5,
        1,
        2,
        3,
        4,
        5,
      ]),
    ]) {
      expect(
        await failureRule(() async => codec.readHeader(bytes)),
        BackupFailures.invalidFileRule,
      );
    }
  });

  test('a header that is not what it should be is refused', () async {
    final body = utf8.encode('{"backupVersion":1}');
    final file = BytesBuilder()
      ..add(ApbackupCodec.magic)
      ..addByte(1)
      ..add((ByteData(4)..setUint32(0, body.length)).buffer.asUint8List())
      ..add(body);

    expect(
      await failureRule(() async => codec.readHeader(file.takeBytes())),
      BackupFailures.invalidFileRule,
    );
  });

  test('a backup from a newer version says to update the app', () async {
    final newerBackup = await encoded(version: 2);
    final newerContainer = Uint8List.fromList(await encoded())..[4] = 2;

    expect(
      await failureRule(() async => codec.readHeader(newerBackup)),
      BackupFailures.newerFormatRule,
    );
    expect(
      await failureRule(() async => codec.readHeader(newerContainer)),
      BackupFailures.newerFormatRule,
    );
    expect(
      await failureRule(() => codec.decode(newerBackup, password)),
      BackupFailures.newerFormatRule,
    );
  });

  test('the work factor is recorded, so it can be raised later', () async {
    final slow = ApbackupCodec(iterations: 2000, inBackground: false);
    final file = await slow.encode(
      header: header(),
      snapshot: snapshot,
      password: password,
    );

    // Opened by a codec configured with a different factor.
    expect(await codec.decode(file, password), snapshot);
  });

  test('works on a background isolate too', () async {
    final background = ApbackupCodec(iterations: 1000);

    final file = await background.encode(
      header: header(),
      snapshot: snapshot,
      password: password,
    );

    expect(await background.decode(file, password), snapshot);
  });

  test('header JSON round trips', () {
    final json = headerToJson(header());

    expect(headerFromJson(json, supported: 1).companyName, 'Acme Ltd');
  });
  test(
    'the new cipher is authenticated before anything is decrypted',
    () async {
      final file = await encoded();
      final headerEnd = 9 + ByteData.sublistView(file, 5, 9).getUint32(0);

      for (final index in [
        headerEnd, // first byte of the data
        (headerEnd + file.length) ~/ 2, // the middle of the data
        file.length - 33, // last byte of the data
        file.length - 32, // first byte of the tag
        file.length - 1, // last byte of the tag
      ]) {
        expect(
          await failureRule(() => codec.decode(flipped(file, index), password)),
          BackupFailures.wrongPasswordRule,
          reason: 'byte $index',
        );
      }
    },
  );

  test('a file cut short inside the tag is refused', () async {
    final file = await encoded();
    final headerEnd = 9 + ByteData.sublistView(file, 5, 9).getUint32(0);

    expect(
      await failureRule(
        () => codec.decode(file.sublist(0, headerEnd + 10), password),
      ),
      BackupFailures.invalidFileRule,
    );
  });

  test(
    'backups made with the first cipher (AES-GCM) can still be read',
    () async {
      // Made by the first version of the app: 'legacy snapshot contents'.
      final legacy = base64.decode(
        'QVBCSwEAAAI3eyJmb3JtYXQiOiJhcGJhY2t1cCIsImJhY2t1cFZlcnNpb24iOjEsImFwcFZlcnNpb24iOiIwLjEuMCIsInNjaGVtYVZlcnNpb24iOjEwLCJjcmVhdGVkQXQiOiIyMDI2LTEwLTEyVDE1OjMwOjAwLjAwMFoiLCJraW5kIjoibWFudWFsIiwiY3JlYXRlZEJ5IjoiSmFuZSBPd25lciIsImRldmljZUlkIjoiZGV2aWNlLTEiLCJjb21wYW55SWQiOiJjb21wYW55LTEiLCJjb21wYW55TmFtZSI6IkFjbWUgTHRkIiwic3VtbWFyeSI6eyJlbXBsb3llZXMiOjMsImF0dGVuZGFuY2VFdmVudHMiOjEwLCJwYXlyb2xsUGVyaW9kcyI6MSwibGF0ZXN0QXR0ZW5kYW5jZUF0IjpudWxsfSwia2RmIjp7Im5hbWUiOiJwYmtkZjItaG1hYy1zaGEyNTYiLCJpdGVyYXRpb25zIjoxMDAwLCJzYWx0IjoiSjFYbFBDVzd5NWpPcUc4UGx2enlPQT09In0sImNpcGhlciI6eyJuYW1lIjoiYWVzLTI1Ni1nY20iLCJub25jZSI6Ik54eHdMZUk0UzhxR1ZkZGIifSwiY29tcHJlc3Npb24iOiJnemlwIiwic2hhMjU2IjoiZDhjYWI5ZDJkYzFmOWJmMjY3MGYwNGNkM2M0ZmU3NjVlMGQ0MjU5OTJiMzhmZTVlOWEyY2Q5MTIxN2Q0YmU5ZSJ9RAlpz9AAsmn4WbmvK1BfcXs+JAOoW5X9k3aZ0xWHTrDKLnf/pVntkjpl2mIVn070lF36H2FhHkcAUUsg',
      );

      expect(codec.readHeader(legacy).companyName, 'Acme Ltd');
      expect(
        utf8.decode(await codec.decode(legacy, 'legacy-pass-123')),
        'legacy snapshot contents',
      );
      expect(
        await failureRule(() => codec.decode(legacy, 'wrong-wrong')),
        BackupFailures.wrongPasswordRule,
      );
    },
  );

  test('encryption is fast enough for a large company', () async {
    // 16 MB of data: the first cipher needed about half a minute for this.
    final big = Uint8List.fromList(
      List.generate(16 * 1024 * 1024, (i) => (i * 31 + i ~/ 7) % 253),
    );
    final watch = Stopwatch()..start();

    final file = await codec.encode(
      header: header(),
      snapshot: big,
      password: password,
    );
    final back = await codec.decode(file, password);

    expect(back.length, big.length);
    expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
