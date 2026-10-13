import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/attendance/domain/daily_attendance.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_formatting.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_routes.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/formatting/time_formatting.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "08:02", one line per session; "…" while a session is open.
String _clockIns(BuildContext context, CompanyTimeZone zone, EmployeeDay d) =>
    d.sessions.isEmpty
    ? '—'
    : d.sessions
          .map((s) => formatCompanyTime(context, zone, s.start))
          .join('\n');

String _clockOuts(BuildContext context, CompanyTimeZone zone, EmployeeDay d) =>
    d.sessions.isEmpty
    ? '—'
    : d.sessions
          .map(
            (s) =>
                s.end == null ? '…' : formatCompanyTime(context, zone, s.end!),
          )
          .join('\n');

/// "08:02 – 12:00, 13:00 – …": every session of the day on one line.
String _sessions(BuildContext context, CompanyTimeZone zone, EmployeeDay d) => d
    .sessions
    .map(
      (s) =>
          '${formatCompanyTime(context, zone, s.start)} – '
          '${s.end == null ? '…' : formatCompanyTime(context, zone, s.end!)}',
    )
    .join(', ');

/// Payable time; time still awaiting review is not counted.
String _worked(EmployeeDay d) {
  if (d.sessions.isEmpty) {
    return '—';
  }
  final worked = formatWorkDuration(d.payable);
  return d.needsReview ? '$worked (review)' : worked;
}

/// The day's status, with lateness and leaving early added.
(String, SemanticColorSet) _status(BuildContext context, EmployeeDay d) {
  final semantic = context.semanticColors;
  final notes = [if (d.isLate) 'late', if (d.leftEarly) 'left early'];
  final label = notes.isEmpty
      ? d.status.label
      : '${d.status.label} · ${notes.join(', ')}';
  final colors = switch (d.status) {
    DayStatus.needsReview || DayStatus.absent => semantic.warning,
    DayStatus.working => semantic.info,
    DayStatus.present => notes.isEmpty ? semantic.success : semantic.warning,
    DayStatus.expected ||
    DayStatus.dayOff ||
    DayStatus.notClockedIn => semantic.neutral,
  };
  return (label, colors);
}

/// The distinct issues of the day, e.g. "Late arrival, Left early".
String _issues(EmployeeDay d) {
  final labels = {for (final i in d.issues) i.type.label};
  return labels.isEmpty ? '—' : labels.join(', ');
}

String _summary(AttendanceTotals t) =>
    '${formatWorkDuration(t.payable)} worked · ${_totalsText(t)}';

String _totalsText(AttendanceTotals t) => [
  '${t.present} present',
  if (t.late > 0) '${t.late} late',
  if (t.leftEarly > 0) '${t.leftEarly} left early',
  if (t.absent > 0) '${t.absent} absent',
  if (t.needsReview > 0) '${t.needsReview} to review',
].join(' · ');

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.day});

  final EmployeeDay day;

  @override
  Widget build(BuildContext context) {
    final (label, colors) = _status(context, day);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          label,
          style: context.textStyles.labelMedium?.copyWith(
            color: colors.onContainer,
          ),
        ),
      ),
    );
  }
}

/// One row per employee per day, with each employee's total, for wide
/// screens. Tapping a row opens the employee's attendance to correct it.
class AttendanceRangeTable extends StatelessWidget {
  const AttendanceRangeTable({
    required this.groups,
    required this.zone,
    super.key,
  });

  /// Each employee's days, in display order.
  final List<List<EmployeeDay>> groups;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context) {
    final bold = context.textStyles.titleSmall;
    final totalColor = context.colors.surfaceContainerHighest;
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          dataRowMinHeight: 48,
          dataRowMaxHeight: double.infinity,
          columns: const [
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Clock in')),
            DataColumn(label: Text('Clock out')),
            DataColumn(label: Text('Worked')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Exceptions')),
          ],
          rows: [
            for (final days in groups) ...[
              for (final d in days)
                DataRow(
                  onSelectChanged: (_) =>
                      context.go(AttendanceRoutes.employee(d.employee.id)),
                  cells: [
                    DataCell(Text(d.employee.details.shownName)),
                    DataCell(Text(formatLocalDate(context, d.date))),
                    DataCell(Text(_clockIns(context, zone, d))),
                    DataCell(Text(_clockOuts(context, zone, d))),
                    DataCell(Text(_worked(d))),
                    DataCell(_StatusLabel(day: d)),
                    DataCell(Text(_issues(d))),
                  ],
                ),
              _totalRow(days, bold, totalColor),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _totalRow(List<EmployeeDay> days, TextStyle? style, Color color) {
    final totals = AttendanceTotals(days);
    return DataRow(
      color: WidgetStatePropertyAll(color),
      cells: [
        DataCell(
          Text(
            'Total · ${days.first.employee.details.shownName}',
            style: style,
          ),
        ),
        DataCell(Text('${days.length} days', style: style)),
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(Text(formatWorkDuration(totals.payable), style: style)),
        DataCell(Text(_totalsText(totals), style: style)),
        const DataCell(Text('')),
      ],
    );
  }
}

/// The same rows for phones: one card per employee with their total, and
/// one line per day.
class AttendanceRangeList extends StatelessWidget {
  const AttendanceRangeList({
    required this.groups,
    required this.zone,
    super.key,
  });

  final List<List<EmployeeDay>> groups;
  final CompanyTimeZone zone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        for (final days in groups)
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(
                    days.first.employee.details.shownName,
                    style: context.textStyles.titleMedium,
                  ),
                  subtitle: Text(_summary(AttendanceTotals(days))),
                ),
                const Divider(height: 1),
                for (final d in days)
                  ListTile(
                    dense: true,
                    onTap: () =>
                        context.go(AttendanceRoutes.employee(d.employee.id)),
                    title: Text(formatLocalDate(context, d.date)),
                    // The status sits at the end of the row, or under the
                    // details when large text leaves no room beside the date.
                    subtitle: context.largeText
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  if (d.sessions.isNotEmpty)
                                    '${_sessions(context, zone, d)} · ${_worked(d)}',
                                  if (d.issues.isNotEmpty) _issues(d),
                                ].join('\n'),
                              ),
                              _StatusLabel(day: d),
                            ],
                          )
                        : Text(
                            [
                              if (d.sessions.isNotEmpty)
                                '${_sessions(context, zone, d)} · ${_worked(d)}',
                              if (d.issues.isNotEmpty) _issues(d),
                            ].join('\n'),
                          ),
                    trailing: context.largeText ? null : _StatusLabel(day: d),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
