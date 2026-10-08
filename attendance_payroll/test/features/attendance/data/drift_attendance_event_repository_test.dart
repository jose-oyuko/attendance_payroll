import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late String employeeId;

  setUp(() async {
    env = TestEnv();
    final session = await env.setUpOwner();
    employeeId = (await env.addEmployee(session)).id;
  });

  NewAttendanceEvent event(
    AttendanceEventType type,
    DateTime occurredAt, {
    DateTime? recordedAt,
    String? employee,
  }) {
    return NewAttendanceEvent(
      employeeId: employee ?? employeeId,
      type: type,
      occurredAt: occurredAt,
      recordedAt: recordedAt ?? occurredAt,
      source: AttendanceEventSource.kiosk,
      deviceId: 'device-1',
      createdBy: employee ?? employeeId,
    );
  }

  test('appends and reads back every field', () async {
    final occurred = nairobiTime(5, 8, 2);
    final recorded = occurred.add(const Duration(seconds: 3));

    final stored = (await env.events.append(
      event(AttendanceEventType.clockIn, occurred, recordedAt: recorded),
    )).unwrap();
    final latest = (await env.events.latestFor(employeeId)).unwrap()!;

    expect(latest.id, stored.id);
    expect(latest.type, AttendanceEventType.clockIn);
    expect(latest.occurredAt, occurred);
    expect(latest.occurredAt.isUtc, isTrue);
    expect(latest.recordedAt, recorded);
    expect(latest.source, AttendanceEventSource.kiosk);
    expect(latest.deviceId, 'device-1');
    expect(latest.createdBy, employeeId);
  });

  test('latest follows occurrence time, not insertion order', () async {
    await env.events.append(
      event(AttendanceEventType.clockOut, nairobiTime(5, 17, 0)),
    );
    // Arrives later (for example from another device) but happened earlier.
    await env.events.append(
      event(AttendanceEventType.clockIn, nairobiTime(5, 8, 0)),
    );

    final latest = (await env.events.latestFor(employeeId)).unwrap()!;

    expect(latest.type, AttendanceEventType.clockOut);
  });

  test('between is half-open and chronological', () async {
    final times = [
      nairobiTime(5, 8, 0),
      nairobiTime(4, 8, 0),
      nairobiTime(6, 0, 0),
      nairobiTime(5, 23, 59),
    ];
    for (final time in times) {
      await env.events.append(event(AttendanceEventType.clockIn, time));
    }

    final found = (await env.events.between(
      employeeId,
      from: nairobiTime(5, 0, 0),
      to: nairobiTime(6, 0, 0),
    )).unwrap();

    expect(found.map((e) => e.occurredAt), [
      nairobiTime(5, 8, 0),
      nairobiTime(5, 23, 59),
    ]);
  });

  test('no history means no latest event', () async {
    expect((await env.events.latestFor(employeeId)).unwrap(), isNull);
  });

  test('events must belong to an existing employee', () async {
    final result = await env.events.append(
      event(
        AttendanceEventType.clockIn,
        nairobiTime(5, 8, 0),
        employee: 'nobody',
      ),
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}
