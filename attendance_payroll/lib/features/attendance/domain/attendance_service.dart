import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/platform/device_identity_repository.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_event_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_repository.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_state.dart';
import 'package:attendance_payroll/features/attendance/domain/session_builder.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/employee_pin_service.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:attendance_payroll/features/employees/domain/employee_repository.dart';

/// The outcome of a clock action.
final class ClockResult {
  const ClockResult({required this.event, required this.state});

  final AttendanceEvent event;

  /// The employee's state after the action.
  final AttendanceState state;
}

/// Records clock-ins and clock-outs and derives attendance from them.
final class AttendanceService {
  AttendanceService({
    required this._employees,
    required this._companies,
    required this._events,
    required this._devices,
    required this._transactions,
    required this._settings,
    this._clock = systemClockUtc,
  });

  static const String pinChangeRequiredRule = 'pin_change_required';
  static const String unknownTimeZoneRule = 'unknown_time_zone';

  final EmployeeRepository _employees;
  final CompanyRepository _companies;
  final AttendanceEventRepository _events;
  final DeviceIdentityRepository _devices;
  final TransactionRunner _transactions;
  final AttendanceSettingsRepository _settings;
  final Clock _clock;

  /// The employee's current state, to show the right action at the kiosk.
  Future<Result<AttendanceState>> currentState(
    PinVerification verification,
  ) async {
    final now = _clock();
    if (_checkVerification(verification, now) case final failure?) {
      return Err(failure);
    }
    final policy = await _policyFor(verification.employee.companyId);
    if (policy case Err(:final failure)) {
      return Err(failure);
    }
    final latest = await _events.latestFor(verification.employee.id);
    return latest.map(
      (event) =>
          AttendanceStateMachine.stateAfter(event, now, policy.valueOrNull!),
    );
  }

  Future<Result<ClockResult>> clockIn(PinVerification verification) {
    return _record(verification, AttendanceEventType.clockIn);
  }

  Future<Result<ClockResult>> clockOut(PinVerification verification) {
    return _record(verification, AttendanceEventType.clockOut);
  }

  /// Sessions starting on company dates [from] to [to], and the issues found
  /// in that period.
  Future<Result<AttendanceTimeline>> timeline(
    AdminSession session,
    String employeeId, {
    required LocalDate from,
    required LocalDate to,
  }) async {
    if (session.check(Permission.viewAttendance) case final denied?) {
      return Err(denied);
    }
    if (to.isBefore(from)) {
      return const Err(
        ValidationFailure(
          field: 'to',
          userMessage: 'The end date cannot be before the start date.',
        ),
      );
    }
    final employee = await _employees.getInCompany(
      session.companyId,
      employeeId,
    );
    if (employee case Err(:final failure)) {
      return Err(failure);
    }
    final timeZone = await _companyTimeZone(session.companyId);
    if (timeZone case Err(:final failure)) {
      return Err(failure);
    }
    final loadedPolicy = await _policyFor(session.companyId);
    if (loadedPolicy case Err(:final failure)) {
      return Err(failure);
    }
    final policy = loadedPolicy.valueOrNull!;
    final zone = timeZone.valueOrNull!;
    final range = zone.rangeOf(from, to);
    // Load context either side so sessions crossing the range boundaries,
    // and duplicates near them, are interpreted exactly as in a wider view.
    final events = await _events.between(
      employeeId,
      from: range.start.subtract(policy.sessionLookaround),
      to: range.end.add(policy.sessionLookaround),
    );
    return events.map((loaded) {
      final full = SessionBuilder(
        policy: policy,
        timeZone: zone,
      ).build(loaded, now: _clock());
      bool inRange(DateTime instant) =>
          !instant.isBefore(range.start) && instant.isBefore(range.end);
      return AttendanceTimeline(
        sessions: [
          for (final s in full.sessions)
            if (!s.workDate.isBefore(from) && !s.workDate.isAfter(to)) s,
        ],
        issues: [
          for (final issue in full.issues)
            if (inRange(issue.occurredAt)) issue,
        ],
      );
    });
  }

  Future<Result<ClockResult>> _record(
    PinVerification verification,
    AttendanceEventType action,
  ) async {
    final now = _clock();
    if (_checkVerification(verification, now) case final failure?) {
      return Err(failure);
    }
    final device = await _devices.currentDeviceId();
    if (device case Err(:final failure)) {
      return Err(failure);
    }
    final employeeId = verification.employee.id;
    final loadedPolicy = await _policyFor(verification.employee.companyId);
    if (loadedPolicy case Err(:final failure)) {
      return Err(failure);
    }
    final policy = loadedPolicy.valueOrNull!;

    // One transaction: the state check and the new event cannot interleave
    // with another action for the same employee.
    return _transactions.run(() async {
      final employee = (await _employees.getById(employeeId)).unwrap();
      if (employee.details.employmentStatus != EmploymentStatus.active) {
        throw const AuthenticationFailure(
          userMessage: 'This employee cannot clock in. Contact your manager.',
        );
      }
      final latest = (await _events.latestFor(employeeId)).unwrap();
      final state = AttendanceStateMachine.stateAfter(latest, now, policy);
      final rejected = AttendanceStateMachine.check(
        state: state,
        action: action,
        latest: latest,
        now: now,
      );
      if (rejected != null) {
        throw rejected;
      }
      final event = (await _events.append(
        NewAttendanceEvent(
          employeeId: employeeId,
          type: action,
          occurredAt: now,
          recordedAt: now,
          source: AttendanceEventSource.kiosk,
          deviceId: device.valueOrNull!,
          createdBy: employeeId,
        ),
      )).unwrap();
      return ClockResult(
        event: event,
        state: AttendanceStateMachine.stateAfter(event, now, policy),
      );
    });
  }

  AppFailure? _checkVerification(PinVerification verification, DateTime now) {
    if (verification.mustChangePin) {
      return const BusinessRuleFailure(
        rule: pinChangeRequiredRule,
        userMessage: 'Change your temporary PIN before clocking in or out.',
      );
    }
    final age = now.difference(verification.verifiedAt);
    if (age.isNegative || age > AttendancePolicy.pinVerificationValidFor) {
      return const AuthenticationFailure(
        userMessage: 'Please enter your PIN again.',
      );
    }
    return null;
  }

  Future<Result<AttendancePolicy>> _policyFor(String companyId) async {
    return (await _settings.forCompany(companyId)).map((s) => s.policy);
  }

  Future<Result<CompanyTimeZone>> _companyTimeZone(String companyId) async {
    final company = await _companies.getById(companyId);
    return switch (company) {
      Err(:final failure) => Err(failure),
      Ok(:final value) when !CompanyTimeZone.isKnown(value.details.timezone) =>
        const Err(
          BusinessRuleFailure(
            rule: unknownTimeZoneRule,
            userMessage:
                "The company's timezone is not recognised. Update it in the "
                'company settings.',
          ),
        ),
      Ok(:final value) => Ok(CompanyTimeZone(value.details.timezone)),
    };
  }
}
