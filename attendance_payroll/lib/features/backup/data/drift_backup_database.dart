import 'dart:io';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// [BackupDatabase] over the app's Drift database.
///
/// A snapshot is SQLite's own `VACUUM INTO`: a consistent copy taken while
/// the app keeps running. A restore never swaps the database file or
/// restarts the app: the snapshot (migrated to the current schema first) is
/// attached to the live connection and every company table is replaced from
/// it inside one transaction, so a failure at any point rolls everything
/// back and the data stays as it was.
final class DriftBackupDatabase implements BackupDatabase {
  DriftBackupDatabase(this._db, {required this._resolveTempDirectory});

  /// Tables that describe this device, not the company. A restore leaves
  /// them alone: the device keeps its identity, its kiosk mode, its printer
  /// and its backup routine, whatever the backup came from.
  static const Set<String> deviceTables = {
    'device_identity',
    'device_settings',
    'printer_settings',
    'backup_settings',
  };

  static const String _attached = 'restored';

  final AppDatabase _db;
  final Future<Directory> Function() _resolveTempDirectory;

  /// Table names of the company data (everything but [deviceTables]).
  List<String> get companyTables => [
    for (final table in _db.allTables)
      if (!deviceTables.contains(table.actualTableName)) table.actualTableName,
  ];

  @override
  Future<String?> currentCompanyId() async {
    final row = await _db
        .customSelect('SELECT id FROM companies ORDER BY created_at LIMIT 1')
        .getSingleOrNull();
    return row?.read<String>('id');
  }

  @override
  Future<DatabaseSnapshot> snapshot() async {
    final company = await _db
        .customSelect(
          'SELECT id, name FROM companies ORDER BY created_at LIMIT 1',
        )
        .getSingleOrNull();
    if (company == null) {
      throw BackupFailures.nothingToBackUp;
    }
    final summary = await _summaryOf(_LiveQueries(_db));
    final file = await _tempFile('snapshot');
    try {
      await _db.customStatement('VACUUM INTO ?', [file.path]);
      return DatabaseSnapshot(
        bytes: await file.readAsBytes(),
        schemaVersion: _db.schemaVersion,
        companyId: company.read<String>('id'),
        companyName: company.read<String>('name'),
        summary: summary,
      );
    } finally {
      await _delete(file);
    }
  }

  @override
  Future<BackupSummary> check(Uint8List snapshot) async {
    final file = await _tempFile('check');
    try {
      await file.writeAsBytes(snapshot, flush: true);
      return await _inspect(file);
    } finally {
      await _delete(file);
    }
  }

  @override
  Future<void> restore(
    Uint8List snapshot, {
    required Future<void> Function(String companyId) inside,
  }) async {
    final file = await _tempFile('restore');
    try {
      await file.writeAsBytes(snapshot, flush: true);
      await _inspect(file);
      await _migrate(file);
      await _replaceFrom(file, inside);
    } finally {
      await _delete(file);
    }
  }

  // Internals ----------------------------------------------------------

  /// Opens [file] on its own, checks it is a sound database of this app and
  /// not from a newer version, and counts what it holds.
  Future<BackupSummary> _inspect(File file) async {
    final sqlite.Database database;
    try {
      database = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
    } on sqlite.SqliteException {
      throw BackupFailures.invalidFile;
    }
    try {
      try {
        final version =
            database.select('PRAGMA user_version').first.values.first as int;
        if (version > _db.schemaVersion) {
          throw BackupFailures.newerSchema;
        }
        if (version < 1) {
          throw BackupFailures.invalidFile;
        }
        final integrity = database
            .select('PRAGMA integrity_check')
            .map((row) => row.values.first)
            .toList();
        if (integrity.length != 1 || integrity.first != 'ok') {
          throw BackupFailures.invalidFile;
        }
        return await _summaryOf(_SqliteQueries(database));
      } on sqlite.SqliteException {
        // Not a SQLite database after all.
        throw BackupFailures.invalidFile;
      }
    } finally {
      database.close();
    }
  }

  /// Brings an older snapshot up to the current schema, using the same
  /// tested migrations as an app update. A snapshot already at the current
  /// version is untouched.
  Future<void> _migrate(File file) async {
    // Drift warns about a second AppDatabase because two on one executor
    // could race. This one has a file of its own, so the warning is moot.
    final warned = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final copy = AppDatabase(NativeDatabase(file));
    try {
      // Opening runs the migration; the check proves it left a sound file.
      final integrity = await copy
          .customSelect('PRAGMA integrity_check')
          .map((row) => row.data.values.first)
          .get();
      if (integrity.length != 1 || integrity.first != 'ok') {
        throw BackupFailures.invalidFile;
      }
    } finally {
      await copy.close();
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = warned;
    }
  }

  Future<void> _replaceFrom(
    File file,
    Future<void> Function(String companyId) inside,
  ) async {
    await _db.customStatement('ATTACH DATABASE ? AS $_attached', [file.path]);
    try {
      await _db.transaction(() async {
        // Foreign keys are checked when the transaction commits, so tables
        // can be emptied and refilled in any order.
        await _db.customStatement('PRAGMA defer_foreign_keys = ON');
        final tables = companyTables;
        for (final table in tables) {
          await _db.customStatement('DELETE FROM main."$table"');
        }
        for (final table in tables) {
          final columns = await _sharedColumns(table);
          final list = columns.map((c) => '"$c"').join(', ');
          await _db.customStatement(
            'INSERT INTO main."$table" ($list) '
            'SELECT $list FROM $_attached."$table"',
          );
        }
        final broken = await _db.customSelect('PRAGMA foreign_key_check').get();
        if (broken.isNotEmpty) {
          throw BackupFailures.invalidFile;
        }
        final company = await _db
            .customSelect(
              'SELECT id FROM companies ORDER BY created_at LIMIT 1',
            )
            .getSingleOrNull();
        if (company == null) {
          throw BackupFailures.invalidFile;
        }
        await inside(company.read<String>('id'));
      });
    } finally {
      await _db.customStatement('DETACH DATABASE $_attached');
    }
    // Screens watching the data show the restored rows.
    _db.markTablesUpdated(_db.allTables);
  }

  /// The columns [table] has in the live database. The restored copy must
  /// have all of them, or the restore is refused.
  Future<List<String>> _sharedColumns(String table) async {
    Future<Set<String>> columnsOf(String schema) async => {
      for (final row
          in await _db
              .customSelect('PRAGMA $schema.table_info("$table")')
              .get())
        row.read<String>('name'),
    };

    final live = await columnsOf('main');
    final restored = await columnsOf(_attached);
    if (restored.isEmpty || !restored.containsAll(live)) {
      throw BackupFailures.invalidFile;
    }
    return live.toList();
  }

  Future<BackupSummary> _summaryOf(_Queries queries) async {
    Future<int> count(String table) async => await queries.tableExists(table)
        ? await queries.integer('SELECT count(*) FROM "$table"')
        : 0;

    final latest = await queries.tableExists('attendance_events')
        ? await queries.text('SELECT max(occurred_at) FROM attendance_events')
        : null;
    return BackupSummary(
      employees: await count('employees'),
      attendanceEvents: await count('attendance_events'),
      payrollPeriods: await count('payroll_periods'),
      latestAttendanceAt: latest == null
          ? null
          : DateTime.tryParse(latest)?.toUtc(),
    );
  }

  Future<File> _tempFile(String purpose) async {
    final directory = await _resolveTempDirectory();
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return File(
      '${directory.path}${Platform.pathSeparator}backup-$purpose-$stamp.db',
    );
  }

  Future<void> _delete(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// The few queries a summary needs, over the live database or a snapshot.
abstract interface class _Queries {
  Future<bool> tableExists(String table);

  Future<int> integer(String sql);

  Future<String?> text(String sql);
}

final class _LiveQueries implements _Queries {
  const _LiveQueries(this._db);

  final AppDatabase _db;

  @override
  Future<bool> tableExists(String table) async => true;

  @override
  Future<int> integer(String sql) async =>
      (await _db.customSelect(sql).getSingle()).data.values.first! as int;

  @override
  Future<String?> text(String sql) async =>
      (await _db.customSelect(sql).getSingle()).data.values.first as String?;
}

final class _SqliteQueries implements _Queries {
  const _SqliteQueries(this._database);

  final sqlite.Database _database;

  @override
  Future<bool> tableExists(String table) async => _database.select(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    [table],
  ).isNotEmpty;

  @override
  Future<int> integer(String sql) async =>
      _database.select(sql).first.values.first! as int;

  @override
  Future<String?> text(String sql) async =>
      _database.select(sql).first.values.first as String?;
}
