import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';

/// One employee's attendance on one company date, as payroll sees it.
final class DayWork {
  const DayWork({
    this.payable = Duration.zero,
    this.awaitingReview = 0,
    this.stillOpen = 0,
  });

  /// Payable time of completed and approved sessions.
  final Duration payable;

  /// Sessions left out because their exceptions are not settled.
  final int awaitingReview;

  /// Sessions left out because the employee is still clocked in.
  final int stillOpen;
}

/// Everything needed to pay one employee.
final class EmployeePayInput {
  const EmployeePayInput({
    required this.employee,
    required this.rates,
    required this.days,
    this.adjustments = const [],
  });

  final Employee employee;
  final List<EmployeeRate> rates;

  /// Work by company date. With a weekly overtime rule this must cover the
  /// whole ISO weeks that overlap the period, so a week spanning two periods
  /// is judged as one week.
  final Map<LocalDate, DayWork> days;
  final List<PayrollAdjustment> adjustments;
}

final class PayrollInput {
  const PayrollInput({
    required this.from,
    required this.to,
    required this.currency,
    required this.settings,
    required this.employees,
  });

  /// The period's dates, inclusive.
  final LocalDate from;
  final LocalDate to;
  final String currency;
  final PayrollSettings settings;
  final List<EmployeePayInput> employees;
}

/// Calculates pay from attendance, rates and adjustments.
///
/// Pure and deterministic: no clock, no database, no floating point. Every
/// amount is computed from an exact ratio and rounded once, half away from
/// zero, so each payslip line can be checked by hand:
///
/// - hourly: hours × rate
/// - daily: days worked × rate
/// - monthly: salary × days employed in the month ÷ days in the month
/// - overtime: overtime hours × hourly equivalent × percentage
///
/// Each day is paid at the rate in force that day, so a rate change during
/// the period produces one line per rate.
final class PayrollCalculator {
  const PayrollCalculator();

  static final BigInt _secondsPerHour = BigInt.from(Duration.secondsPerHour);
  static final BigInt _hundred = BigInt.from(100);
  static final BigInt _monthsPerYear = BigInt.from(12);
  static final BigInt _weeksPerYear = BigInt.from(52);

  PayrollResult calculate(PayrollInput input) {
    final lines = <PayrollLine>[];
    final issues = <PayrollIssue>[];
    final employees = [...input.employees]
      ..sort((a, b) => a.employee.id.compareTo(b.employee.id));
    for (final employee in employees) {
      final line = _pay(input, employee, issues);
      if (line != null) {
        lines.add(line);
      }
    }
    return PayrollResult(lines: lines, issues: issues);
  }

  PayrollLine? _pay(
    PayrollInput input,
    EmployeePayInput e,
    List<PayrollIssue> issues,
  ) {
    final id = e.employee.id;
    final name = e.employee.details.shownName;
    final split = splitOvertime(e.days, input.settings);
    final segments = <String, _Segment>{};
    var unpricedDays = 0;
    var awaitingReview = 0;
    var stillOpen = 0;
    var mismatchedCurrency = false;

    for (
      var date = input.from;
      !date.isAfter(input.to);
      date = date.addDays(1)
    ) {
      final work = e.days[date];
      awaitingReview += work?.awaitingReview ?? 0;
      stillOpen += work?.stillOpen ?? 0;
      final (regular, overtime) = split[date] ?? (Duration.zero, Duration.zero);
      final worked = regular + overtime > Duration.zero;
      final rate = _rateOn(e.rates, date);
      if (rate == null) {
        if (worked) {
          unpricedDays++;
        }
        continue;
      }
      if (rate.currencyCode != input.currency) {
        mismatchedCurrency = true;
        continue;
      }
      final segment = segments[rate.id] ??= _Segment(rate);
      segment
        ..regular += regular
        ..overtime += overtime;
      if (worked) {
        segment.workedDays++;
      }
      if (rate.rateType == RateType.monthly && _employed(e.employee, date)) {
        final month = (date.year, date.month);
        segment.salaryDays[month] = (segment.salaryDays[month] ?? 0) + 1;
      }
    }

    final issuesBefore = issues.length;
    void issue(PayrollIssueCode code, String message) =>
        issues.add(PayrollIssue(code: code, employeeId: id, message: message));

    if (awaitingReview > 0) {
      issue(
        PayrollIssueCode.attendanceAwaitingReview,
        '$name: $awaitingReview session(s) need review and are not paid yet.',
      );
    }
    if (stillOpen > 0) {
      issue(
        PayrollIssueCode.stillClockedIn,
        '$name is still clocked in; that session is not included yet.',
      );
    }
    if (unpricedDays > 0) {
      issue(
        PayrollIssueCode.missingRate,
        '$name worked on $unpricedDays day(s) with no pay rate; that time '
        'is unpaid.',
      );
    }
    final salaried = segments.values.any((s) => s.salaryDays.isNotEmpty);
    if (salaried &&
        e.employee.details.employmentStatus == EmploymentStatus.archived &&
        e.employee.details.employmentEndDate == null) {
      issue(
        PayrollIssueCode.archivedWithoutEndDate,
        '$name is archived but has no employment end date, so the salary '
        'is paid for the whole period.',
      );
    }
    if (mismatchedCurrency) {
      issue(
        PayrollIssueCode.currencyMismatch,
        "$name has a pay rate in another currency than the company's.",
      );
    }

    final ordered = segments.values.toList()
      ..sort((a, b) => a.rate.effectiveFrom.compareTo(b.rate.effectiveFrom));
    final items = <PayrollItem>[
      for (final segment in ordered) ..._earnings(segment, input),
      ..._adjustments(e.adjustments),
    ];
    final regularHours = ordered.fold(Duration.zero, (t, s) => t + s.regular);
    final overtimeHours = ordered.fold(Duration.zero, (t, s) => t + s.overtime);
    // An employee with a problem keeps a line, even an empty one, so the
    // review shows who it concerns.
    if (items.isEmpty && issues.length == issuesBefore) {
      return null;
    }
    final line = PayrollLine(
      employeeId: id,
      currency: input.currency,
      regularHours: regularHours,
      overtimeHours: overtimeHours,
      items: items,
    );
    if (line.net.isNegative) {
      issue(
        PayrollIssueCode.negativeNetPay,
        '$name: deductions (${line.deductions}) exceed earnings '
        '(${line.gross}).',
      );
    }
    return line;
  }

  List<PayrollItem> _earnings(_Segment s, PayrollInput input) {
    final rate = s.rate;
    final money = Money(rate.amountMinor, rate.currencyCode);
    final r = BigInt.from(rate.amountMinor);
    final c = rate.currencyCode;
    final percent = input.settings.overtimePercent;
    final p = BigInt.from(percent);
    final items = <PayrollItem>[];

    switch (rate.rateType) {
      case RateType.hourly:
        if (s.regular > Duration.zero) {
          items.add(
            PayrollItem(
              kind: PayrollItemKind.regularPay,
              description: 'Regular pay',
              amount: Money.ofRatio(
                c,
                r * _seconds(s.regular),
                _secondsPerHour,
              ),
              rateType: rate.rateType,
              rate: money,
              hours: s.regular,
            ),
          );
        }
      case RateType.daily:
        if (s.workedDays > 0) {
          items.add(
            PayrollItem(
              kind: PayrollItemKind.regularPay,
              description: 'Regular pay',
              amount: Money(rate.amountMinor * s.workedDays, c),
              rateType: rate.rateType,
              rate: money,
              days: s.workedDays,
            ),
          );
        }
      case RateType.monthly:
        final months = s.salaryDays.keys.toList()..sort(_compareMonths);
        for (final month in months) {
          final days = s.salaryDays[month]!;
          final inMonth = _daysInMonth(month);
          items.add(
            PayrollItem(
              kind: PayrollItemKind.regularPay,
              description: 'Salary ($days of $inMonth days)',
              amount: Money.ofRatio(
                c,
                r * BigInt.from(days),
                BigInt.from(inMonth),
              ),
              rateType: rate.rateType,
              rate: money,
              days: days,
            ),
          );
        }
    }

    if (s.overtime > Duration.zero) {
      final seconds = _seconds(s.overtime);
      // Overtime = overtime seconds × hourly equivalent × percent / 100.
      final (numerator, denominator) = switch (rate.rateType) {
        RateType.hourly => (r * seconds * p, _secondsPerHour * _hundred),
        RateType.daily => (
          r * seconds * p,
          _seconds(input.settings.standardDay) * _hundred,
        ),
        RateType.monthly => (
          r * _monthsPerYear * seconds * p,
          _weeksPerYear * _seconds(input.settings.standardWeek) * _hundred,
        ),
      };
      items.add(
        PayrollItem(
          kind: PayrollItemKind.overtimePay,
          description: 'Overtime ($percent%)',
          amount: Money.ofRatio(c, numerator, denominator),
          rateType: rate.rateType,
          rate: money,
          hours: s.overtime,
          percent: percent,
        ),
      );
    }
    return items;
  }

  static List<PayrollItem> _adjustments(List<PayrollAdjustment> adjustments) {
    final ordered = [...adjustments]
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return [
      for (final a in ordered)
        PayrollItem(
          kind: switch (a.type) {
            AdjustmentType.allowance => PayrollItemKind.allowance,
            AdjustmentType.bonus => PayrollItemKind.bonus,
            AdjustmentType.deduction => PayrollItemKind.deduction,
          },
          description: a.description,
          amount: a.amount,
        ),
    ];
  }

  /// Splits each day's payable time into regular and overtime: first by the
  /// daily threshold, then by the weekly one, filling each ISO week's
  /// regular allowance in date order so the week's last hours are overtime.
  static Map<LocalDate, (Duration, Duration)> splitOvertime(
    Map<LocalDate, DayWork> days,
    PayrollSettings settings,
  ) {
    final dates = days.keys.toList()..sort();
    final result = <LocalDate, (Duration, Duration)>{};
    final daily = settings.dailyOvertimeAfter;
    for (final date in dates) {
      final payable = days[date]!.payable;
      final overtime = daily != null && payable > daily
          ? payable - daily
          : Duration.zero;
      result[date] = (payable - overtime, overtime);
    }

    final weekly = settings.weeklyOvertimeAfter;
    if (weekly != null) {
      final counted = <LocalDate, Duration>{};
      for (final date in dates) {
        final weekStart = date.addDays(1 - date.weekday);
        final so = counted[weekStart] ?? Duration.zero;
        final (regular, overtime) = result[date]!;
        final room = weekly > so ? weekly - so : Duration.zero;
        final kept = regular < room ? regular : room;
        result[date] = (kept, overtime + (regular - kept));
        counted[weekStart] = so + kept;
      }
    }
    return result;
  }

  static EmployeeRate? _rateOn(List<EmployeeRate> rates, LocalDate date) {
    for (final rate in rates) {
      if (rate.appliesOn(date)) {
        return rate;
      }
    }
    return null;
  }

  static bool _employed(Employee employee, LocalDate date) {
    final d = employee.details;
    final end = d.employmentEndDate;
    return !date.isBefore(d.employmentStartDate) &&
        (end == null || !date.isAfter(end));
  }

  static BigInt _seconds(Duration d) => BigInt.from(d.inSeconds);

  static int _daysInMonth((int, int) month) {
    final (year, m) = month;
    return DateTime.utc(year, m + 1, 0).day;
  }

  static int _compareMonths((int, int) a, (int, int) b) {
    final byYear = a.$1.compareTo(b.$1);
    return byYear != 0 ? byYear : a.$2.compareTo(b.$2);
  }
}

class _Segment {
  _Segment(this.rate);

  final EmployeeRate rate;
  Duration regular = Duration.zero;
  Duration overtime = Duration.zero;
  int workedDays = 0;

  /// Monthly salary: employed days per (year, month).
  final Map<(int, int), int> salaryDays = {};
}
