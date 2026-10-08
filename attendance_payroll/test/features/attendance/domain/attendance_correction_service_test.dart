import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_state.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/attendance_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/test_env.dart';

void main() {
  late TestEnv env;
  late AdminSession admin;
  late Employee john;

  setUp(() async {
    env = TestEnv();
    admin = await env.setUpOwner();
    john = await env.addEmployee(admin);
  });

  /// John uses the kiosk at a Nairobi wall time in October 2026.
  Future<AttendanceEvent> kiosk(
    AttendanceEventType type,
    int day,
    int hour,
    int minute,
  ) async {
    final at = nairobiTime(day, hour, minute);
    env.clock.jumpTo(at.subtract(const Duration(seconds: 30)));
    final verification = await env.signInAtKiosk(admin, john);
    env.clock.jumpTo(at);
    final result = type == AttendanceEventType.clockIn
        ? await env.attendance.clockIn(verification)
        : await env.attendance.clockOut(verification);
    return result.unwrap().event;
  }

  /// The admin works at 18:00 on 6 October.
  void adminWorksLater() => env.clock.jumpTo(nairobiTime(6, 18, 0));

  Future<AttendanceTimeline> october5() async {
    return (await env.attendance.timeline(
      admin,
      john.id,
      from: LocalDate(2026, 10, 5),
      to: LocalDate(2026, 10, 5),
    )).unwrap();
  }

  group('adding a missing entry', () {
    test('a forgotten clock-out makes the day payable', () async {
      await kiosk(AttendanceEventType.clockIn, 5, 8, 2);
      adminWorksLater();
      expect(
        (await october5()).sessions.single.status,
        SessionStatus.exception,
      );

      final correction = (await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockOut,
        occurredAt: nairobiTime(5, 17, 0),
        reason: 'Employee forgot to clock out.',
      )).unwrap();

      expect(correction.kind, AttendanceCorrectionKind.added);
      expect(correction.correctedBy, admin.admin.id);
      final session = (await october5()).sessions.single;
      expect(session.status, SessionStatus.completed);
      expect(session.payableDuration, const Duration(hours: 8, minutes: 58));
      expect(session.isCorrected, isTrue);
      expect(session.clockOut!.source, AttendanceEventSource.admin);
      expect(session.clockOut!.createdBy, admin.admin.id);
    });

    test('a forgotten clock-in can be added for a whole day', () async {
      adminWorksLater();
      for (final (type, hour) in [
        (AttendanceEventType.clockIn, 8),
        (AttendanceEventType.clockOut, 17),
      ]) {
        (await env.attendanceCorrections.addMissingEntry(
          admin,
          john.id,
          type: type,
          occurredAt: nairobiTime(5, hour, 0),
          reason: 'Was on site; kiosk was offline.',
        )).unwrap();
      }

      expect(
        (await october5()).sessions.single.payableDuration,
        const Duration(hours: 9),
      );
    });

    test('the kiosk follows the corrected state', () async {
      await kiosk(AttendanceEventType.clockIn, 5, 8, 0);
      adminWorksLater();
      await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockOut,
        occurredAt: nairobiTime(5, 17, 0),
        reason: 'Forgot to clock out.',
      );

      final state = (await env.attendance.currentState(
        await env.signInAtKiosk(admin, john),
      )).unwrap();

      expect(state, isA<NotClockedIn>());
    });
  });

  group('changing a time', () {
    test('the new time counts and the original is kept', () async {
      // Spec §17: clock-out recorded at 14:00, corrected to 17:00.
      await kiosk(AttendanceEventType.clockIn, 5, 8, 0);
      final original = await kiosk(AttendanceEventType.clockOut, 5, 14, 0);
      adminWorksLater();

      final correction = (await env.attendanceCorrections.changeTime(
        admin,
        original.id,
        newOccurredAt: nairobiTime(5, 17, 0),
        reason: 'Employee forgot to clock out.',
      )).unwrap();

      expect(correction.previousOccurredAt, nairobiTime(5, 14, 0));
      expect(correction.newOccurredAt, nairobiTime(5, 17, 0));
      expect(correction.originalEventId, original.id);
      final session = (await october5()).sessions.single;
      expect(session.end, nairobiTime(5, 17, 0));
      expect(session.duration, const Duration(hours: 9));

      final kept = (await env.events.getById(original.id)).unwrap();
      expect(kept.event.occurredAt, nairobiTime(5, 14, 0));
      expect(kept.isSuperseded, isTrue);
      expect(await env.db.select(env.db.attendanceEvents).get(), hasLength(3));
    });

    test('an entry can only be corrected once; correct the new one', () async {
      final original = await kiosk(AttendanceEventType.clockIn, 5, 8, 0);
      adminWorksLater();
      final first = (await env.attendanceCorrections.changeTime(
        admin,
        original.id,
        newOccurredAt: nairobiTime(5, 7, 30),
        reason: 'Arrived earlier.',
      )).unwrap();

      final again = await env.attendanceCorrections.changeTime(
        admin,
        original.id,
        newOccurredAt: nairobiTime(5, 7, 45),
        reason: 'Second thoughts.',
      );
      final chained = await env.attendanceCorrections.changeTime(
        admin,
        first.replacementEventId!,
        newOccurredAt: nairobiTime(5, 7, 45),
        reason: 'Checked the gate log.',
      );

      expect(again.failureOrNull, isA<ConflictFailure>());
      expect(chained.isOk, isTrue);
      expect((await october5()).sessions.single.start, nairobiTime(5, 7, 45));
    });
  });

  test('removing a mistaken entry fixes the day', () async {
    // An accidental clock-out at 08:30 split the day.
    await kiosk(AttendanceEventType.clockIn, 5, 8, 0);
    final mistake = await kiosk(AttendanceEventType.clockOut, 5, 8, 30);
    await kiosk(AttendanceEventType.clockIn, 5, 8, 31);
    await kiosk(AttendanceEventType.clockOut, 5, 17, 0);
    adminWorksLater();
    final secondClockIn = (await october5()).sessions.last.clockIn;

    await env.attendanceCorrections.removeEntry(
      admin,
      mistake.id,
      reason: 'Pressed clock-out by mistake.',
    );
    await env.attendanceCorrections.removeEntry(
      admin,
      secondClockIn.id,
      reason: 'Pressed clock-out by mistake.',
    );

    final session = (await october5()).sessions.single;
    expect(session.duration, const Duration(hours: 9));
    expect(session.issues, isEmpty);
  });

  group('rules', () {
    test('a reason is required', () async {
      final result = await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockIn,
        occurredAt: nairobiTime(1, 8, 0),
        reason: '  ',
      );

      expect((result.failureOrNull! as ValidationFailure).field, 'reason');
    });

    test('corrections cannot be in the future', () async {
      final result = await env.attendanceCorrections.addMissingEntry(
        admin,
        john.id,
        type: AttendanceEventType.clockIn,
        occurredAt: env.clock().add(const Duration(hours: 1)),
        reason: 'Planned shift',
      );

      expect((result.failureOrNull! as ValidationFailure).field, 'time');
    });

    test("another company's attendance cannot be corrected", () async {
      final other = (await env.companies.create(
        const CompanyDetails(
          name: 'Other',
          currencyCode: 'KES',
          timezone: 'UTC',
        ),
      )).unwrap();
      final foreign = (await env.employees.create(
        other.id,
        johnDetails(),
      )).unwrap();

      final result = await env.attendanceCorrections.addMissingEntry(
        admin,
        foreign.id,
        type: AttendanceEventType.clockIn,
        occurredAt: nairobiTime(1, 8, 0),
        reason: 'Not mine to fix',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(await env.db.select(env.db.attendanceEvents).get(), isEmpty);
    });
  });

  test('every correction is audited and listed in the history', () async {
    final clockIn = await kiosk(AttendanceEventType.clockIn, 5, 8, 0);
    adminWorksLater();
    await env.attendanceCorrections.changeTime(
      admin,
      clockIn.id,
      newOccurredAt: nairobiTime(5, 7, 50),
      reason: 'Badge reader was slow.',
    );
    await env.attendanceCorrections.addMissingEntry(
      admin,
      john.id,
      type: AttendanceEventType.clockOut,
      occurredAt: nairobiTime(5, 17, 0),
      reason: 'Forgot to clock out.',
    );

    final rows = await env.auditRows();
    expect(rows.where((r) => r.action == 'attendance.corrected'), hasLength(2));
    final range = nairobi.rangeOf(
      LocalDate(2026, 10, 5),
      LocalDate(2026, 10, 5),
    );
    final history = (await env.attendanceCorrections.history(
      admin,
      john.id,
      from: range.start,
      to: range.end,
    )).unwrap();
    expect(history.map((c) => c.kind), [
      AttendanceCorrectionKind.added,
      AttendanceCorrectionKind.timeChanged,
    ]);
    expect(history.first.reason, 'Forgot to clock out.');
  });

  test('a correction whose audit fails leaves nothing behind', () async {
    final unaudited = AttendanceCorrectionService(
      employees: env.employees,
      events: env.events,
      corrections: env.corrections,
      devices: DriftDeviceIdentityRepository(env.db),
      audit: _FailingAudit(),
      transactions: env.transactions,
      clock: env.clock.call,
    );

    final result = await unaudited.addMissingEntry(
      admin,
      john.id,
      type: AttendanceEventType.clockIn,
      occurredAt: nairobiTime(1, 8, 0),
      reason: 'Should roll back',
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
    expect(await env.db.select(env.db.attendanceEvents).get(), isEmpty);
    expect(await env.db.select(env.db.attendanceCorrections).get(), isEmpty);
  });
}

/// Fails every write, to prove a correction rolls back with its audit entry.
class _FailingAudit implements AuditLogRepository {
  @override
  Future<Result<void>> record(AuditEntry entry) async {
    return const Err(DatabaseFailure());
  }
}
