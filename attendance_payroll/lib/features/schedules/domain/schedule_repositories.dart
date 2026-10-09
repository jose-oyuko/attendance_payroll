import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';

abstract interface class WorkScheduleRepository {
  /// Fails with a `ConflictFailure` when the name is already used in the
  /// company.
  Future<Result<WorkSchedule>> create(
    String companyId,
    WorkScheduleDetails details,
  );

  Future<Result<WorkSchedule>> getById(String id);

  /// The company's schedules, by name.
  Future<Result<List<WorkSchedule>>> listByCompany(String companyId);

  /// Replaces the details, including the working days. Fails with a
  /// `ConflictFailure` when [expectedVersion] is stale.
  Future<Result<WorkSchedule>> update(
    String id,
    WorkScheduleDetails details, {
    required int expectedVersion,
  });
}

/// Business rules for schedule assignment, reported as
/// `BusinessRuleFailure.rule`.
abstract final class ScheduleAssignmentRules {
  /// A new assignment must start after the latest one starts.
  static const String mustStartAfterLatest = 'schedule_must_start_after_latest';
}

abstract interface class ScheduleAssignmentRepository {
  /// Assigns [scheduleId] (or no schedule, when `null`) from [effectiveFrom].
  /// The current assignment is closed the day before. Fails with a
  /// `BusinessRuleFailure` ([ScheduleAssignmentRules.mustStartAfterLatest])
  /// when it does not start after the latest assignment.
  Future<Result<ScheduleAssignment>> assign(
    String employeeId,
    String? scheduleId, {
    required LocalDate effectiveFrom,
  });

  /// The employee's assignments, oldest first.
  Future<Result<List<ScheduleAssignment>>> history(String employeeId);

  /// Every assignment of the company's employees.
  Future<Result<List<ScheduleAssignment>>> forCompany(String companyId);
}
