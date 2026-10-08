import 'package:attendance_payroll/core/logging/app_logger.dart';
import 'package:attendance_payroll/core/logging/log_level.dart';
import 'package:attendance_payroll/core/logging/log_record.dart';
import 'package:attendance_payroll/core/logging/log_sink.dart';
import 'package:attendance_payroll/core/logging/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_log_sink.dart';

class _ThrowingSink implements LogSink {
  @override
  void write(LogRecord record) => throw StateError('sink failure');
}

void main() {
  group('AppLogger', () {
    late MemoryLogSink sink;

    setUp(() => sink = MemoryLogSink());

    test('drops records below the minimum level', () {
      final logger = AppLogger(sinks: [sink], minLevel: LogLevel.warning);

      logger
        ..debug('t', 'debug')
        ..info('t', 'info')
        ..warning('t', 'warning')
        ..error('t', 'error');

      expect(sink.records.map((r) => r.message), ['warning', 'error']);
    });

    test('redacts sensitive fields before they reach a sink', () {
      final logger = AppLogger(sinks: [sink], minLevel: LogLevel.debug);

      logger.info(
        'auth',
        'Employee authenticated',
        fields: <String, Object?>{'employeeId': 'e-1', 'pin': '1234'},
      );

      final fields = sink.records.single.fields;
      expect(fields['employeeId'], 'e-1');
      expect(fields['pin'], Redactor.mask);
      expect(sink.records.single.format(), isNot(contains('1234')));
    });

    test('passes error and stack trace through and uses the clock', () {
      final time = DateTime.utc(2026, 10, 5, 8);
      final trace = StackTrace.current;
      final error = StateError('boom');
      final logger = AppLogger(
        sinks: [sink],
        minLevel: LogLevel.debug,
        clock: () => time,
      );

      logger.error('db', 'Write failed', error: error, stackTrace: trace);

      final record = sink.records.single;
      expect(record.level, LogLevel.error);
      expect(record.tag, 'db');
      expect(record.error, same(error));
      expect(record.stackTrace, same(trace));
      expect(record.time, time);
    });

    test('a failing sink does not stop other sinks or throw', () {
      final logger = AppLogger(
        sinks: [_ThrowingSink(), sink],
        minLevel: LogLevel.debug,
      );

      expect(() => logger.info('t', 'hello'), returnsNormally);
      expect(sink.records, hasLength(1));
    });

    test('silent logger discards everything', () {
      final logger = AppLogger.silent();

      expect(() => logger.error('t', 'ignored'), returnsNormally);
    });

    test('format includes level, tag, message and fields', () {
      final logger = AppLogger(sinks: [sink], minLevel: LogLevel.debug);

      logger.info('boot', 'Started', fields: <String, Object?>{'env': 'dev'});

      expect(sink.records.single.format(), '[INFO] boot: Started {env: dev}');
    });
  });
}
