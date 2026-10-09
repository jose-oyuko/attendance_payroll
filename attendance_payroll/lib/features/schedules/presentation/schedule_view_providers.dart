import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/schedules/data/schedule_providers.dart';
import 'package:attendance_payroll/features/schedules/domain/work_schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final schedulesProvider = FutureProvider.autoDispose<List<WorkSchedule>>((
  ref,
) async {
  final session = requireSession(ref);
  return (await ref.watch(workScheduleServiceProvider).list(session)).unwrap();
});

final scheduleProvider = FutureProvider.autoDispose
    .family<WorkSchedule, String>((ref, id) async {
      final session = requireSession(ref);
      return (await ref.watch(workScheduleServiceProvider).get(session, id))
          .unwrap();
    });

/// An employee's schedule assignments, oldest first.
final scheduleHistoryProvider = FutureProvider.autoDispose
    .family<List<ScheduleAssignment>, String>((ref, employeeId) async {
      final session = requireSession(ref);
      return (await ref
              .watch(workScheduleServiceProvider)
              .history(session, employeeId))
          .unwrap();
    });
