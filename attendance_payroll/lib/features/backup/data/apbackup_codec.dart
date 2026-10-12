import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:attendance_payroll/features/backup/data/backup_header_json.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:pointycastle/export.dart';

/// The `.apbackup` file format, version 1.
///
/// ```
/// "APBK"            4 bytes   magic
/// container version 1 byte    layout of everything after it
/// header length     4 bytes   big-endian
/// header            JSON, readable without the password
/// encrypted data    AES-256-GCM of the gzip-compressed database
/// ```
///
/// The key comes from the backup password with PBKDF2-HMAC-SHA256 (salt and
/// work factor are in the header). The header is the GCM associated data, so
/// changing any byte of the header or the data makes decryption fail: a
/// damaged or tampered file is never half-read. The header also holds the
/// SHA-256 of the compressed database as an independent integrity check.
///
/// Key derivation, compression and encryption run on a background isolate so
/// a backup never freezes the screen.
final class ApbackupCodec implements BackupCodec {
  ApbackupCodec({
    this.iterations = defaultIterations,
    this.inBackground = true,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// PBKDF2 work factor for new backups. The file records the factor it was
  /// made with, so this can be raised without breaking old backups.
  static const int defaultIterations = 150000;

  static const List<int> magic = [0x41, 0x50, 0x42, 0x4B];
  static const int containerVersion = 1;
  static const int _fixedBytes = 9;
  static const int _keyLength = 32;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _tagBits = 128;

  final int iterations;
  final bool inBackground;
  final Random _random;

  Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));

  @override
  BackupHeader readHeader(Uint8List file) {
    final (:json, headerEnd: _) = _parse(file);
    return headerFromJson(json, supported: _supportedVersion);
  }

  @override
  Future<Uint8List> encode({
    required BackupHeader header,
    required Uint8List snapshot,
    required String password,
  }) {
    final job = _EncodeJob(
      header: headerToJson(header),
      snapshot: snapshot,
      password: password,
      iterations: iterations,
      salt: _randomBytes(_saltLength),
      nonce: _randomBytes(_nonceLength),
    );
    return _run(_encode, job);
  }

  @override
  Future<Uint8List> decode(Uint8List file, String password) {
    // Fail on a bad or newer file before spending time on the key.
    readHeader(file);
    return _run(_decode, _DecodeJob(file: file, password: password));
  }

  Future<R> _run<J, R>(R Function(J job) work, J job) {
    return inBackground
        ? Isolate.run(() => work(job))
        : Future(() => work(job));
  }

  static const int _supportedVersion = 1;
}

/// The header JSON of [file] and where the encrypted data starts.
({Map<String, Object?> json, int headerEnd}) _parse(Uint8List file) {
  if (file.length < ApbackupCodec._fixedBytes || !_startsWithMagic(file)) {
    throw BackupFailures.invalidFile;
  }
  if (file[4] > ApbackupCodec.containerVersion) {
    throw BackupFailures.newerFormat;
  }
  final length = ByteData.sublistView(file, 5, 9).getUint32(0);
  final end = ApbackupCodec._fixedBytes + length;
  if (length == 0 || end > BackupCodec.headerPrefixBytes || end > file.length) {
    throw BackupFailures.invalidFile;
  }
  try {
    final decoded = jsonDecode(
      utf8.decode(file.sublist(ApbackupCodec._fixedBytes, end)),
    );
    if (decoded is! Map<String, Object?>) {
      throw BackupFailures.invalidFile;
    }
    return (json: decoded, headerEnd: end);
  } on FormatException {
    throw BackupFailures.invalidFile;
  }
}

bool _startsWithMagic(Uint8List file) {
  for (var i = 0; i < ApbackupCodec.magic.length; i++) {
    if (file[i] != ApbackupCodec.magic[i]) {
      return false;
    }
  }
  return true;
}

String _sha256Hex(Uint8List bytes) => SHA256Digest()
    .process(bytes)
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join();

Uint8List _deriveKey(String password, Uint8List salt, int iterations) =>
    derivePbkdf2(
      Pbkdf2Job(
        secret: password,
        salt: salt,
        iterations: iterations,
        keyLength: ApbackupCodec._keyLength,
      ),
    );

GCMBlockCipher _cipher({
  required bool encrypt,
  required Uint8List key,
  required Uint8List nonce,
  required Uint8List headerBytes,
}) => GCMBlockCipher(AESEngine())
  ..init(
    encrypt,
    AEADParameters(
      KeyParameter(key),
      ApbackupCodec._tagBits,
      nonce,
      headerBytes,
    ),
  );

final class _EncodeJob {
  const _EncodeJob({
    required this.header,
    required this.snapshot,
    required this.password,
    required this.iterations,
    required this.salt,
    required this.nonce,
  });

  final Map<String, Object?> header;
  final Uint8List snapshot;
  final String password;
  final int iterations;
  final Uint8List salt;
  final Uint8List nonce;
}

final class _DecodeJob {
  const _DecodeJob({required this.file, required this.password});

  final Uint8List file;
  final String password;
}

Uint8List _encode(_EncodeJob job) {
  final compressed = Uint8List.fromList(gzip.encode(job.snapshot));
  final headerBytes = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'format': 'apbackup',
        ...job.header,
        'kdf': {
          'name': 'pbkdf2-hmac-sha256',
          'iterations': job.iterations,
          'salt': base64.encode(job.salt),
        },
        'cipher': {'name': 'aes-256-gcm', 'nonce': base64.encode(job.nonce)},
        'compression': 'gzip',
        'sha256': _sha256Hex(compressed),
      }),
    ),
  );
  final key = _deriveKey(job.password, job.salt, job.iterations);
  final encrypted = _cipher(
    encrypt: true,
    key: key,
    nonce: job.nonce,
    headerBytes: headerBytes,
  ).process(compressed);

  final out = BytesBuilder(copy: false)
    ..add(ApbackupCodec.magic)
    ..addByte(ApbackupCodec.containerVersion)
    ..add((ByteData(4)..setUint32(0, headerBytes.length)).buffer.asUint8List())
    ..add(headerBytes)
    ..add(encrypted);
  return out.takeBytes();
}

Uint8List _decode(_DecodeJob job) {
  final (:json, :headerEnd) = _parse(job.file);
  final headerBytes = Uint8List.sublistView(
    job.file,
    ApbackupCodec._fixedBytes,
    headerEnd,
  );
  final kdf = json['kdf'];
  final cipher = json['cipher'];
  final expected = json['sha256'];
  if (kdf is! Map<String, Object?> ||
      cipher is! Map<String, Object?> ||
      expected is! String ||
      kdf['name'] != 'pbkdf2-hmac-sha256' ||
      cipher['name'] != 'aes-256-gcm' ||
      json['compression'] != 'gzip') {
    throw BackupFailures.invalidFile;
  }
  final iterations = kdf['iterations'];
  final salt = kdf['salt'];
  final nonce = cipher['nonce'];
  if (iterations is! int ||
      iterations < 1 ||
      salt is! String ||
      nonce is! String) {
    throw BackupFailures.invalidFile;
  }
  final Uint8List saltBytes;
  final Uint8List nonceBytes;
  try {
    saltBytes = base64.decode(salt);
    nonceBytes = base64.decode(nonce);
  } on FormatException {
    throw BackupFailures.invalidFile;
  }
  final key = _deriveKey(job.password, saltBytes, iterations);
  final Uint8List compressed;
  try {
    compressed = _cipher(
      encrypt: false,
      key: key,
      nonce: nonceBytes,
      headerBytes: headerBytes,
    ).process(Uint8List.sublistView(job.file, headerEnd));
  } on InvalidCipherTextException {
    // Wrong password, or a changed byte anywhere in the file: GCM cannot
    // tell them apart, and neither should the message.
    throw BackupFailures.wrongPassword;
  } on ArgumentError {
    throw BackupFailures.invalidFile;
  }
  if (_sha256Hex(compressed) != expected) {
    throw BackupFailures.invalidFile;
  }
  try {
    return Uint8List.fromList(gzip.decode(compressed));
  } on FormatException {
    throw BackupFailures.invalidFile;
  }
}
