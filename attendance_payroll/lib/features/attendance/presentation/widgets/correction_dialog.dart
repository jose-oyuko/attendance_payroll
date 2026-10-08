import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/presentation/attendance_formatting.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/formatting/date_formatting.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/date_field.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the administrator wants to correct.
sealed class CorrectionRequest {
  const CorrectionRequest();
}

/// Add a clock action the employee forgot.
final class AddEntryRequest extends CorrectionRequest {
  const AddEntryRequest({
    required this.employeeId,
    required this.date,
    this.type = AttendanceEventType.clockIn,
  });

  final String employeeId;
  final LocalDate date;
  final AttendanceEventType type;
}

/// Change the time of an existing entry.
final class ChangeTimeRequest extends CorrectionRequest {
  const ChangeTimeRequest({
    required this.eventId,
    required this.type,
    required this.occurredAt,
  });

  final String eventId;
  final AttendanceEventType type;
  final DateTime occurredAt;
}

/// Stop an entry from counting.
final class RemoveEntryRequest extends CorrectionRequest {
  const RemoveEntryRequest({
    required this.eventId,
    required this.type,
    required this.occurredAt,
  });

  final String eventId;
  final AttendanceEventType type;
  final DateTime occurredAt;
}

/// Shows the correction form. Resolves to `true` once a correction is saved.
Future<bool> showCorrectionDialog(
  BuildContext context, {
  required CorrectionRequest request,
  required CompanyTimeZone zone,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _CorrectionDialog(request: request, zone: zone),
  );
  return saved ?? false;
}

class _CorrectionDialog extends ConsumerStatefulWidget {
  const _CorrectionDialog({required this.request, required this.zone});

  final CorrectionRequest request;
  final CompanyTimeZone zone;

  @override
  ConsumerState<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends ConsumerState<_CorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late AttendanceEventType _type;
  LocalDate? _date;
  TimeOfDay? _time;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    switch (widget.request) {
      case AddEntryRequest(:final type, :final date):
        _type = type;
        _date = date;
      case ChangeTimeRequest(:final type, :final occurredAt) ||
          RemoveEntryRequest(:final type, :final occurredAt):
        _type = type;
        final wall = widget.zone.wallTimeOf(occurredAt);
        _date = wall.date;
        _time = TimeOfDay(
          hour: wall.timeOfDay.inHours,
          minute: wall.timeOfDay.inMinutes % Duration.minutesPerHour,
        );
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  DateTime? get _chosenInstant {
    final date = _date;
    final time = _time;
    if (date == null || time == null) {
      return null;
    }
    return widget.zone.instantAt(
      date,
      Duration(hours: time.hour, minutes: time.minute),
    );
  }

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(attendanceCorrectionServiceProvider);
    final reason = _reason.text;
    final result = switch (widget.request) {
      AddEntryRequest(:final employeeId) => await service.addMissingEntry(
        session,
        employeeId,
        type: _type,
        occurredAt: _chosenInstant!,
        reason: reason,
      ),
      ChangeTimeRequest(:final eventId) => await service.changeTime(
        session,
        eventId,
        newOccurredAt: _chosenInstant!,
        reason: reason,
      ),
      RemoveEntryRequest(:final eventId) => await service.removeEntry(
        session,
        eventId,
        reason: reason,
      ),
    };
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.userMessage;
        });
    }
  }

  String get _title => switch (widget.request) {
    AddEntryRequest() => 'Add missing entry',
    ChangeTimeRequest() => 'Change ${_type.label.toLowerCase()} time',
    RemoveEntryRequest() => 'Remove ${_type.label.toLowerCase()}',
  };

  String get _saveLabel => switch (widget.request) {
    AddEntryRequest() => 'Add entry',
    ChangeTimeRequest() => 'Save new time',
    RemoveEntryRequest() => 'Remove entry',
  };

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final error = _error;
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (error != null) FailureBanner(message: error),
              ...switch (request) {
                AddEntryRequest() => [
                  SegmentedButton<AttendanceEventType>(
                    segments: [
                      for (final type in AttendanceEventType.values)
                        ButtonSegment(value: type, label: Text(type.label)),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) =>
                        setState(() => _type = selection.first),
                  ),
                  ..._dateAndTime(),
                ],
                ChangeTimeRequest(:final occurredAt) => [
                  Text(
                    'Recorded at '
                    '${formatCompanyTime(context, widget.zone, occurredAt)} on '
                    '${formatLocalDate(context, widget.zone.dateOf(occurredAt))}.'
                    ' The original entry is kept in the history.',
                  ),
                  ..._dateAndTime(),
                ],
                RemoveEntryRequest(:final occurredAt) => [
                  Text(
                    'The ${_type.label.toLowerCase()} at '
                    '${formatCompanyTime(context, widget.zone, occurredAt)} on '
                    '${formatLocalDate(context, widget.zone.dateOf(occurredAt))}'
                    ' will no longer count. It stays in the history.',
                  ),
                ],
              },
              TextFormField(
                controller: _reason,
                maxLength: CorrectionReason.maxLength,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'For example: forgot to clock out',
                ),
                validator: (value) =>
                    CorrectionReason.validate(value ?? '')?.userMessage,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        BusyButton(label: _saveLabel, busy: _busy, onPressed: _save),
      ],
    );
  }

  List<Widget> _dateAndTime() {
    return [
      DateField(
        label: 'Date',
        value: _date,
        onChanged: (date) => setState(() => _date = date),
        validator: (date) => date == null ? 'Choose a date.' : null,
      ),
      TimeField(
        label: 'Time (company time)',
        value: _time,
        onChanged: (time) => setState(() => _time = time),
        validator: (time) => time == null ? 'Choose a time.' : null,
      ),
    ];
  }
}
