import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';

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

  AttendanceTimeline build(
    Iterable<AttendanceEvent> events, {
    required DateTime now,
  }) {
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
            sessions.add(_closed(open, event));
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
              sessions.add(_withIssue(closed, issue));
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
      sessions.add(_isStale(open, now) ? _unclosed(open) : _stillOpen(open));
    }

    final issues = [
      for (final session in sessions) ...session.issues,
      ...looseIssues,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return AttendanceTimeline(sessions: sessions, issues: issues);
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

  AttendanceSession _closed(_OpenSession open, AttendanceEvent clockOut) {
    final workDate = timeZone.dateOf(open.clockIn.occurredAt);
    final duration = clockOut.occurredAt.difference(open.clockIn.occurredAt);
    final issues = [
      ...open.issues,
      if (timeZone.dateOf(clockOut.occurredAt) != workDate)
        _issue(AttendanceIssueType.overnightSession, clockOut, open.key),
      if (duration > policy.excessiveDurationAfter)
        _issue(AttendanceIssueType.excessiveDuration, clockOut, open.key),
    ];
    return AttendanceSession(
      clockIn: open.clockIn,
      clockOut: clockOut,
      workDate: workDate,
      status: _statusFor(issues, isOpen: false),
      issues: issues,
      breakDuration: policy.automaticBreak?.breakFor(duration) ?? Duration.zero,
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

  AttendanceSession _stillOpen(_OpenSession open) {
    return AttendanceSession(
      clockIn: open.clockIn,
      clockOut: null,
      workDate: timeZone.dateOf(open.clockIn.occurredAt),
      status: _statusFor(open.issues, isOpen: true),
      issues: open.issues,
      breakDuration: Duration.zero,
    );
  }

  AttendanceSession _withIssue(
    AttendanceSession session,
    AttendanceIssue issue,
  ) {
    final issues = [...session.issues, issue];
    return AttendanceSession(
      clockIn: session.clockIn,
      clockOut: session.clockOut,
      workDate: session.workDate,
      status: _statusFor(issues, isOpen: session.clockOut == null),
      issues: issues,
      breakDuration: session.breakDuration,
    );
  }

  static SessionStatus _statusFor(
    List<AttendanceIssue> issues, {
    required bool isOpen,
  }) {
    if (issues.any((issue) => issue.type.blocksPayroll)) {
      return SessionStatus.exception;
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
