import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
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

/// Increases whenever attendance data changes (a correction or an exception
/// decision). Every derived attendance view watches it, so a change made on
/// one screen refreshes all of them, including those kept alive in other
/// tabs.
class AttendanceRevision extends Notifier<int> {
  @override
  int build() => 0;

  void changed() => state++;
}

final attendanceRevisionProvider = NotifierProvider<AttendanceRevision, int>(
  AttendanceRevision.new,
);

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
      ref.watch(attendanceRevisionProvider);
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
      ref.watch(attendanceRevisionProvider);
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
      ref.watch(attendanceRevisionProvider);
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

/// A range of company dates.
typedef DateRange = ({LocalDate from, LocalDate to});

/// Exceptions revealed in a range, newest first.
final exceptionsProvider = FutureProvider.autoDispose
    .family<List<AttendanceException>, DateRange>((ref, range) async {
      ref.watch(attendanceRevisionProvider);
      final session = requireSession(ref);
      return (await ref
              .watch(attendanceExceptionServiceProvider)
              .list(session, from: range.from, to: range.to))
          .unwrap();
    });

/// How far back the dashboard and the default exceptions view look.
const int recentExceptionDays = 30;

/// The last [recentExceptionDays] company days, up to today.
final recentRangeProvider = FutureProvider.autoDispose<DateRange>((ref) async {
  final zone = await ref.watch(companyTimeZoneProvider.future);
  final today = zone.dateOf(DateTime.now());
  return (from: today.addDays(1 - recentExceptionDays), to: today);
});

/// Exceptions in the recent range still waiting for a decision.
final openExceptionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final range = await ref.watch(recentRangeProvider.future);
  final exceptions = await ref.watch(exceptionsProvider(range).future);
  return exceptions.where((e) => e.status.needsAction).length;
});
