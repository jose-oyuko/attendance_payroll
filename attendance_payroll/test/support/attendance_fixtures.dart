import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';

final CompanyTimeZone nairobi = CompanyTimeZone('Africa/Nairobi');

/// The UTC instant of a Nairobi wall-clock time in October 2026, e.g.
/// `nairobiTime(5, 8, 2)` is 5 Oct 2026 08:02 local.
DateTime nairobiTime(int day, int hour, int minute) {
  return nairobi
      .startOfDay(LocalDate(2026, 10, day))
      .add(Duration(hours: hour, minutes: minute));
}

/// Builds events with unique, ordered ids for one employee.
class EventFactory {
  EventFactory({this.employeeId = 'emp-1'});

  final String employeeId;
  int _count = 0;

  AttendanceEvent at(
    AttendanceEventType type,
    DateTime occurredAt, {
    DateTime? recordedAt,
    String? id,
  }) {
    _count++;
    return AttendanceEvent(
      id: id ?? 'ev-${_count.toString().padLeft(3, '0')}',
      employeeId: employeeId,
      type: type,
      occurredAt: occurredAt,
      recordedAt: recordedAt ?? occurredAt,
      source: AttendanceEventSource.kiosk,
      deviceId: 'device-1',
      createdBy: employeeId,
    );
  }

  /// Clock-in at a Nairobi wall-clock time in October 2026.
  AttendanceEvent clockIn(int day, int hour, int minute) =>
      at(AttendanceEventType.clockIn, nairobiTime(day, hour, minute));

  /// Clock-out at a Nairobi wall-clock time in October 2026.
  AttendanceEvent clockOut(int day, int hour, int minute) =>
      at(AttendanceEventType.clockOut, nairobiTime(day, hour, minute));
}
