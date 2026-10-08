import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/company/presentation/current_company_provider.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An employee and a range of company dates.
typedef AttendanceQuery = ({String employeeId, LocalDate from, LocalDate to});

final attendanceEmployeeProvider = FutureProvider.autoDispose
    .family<Employee, String>((ref, employeeId) async {
      final session = requireSession(ref);
      return (await ref
              .watch(employeeManagementServiceProvider)
              .get(session, employeeId))
          .unwrap();
    });

final attendanceTimelineProvider = FutureProvider.autoDispose
    .family<AttendanceTimeline, AttendanceQuery>((ref, query) async {
      final session = requireSession(ref);
      return (await ref
              .watch(attendanceServiceProvider)
              .timeline(
                session,
                query.employeeId,
                from: query.from,
                to: query.to,
              ))
          .unwrap();
    });

final correctionHistoryProvider = FutureProvider.autoDispose
    .family<List<AttendanceCorrection>, AttendanceQuery>((ref, query) async {
      final session = requireSession(ref);
      final zone = await ref.watch(companyTimeZoneProvider.future);
      final range = zone.rangeOf(query.from, query.to);
      return (await ref
              .watch(attendanceCorrectionServiceProvider)
              .history(
                session,
                query.employeeId,
                from: range.start,
                to: range.end,
              ))
          .unwrap();
    });

/// Administrator display names by id, for showing who made a correction.
final adminNamesProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final session = requireSession(ref);
  final admins =
      (await ref
              .watch(adminUserRepositoryProvider)
              .listByCompany(session.companyId))
          .unwrap();
  return {for (final admin in admins) admin.id: admin.displayName};
});

/// Everyone's attendance on one company date.
final dailyAttendanceProvider = FutureProvider.autoDispose
    .family<DailyAttendance, LocalDate>((ref, date) async {
      final session = requireSession(ref);
      return (await ref.watch(attendanceServiceProvider).day(session, date))
          .unwrap();
    });

/// Today's attendance, by the company's calendar.
final todaysAttendanceProvider = FutureProvider.autoDispose<DailyAttendance>((
  ref,
) async {
  final zone = await ref.watch(companyTimeZoneProvider.future);
  return ref.watch(dailyAttendanceProvider(zone.dateOf(DateTime.now())).future);
});
