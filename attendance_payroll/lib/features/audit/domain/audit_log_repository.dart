import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';

/// Append-only audit trail. Entries are never updated or deleted.
abstract interface class AuditLogRepository {
  /// Records [entry] with the current time and this device's id. Call it in
  /// the same transaction as the change it describes.
  Future<Result<void>> record(AuditEntry entry);

  /// Entries about one entity, newest first.
  Future<Result<List<AuditRecord>>> forEntity(
    String entityType,
    String entityId,
  );
}

/// A stored audit entry.
final class AuditRecord {
  const AuditRecord({
    required this.action,
    required this.actorType,
    required this.actorId,
    required this.occurredAt,
    required this.metadata,
  });

  /// The action's stable code, e.g. `payroll.finalized`.
  final String action;
  final AuditActorType actorType;
  final String? actorId;
  final DateTime occurredAt;
  final Map<String, Object?> metadata;
}
