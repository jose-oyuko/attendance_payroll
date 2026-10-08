import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Inputs to one PBKDF2 derivation. Plain data, so it can be sent to a
/// background isolate.
final class Pbkdf2Job {
  const Pbkdf2Job({
    required this.secret,
    required this.salt,
    required this.iterations,
    required this.keyLength,
  });

  final String secret;
  final Uint8List salt;
  final int iterations;
  final int keyLength;
}

/// PBKDF2-HMAC-SHA256 (RFC 8018). Top-level so it can run on another isolate.
Uint8List derivePbkdf2(Pbkdf2Job job) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
    ..init(Pbkdf2Parameters(job.salt, job.iterations, job.keyLength));
  return derivator.process(Uint8List.fromList(utf8.encode(job.secret)));
}

/// Runs a derivation. The app runs it on a background isolate so hashing never
/// blocks the UI; tests run it inline.
typedef Pbkdf2Executor = Future<Uint8List> Function(Pbkdf2Job job);

Future<Uint8List> derivePbkdf2Inline(Pbkdf2Job job) async => derivePbkdf2(job);

/// Hashes and verifies PINs and passwords. Plain secrets are never stored.
///
/// Each hash is self-describing: verification reads the work factor from the
/// hash itself, so it can be raised later without invalidating old hashes.
///
/// `pbkdf2-sha256$<iterations>$<salt, base64>$<key, base64>`
final class SecretHasher {
  SecretHasher({
    required this.iterations,
    this._executor = derivePbkdf2Inline,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const String scheme = 'pbkdf2-sha256';
  static const int saltLength = 16;
  static const int keyLength = 32;

  /// PBKDF2 work factor for new hashes.
  final int iterations;
  final Pbkdf2Executor _executor;
  final Random _random;

  Future<String>? _dummyHash;

  /// Hashes [secret] with a fresh random salt.
  Future<String> hash(String secret) async {
    final salt = Uint8List.fromList(
      List<int>.generate(saltLength, (_) => _random.nextInt(256)),
    );
    final key = await _executor(
      Pbkdf2Job(
        secret: secret,
        salt: salt,
        iterations: iterations,
        keyLength: keyLength,
      ),
    );
    return [
      scheme,
      iterations,
      base64.encode(salt),
      base64.encode(key),
    ].join(r'$');
  }

  /// Whether [secret] matches [encoded]. A malformed hash never matches.
  Future<bool> verify(String secret, String encoded) async {
    final parsed = _ParsedHash.tryParse(encoded);
    if (parsed == null) {
      return false;
    }
    final key = await _executor(
      Pbkdf2Job(
        secret: secret,
        salt: parsed.salt,
        iterations: parsed.iterations,
        keyLength: parsed.key.length,
      ),
    );
    return _constantTimeEquals(key, parsed.key);
  }

  /// Spends the same time as a real [verify] and always fails. Used when the
  /// account does not exist, so response time does not reveal that.
  Future<void> verifyAgainstDummy(String secret) async {
    final dummy = await (_dummyHash ??= hash('dummy-secret'));
    await verify(secret, dummy);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}

final class _ParsedHash {
  const _ParsedHash(this.iterations, this.salt, this.key);

  final int iterations;
  final Uint8List salt;
  final Uint8List key;

  static _ParsedHash? tryParse(String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != SecretHasher.scheme) {
      return null;
    }
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) {
      return null;
    }
    try {
      final salt = base64.decode(parts[2]);
      final key = base64.decode(parts[3]);
      if (salt.isEmpty || key.isEmpty) {
        return null;
      }
      return _ParsedHash(iterations, salt, key);
    } on FormatException {
      return null;
    }
  }
}
