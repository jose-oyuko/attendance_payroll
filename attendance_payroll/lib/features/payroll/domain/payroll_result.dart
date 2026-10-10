import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';

/// Components of pay.
enum PayrollItemKind {
  regularPay,
  overtimePay,
  allowance,
  bonus,
  deduction;

  /// Deductions reduce pay; everything else adds to it.
  bool get isDeduction => this == deduction;
}

/// One explainable line of a payslip, e.g. "Regular 176.50 h × KES 500.00 =
/// KES 88,250.00".
final class PayrollItem {
  const PayrollItem({
    required this.kind,
    required this.description,
    required this.amount,
    this.rateType,
    this.rate,
    this.hours,
    this.days,
    this.percent,
  });

  final PayrollItemKind kind;
  final String description;

  /// Always positive; [kind] says whether it adds or subtracts.
  final Money amount;

  /// For calculated pay: the rate it was paid at.
  final RateType? rateType;
  final Money? rate;

  /// Time it pays for (hourly pay, overtime).
  final Duration? hours;

  /// Days it pays for (daily or monthly rates).
  final int? days;

  /// Overtime percentage applied.
  final int? percent;
}

enum PayrollIssueSeverity {
  /// Payroll must not be finalized until it is resolved.
  blocking,

  /// Worth checking; does not prevent finalization.
  warning,
}

/// Something about the payroll an administrator should know.
enum PayrollIssueCode {
  /// Sessions with unsettled attendance exceptions were left out.
  attendanceAwaitingReview(PayrollIssueSeverity.blocking),

  /// Time was worked on days with no pay rate, so it is unpaid.
  missingRate(PayrollIssueSeverity.blocking),

  /// Deductions exceed earnings.
  negativeNetPay(PayrollIssueSeverity.blocking),

  /// Still clocked in; that session is not included yet.
  stillClockedIn(PayrollIssueSeverity.warning),

  /// A rate is in another currency than the company's.
  currencyMismatch(PayrollIssueSeverity.blocking),

  /// Archived without an employment end date: a salary is paid for every
  /// day of the period.
  archivedWithoutEndDate(PayrollIssueSeverity.warning);

  const PayrollIssueCode(this.severity);

  final PayrollIssueSeverity severity;
}

final class PayrollIssue {
  const PayrollIssue({
    required this.code,
    required this.employeeId,
    required this.message,
  });

  final PayrollIssueCode code;
  final String? employeeId;
  final String message;

  PayrollIssueSeverity get severity => code.severity;
}

/// One employee's pay for a period.
final class PayrollLine {
  PayrollLine({
    required this.employeeId,
    required this.currency,
    required this.regularHours,
    required this.overtimeHours,
    required this.items,
  });

  final String employeeId;
  final String currency;

  /// Paid time, for information (salaried pay does not depend on it).
  final Duration regularHours;
  final Duration overtimeHours;
  final List<PayrollItem> items;

  Money _total(PayrollItemKind kind) => Money.sum(currency, [
    for (final item in items)
      if (item.kind == kind) item.amount,
  ]);

  late final Money regularPay = _total(PayrollItemKind.regularPay);
  late final Money overtimePay = _total(PayrollItemKind.overtimePay);
  late final Money allowances = _total(PayrollItemKind.allowance);
  late final Money bonuses = _total(PayrollItemKind.bonus);
  late final Money deductions = _total(PayrollItemKind.deduction);

  /// Regular + overtime + allowances + bonuses.
  late final Money gross = regularPay + overtimePay + allowances + bonuses;

  /// Gross − deductions.
  late final Money net = gross - deductions;
}

/// The outcome of a payroll calculation.
final class PayrollResult {
  const PayrollResult({required this.lines, required this.issues});

  /// One per paid employee, ordered by employee id for stable output.
  final List<PayrollLine> lines;
  final List<PayrollIssue> issues;

  bool get hasBlockingIssues =>
      issues.any((i) => i.severity == PayrollIssueSeverity.blocking);

  /// Sums per currency, in order of first appearance. Normally one; more
  /// only when rates disagree with the company currency (a blocking issue).
  List<PayrollTotals> get totals {
    final byCurrency = <String, List<PayrollLine>>{};
    for (final line in lines) {
      (byCurrency[line.currency] ??= []).add(line);
    }
    return [
      for (final MapEntry(:key, :value) in byCurrency.entries)
        PayrollTotals(key, value),
    ];
  }

  /// Every figure and problem in a stable textual form. Two results with the
  /// same fingerprint pay exactly the same: used to confirm a stored run is
  /// still current before it is approved or finalized.
  String get fingerprint {
    final buffer = StringBuffer();
    for (final line in lines) {
      buffer.writeln(
        'L|${line.employeeId}|${line.currency}|'
        '${line.regularHours.inSeconds}|${line.overtimeHours.inSeconds}',
      );
      for (final i in line.items) {
        buffer.writeln(
          'I|${i.kind.name}|${i.description}|'
          '${i.amount.minorUnits}|${i.rateType?.name}|'
          '${i.rate?.minorUnits}|${i.hours?.inSeconds}|${i.days}|'
          '${i.percent}',
        );
      }
    }
    for (final issue in issues) {
      buffer.writeln('P|${issue.code.name}|${issue.employeeId}');
    }
    return buffer.toString();
  }
}

/// The sums of every line paid in [currency].
final class PayrollTotals {
  PayrollTotals(this.currency, Iterable<PayrollLine> lines)
    : lines = List.unmodifiable(lines);

  final String currency;
  final List<PayrollLine> lines;

  Money _sum(Money Function(PayrollLine) of) =>
      Money.sum(currency, lines.map(of));

  Duration _hours(Duration Function(PayrollLine) of) =>
      lines.fold(Duration.zero, (total, line) => total + of(line));

  late final Duration regularHours = _hours((l) => l.regularHours);
  late final Duration overtimeHours = _hours((l) => l.overtimeHours);
  late final Money regularPay = _sum((l) => l.regularPay);
  late final Money overtimePay = _sum((l) => l.overtimePay);
  late final Money allowances = _sum((l) => l.allowances);
  late final Money bonuses = _sum((l) => l.bonuses);
  late final Money deductions = _sum((l) => l.deductions);
  late final Money gross = _sum((l) => l.gross);
  late final Money net = _sum((l) => l.net);
}
