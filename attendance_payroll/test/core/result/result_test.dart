import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('ok exposes its value', () {
      const result = Result<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('err exposes its failure', () {
      const failure = NotFoundFailure(entity: 'employee');
      const result = Result<int>.err(failure);

      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
    });

    test('unwrap returns the value or throws the failure', () {
      const failure = NotFoundFailure(entity: 'employee');

      expect(const Result<int>.ok(7).unwrap(), 7);
      expect(
        () => const Result<int>.err(failure).unwrap(),
        throwsA(same(failure)),
      );
    });

    test('fold selects the matching branch', () {
      const ok = Result<int>.ok(2);
      const err = Result<int>.err(UnexpectedFailure());

      expect(ok.fold((value) => 'v$value', (failure) => failure.code), 'v2');
      expect(
        err.fold((value) => 'v$value', (failure) => failure.code),
        'unexpected',
      );
    });

    test('map transforms ok and preserves err', () {
      const ok = Result<int>.ok(2);
      const err = Result<int>.err(DatabaseFailure());

      expect(ok.map((value) => value * 10).valueOrNull, 20);
      expect(err.map((value) => value * 10).failureOrNull?.code, 'database');
    });

    test('guard returns ok when the action succeeds', () async {
      final result = await Result.guard(() async => 'done');

      expect(result.valueOrNull, 'done');
    });

    test('guard converts thrown errors into failures', () async {
      final result = await Result.guard<int>(() async {
        throw StateError('boom');
      });

      final failure = result.failureOrNull;
      expect(failure, isA<UnexpectedFailure>());
      expect(failure?.cause, isA<StateError>());
    });

    test('guard keeps an AppFailure that was thrown', () async {
      const thrown = ConflictFailure(userMessage: 'Duplicate.');

      final result = await Result.guard<int>(() async => throw thrown);

      expect(result.failureOrNull, same(thrown));
    });
  });
}
