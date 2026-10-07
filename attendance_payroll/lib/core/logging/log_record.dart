import 'package:attendance_payroll/core/logging/log_level.dart';

/// One structured log entry.
///
/// [fields] have already been passed through the redactor by the time a
/// record reaches a sink.
final class LogRecord {
  const LogRecord({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.fields = const <String, Object?>{},
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final LogLevel level;

  /// Short component name, for example `bootstrap` or `attendance`.
  final String tag;
  final String message;
  final Map<String, Object?> fields;
  final Object? error;
  final StackTrace? stackTrace;

  /// Single-line representation for console output.
  String format() {
    final buffer = StringBuffer('[${level.label}] $tag: $message');
    if (fields.isNotEmpty) {
      buffer.write(' $fields');
    }
    return buffer.toString();
  }
}
