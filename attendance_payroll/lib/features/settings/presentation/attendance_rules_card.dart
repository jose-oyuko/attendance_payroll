import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _storedPolicyProvider =
    FutureProvider.autoDispose<StoredAttendancePolicy>((ref) async {
      final session = requireSession(ref);
      return (await ref.watch(attendanceSettingsServiceProvider).get(session))
          .unwrap();
    });

/// The company's attendance thresholds. Every workplace differs, so each
/// company sets its own; changes are audited.
class AttendanceRulesCard extends ConsumerWidget {
  const AttendanceRulesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored = ref.watch(_storedPolicyProvider);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text('Attendance rules', style: context.textStyles.titleMedium),
            switch (stored) {
              AsyncData(:final value) => _RulesForm(
                key: ValueKey(value.version),
                stored: value,
              ),
              AsyncError(:final error) => Text(
                AppFailure.from(error).userMessage,
              ),
              _ => const LinearProgressIndicator(),
            },
          ],
        ),
      ),
    );
  }
}

class _RulesForm extends ConsumerStatefulWidget {
  const _RulesForm({required this.stored, super.key});

  final StoredAttendancePolicy stored;

  @override
  ConsumerState<_RulesForm> createState() => _RulesFormState();
}

class _RulesFormState extends ConsumerState<_RulesForm> {
  static final RegExp _number = RegExp(r'^\d+(\.\d{1,2})?$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _duplicateMinutes;
  late final TextEditingController _staleHours;
  late final TextEditingController _excessiveHours;
  late final TextEditingController _breakMinutes;
  late final TextEditingController _breakAfterHours;
  late bool _breakEnabled;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final policy = widget.stored.policy;
    final automaticBreak = policy.automaticBreak;
    _duplicateMinutes = TextEditingController(
      text: '${policy.duplicateWindow.inMinutes}',
    );
    _staleHours = TextEditingController(
      text: _hours(policy.staleOpenSessionAfter),
    );
    _excessiveHours = TextEditingController(
      text: _hours(policy.excessiveDurationAfter),
    );
    _breakEnabled = automaticBreak != null;
    _breakMinutes = TextEditingController(
      text: '${automaticBreak?.deduct.inMinutes ?? 60}',
    );
    _breakAfterHours = TextEditingController(
      text: automaticBreak == null ? '6' : _hours(automaticBreak.after),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _duplicateMinutes,
      _staleHours,
      _excessiveHours,
      _breakMinutes,
      _breakAfterHours,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// "16", "7.5": hours with at most two decimals, shown without trailing
  /// zeros.
  static String _hours(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes % Duration.minutesPerHour == 0) {
      return '${minutes ~/ Duration.minutesPerHour}';
    }
    return (minutes / Duration.minutesPerHour)
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '');
  }

  /// Durations only (not money), so converting through a double is exact
  /// enough: the result is rounded to whole minutes.
  static Duration? _parse(String text, {required bool hours}) {
    final trimmed = text.trim();
    if (!_number.hasMatch(trimmed)) {
      return null;
    }
    final value = double.parse(trimmed);
    return Duration(
      minutes: (hours ? value * Duration.minutesPerHour : value).round(),
    );
  }

  String? _validateNumber(String? text) {
    return _number.hasMatch((text ?? '').trim()) ? null : 'Enter a number.';
  }

  Future<void> _save() async {
    final session = ref.read(adminSessionProvider);
    if (_busy || session == null || !_formKey.currentState!.validate()) {
      return;
    }
    final policy = AttendancePolicy(
      duplicateWindow: _parse(_duplicateMinutes.text, hours: false)!,
      staleOpenSessionAfter: _parse(_staleHours.text, hours: true)!,
      excessiveDurationAfter: _parse(_excessiveHours.text, hours: true)!,
      automaticBreak: _breakEnabled
          ? AutomaticBreak(
              after: _parse(_breakAfterHours.text, hours: true)!,
              deduct: _parse(_breakMinutes.text, hours: false)!,
            )
          : null,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(attendanceSettingsServiceProvider)
        .update(session, policy, expectedVersion: widget.stored.version);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Ok():
        ref.invalidate(_storedPolicyProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance rules saved.')),
        );
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.userMessage;
        });
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String helper, {
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(labelText: label, helperText: helper),
      validator: enabled ? _validateNumber : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit =
        ref
            .watch(adminSessionProvider)
            ?.can(Permission.manageAttendanceSettings) ??
        false;
    final error = _error;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          if (error != null) FailureBanner(message: error),
          _numberField(
            _duplicateMinutes,
            'Ignore repeated taps within (minutes)',
            'A second clock-in or clock-out this soon is a double tap.',
            enabled: canEdit,
          ),
          _numberField(
            _staleHours,
            'Assume a forgotten clock-out after (hours)',
            'After this, the employee can clock in again and the old '
                'session is flagged.',
            enabled: canEdit,
          ),
          _numberField(
            _excessiveHours,
            'Flag sessions longer than (hours)',
            'Longer sessions need review before they are paid.',
            enabled: canEdit,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deduct an automatic break'),
            subtitle: const Text(
              'For workplaces where breaks are not clocked.',
            ),
            value: _breakEnabled,
            onChanged: canEdit
                ? (value) => setState(() => _breakEnabled = value)
                : null,
          ),
          if (_breakEnabled) ...[
            _numberField(
              _breakMinutes,
              'Break length (minutes)',
              'Deducted from payable time.',
              enabled: canEdit,
            ),
            _numberField(
              _breakAfterHours,
              'For sessions of at least (hours)',
              'Shorter sessions have no deduction.',
              enabled: canEdit,
            ),
          ],
          if (canEdit)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: BusyButton(
                label: 'Save rules',
                busy: _busy,
                onPressed: _save,
              ),
            ),
        ],
      ),
    );
  }
}
