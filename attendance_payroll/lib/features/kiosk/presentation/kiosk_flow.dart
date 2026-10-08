import 'dart:async';

import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/data/attendance_providers.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_service.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_state.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/authentication/domain/pin_policy.dart';
import 'package:attendance_payroll/features/kiosk/data/kiosk_providers.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where an employee is in the kiosk flow:
///
/// ```
/// ChoosingEmployee → EnteringPin → (ChoosingNewPin) → Confirming → Finished
/// ```
///
/// Every step except the first times out back to the start, so a walked-away
/// employee never leaves their PIN entry or confirmation on screen.
sealed class KioskStep {
  const KioskStep();
}

final class ChoosingEmployee extends KioskStep {
  const ChoosingEmployee();
}

final class EnteringPin extends KioskStep {
  const EnteringPin(this.employee, {this.error});

  final KioskEmployee employee;
  final String? error;
}

/// Choosing a new PIN: required when the current one is temporary, or by
/// choice from the confirmation step.
final class ChoosingNewPin extends KioskStep {
  const ChoosingNewPin({
    required this.employee,
    required this.currentPin,
    required this.isRequired,
    this.firstEntry,
    this.error,
  });

  final KioskEmployee employee;

  /// Held only for the few seconds of this step, to prove the change.
  final String currentPin;
  final bool isRequired;

  /// The new PIN entered once, awaiting confirmation.
  final String? firstEntry;
  final String? error;
}

final class Confirming extends KioskStep {
  const Confirming({
    required this.employee,
    required this.verification,
    required this.state,
    required this.pin,
    this.message,
    this.error,
  });

  final KioskEmployee employee;
  final PinVerification verification;
  final AttendanceState state;
  final String pin;

  /// Positive note, e.g. after a PIN change.
  final String? message;
  final String? error;
}

final class Finished extends KioskStep {
  const Finished({required this.employee, required this.event});

  final KioskEmployee employee;
  final AttendanceEvent event;
}

/// The kiosk step plus whether an operation is running.
final class KioskFlowState {
  const KioskFlowState(this.step, {this.busy = false});

  final KioskStep step;
  final bool busy;
}

class KioskFlow extends Notifier<KioskFlowState> {
  /// Idle time before an unfinished step returns to the start.
  static const Duration inactivityTimeout = Duration(seconds: 30);

  /// How long the confirmation message stays up.
  static const Duration finishedDisplay = Duration(seconds: 5);

  Timer? _timer;

  @override
  KioskFlowState build() {
    ref.onDispose(() => _timer?.cancel());
    return const KioskFlowState(ChoosingEmployee());
  }

  void selectEmployee(KioskEmployee employee) => _go(EnteringPin(employee));

  void reset() => _go(const ChoosingEmployee());

  /// Any interaction restarts the inactivity timer.
  void touch() => _restartTimer(state.step);

  Future<void> submitPin(String pin) async {
    final step = state.step;
    if (step is! EnteringPin || state.busy) {
      return;
    }
    _busy();
    final verified = await ref
        .read(kioskServiceProvider)
        .verifyPin(step.employee.id, pin);
    switch (verified) {
      case Err(:final failure):
        _go(EnteringPin(step.employee, error: failure.userMessage));
      case Ok(:final value) when value.mustChangePin:
        _go(
          ChoosingNewPin(
            employee: step.employee,
            currentPin: pin,
            isRequired: true,
          ),
        );
      case Ok(:final value):
        await _confirm(step.employee, value, pin);
    }
  }

  void startPinChange() {
    final step = state.step;
    if (step is Confirming) {
      _go(
        ChoosingNewPin(
          employee: step.employee,
          currentPin: step.pin,
          isRequired: false,
        ),
      );
    }
  }

  Future<void> submitNewPin(String pin) async {
    final step = state.step;
    if (step is! ChoosingNewPin || state.busy) {
      return;
    }
    final first = step.firstEntry;
    if (first == null) {
      final invalid = PinPolicy.validate(pin);
      _go(
        ChoosingNewPin(
          employee: step.employee,
          currentPin: step.currentPin,
          isRequired: step.isRequired,
          firstEntry: invalid == null ? pin : null,
          error: invalid?.userMessage,
        ),
      );
      return;
    }
    if (pin != first) {
      _go(
        ChoosingNewPin(
          employee: step.employee,
          currentPin: step.currentPin,
          isRequired: step.isRequired,
          error: 'The PINs did not match. Choose your new PIN again.',
        ),
      );
      return;
    }
    _busy();
    final kiosk = ref.read(kioskServiceProvider);
    final changed = await kiosk.changePin(
      step.employee.id,
      currentPin: step.currentPin,
      newPin: pin,
    );
    if (changed case Err(:final failure)) {
      _go(
        ChoosingNewPin(
          employee: step.employee,
          currentPin: step.currentPin,
          isRequired: step.isRequired,
          error: failure.userMessage,
        ),
      );
      return;
    }
    final verified = await kiosk.verifyPin(step.employee.id, pin);
    switch (verified) {
      case Err(:final failure):
        _go(EnteringPin(step.employee, error: failure.userMessage));
      case Ok(:final value):
        await _confirm(step.employee, value, pin, message: 'PIN changed.');
    }
  }

  Future<void> clock(AttendanceEventType action) async {
    final step = state.step;
    if (step is! Confirming || state.busy) {
      return;
    }
    _busy();
    final service = ref.read(attendanceServiceProvider);
    final result = action == AttendanceEventType.clockIn
        ? await service.clockIn(step.verification)
        : await service.clockOut(step.verification);
    switch (result) {
      case Ok(:final ClockResult value):
        _go(Finished(employee: step.employee, event: value.event));
      case Err(:final failure):
        _go(
          Confirming(
            employee: step.employee,
            verification: step.verification,
            state: step.state,
            pin: step.pin,
            error: failure.userMessage,
          ),
        );
    }
  }

  Future<void> _confirm(
    KioskEmployee employee,
    PinVerification verification,
    String pin, {
    String? message,
  }) async {
    final current = await ref
        .read(attendanceServiceProvider)
        .currentState(verification);
    switch (current) {
      case Err(:final failure):
        _go(EnteringPin(employee, error: failure.userMessage));
      case Ok(:final value):
        _go(
          Confirming(
            employee: employee,
            verification: verification,
            state: value,
            pin: pin,
            message: message,
          ),
        );
    }
  }

  void _busy() {
    state = KioskFlowState(state.step, busy: true);
  }

  void _go(KioskStep step) {
    state = KioskFlowState(step);
    _restartTimer(step);
  }

  void _restartTimer(KioskStep step) {
    _timer?.cancel();
    final timeout = switch (step) {
      ChoosingEmployee() => null,
      Finished() => finishedDisplay,
      _ => inactivityTimeout,
    };
    if (timeout != null) {
      _timer = Timer(timeout, reset);
    }
  }
}

final kioskFlowProvider = NotifierProvider<KioskFlow, KioskFlowState>(
  KioskFlow.new,
);

/// Employees to choose from on the kiosk.
final kioskEmployeesProvider = FutureProvider.autoDispose<List<KioskEmployee>>(
  (ref) async => (await ref.watch(kioskServiceProvider).employees()).unwrap(),
);
