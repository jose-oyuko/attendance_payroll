import 'package:attendance_payroll/core/logging/log_record.dart';
import 'package:attendance_payroll/core/logging/log_sink.dart';

/// Collects records in memory so tests can assert on what was logged.
class MemoryLogSink implements LogSink {
  final List<LogRecord> records = <LogRecord>[];

  @override
  void write(LogRecord record) => records.add(record);
}
