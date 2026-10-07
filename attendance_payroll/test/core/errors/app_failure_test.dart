import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('from returns an existing failure unchanged', () {
      const failure = PermissionFailure();

      expect(AppFailure.from(failure), same(failure));
    });

    test('from wraps unknown errors as UnexpectedFailure', () {
      final error = StateError('SqliteException: UNIQUE constraint failed');
      final trace = StackTrace.current;

      final failure = AppFailure.from(error, trace);

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.cause, same(error));
      expect(failure.stackTrace, same(trace));
    });

    test('user messages never contain the technical cause', () {
      final failure = AppFailure.from(
        StateError('SqliteException: UNIQUE constraint failed'),
      );

      expect(failure.userMessage, isNot(contains('Sqlite')));
      expect(failure.toString(), isNot(contains('Sqlite')));
    });

    test('subclasses expose stable codes and sensible messages', () {
      expect(const ValidationFailure(userMessage: 'Bad.').code, 'validation');
      expect(const ConflictFailure(userMessage: 'Dup.').code, 'conflict');
      expect(const AuthenticationFailure().code, 'authentication');
      expect(const PermissionFailure().code, 'permission_denied');
      expect(const DatabaseFailure().userMessage, contains('try again'));
      expect(
        const NotFoundFailure(entity: 'employee').userMessage,
        'The requested employee could not be found.',
      );
      expect(
        const BusinessRuleFailure(
          rule: 'payroll_finalized',
          userMessage: 'Payroll has already been finalized.',
        ).rule,
        'payroll_finalized',
      );
    });

    test('failures can be handled exhaustively', () {
      String describe(AppFailure failure) => switch (failure) {
        ValidationFailure() => 'validation',
        NotFoundFailure() => 'not found',
        ConflictFailure() => 'conflict',
        AuthenticationFailure() => 'authentication',
        PermissionFailure() => 'permission',
        BusinessRuleFailure() => 'business rule',
        DatabaseFailure() => 'database',
        UnexpectedFailure() => 'unexpected',
      };

      expect(describe(const DatabaseFailure()), 'database');
    });
  });
}
