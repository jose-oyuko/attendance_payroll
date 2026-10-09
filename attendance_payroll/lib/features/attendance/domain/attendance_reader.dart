import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/session_builder.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';

/// Derived attendance for company dates [from] to [to].
final class AttendanceSnapshot {
  const AttendanceSnapshot({
    required this.from,
    required this.to,
    required this.timeZone,
    required this.policy,
    required this.employees,
    required this.timelines,
    required this.reviews,
  });

  final LocalDate from;
  final LocalDate to;
  final CompanyTimeZone timeZone;
  final AttendancePolicy policy;

  /// The employees read (all of the company's, or the one requested).
  final List<Employee> employees;

  /// Every employee's timeline, built from the range plus surrounding
  /// context; use [sessionsFor] and [issuesFor] for the range itself.
  final Map<String, AttendanceTimeline> timelines;

  /// Review decisions for exceptions around the range, oldest first.
  final List<ExceptionReview> reviews;

  bool _inRange(LocalDate date) => !date.isBefore(from) && !date.isAfter(to);

  /// Sessions that started on a date in the range.
  List<AttendanceSession> sessionsFor(String employeeId) => [
    for (final s
        in timelines[employeeId]?.sessions ?? const <AttendanceSession>[])
      if (_inRange(s.workDate)) s,
  ];

  /// Issues revealed by events on a date in the range.
  List<AttendanceIssue> issuesFor(String employeeId) => [
    for (final i in timelines[employeeId]?.issues ?? const <AttendanceIssue>[])
      if (_inRange(timeZone.dateOf(i.occurredAt))) i,
  ];

  AttendanceTimeline timelineFor(String employeeId) => AttendanceTimeline(
    sessions: sessionsFor(employeeId),
    issues: issuesFor(employeeId),
  );
}

/// Reads events and review decisions and derives attendance from them, the
/// same way for every screen and for payroll.
final class AttendanceReader {
  AttendanceReader({
    required this._companies,
    required this._employees,
    required this._events,
    required this._settings,
    required this._reviews,
    this._clock = systemClockUtc,
  });

  static const String unknownTimeZoneRule = 'unknown_time_zone';

  final CompanyRepository _companies;
  final EmployeeRepository _employees;
  final AttendanceEventRepository _events;
  final AttendanceSettingsRepository _settings;
  final ExceptionReviewRepository _reviews;
  final Clock _clock;

  /// The company's attendance policy.
  Future<Result<AttendancePolicy>> policyFor(String companyId) async {
    return (await _settings.forCompany(companyId)).map((s) => s.policy);
  }

  /// Attendance of every employee of [companyId], or only [employeeId], on
  /// dates [from] to [to]. Fails with a `ValidationFailure` for a reversed
  /// range and a `NotFoundFailure` for an employee of another company.
  Future<Result<AttendanceSnapshot>> read(
    String companyId, {
    required LocalDate from,
    required LocalDate to,
    String? employeeId,
  }) async {
    if (to.isBefore(from)) {
      return const Err(
        ValidationFailure(
          field: 'to',
          userMessage: 'The end date cannot be before the start date.',
        ),
      );
    }
    return Result.guard(() async {
      final company = (await _companies.getById(companyId)).unwrap();
      final zoneName = company.details.timezone;
      if (!CompanyTimeZone.isKnown(zoneName)) {
        throw const BusinessRuleFailure(
          rule: unknownTimeZoneRule,
          userMessage:
              "The company's timezone is not recognised. Update it in the "
              'company settings.',
        );
      }
      final zone = CompanyTimeZone(zoneName);
      final policy = (await policyFor(companyId)).unwrap();
      final employees = employeeId == null
          ? (await _employees.listByCompany(
              companyId,
              includeArchived: true,
            )).unwrap()
          : [(await _employees.getInCompany(companyId, employeeId)).unwrap()];

      // Context either side, so sessions and duplicates near the range
      // boundaries are interpreted exactly as in a wider view.
      final range = zone.rangeOf(from, to);
      final start = range.start.subtract(policy.sessionLookaround);
      final end = range.end.add(policy.sessionLookaround);
      final events = employeeId == null
          ? (await _events.betweenForCompany(
              companyId,
              from: start,
              to: end,
            )).unwrap()
          : (await _events.between(employeeId, from: start, to: end)).unwrap();
      final reviews = (await _reviews.forCompany(
        companyId,
        from: start,
        to: end,
      )).unwrap();

      final byEmployee = <String, List<AttendanceEvent>>{};
      for (final event in events) {
        (byEmployee[event.employeeId] ??= []).add(event);
      }
      final builder = SessionBuilder(policy: policy, timeZone: zone);
      final accepted = acceptedIssueKeys(reviews);
      final now = _clock();
      return AttendanceSnapshot(
        from: from,
        to: to,
        timeZone: zone,
        policy: policy,
        employees: employees,
        timelines: {
          for (final employee in employees)
            employee.id: builder.build(
              byEmployee[employee.id] ?? const [],
              now: now,
              acceptedIssueKeys: accepted,
            ),
        },
        reviews: reviews,
      );
    });
  }

  /// Issues whose latest decision settles them.
  static Set<String> acceptedIssueKeys(List<ExceptionReview> reviews) {
    final latest = <String, ExceptionReview>{};
    for (final review in reviews) {
      latest[review.issueKey] = review;
    }
    return {
      for (final review in latest.values)
        if (review.decision != ReviewDecision.reviewed) review.issueKey,
    };
  }
}
