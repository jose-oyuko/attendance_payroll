import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';

/// Append-only audit trail. Entries are never updated or deleted.
abstract interface class AuditLogRepository {
  /// Records [entry] with the current time and this device's id. Call it in
  /// the same transaction as the change it describes.
  Future<Result<void>> record(AuditEntry entry);
}
