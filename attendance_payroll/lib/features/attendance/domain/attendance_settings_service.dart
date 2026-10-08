import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_settings_repository.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';

/// Reads and changes a company's attendance thresholds.
final class AttendanceSettingsService {
  AttendanceSettingsService({
    required this._settings,
    required this._audit,
    required this._transactions,
  });

  final AttendanceSettingsRepository _settings;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;

  Future<Result<StoredAttendancePolicy>> get(AdminSession session) async {
    if (session.check(Permission.viewAttendance) case final denied?) {
      return Err(denied);
    }
    return _settings.forCompany(session.companyId);
  }

  /// Saves [policy] for the session's company. Changes apply to how all
  /// attendance is interpreted from then on, including past sessions viewed
  /// later; recorded events never change.
  Future<Result<StoredAttendancePolicy>> update(
    AdminSession session,
    AttendancePolicy policy, {
    required int expectedVersion,
  }) async {
    if (session.check(Permission.manageAttendanceSettings) case final denied?) {
      return Err(denied);
    }
    if (policy.validate() case final invalid?) {
      return Err(invalid);
    }
    return _transactions.run(() async {
      final before = (await _settings.forCompany(session.companyId)).unwrap();
      final saved = (await _settings.save(
        session.companyId,
        policy,
        expectedVersion: expectedVersion,
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.attendanceSettingsChanged,
          entityType: 'attendance_settings',
          entityId: session.companyId,
          metadata: {'fields': policy.changedFieldsFrom(before.policy)},
        ),
      )).unwrap();
      return saved;
    });
  }
}
