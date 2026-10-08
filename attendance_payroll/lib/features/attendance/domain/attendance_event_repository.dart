import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';

/// Append-only store of attendance events. There is deliberately no update or
/// delete.
///
/// Queries return only events that currently count: an event superseded by
/// an administrator's correction is kept but left out (see
/// `AttendanceCorrection`).
abstract interface class AttendanceEventRepository {
  Future<Result<AttendanceEvent>> append(NewAttendanceEvent event);

  /// Any event by id, including superseded ones, with whether it still
  /// counts.
  Future<Result<({AttendanceEvent event, bool isSuperseded})>> getById(
    String id,
  );

  /// The employee's most recent counting event in chronological order, or
  /// `null`.
  Future<Result<AttendanceEvent?>> latestFor(String employeeId);

  /// The employee's counting events with `occurredAt` in `[from, to)`, in
  /// chronological order.
  Future<Result<List<AttendanceEvent>>> between(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  });

  /// Counting events of every employee of [companyId] with `occurredAt` in
  /// `[from, to)`, in chronological order.
  Future<Result<List<AttendanceEvent>>> betweenForCompany(
    String companyId, {
    required DateTime from,
    required DateTime to,
  });
}
