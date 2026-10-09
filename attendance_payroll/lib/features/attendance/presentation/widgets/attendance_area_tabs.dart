import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_view_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AttendanceTab { daily, exceptions }

/// Switches between the daily view and the exceptions of the Attendance
/// area, showing how many exceptions need action.
class AttendanceAreaTabs extends ConsumerWidget {
  const AttendanceAreaTabs({required this.selected, super.key});

  final AttendanceTab selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openExceptionCountProvider).value ?? 0;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SegmentedButton<AttendanceTab>(
        showSelectedIcon: false,
        segments: [
          const ButtonSegment(
            value: AttendanceTab.daily,
            icon: Icon(Icons.today_outlined),
            label: Text('Daily'),
          ),
          ButtonSegment(
            value: AttendanceTab.exceptions,
            icon: Badge(
              isLabelVisible: open > 0,
              label: Text('$open'),
              child: const Icon(Icons.report_outlined),
            ),
            label: const Text('Exceptions'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => context.go(
          selection.first == AttendanceTab.daily
              ? AttendanceRoutes.day
              : AttendanceRoutes.exceptions,
        ),
      ),
    );
  }
}
