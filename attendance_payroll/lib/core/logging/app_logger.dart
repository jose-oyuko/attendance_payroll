import 'package:attendance_payroll/core/logging/log_level.dart';
import 'package:attendance_payroll/core/logging/log_record.dart';
import 'package:attendance_payroll/core/logging/log_sink.dart';
import 'package:attendance_payroll/core/logging/redactor.dart';

/// Structured logger with level filtering and automatic redaction.
///
/// Records below [minLevel] are dropped before any work is done. A sink that
/// throws never breaks the caller.
final class AppLogger {
  AppLogger({
    required List<LogSink> sinks,
    this.minLevel = LogLevel.info,
    DateTime Function()? clock,
  }) : _sinks = List<LogSink>.unmodifiable(sinks),
       _clock = clock ?? DateTime.now;

  /// A logger that discards everything. Used as the default in tests.
  AppLogger.silent() : this(sinks: const <LogSink>[]);

  final LogLevel minLevel;
  final List<LogSink> _sinks;
  final DateTime Function() _clock;

  bool isEnabled(LogLevel level) => level.isAtLeast(minLevel);

  void log(
    LogLevel level,
    String tag,
    String message, {
    Map<String, Object?> fields = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_sinks.isEmpty || !isEnabled(level)) {
      return;
    }
    final record = LogRecord(
      time: _clock(),
      level: level,
      tag: tag,
      message: message,
      fields: Redactor.redactMap(fields),
      error: error,
      stackTrace: stackTrace,
    );
    for (final sink in _sinks) {
      try {
        sink.write(record);
      } on Object {
        // Logging must never crash the application.
      }
    }
  }

  void debug(
    String tag,
    String message, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) => log(LogLevel.debug, tag, message, fields: fields);

  void info(
    String tag,
    String message, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) => log(LogLevel.info, tag, message, fields: fields);

  void warning(
    String tag,
    String message, {
    Map<String, Object?> fields = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.warning,
    tag,
    message,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
  );

  void error(
    String tag,
    String message, {
    Map<String, Object?> fields = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.error,
    tag,
    message,
    fields: fields,
    error: error,
    stackTrace: stackTrace,
  );
}
