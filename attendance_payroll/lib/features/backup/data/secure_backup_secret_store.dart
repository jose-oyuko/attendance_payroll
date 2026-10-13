import 'package:attendance_payroll/features/backup/domain/backup_ports.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [BackupSecretStore] in the platform's secure storage (the Android
/// Keystore), outside the database and out of backups.
final class SecureBackupSecretStore implements BackupSecretStore {
  const SecureBackupSecretStore([this._storage = const FlutterSecureStorage()]);

  static const String _key = 'backup_password';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on Object {
      // Secure storage can be unreadable after a device restore (the key
      // that protected it is gone). That is the same as no password: the
      // administrator sets a new one.
      return null;
    }
  }

  @override
  Future<void> write(String password) =>
      _storage.write(key: _key, value: password);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
