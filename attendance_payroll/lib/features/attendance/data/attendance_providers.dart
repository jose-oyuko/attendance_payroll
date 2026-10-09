import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/attendance/data/drift_attendance_correction_repository.dart';
import 'package:attendance_payroll/features/attendance/data/drift_attendance_event_repository.dart';
import 'package:attendance_payroll/features/attendance/data/drift_attendance_settings_repository.dart';
import 'package:attendance_payroll/features/attendance/data/drift_exception_review_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_reader.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_service.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/company/data/company_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/schedules/data/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final attendanceEventRepositoryProvider = Provider<AttendanceEventRepository>(
  (ref) => DriftAttendanceEventRepository(ref.watch(appDatabaseProvider)),
);

final attendanceSettingsRepositoryProvider =
    Provider<AttendanceSettingsRepository>(
      (ref) =>
          DriftAttendanceSettingsRepository(ref.watch(appDatabaseProvider)),
    );

final attendanceCorrectionRepositoryProvider =
    Provider<AttendanceCorrectionRepository>(
      (ref) =>
          DriftAttendanceCorrectionRepository(ref.watch(appDatabaseProvider)),
    );

final exceptionReviewRepositoryProvider = Provider<ExceptionReviewRepository>(
  (ref) => DriftExceptionReviewRepository(ref.watch(appDatabaseProvider)),
);

final attendanceReaderProvider = Provider<AttendanceReader>(
  (ref) => AttendanceReader(
    companies: ref.watch(companyRepositoryProvider),
    employees: ref.watch(employeeRepositoryProvider),
    events: ref.watch(attendanceEventRepositoryProvider),
    settings: ref.watch(attendanceSettingsRepositoryProvider),
    reviews: ref.watch(exceptionReviewRepositoryProvider),
    schedules: ref.watch(scheduleSourceProvider),
  ),
);

final attendanceServiceProvider = Provider<AttendanceService>(
  (ref) => AttendanceService(
    employees: ref.watch(employeeRepositoryProvider),
    events: ref.watch(attendanceEventRepositoryProvider),
    devices: ref.watch(deviceIdentityRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
    reader: ref.watch(attendanceReaderProvider),
  ),
);

final attendanceExceptionServiceProvider = Provider<AttendanceExceptionService>(
  (ref) => AttendanceExceptionService(
    reader: ref.watch(attendanceReaderProvider),
    reviews: ref.watch(exceptionReviewRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  ),
);

final attendanceSettingsServiceProvider = Provider<AttendanceSettingsService>(
  (ref) => AttendanceSettingsService(
    settings: ref.watch(attendanceSettingsRepositoryProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  ),
);

final attendanceCorrectionServiceProvider =
    Provider<AttendanceCorrectionService>(
      (ref) => AttendanceCorrectionService(
        employees: ref.watch(employeeRepositoryProvider),
        events: ref.watch(attendanceEventRepositoryProvider),
        corrections: ref.watch(attendanceCorrectionRepositoryProvider),
        reviews: ref.watch(exceptionReviewRepositoryProvider),
        devices: ref.watch(deviceIdentityRepositoryProvider),
        audit: ref.watch(auditLogRepositoryProvider),
        transactions: ref.watch(transactionRunnerProvider),
      ),
    );
