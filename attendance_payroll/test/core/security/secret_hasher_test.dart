import 'dart:convert';
import 'dart:typed_data';

import 'package:attendance_payroll/core/security/secret_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('PBKDF2-HMAC-SHA256 matches the RFC 7914 test vector', () {
    final key = derivePbkdf2(
      Pbkdf2Job(
        secret: 'passwd',
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 1,
        keyLength: 64,
      ),
    );

    expect(
      _hex(key),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
      '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
    );
  });

  group('SecretHasher', () {
    final hasher = SecretHasher(iterations: 3);

    test('hashes are self-describing and never contain the secret', () async {
      final encoded = await hasher.hash('2468');
      final parts = encoded.split(r'$');

      expect(parts, hasLength(4));
      expect(parts[0], SecretHasher.scheme);
      expect(parts[1], '3');
      expect(base64.decode(parts[2]), hasLength(SecretHasher.saltLength));
      expect(base64.decode(parts[3]), hasLength(SecretHasher.keyLength));
      expect(encoded, isNot(contains('2468')));
    });

    test('the same secret hashes differently each time', () async {
      expect(await hasher.hash('2468'), isNot(await hasher.hash('2468')));
    });

    test('verify accepts the right secret and rejects others', () async {
      final encoded = await hasher.hash('2468');

      expect(await hasher.verify('2468', encoded), isTrue);
      expect(await hasher.verify('2469', encoded), isFalse);
      expect(await hasher.verify('', encoded), isFalse);
    });

    test('verify uses the work factor stored in the hash', () async {
      final older = await SecretHasher(iterations: 1).hash('2468');

      expect(await hasher.verify('2468', older), isTrue);
    });

    test('malformed hashes never match', () async {
      for (final encoded in [
        '',
        'plain-text',
        r'md5$1$c2FsdA==$a2V5',
        r'pbkdf2-sha256$0$c2FsdA==$a2V5',
        r'pbkdf2-sha256$x$c2FsdA==$a2V5',
        r'pbkdf2-sha256$1$not base64$a2V5',
      ]) {
        expect(await hasher.verify('2468', encoded), isFalse, reason: encoded);
      }
    });

    test('verifyAgainstDummy completes', () async {
      await expectLater(hasher.verifyAgainstDummy('2468'), completes);
    });
  });
}
