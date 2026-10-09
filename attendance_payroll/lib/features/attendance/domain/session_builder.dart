import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/day_schedule.dart';

DaySchedule _unscheduled(LocalDate date) => const Unscheduled();

/// Derives sessions from one employee's events.
///
/// Pure and deterministic: the same events, policy and `now` always give the
/// same result, whatever order the events are passed in. No event is ever
/// dropped; anything that does not fit a clean clock-in/clock-out pair is
/// reported as an [AttendanceIssue].
final class SessionBuilder {
  const SessionBuilder({required this.policy, required this.timeZone});

  final AttendancePolicy policy;
  final CompanyTimeZone timeZone;

  /// [acceptedIssueKeys] are issues an administrator accepted as recorded
  /// (see `ExceptionReview`); they no longer block payroll. [schedule] says
  /// what the employee was expected to work each day: it decides the break,
  /// whether crossing midnight is expected, and lateness and early departure.
  AttendanceTimeline build(
    Iterable<AttendanceEvent> events, {
    required DateTime now,
    Set<String> acceptedIssueKeys = const {},
    ScheduleLookup schedule = _unscheduled,
  }) {
    final accepted = acceptedIssueKeys;
    final sorted = [...events]..sort(AttendanceEvent.compareChronologically);
    assert(
      sorted.map((e) => e.employeeId).toSet().length <= 1,
      'Sessions are built per employee.',
    );

    final sessions = <AttendanceSession>[];
    final looseIssues = <AttendanceIssue>[];
    _OpenSession? open;
    AttendanceEvent? previous;
    // Whether the latest clock-outs (a clock-out and its duplicates) closed
    // the last session, so further duplicates belong to it.
    var closingRun = false;

    for (final event in sorted) {
      switch (event.type) {
        case AttendanceEventType.clockIn:
          closingRun = false;
          if (open == null) {
            open = _OpenSession(event);
          } else if (_isDuplicate(previous, event)) {
            open.issues.add(
              _issue(AttendanceIssueType.duplicateClockIn, event, open.key),
            );
          } else {
            // A clock-out is missing before this clock-in.
            sessions.add(_unclosed(open));
            open = _OpenSession(event);
          }
        case AttendanceEventType.clockOut:
          if (open != null) {
            sessions.add(_closed(open, event, accepted, schedule));
            open = null;
            closingRun = true;
          } else if (_isDuplicate(previous, event)) {
            final closed = closingRun ? sessions.removeLast() : null;
            final issue = _issue(
              AttendanceIssueType.duplicateClockOut,
              event,
              closed?.key,
            );
            if (closed == null) {
              looseIssues.add(issue);
            } else {
              sessions.add(_withIssue(closed, issue, accepted));
            }
          } else {
            closingRun = false;
            looseIssues.add(
              _issue(AttendanceIssueType.clockOutWithoutClockIn, event, null),
            );
          }
      }
      previous = event;
    }

    if (open != null) {
      sessions.add(
        _isStale(open, now) ? _unclosed(open) : _stillOpen(open, accepted),
      );
    }

    final checked = _compareWithSchedule(sessions, schedule, accepted);
    final issues = [
      for (final session in checked) ...session.issues,
      ...looseIssues,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return AttendanceTimeline(sessions: checked, issues: issues);
  }

  /// Scheduled shifts on dates [from] to [to] that ended by [now] with no
  /// session starting that day.
  List<AttendanceIssue> missingAttendance(
    String employeeId,
    List<AttendanceSession> sessions, {
    required LocalDate from,
    required LocalDate to,
    required DateTime now,
    required ScheduleLookup schedule,
  }) {
    final worked = {for (final s in sessions) s.workDate};
    final issues = <AttendanceIssue>[];
    for (var date = from; !date.isAfter(to); date = date.addDays(1)) {
      if (schedule(date) case final ScheduledShift shift
          when !worked.contains(date) && !now.isBefore(shift.end)) {
        issues.add(
          AttendanceIssue(
            type: AttendanceIssueType.missingAttendance,
            employeeId: employeeId,
            anchor: AttendanceIssue.dayAnchor(employeeId, date),
            occurredAt: shift.start,
          ),
        );
      }
    }
    return issues;
  }

  /// Adds lateness (the day's first session) and early departure (the day's
  /// last session, once clocked out) for scheduled days.
  List<AttendanceSession> _compareWithSchedule(
    List<AttendanceSession> sessions,
    ScheduleLookup schedule,
    Set<String> accepted,
  ) {
    final result = [...sessions];
    final byDate = <LocalDate, List<int>>{};
    for (final (index, session) in result.indexed) {
      (byDate[session.workDate] ??= []).add(index);
    }
    for (final MapEntry(key: date, value: indexes) in byDate.entries) {
      final shift = schedule(date);
      if (shift is! ScheduledShift) {
        continue;
      }
      final first = result[indexes.first];
      if (first.start.isAfter(shift.start.add(shift.lateTolerance))) {
        result[indexes.first] = _withIssue(
          first,
          _issue(AttendanceIssueType.lateArrival, first.clockIn, first.key),
          accepted,
        );
      }
      final last = result[indexes.last];
      final clockOut = last.clockOut;
      final earliestEnd = shift.end.subtract(shift.earlyDepartureTolerance);
      if (clockOut != null && clockOut.occurredAt.isBefore(earliestEnd)) {
        result[indexes.last] = _withIssue(
          last,
          _issue(AttendanceIssueType.earlyDeparture, clockOut, last.key),
          accepted,
        );
      }
    }
    return result;
  }

  /// The same action repeated within the duplicate window.
  bool _isDuplicate(AttendanceEvent? previous, AttendanceEvent event) {
    return previous != null &&
        previous.type == event.type &&
        event.occurredAt.difference(previous.occurredAt) <=
            policy.duplicateWindow;
  }

  bool _isStale(_OpenSession open, DateTime at) {
    return at.difference(open.clockIn.occurredAt) >
        policy.staleOpenSessionAfter;
  }

  AttendanceSession _closed(
    _OpenSession open,
    AttendanceEvent clockOut,
    Set<String> accepted,
    ScheduleLookup schedule,
  ) {
    final workDate = timeZone.dateOf(open.clockIn.occurredAt);
    final duration = clockOut.occurredAt.difference(open.clockIn.occurredAt);
    final shift = schedule(workDate);
    final nightShift = shift is ScheduledShift && shift.crossesMidnight;
    // A scheduled day uses the schedule's break rule, even "no break".
    final automaticBreak = shift is ScheduledShift
        ? shift.automaticBreak
        : policy.automaticBreak;
    final issues = [
      ...open.issues,
      if (timeZone.dateOf(clockOut.occurredAt) != workDate && !nightShift)
        _issue(AttendanceIssueType.overnightSession, clockOut, open.key),
      if (duration > policy.excessiveDurationAfter)
        _issue(AttendanceIssueType.excessiveDuration, clockOut, open.key),
    ];
    return AttendanceSession(
      clockIn: open.clockIn,
      clockOut: clockOut,
      workDate: workDate,
      status: _statusFor(issues, accepted, isOpen: false),
      issues: issues,
      breakDuration: automaticBreak?.breakFor(duration) ?? Duration.zero,
    );
  }

  AttendanceSession _unclosed(_OpenSession open) {
    final issues = [
      ...open.issues,
      _issue(AttendanceIssueType.missingClockOut, open.clockIn, open.key),
    ];
    return AttendanceSession(
      clockIn: open.clockIn,
      clockOut: null,
      workDate: timeZone.dateOf(open.clockIn.occurredAt),
      status: SessionStatus.exception,
      issues: issues,
      breakDuration: Duration.zero,
    );
  }

  AttendanceSession _stillOpen(_OpenSession open, Set<String> accepted) {
    return AttendanceSession(
      clockIn: open.clockIn,
      clockOut: null,
      workDate: timeZone.dateOf(open.clockIn.occurredAt),
      status: _statusFor(open.issues, accepted, isOpen: true),
      issues: open.issues,
      breakDuration: Duration.zero,
    );
  }

  AttendanceSession _withIssue(
    AttendanceSession session,
    AttendanceIssue issue,
    Set<String> accepted,
  ) {
    final issues = [...session.issues, issue];
    return AttendanceSession(
      clockIn: session.clockIn,
      clockOut: session.clockOut,
      workDate: session.workDate,
      status: _statusFor(issues, accepted, isOpen: session.clockOut == null),
      issues: issues,
      breakDuration: session.breakDuration,
    );
  }

  /// Blocking issues make a session an exception until every one of them is
  /// accepted; then it is approved. (A session without a clock-out is built
  /// by [_unclosed] and is always an exception: there is no time to accept.)
  static SessionStatus _statusFor(
    List<AttendanceIssue> issues,
    Set<String> accepted, {
    required bool isOpen,
  }) {
    final blocking = [
      for (final issue in issues)
        if (issue.type.blocksPayroll) issue,
    ];
    if (blocking.any((issue) => !accepted.contains(issue.key))) {
      return SessionStatus.exception;
    }
    if (blocking.isNotEmpty) {
      return SessionStatus.approved;
    }
    return isOpen ? SessionStatus.open : SessionStatus.completed;
  }

  static AttendanceIssue _issue(
    AttendanceIssueType type,
    AttendanceEvent event,
    String? sessionKey,
  ) {
    return AttendanceIssue(
      type: type,
      employeeId: event.employeeId,
      anchor: event.id,
      eventId: event.id,
      occurredAt: event.occurredAt,
      sessionKey: sessionKey,
    );
  }
}

class _OpenSession {
  _OpenSession(this.clockIn);

  final AttendanceEvent clockIn;
  final List<AttendanceIssue> issues = [];

  String get key => clockIn.id;
}
