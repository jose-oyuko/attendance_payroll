/// Severity of a log record. Values match `dart:developer` levels.
enum LogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.severity);

  final int severity;

  /// Upper-case label used in formatted output.
  String get label => name.toUpperCase();

  /// Whether this level is at least as severe as [other].
  bool isAtLeast(LogLevel other) => severity >= other.severity;
}
