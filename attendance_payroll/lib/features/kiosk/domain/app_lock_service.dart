import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';

/// Where this device keeps how long the app may sit untouched.
abstract interface class AppLockSettingsRepository {
  /// The saved time in minutes (0 for never), or `null` when none was chosen.
  Future<Result<int?>> lockAfterMinutes();

  Future<Result<void>> setLockAfterMinutes(int minutes);
}

/// When the app locks itself. Locked means the attendance kiosk is showing:
/// employees can clock in and out, and an administrator signs in to get
/// back to the rest of the app.
///
/// The time is a setting of this device, chosen by an administrator. It
/// exists so a workplace can pick what suits it: a shop counter that is
/// watched all day can wait longer than a phone left on a desk.
final class AppLockService {
  AppLockService({
    required this._settings,
    required this._audit,
    required this._transactions,
  });

  /// The time before anyone has chosen one.
  static const int defaultMinutes = 15;

  /// The value that means the app never locks by itself.
  static const int neverMinutes = 0;

  /// The longest time that can be chosen.
  static const int maxMinutes = 480;

  /// The times offered on screen, shortest first. [neverMinutes] is offered
  /// separately.
  static const List<int> choices = [1, 2, 5, 10, 15, 30, 60, 120];

  final AppLockSettingsRepository _settings;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;

  /// Minutes before the app locks, [neverMinutes] for never. Needs no
  /// session: it is read while deciding whether to lock one.
  Future<Result<int>> current() async {
    final saved = await _settings.lockAfterMinutes();
    return saved.map((minutes) => minutes ?? defaultMinutes);
  }

  /// Changes the time. Audited, because a long time (or never) is a decision
  /// about how exposed the payroll data is when the device is left alone.
  Future<Result<int>> setMinutes(AdminSession session, int value) async {
    if (session.check(Permission.manageKiosk) case final denied?) {
      return Err(denied);
    }
    if (value != neverMinutes && (value < 1 || value > maxMinutes)) {
      return const Err(
        ValidationFailure(
          field: 'lockAfterMinutes',
          userMessage: 'Choose between 1 minute and 8 hours, or never.',
        ),
      );
    }
    return _transactions.run(() async {
      final before = (await current()).unwrap();
      if (before == value) {
        return value;
      }
      (await _settings.setLockAfterMinutes(value)).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.appLockChanged,
          entityType: 'device',
          entityId: null,
          metadata: {'never': value == neverMinutes},
        ),
      )).unwrap();
      return value;
    });
  }
}
