import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewAdminUser', () {
    test('normalized lower-cases and trims the username', () {
      const user = NewAdminUser(username: '  Admin.One ', displayName: ' A ');

      final normalized = user.normalized();

      expect(normalized.username, 'admin.one');
      expect(normalized.displayName, 'A');
      expect(normalized.validate(), isNull);
    });

    test('rejects usernames that are too short or contain spaces', () {
      for (final username in ['ab', 'has space', 'x' * 33]) {
        final user = NewAdminUser(username: username, displayName: 'Admin');

        expect(user.validate()?.field, 'username', reason: username);
      }
    });

    test('requires a display name', () {
      const user = NewAdminUser(username: 'admin', displayName: ' ');

      expect(user.validate()?.field, 'displayName');
    });
  });
}
