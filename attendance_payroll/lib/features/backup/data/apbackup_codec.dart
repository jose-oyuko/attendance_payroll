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
/// encrypted data    AES-256-CTR of the gzip-compressed database
/// tag               32 bytes  HMAC-SHA256 over the header and the data
/// ```
///
/// Encrypt-then-MAC: a master key comes from the backup password with
/// PBKDF2-HMAC-SHA256 (salt and work factor are in the header), and an
/// encryption key and a separate MAC key are derived from it. The tag covers
/// the header length, the header and the encrypted data and is checked, in
/// constant time, **before** anything is decrypted, so a damaged or tampered
/// file (or a wrong password) is rejected without being half-read. The header
/// also holds the SHA-256 of the compressed database as an independent
/// integrity check.
///
/// This replaced AES-GCM, whose authentication step is about thirty times
/// slower in pure Dart (minutes for a large company on a phone). Files made
/// with the GCM cipher are still read.
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

  /// The cipher of new backups.
  static const String ctrHmacCipher = 'aes-256-ctr-hmac-sha256';

  /// The cipher of the first backups of the app, still readable.
  static const String gcmCipher = 'aes-256-gcm';

  /// The secret behind "standard protection": backups the administrator did
  /// not protect with a password. It is public on purpose (it is in the app
  /// and in this file): it makes the file unreadable as a plain database and
  /// tamper-evident, but anyone with the app can open such a backup. A
  /// password is what keeps a backup private from someone who has the file.
  static const String standardSecret =
      'attendance-payroll/standard-protection/v1';

  static const int _fixedBytes = 9;
  static const int _keyLength = 32;
  static const int _saltLength = 16;
  static const int _ivLength = 16;
  static const int _macLength = 32;
  static const int _gcmTagBits = 128;

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
    String? password,
  }) {
    final secret = header.passwordProtected
        ? (password ?? (throw BackupFailures.noPassword))
        : standardSecret;
    final job = _EncodeJob(
      header: headerToJson(header),
      snapshot: snapshot,
      password: secret,
      iterations: iterations,
      salt: _randomBytes(_saltLength),
      iv: _randomBytes(_ivLength),
    );
    return _run(_encode, job);
  }

  @override
  Future<Uint8List> decode(Uint8List file, String? password) {
    // Fail on a bad or newer file before spending time on the key.
    final header = readHeader(file);
    final secret = header.passwordProtected
        ? (password ?? (throw BackupFailures.noPassword))
        : standardSecret;
    return _run(_decode, _DecodeJob(file: file, password: secret));
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

Uint8List _masterKey(String password, Uint8List salt, int iterations) =>
    derivePbkdf2(
      Pbkdf2Job(
        secret: password,
        salt: salt,
        iterations: iterations,
        keyLength: ApbackupCodec._keyLength,
      ),
    );

/// HMAC-SHA256 of the concatenation of [parts].
Uint8List _hmac(Uint8List key, List<Uint8List> parts) {
  final mac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
  for (final part in parts) {
    mac.update(part, 0, part.length);
  }
  final out = Uint8List(mac.macSize);
  mac.doFinal(out, 0);
  return out;
}

/// The encryption key and the MAC key, from the master key. Separate keys
/// for separate purposes, so neither can be confused for the other.
({Uint8List encryption, Uint8List mac}) _subKeys(Uint8List master) => (
  encryption: _hmac(master, [Uint8List.fromList(utf8.encode('apbackup enc'))]),
  mac: _hmac(master, [Uint8List.fromList(utf8.encode('apbackup mac'))]),
);

Uint8List _ctr(Uint8List key, Uint8List iv, Uint8List data) => (CTRStreamCipher(
  AESEngine(),
)..init(true, ParametersWithIV(KeyParameter(key), iv))).process(data);

/// The tag over the length of the header, the header and the data.
Uint8List _tag(Uint8List macKey, Uint8List header, Uint8List data) =>
    _hmac(macKey, [
      (ByteData(4)..setUint32(0, header.length)).buffer.asUint8List(),
      header,
      data,
    ]);

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}

final class _EncodeJob {
  const _EncodeJob({
    required this.header,
    required this.snapshot,
    required this.password,
    required this.iterations,
    required this.salt,
    required this.iv,
  });

  final Map<String, Object?> header;
  final Uint8List snapshot;
  final String password;
  final int iterations;
  final Uint8List salt;
  final Uint8List iv;
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
        'cipher': {
          'name': ApbackupCodec.ctrHmacCipher,
          'iv': base64.encode(job.iv),
        },
        'compression': 'gzip',
        'sha256': _sha256Hex(compressed),
      }),
    ),
  );
  final keys = _subKeys(_masterKey(job.password, job.salt, job.iterations));
  final encrypted = _ctr(keys.encryption, job.iv, compressed);

  final out = BytesBuilder(copy: false)
    ..add(ApbackupCodec.magic)
    ..addByte(ApbackupCodec.containerVersion)
    ..add((ByteData(4)..setUint32(0, headerBytes.length)).buffer.asUint8List())
    ..add(headerBytes)
    ..add(encrypted)
    ..add(_tag(keys.mac, headerBytes, encrypted));
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
      json['compression'] != 'gzip') {
    throw BackupFailures.invalidFile;
  }
  final iterations = kdf['iterations'];
  final salt = kdf['salt'];
  if (iterations is! int || iterations < 1 || salt is! String) {
    throw BackupFailures.invalidFile;
  }
  final body = Uint8List.sublistView(job.file, headerEnd);
  final Uint8List compressed;
  try {
    final master = _masterKey(job.password, base64.decode(salt), iterations);
    compressed = switch (cipher['name']) {
      ApbackupCodec.ctrHmacCipher => _openCtr(
        master,
        cipher,
        headerBytes,
        body,
      ),
      ApbackupCodec.gcmCipher => _openGcm(master, cipher, headerBytes, body),
      _ => throw BackupFailures.invalidFile,
    };
  } on FormatException {
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

/// The current cipher: the tag is checked first, then the data is decrypted.
Uint8List _openCtr(
  Uint8List master,
  Map<String, Object?> cipher,
  Uint8List headerBytes,
  Uint8List body,
) {
  final iv = cipher['iv'];
  if (iv is! String || body.length < ApbackupCodec._macLength) {
    throw BackupFailures.invalidFile;
  }
  final ivBytes = base64.decode(iv);
  if (ivBytes.length != ApbackupCodec._ivLength) {
    throw BackupFailures.invalidFile;
  }
  final keys = _subKeys(master);
  final split = body.length - ApbackupCodec._macLength;
  final data = Uint8List.sublistView(body, 0, split);
  final tag = Uint8List.sublistView(body, split);
  // A wrong password and a changed byte anywhere give a different tag; the
  // two cannot be told apart, and neither should the message.
  if (!_sameBytes(_tag(keys.mac, headerBytes, data), tag)) {
    throw BackupFailures.wrongPassword;
  }
  return _ctr(keys.encryption, ivBytes, data);
}

/// The cipher of the first backups (AES-256-GCM), kept readable.
Uint8List _openGcm(
  Uint8List master,
  Map<String, Object?> cipher,
  Uint8List headerBytes,
  Uint8List body,
) {
  final nonce = cipher['nonce'];
  if (nonce is! String) {
    throw BackupFailures.invalidFile;
  }
  try {
    return (GCMBlockCipher(AESEngine())..init(
          false,
          AEADParameters(
            KeyParameter(master),
            ApbackupCodec._gcmTagBits,
            base64.decode(nonce),
            headerBytes,
          ),
        ))
        .process(body);
  } on InvalidCipherTextException {
    throw BackupFailures.wrongPassword;
  } on ArgumentError {
    throw BackupFailures.invalidFile;
  }
}
