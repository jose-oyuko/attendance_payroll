import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/day_schedule.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';
import 'package:attendance_payroll/features/schedules/domain/schedule_repositories.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';

/// Work schedules and who follows which, for administrators.
final class WorkScheduleService {
  WorkScheduleService({
    required this._schedules,
    required this._assignments,
    required this._employees,
    required this._audit,
    required this._transactions,
  });

  final WorkScheduleRepository _schedules;
  final ScheduleAssignmentRepository _assignments;
  final EmployeeRepository _employees;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;

  Future<Result<List<WorkSchedule>>> list(AdminSession session) async {
    if (session.check(Permission.viewSchedules) case final denied?) {
      return Err(denied);
    }
    return _schedules.listByCompany(session.companyId);
  }

  Future<Result<WorkSchedule>> get(AdminSession session, String id) async {
    if (session.check(Permission.viewSchedules) case final denied?) {
      return Err(denied);
    }
    return _scheduleOf(session, id);
  }

  Future<Result<WorkSchedule>> create(
    AdminSession session,
    WorkScheduleDetails details,
  ) async {
    if (session.check(Permission.manageSchedules) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final created = (await _schedules.create(
        session.companyId,
        details,
      )).unwrap();
      await _record(
        session,
        AuditAction.scheduleCreated,
        'work_schedule',
        created.id,
      );
      return created;
    });
  }

  /// Changes a schedule. It applies to every date its employees are on it,
  /// including past ones, until those dates' payroll is finalized.
  Future<Result<WorkSchedule>> update(
    AdminSession session,
    String id,
    WorkScheduleDetails details, {
    required int expectedVersion,
  }) async {
    if (session.check(Permission.manageSchedules) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      final before = (await _scheduleOf(session, id)).unwrap();
      final after = (await _schedules.update(
        id,
        details,
        expectedVersion: expectedVersion,
      )).unwrap();
      await _record(
        session,
        AuditAction.scheduleUpdated,
        'work_schedule',
        id,
        metadata: {'fields': after.details.changedFieldsFrom(before.details)},
      );
      return after;
    });
  }

  /// Puts the employee on [scheduleId] (or no schedule) from [effectiveFrom].
  Future<Result<ScheduleAssignment>> assign(
    AdminSession session,
    String employeeId,
    String? scheduleId, {
    required LocalDate effectiveFrom,
  }) async {
    if (session.check(Permission.manageSchedules) case final denied?) {
      return Err(denied);
    }
    return _transactions.run(() async {
      (await _employees.getInCompany(session.companyId, employeeId)).unwrap();
      if (scheduleId != null) {
        (await _scheduleOf(session, scheduleId)).unwrap();
      }
      final assignment = (await _assignments.assign(
        employeeId,
        scheduleId,
        effectiveFrom: effectiveFrom,
      )).unwrap();
      await _record(
        session,
        AuditAction.employeeScheduleAssigned,
        'employee',
        employeeId,
        metadata: {
          'scheduleId': scheduleId,
          'effectiveFrom': effectiveFrom.toIsoString(),
        },
      );
      return assignment;
    });
  }

  /// The employee's schedule history, oldest first.
  Future<Result<List<ScheduleAssignment>>> history(
    AdminSession session,
    String employeeId,
  ) async {
    if (session.check(Permission.viewSchedules) case final denied?) {
      return Err(denied);
    }
    final employee = await _employees.getInCompany(
      session.companyId,
      employeeId,
    );
    if (employee case Err(:final failure)) {
      return Err(failure);
    }
    return _assignments.history(employeeId);
  }

  Future<Result<WorkSchedule>> _scheduleOf(
    AdminSession session,
    String id,
  ) async {
    final found = await _schedules.getById(id);
    return switch (found) {
      Ok(:final value) when value.companyId != session.companyId => const Err(
        NotFoundFailure(entity: 'schedule'),
      ),
      _ => found,
    };
  }

  Future<void> _record(
    AdminSession session,
    AuditAction action,
    String entityType,
    String entityId, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    (await _audit.record(
      AuditEntry(
        companyId: session.companyId,
        actorType: AuditActorType.admin,
        actorId: session.admin.id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
      ),
    )).unwrap();
  }
}

/// Supplies attendance with each employee's expectations, from their
/// schedule assignments.
final class CompanyScheduleSource implements ScheduleSource {
  CompanyScheduleSource({required this._schedules, required this._assignments});

  final WorkScheduleRepository _schedules;
  final ScheduleAssignmentRepository _assignments;

  @override
  Future<Result<Map<String, ScheduleLookup>>> forCompany(
    String companyId, {
    required CompanyTimeZone timeZone,
  }) {
    return Result.guard(() async {
      final schedules = {
        for (final s in (await _schedules.listByCompany(companyId)).unwrap())
          s.id: s.details,
      };
      final byEmployee = <String, List<ScheduleAssignment>>{};
      for (final a in (await _assignments.forCompany(companyId)).unwrap()) {
        (byEmployee[a.employeeId] ??= []).add(a);
      }
      return {
        for (final MapEntry(key: employeeId, value: assignments)
            in byEmployee.entries)
          employeeId: (LocalDate date) {
            for (final assignment in assignments) {
              if (assignment.appliesOn(date)) {
                final schedule = schedules[assignment.scheduleId];
                return schedule == null
                    ? const Unscheduled()
                    : schedule.dayScheduleOn(date, timeZone);
              }
            }
            return const Unscheduled();
          },
      };
    });
  }
}
