import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/day_schedule.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/schedules/data/drift_schedule_assignment_repository.dart';
import 'package:attendance_payroll/features/schedules/data/drift_work_schedule_repository.dart';
import 'package:attendance_payroll/features/schedules/domain/schedule_repositories.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workScheduleRepositoryProvider = Provider<WorkScheduleRepository>(
  (ref) => DriftWorkScheduleRepository(ref.watch(appDatabaseProvider)),
);

final scheduleAssignmentRepositoryProvider =
    Provider<ScheduleAssignmentRepository>(
      (ref) =>
          DriftScheduleAssignmentRepository(ref.watch(appDatabaseProvider)),
    );

final workScheduleServiceProvider = Provider<WorkScheduleService>(
  (ref) => WorkScheduleService(
    schedules: ref.watch(workScheduleRepositoryProvider),
    assignments: ref.watch(scheduleAssignmentRepositoryProvider),
    employees: ref.watch(employeeRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  ),
);

/// Schedules for attendance (see [ScheduleSource]).
final scheduleSourceProvider = Provider<ScheduleSource>(
  (ref) => CompanyScheduleSource(
    schedules: ref.watch(workScheduleRepositoryProvider),
    assignments: ref.watch(scheduleAssignmentRepositoryProvider),
  ),
);
