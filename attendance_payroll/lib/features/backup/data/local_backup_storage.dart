import 'dart:io';
import 'dart:typed_data';

import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/backup/domain/backup_failures.dart';
import 'package:attendance_payroll/features/backup/domain/backup_models.dart';
import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';

/// [BackupStorage] in a folder of the app's private storage. Other apps
/// cannot read it, and the files are encrypted anyway.
final class LocalBackupStorage implements BackupStorage {
  LocalBackupStorage(this._resolveDirectory);

  static const String extension = '.apbackup';
  static const String _partial = '.partial';

  /// Where backups live; created on first use.
  final Future<Directory> Function() _resolveDirectory;

  Future<Directory> _directory() async {
    final directory = await _resolveDirectory();
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// The file called [name]; names that could point outside the folder are
  /// refused.
  Future<File> _file(String name) async {
    final valid =
        RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name) &&
        !name.contains('..') &&
        name.endsWith(extension);
    if (!valid) {
      throw BackupFailures.invalidFile;
    }
    return File('${(await _directory()).path}${Platform.pathSeparator}$name');
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } on PathNotFoundException {
      throw const NotFoundFailure(entity: 'backup');
    } on FileSystemException catch (error) {
      throw BackupFailures.storageFailed(error);
    }
  }

  @override
  Future<List<StoredBackupFile>> list() {
    return _guard(() async {
      final files = <StoredBackupFile>[];
      await for (final entity in (await _directory()).list()) {
        if (entity is! File || !entity.path.endsWith(extension)) {
          continue;
        }
        final stat = await entity.stat();
        files.add(
          StoredBackupFile(
            name: entity.uri.pathSegments.last,
            sizeBytes: stat.size,
            modifiedAt: stat.modified.toUtc(),
          ),
        );
      }
      return files;
    });
  }

  @override
  Future<Uint8List> readPrefix(String name, int maxBytes) {
    return _guard(() async {
      final handle = await (await _file(name)).open();
      try {
        return await handle.read(maxBytes);
      } finally {
        await handle.close();
      }
    });
  }

  @override
  Future<Uint8List> read(String name) {
    return _guard(() async => (await _file(name)).readAsBytes());
  }

  @override
  Future<void> write(String name, Uint8List bytes) {
    return _guard(() async {
      final target = await _file(name);
      // Written under another name and renamed when complete, so a crash or
      // a full disk never leaves a half-written backup that looks real.
      final partial = File('${target.path}$_partial');
      try {
        await partial.writeAsBytes(bytes, flush: true);
        await partial.rename(target.path);
      } on Object {
        if (partial.existsSync()) {
          await partial.delete();
        }
        rethrow;
      }
    });
  }

  @override
  Future<void> delete(String name) {
    return _guard(() async {
      final file = await _file(name);
      if (file.existsSync()) {
        await file.delete();
      }
    });
  }
}
