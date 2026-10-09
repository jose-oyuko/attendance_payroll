import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/session_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';

const _hm = Duration.new;

void main() {
  late EventFactory e;
  final builder = SessionBuilder(
    policy: const AttendancePolicy(),
    timeZone: nairobi,
  );
  // Long after every event, so open sessions are stale unless a test says
  // otherwise.
  final later = nairobiTime(20, 12, 0);

  AttendanceTimeline build(List<AttendanceEvent> events, {DateTime? now}) {
    return builder.build(events, now: now ?? later);
  }

  List<AttendanceIssueType> types(Iterable<AttendanceIssue> issues) {
    return [for (final issue in issues) issue.type];
  }

  setUp(() => e = EventFactory());

  test('no events, no sessions', () {
    final timeline = build([]);

    expect(timeline.sessions, isEmpty);
    expect(timeline.issues, isEmpty);
  });

  test('a normal day is one completed, payable session', () {
    final clockIn = e.clockIn(5, 8, 2);
    final clockOut = e.clockOut(5, 17, 4);

    final session = build([clockIn, clockOut]).sessions.single;

    expect(session.key, clockIn.id);
    expect(session.status, SessionStatus.completed);
    expect(session.workDate, LocalDate(2026, 10, 5));
    expect(session.start, clockIn.occurredAt);
    expect(session.end, clockOut.occurredAt);
    expect(session.duration, _hm(hours: 9, minutes: 2));
    expect(session.payableDuration, _hm(hours: 9, minutes: 2));
    expect(session.issues, isEmpty);
  });

  test('forgotten clock-out answered next morning is not paid as 23h 59m', () {
    // Spec §30: Monday 08:02 in, Tuesday 08:01 out.
    final timeline = build([e.clockIn(5, 8, 2), e.clockOut(6, 8, 1)]);
    final session = timeline.sessions.single;

    expect(session.duration, _hm(hours: 23, minutes: 59));
    expect(session.status, SessionStatus.exception);
    expect(session.payableDuration, isNull);
    expect(types(session.issues), [
      AttendanceIssueType.overnightSession,
      AttendanceIssueType.excessiveDuration,
    ]);
  });

  test('clocking in the next day closes a forgotten session as missing', () {
    final monday = e.clockIn(5, 8, 2);
    final tuesday = e.clockIn(6, 8, 0);
    final timeline = build([monday, tuesday, e.clockOut(6, 17, 0)]);

    expect(timeline.sessions, hasLength(2));
    final forgotten = timeline.sessions.first;
    expect(forgotten.key, monday.id);
    expect(forgotten.end, isNull);
    expect(forgotten.status, SessionStatus.exception);
    expect(types(forgotten.issues), [AttendanceIssueType.missingClockOut]);
    expect(timeline.sessions.last.key, tuesday.id);
    expect(timeline.sessions.last.status, SessionStatus.completed);
  });

  test('an open session is open until it becomes stale', () {
    final clockIn = e.clockIn(5, 8, 0);

    final now = build([clockIn], now: nairobiTime(5, 12, 0)).sessions.single;
    final nextDay = build([clockIn], now: nairobiTime(6, 9, 0)).sessions.single;

    expect(now.status, SessionStatus.open);
    expect(now.issues, isEmpty);
    expect(now.payableDuration, isNull);
    expect(nextDay.status, SessionStatus.exception);
    expect(types(nextDay.issues), [AttendanceIssueType.missingClockOut]);
  });

  group('duplicates', () {
    test('a double-tapped clock-in is flagged; the first one counts', () {
      final first = e.clockIn(5, 8, 1);
      final second = e.clockIn(5, 8, 2);
      final timeline = build([first, second, e.clockOut(5, 17, 0)]);
      final session = timeline.sessions.single;

      expect(session.start, first.occurredAt);
      expect(session.status, SessionStatus.completed);
      expect(session.issues.single.type, AttendanceIssueType.duplicateClockIn);
      expect(session.issues.single.eventId, second.id);
      expect(session.issues.single.sessionKey, first.id);
    });

    test('every clock-out in a double-tap run belongs to the session', () {
      final out = e.clockOut(5, 17, 0);
      final timeline = build([
        e.clockIn(5, 8, 0),
        out,
        e.clockOut(5, 17, 2),
        e.clockOut(5, 17, 5),
      ]);
      final session = timeline.sessions.single;

      expect(session.end, out.occurredAt);
      expect(session.status, SessionStatus.completed);
      expect(types(session.issues), [
        AttendanceIssueType.duplicateClockOut,
        AttendanceIssueType.duplicateClockOut,
      ]);
      expect(timeline.issues, hasLength(2));
    });

    test('a later second clock-in means a clock-out was missed', () {
      // Clocked in at 08:00, forgot to clock out for lunch, back at 13:00.
      final timeline = build([
        e.clockIn(5, 8, 0),
        e.clockIn(5, 13, 0),
        e.clockOut(5, 17, 0),
      ]);

      expect(timeline.sessions, hasLength(2));
      expect(types(timeline.sessions.first.issues), [
        AttendanceIssueType.missingClockOut,
      ]);
      expect(timeline.sessions.last.duration, _hm(hours: 4));
      expect(timeline.sessions.last.status, SessionStatus.completed);
    });

    test('a later second clock-out means a clock-in was missed', () {
      final orphan = e.clockOut(5, 17, 0);
      final timeline = build([
        e.clockIn(5, 8, 0),
        e.clockOut(5, 12, 0),
        orphan,
      ]);

      expect(timeline.sessions.single.duration, _hm(hours: 4));
      expect(timeline.sessions.single.issues, isEmpty);
      final issue = timeline.issues.single;
      expect(issue.type, AttendanceIssueType.clockOutWithoutClockIn);
      expect(issue.eventId, orphan.id);
      expect(issue.sessionKey, isNull);
    });
  });

  test('a clock-out with nothing before it is flagged, never dropped', () {
    final orphan = e.clockOut(5, 17, 0);

    final timeline = build([orphan]);

    expect(timeline.sessions, isEmpty);
    expect(types(timeline.issues), [
      AttendanceIssueType.clockOutWithoutClockIn,
    ]);
  });

  test('a session crossing company midnight is flagged as overnight', () {
    final session = build([
      e.clockIn(5, 20, 0),
      e.clockOut(6, 4, 0),
    ]).sessions.single;

    expect(session.duration, _hm(hours: 8));
    expect(session.status, SessionStatus.exception);
    expect(types(session.issues), [AttendanceIssueType.overnightSession]);
  });

  test('a long same-day session is flagged for review, not shortened', () {
    final session = build([
      e.clockIn(5, 8, 0),
      e.clockOut(5, 23, 30),
    ]).sessions.single;

    expect(session.duration, _hm(hours: 15, minutes: 30));
    expect(types(session.issues), [AttendanceIssueType.excessiveDuration]);
    expect(session.payableDuration, isNull);
  });

  test('exactly the excessive threshold is still normal', () {
    final session = build([
      e.clockIn(5, 8, 0),
      e.clockOut(5, 20, 0),
    ]).sessions.single;

    expect(session.status, SessionStatus.completed);
  });

  test('the work date is the company date of the clock-in', () {
    // 00:30 in Nairobi is 21:30 UTC the previous day.
    final clockIn = e.clockIn(6, 0, 30);
    expect(clockIn.occurredAt, DateTime.utc(2026, 10, 5, 21, 30));

    final session = build([clockIn, e.clockOut(6, 6, 0)]).sessions.single;

    expect(session.workDate, LocalDate(2026, 10, 6));
    expect(session.issues, isEmpty);
  });

  group('automatic break', () {
    final withBreak = SessionBuilder(
      policy: const AttendancePolicy(
        automaticBreak: AutomaticBreak(
          after: Duration(hours: 6),
          deduct: Duration(hours: 1),
        ),
      ),
      timeZone: nairobi,
    );

    test('is deducted from long sessions (9h present → 8h payable)', () {
      final session = withBreak
          .build([e.clockIn(5, 8, 0), e.clockOut(5, 17, 0)], now: later)
          .sessions
          .single;

      expect(session.breakDuration, _hm(hours: 1));
      expect(session.payableDuration, _hm(hours: 8));
    });

    test('is not deducted from short sessions', () {
      final session = withBreak
          .build([e.clockIn(5, 8, 0), e.clockOut(5, 12, 0)], now: later)
          .sessions
          .single;

      expect(session.breakDuration, Duration.zero);
      expect(session.payableDuration, _hm(hours: 4));
    });
  });

  test('the result does not depend on input order', () {
    final events = [
      e.clockIn(5, 8, 0),
      e.clockIn(5, 8, 3),
      e.clockOut(5, 17, 0),
      e.clockOut(6, 9, 0),
      e.clockIn(7, 8, 0),
    ];

    String describe(AttendanceTimeline t) => [
      for (final s in t.sessions) '${s.key}:${s.status}:${s.end}',
      for (final i in t.issues) '${i.type}:${i.eventId}',
    ].join('|');

    expect(describe(build(events.reversed.toList())), describe(build(events)));
  });

  test('simultaneous events are ordered by recording time, then id', () {
    final instant = nairobiTime(5, 8, 0);
    final clockOut = e.at(
      AttendanceEventType.clockOut,
      instant,
      recordedAt: instant.add(const Duration(seconds: 1)),
    );
    final clockIn = e.at(AttendanceEventType.clockIn, instant);

    final timeline = build([clockOut, clockIn]);

    expect(timeline.sessions.single.duration, Duration.zero);
    expect(timeline.issues, isEmpty);
  });

  test('issues are listed chronologically across sessions', () {
    final timeline = build([
      e.clockOut(5, 7, 0),
      e.clockIn(5, 8, 0),
      e.clockIn(5, 8, 1),
      e.clockOut(6, 9, 0),
    ]);

    expect(types(timeline.issues), [
      AttendanceIssueType.clockOutWithoutClockIn,
      AttendanceIssueType.duplicateClockIn,
      AttendanceIssueType.overnightSession,
      AttendanceIssueType.excessiveDuration,
    ]);
  });

  group('accepted issues', () {
    test('accepting every blocking issue approves the session', () {
      final events = [e.clockIn(5, 8, 0), e.clockOut(5, 23, 30)];
      final flagged = build(events).sessions.single;
      final key = flagged.issues.single.key;

      final approved = builder
          .build(events, now: later, acceptedIssueKeys: {key})
          .sessions
          .single;

      expect(flagged.status, SessionStatus.exception);
      expect(approved.status, SessionStatus.approved);
      expect(approved.payableDuration, const Duration(hours: 15, minutes: 30));
      expect(approved.issues, hasLength(1), reason: 'the issue stays visible');
    });

    test('accepting only some blocking issues is not enough', () {
      // Overnight and excessive: both must be accepted.
      final events = [e.clockIn(5, 8, 2), e.clockOut(6, 8, 1)];
      final keys = build(events).sessions.single.issues.map((i) => i.key);

      final partly = builder
          .build(events, now: later, acceptedIssueKeys: {keys.first})
          .sessions
          .single;

      expect(partly.status, SessionStatus.exception);
      expect(partly.payableDuration, isNull);
    });

    test('a session without a clock-out can never be approved', () {
      final events = [e.clockIn(5, 8, 0)];
      final key = build(events).sessions.single.issues.single.key;

      final session = builder
          .build(events, now: later, acceptedIssueKeys: {key})
          .sessions
          .single;

      expect(session.status, SessionStatus.exception);
      expect(session.payableDuration, isNull);
    });

    test('issue keys are stable across rebuilds', () {
      final events = [
        e.clockIn(5, 8, 0),
        e.clockIn(5, 8, 1),
        e.clockOut(5, 17, 0),
      ];

      expect(
        build(events).issues.single.key,
        build(events.reversed.toList()).issues.single.key,
      );
      expect(build(events).issues.single.key, 'duplicateClockIn:ev-002');
    });
  });
}
