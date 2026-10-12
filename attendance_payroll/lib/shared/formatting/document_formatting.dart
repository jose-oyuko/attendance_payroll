import 'package:attendance_payroll/core/utils/local_date.dart';

// Dates on paper (PDF documents and thermal receipts). They have no locale
// or device settings, so they use one unambiguous style: "05 Oct 2026".

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "05 Oct 2026".
String formatDocumentDate(LocalDate d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

/// "08:02", 24-hour.
String formatDocumentTime(Duration timeOfDay) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(timeOfDay.inHours)}:${two(timeOfDay.inMinutes % 60)}';
}
