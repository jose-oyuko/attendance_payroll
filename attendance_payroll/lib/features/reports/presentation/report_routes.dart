import 'package:attendance_payroll/core/utils/local_date.dart';

/// The printable documents.
enum ReportKind {
  payslips,
  payrollSummary,
  attendance,
  timesheet,
  exceptions;

  /// Documents of a payroll period; the others cover a date range.
  bool get isPayroll => this == payslips || this == payrollSummary;
}

/// Which document to produce, with its parameters. Encoded in the preview
/// location, so a preview can be opened from any screen.
final class ReportRequest {
  const ReportRequest({
    required this.kind,
    this.periodId,
    this.employeeId,
    this.from,
    this.to,
  });

  final ReportKind kind;

  /// Payslips and the payroll summary.
  final String? periodId;

  /// One employee's payslip, or a timesheet.
  final String? employeeId;

  /// Attendance, timesheet and exception reports.
  final LocalDate? from;
  final LocalDate? to;

  Map<String, String> toQuery() => {
    'kind': kind.name,
    'period': ?periodId,
    'employee': ?employeeId,
    'from': ?from?.toIsoString(),
    'to': ?to?.toIsoString(),
  };

  /// The request in [query], or `null` when it is incomplete or malformed.
  static ReportRequest? fromQuery(Map<String, String> query) {
    final kind = ReportKind.values.asNameMap()[query['kind']];
    if (kind == null) {
      return null;
    }
    LocalDate? date(String key) {
      final value = query[key];
      if (value == null) {
        return null;
      }
      try {
        return LocalDate.parse(value);
      } on FormatException {
        return null;
      }
    }

    final request = ReportRequest(
      kind: kind,
      periodId: query['period'],
      employeeId: query['employee'],
      from: date('from'),
      to: date('to'),
    );
    final complete = kind.isPayroll
        ? request.periodId != null
        : request.from != null &&
              request.to != null &&
              (kind != ReportKind.timesheet || request.employeeId != null);
    return complete ? request : null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReportRequest &&
      other.kind == kind &&
      other.periodId == periodId &&
      other.employeeId == employeeId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, periodId, employeeId, from, to);
}

/// Locations of the Reports area and of the document preview.
abstract final class ReportRoutes {
  static const String list = '/reports';

  /// Outside the administrator shell, so opening a document from payroll
  /// or attendance and going back returns there.
  static const String preview = '/document';

  static String previewOf(ReportRequest request) =>
      Uri(path: preview, queryParameters: request.toQuery()).toString();
}
