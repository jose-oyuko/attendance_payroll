import 'dart:developer' as developer;

import 'package:attendance_payroll/core/logging/log_record.dart';

/// Destination for log records (console, file, crash reporter, ...).
abstract interface class LogSink {
  void write(LogRecord record);
}

/// Writes records through `dart:developer`, which shows up in the IDE and
/// `flutter run` console and in DevTools.
final class ConsoleLogSink implements LogSink {
  const ConsoleLogSink();

  @override
  void write(LogRecord record) {
    developer.log(
      record.format(),
      time: record.time,
      level: record.level.severity,
      name: 'attendance_payroll',
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
