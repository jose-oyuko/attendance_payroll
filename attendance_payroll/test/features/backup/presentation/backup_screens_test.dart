import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/backup/data/backup_providers.dart';
import 'package:attendance_payroll/features/backup/data/drift_backup_database.dart';
import 'package:attendance_payroll/features/backup/presentation/backup_view_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_backups.dart';
import '../../../support/pump_app.dart';
import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

/// Lets real work finish. File and database work runs on the real event
/// loop, outside the test's fake time, so real time and frames alternate
/// until [until] holds (or, without it, for a short fixed time). A few plain
/// frames then finish dialogs and snack bars. `pumpAndSettle` is not used:
/// other tabs of the app keep reloading after a restore, so the app never
/// goes quiet.
Future<void> _work(WidgetTester tester, {bool Function()? until}) async {
  final rounds = until == null ? 8 : 400;
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (until != null && until()) {
      break;
    }
  }
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (until != null) {
    expect(
      until(),
      isTrue,
      reason:
          'The work did not finish in time. On screen: '
          '${_screenText()}',
    );
  }
}

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool Function()? until,
}) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _work(tester, until: until);
}

/// Everything written on screen, for the message of a failed wait.
String _screenText() => find
    .byType(Text)
    .evaluate()
    .map((e) => (e.widget as Text).data)
    .whereType<String>()
    .map((t) => t.replaceAll(RegExp(r'\s+'), ' '))
    .join(' | ');

bool Function() _shown(String text) =>
    () => find.text(text).evaluate().isNotEmpty;

/// The backup providers over the app's own database, with files in memory.
class _Fixture {
  _Fixture(this.temp) : db = openTestDatabase();

  final Directory temp;
  final AppDatabase db;
  final InMemoryBackupStorage storage = InMemoryBackupStorage();
  final InMemorySecretStore secrets = InMemorySecretStore();
  final List<({String name, Uint8List bytes})> shared = [];
  Uint8List? picked;

  List<Override> get overrides => [
    backupStorageProvider.overrideWithValue(storage),
    backupSecretStoreProvider.overrideWithValue(secrets),
    backupCodecProvider.overrideWithValue(fastCodec()),
    backupDatabaseProvider.overrideWithValue(
      DriftBackupDatabase(db, resolveTempDirectory: () async => temp),
    ),
    backupFilePickerProvider.overrideWithValue(() async => picked),
    backupFileSharerProvider.overrideWithValue((name, bytes) async {
      shared.add((name: name, bytes: bytes));
    }),
  ];

  Future<int> employees() async =>
      (await db.customSelect('SELECT count(*) AS c FROM employees').getSingle())
          .read<int>('c');
}

void main() {
  late Directory temp;
  late _Fixture fixture;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('backup-screens-test');
    addTearDown(() => temp.deleteSync(recursive: true));
    fixture = _Fixture(temp);
  });

  Future<ProviderContainer> openApp(
    WidgetTester tester, {
    Size size = tabletSize,
    bool signedIn = true,
  }) => pumpApp(
    tester,
    size: size,
    signedIn: signedIn,
    database: fixture.db,
    overrides: fixture.overrides,
  );

  Future<ProviderContainer> openBackups(
    WidgetTester tester, {
    Size size = tabletSize,
  }) async {
    final c = await openApp(tester, size: size);
    if (size == phoneSize) {
      await _tap(tester, find.byTooltip('Open navigation menu'));
    }
    await _tap(tester, find.text('Backup'));
    return c;
  }

  /// A signed-in app with one backup already made (the password is set
  /// after opening, so the shell's own automatic backup stays out of it).
  Future<ProviderContainer> openWithOneBackup(WidgetTester tester) async {
    final c = await openApp(tester);
    fixture.secrets.password = 'my backup password';
    final session = c.read(adminSessionProvider)!;
    await tester.runAsync(() => c.read(backupServiceProvider).create(session));
    await _tap(tester, find.text('Backup'));
    return c;
  }

  /// A backup made on another device, as a file.
  Future<Uint8List> backupFromAnotherDevice(WidgetTester tester) async {
    final other = BackupTestDevice(TestEnv(), temp);
    final session = (await tester.runAsync(other.env.setUpOwner))!;
    await tester.runAsync(() => other.env.addEmployee(session));
    final info = (await tester.runAsync(
      () => other.service.create(session),
    ))!.unwrap();
    return other.storage.files[info.fileName]!;
  }

  testWidgets('starts empty and asks for a password before the first backup', (
    tester,
  ) async {
    await openBackups(tester);

    expect(find.text('No backup yet'), findsOneWidget);
    expect(find.textContaining('No backups yet'), findsOneWidget);
    expect(find.text('Set backup password'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'Back up now'));
    expect(find.text('Set a backup password'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Backup password'),
      'short',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm the password'),
      'different',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Save password'));
    expect(find.textContaining('at least 8'), findsOneWidget);
    expect(find.text('The passwords differ.'), findsOneWidget);
    expect(fixture.secrets.password, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Backup password'),
      'my backup password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm the password'),
      'my backup password',
    );
    // The password is saved and the backup is made straight away.
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Save password'),
      until: () => fixture.storage.files.isNotEmpty,
    );
    await _work(tester);

    expect(fixture.secrets.password, 'my backup password');
    expect(fixture.storage.files, hasLength(1));
    expect(find.text('No backup yet'), findsNothing);
    expect(find.textContaining('Manual ·'), findsOneWidget);
    expect(find.text('Change backup password'), findsOneWidget);
  });

  testWidgets('exports a backup through the share sheet', (tester) async {
    await openWithOneBackup(tester);

    await _tap(tester, find.byTooltip('Backup actions').first);
    await _tap(
      tester,
      find.text('Export'),
      until: () => fixture.shared.isNotEmpty,
    );

    final name = fixture.storage.files.keys.single;
    expect(fixture.shared.single.name, name);
    expect(fixture.shared.single.bytes, fixture.storage.files[name]);
  });

  testWidgets('deletes a backup after confirmation', (tester) async {
    await openWithOneBackup(tester);

    await _tap(tester, find.byTooltip('Backup actions').first);
    await _tap(tester, find.text('Delete'));
    expect(find.text('Delete this backup?'), findsOneWidget);
    await _tap(tester, find.text('Cancel'));
    expect(fixture.storage.files, hasLength(1));

    await _tap(tester, find.byTooltip('Backup actions').first);
    await _tap(tester, find.text('Delete'));
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Delete'),
      until: () => fixture.storage.files.isEmpty,
    );
    await _work(tester);

    expect(find.textContaining('No backups yet'), findsOneWidget);
  });

  testWidgets('restoring a backup replaces the data and signs out', (
    tester,
  ) async {
    final c = await openWithOneBackup(tester);
    final session = c.read(adminSessionProvider)!;
    await tester.runAsync(
      () => c
          .read(employeeManagementServiceProvider)
          .create(session, johnDetails()),
    );
    expect(await tester.runAsync(fixture.employees), 1);

    await _tap(tester, find.byTooltip('Backup actions').first);
    await _tap(tester, find.text('Restore'));

    // The consequence is spelled out before anything happens.
    expect(find.text('Replace all data?'), findsOneWidget);
    expect(find.textContaining('safety backup'), findsOneWidget);
    expect(find.text('Acme Ltd'), findsOneWidget);

    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Restore'),
      until: _shown('Backup restored'),
    );
    await _tap(tester, find.text('Continue'));

    expect(await tester.runAsync(fixture.employees), 0);
    // Back at sign-in, where the restored administrators can sign in.
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Reports'), findsNothing);
    expect(
      fixture.storage.files.keys.where((n) => n.endsWith('-safety.apbackup')),
      hasLength(1),
    );
  });

  testWidgets('a backup file needs its password to be restored', (
    tester,
  ) async {
    fixture.picked = await backupFromAnotherDevice(tester);
    await openBackups(tester);

    await _tap(tester, find.text('Choose backup file'));
    expect(find.text('Replace all data?'), findsOneWidget);
    // Another company: replacing this one needs an explicit yes.
    expect(find.textContaining('different company'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Restore'))
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password of this backup'),
      'not the password',
    );
    await _tap(tester, find.byType(Checkbox));
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Restore'),
      until: () =>
          find.textContaining('password is wrong').evaluate().isNotEmpty,
    );
    expect(await tester.runAsync(fixture.employees), 0);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password of this backup'),
      'backup-pass-123',
    );
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Restore'),
      until: _shown('Backup restored'),
    );
    await _tap(tester, find.text('Continue'));

    expect(await tester.runAsync(fixture.employees), 1);
  });

  testWidgets('a file that is not a backup is refused with a message', (
    tester,
  ) async {
    fixture.picked = Uint8List.fromList(List.filled(100, 5));
    await openBackups(tester);

    await _tap(tester, find.text('Choose backup file'));

    expect(find.textContaining('not a valid backup'), findsOneWidget);
    expect(find.text('Replace all data?'), findsNothing);
  });

  testWidgets('choosing no file does nothing', (tester) async {
    await openBackups(tester);

    await _tap(tester, find.text('Choose backup file'));

    expect(find.text('Replace all data?'), findsNothing);
  });

  testWidgets('settings are saved as they are changed', (tester) async {
    await openBackups(tester);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await _tap(tester, find.byType(SwitchListTile));
    await _work(tester);

    final row = await tester.runAsync(
      () => fixture.db
          .customSelect('SELECT automatic_enabled AS a FROM backup_settings')
          .getSingle(),
    );
    expect(row!.read<bool>('a'), isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('works on a phone', (tester) async {
    await openBackups(tester, size: phoneSize);

    expect(find.text('No backup yet'), findsOneWidget);
    expect(find.text('Restore from a file'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new installation can restore instead of setting up', (
    tester,
  ) async {
    fixture.picked = await backupFromAnotherDevice(tester);
    await openApp(tester, signedIn: false);
    expect(find.text('Set up your company'), findsOneWidget);

    await _tap(tester, find.text('Restore from a backup instead'));
    expect(find.text('Restore this backup?'), findsOneWidget);
    // Nothing exists yet, so there is no warning about replacing data.
    expect(find.textContaining('safety backup'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password of this backup'),
      'backup-pass-123',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Restore'))
          .onPressed,
      isNotNull,
      reason: 'Restore should be enabled once a password is typed',
    );
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Restore'),
      until: _shown('Backup restored'),
    );
    await _tap(tester, find.text('Continue'));

    // The restored company exists, so setup is over: its owner signs in.
    expect(await tester.runAsync(fixture.employees), 1);
    expect(find.text('Set up your company'), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('the automatic backup is made when the app is opened', (
    tester,
  ) async {
    fixture.secrets.password = 'my backup password';
    await openApp(tester);

    await _work(
      tester,
      until: () => fixture.storage.files.keys.any(
        (n) => n.endsWith('-automatic.apbackup'),
      ),
    );

    expect(fixture.storage.files, hasLength(1));
  });
}
