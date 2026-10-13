import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The promises the app makes about itself (offline, nothing secret in logs,
/// secure randomness, no SQL built from text), checked against the source so
/// a later change cannot quietly break them. See docs/SECURITY.md.
void main() {
  /// Every Dart file under lib, except generated code, as (path, source).
  final sources = [
    for (final entity in Directory('lib').listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('.g.dart') &&
          !entity.path.endsWith('.steps.dart'))
        (
          path: entity.path.replaceAll(r'\', '/'),
          source: entity.readAsStringSync(),
        ),
  ];

  /// The source without comments, which may mention anything.
  String code(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  List<String> offenders(bool Function(String code) bad) => [
    for (final (:path, :source) in sources)
      if (bad(code(source))) path,
  ];

  test('the app never uses the network', () {
    final network = RegExp(
      r'HttpClient|package:http/|package:dio|WebSocket|Socket\.connect|'
      r'RawSocket|Uri\.https?\(|http://|https://',
    );

    // Links in documentation comments are fine; code is not.
    expect(offenders(network.hasMatch), isEmpty);
  });

  test('nothing is printed: output goes through the redacting logger', () {
    // A statement that starts with print( or any debugPrint(. (The printer's
    // own print method is not console output.)
    final output = RegExp(r'^\s*print\(|\bdebugPrint\(', multiLine: true);

    expect(offenders(output.hasMatch), isEmpty);
  });

  test('secrets use a cryptographically secure random source', () {
    for (final (:path, :source) in sources) {
      final unseeded = RegExp(r'Random\(\s*\)').allMatches(code(source));
      expect(unseeded, isEmpty, reason: '$path uses a predictable Random()');
    }
  });

  test('SQL is never built from text', () {
    // Statements are either constants or use bound parameters. The only
    // interpolation allowed is of table and schema names that come from the
    // schema itself, in the files listed here.
    const interpolatesSchemaNames = {
      'lib/features/backup/data/drift_backup_database.dart',
    };
    final sqlCall = RegExp(
      r'(customStatement|customSelect|customUpdate|customInsert|\.execute|\.select)\(\s*'
      r'(?:"[^"]*\$|'
      "'"
      r'[^'
      "'"
      r']*\$)',
    );

    final offending = [
      for (final (:path, :source) in sources)
        if (!interpolatesSchemaNames.contains(path) &&
            sqlCall.hasMatch(code(source)))
          path,
    ];

    expect(offending, isEmpty);
  });

  test('the database file is never read by anything but the data layer', () {
    // Presentation and domain code ask repositories; they never open SQLite.
    final offending = [
      for (final (:path, :source) in sources)
        if ((path.contains('/presentation/') || path.contains('/domain/')) &&
            RegExp(
              r'package:drift/|package:sqlite3/|AppDatabase',
            ).hasMatch(code(source)))
          path,
    ];

    expect(offending, isEmpty);
  });

  group('the Android manifest', () {
    late String manifest;

    setUpAll(() {
      manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
    });

    test('removes the network permission plugins bring in', () {
      expect(
        manifest,
        matches(
          RegExp(r'android\.permission\.INTERNET"\s+tools:node="remove"'),
        ),
      );
    });

    test('does not let Android copy the database to a Google account', () {
      expect(manifest, contains('android:allowBackup="false"'));
    });

    test('forbids clear-text traffic', () {
      expect(manifest, contains('android:usesCleartextTraffic="false"'));
    });

    test('asks only for the Bluetooth permissions printing needs', () {
      final permissions = RegExp(
        r'<uses-permission[^>]*android:name="([^"]+)"',
      ).allMatches(manifest).map((m) => m.group(1)).toSet();

      expect(permissions, {
        'android.permission.INTERNET', // present only to be removed
        'android.permission.BLUETOOTH',
        'android.permission.BLUETOOTH_ADMIN',
        'android.permission.BLUETOOTH_CONNECT',
        'android.permission.BLUETOOTH_SCAN',
      });
    });
  });

  test('release signing keys cannot be committed', () {
    final ignore = File('.gitignore').readAsStringSync();

    expect(ignore, contains('key.properties'));
    expect(ignore, contains('*.jks'));
    expect(ignore, contains('*.keystore'));
  });
  group('the application id', () {
    late String gradle;

    setUpAll(() {
      gradle = File('android/app/build.gradle.kts').readAsStringSync();
    });

    String valueOf(String key) =>
        RegExp('$key\\s*=\\s*"([^"]+)"').firstMatch(gradle)!.group(1)!;

    test('is the same in the namespace and the application id', () {
      expect(valueOf('applicationId'), valueOf('namespace'));
    });

    test('is a real id, not the template placeholder Play refuses', () {
      final id = valueOf('applicationId');

      expect(id, isNot(startsWith('com.example')));
      expect(id, matches(RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$')));
    });

    test('is the package of MainActivity, in the matching folder', () {
      final id = valueOf('applicationId');
      final folder = 'android/app/src/main/kotlin/${id.replaceAll('.', '/')}';

      final activity = File('$folder/MainActivity.kt');

      expect(
        activity.existsSync(),
        isTrue,
        reason: 'MainActivity.kt in $folder',
      );
      expect(activity.readAsStringSync(), contains('package $id'));
    });
  });
}
