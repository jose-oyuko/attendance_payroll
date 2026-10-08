import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:drift/drift.dart';

/// Stores a [LocalDate] as `YYYY-MM-DD` text.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toIsoString();
}
