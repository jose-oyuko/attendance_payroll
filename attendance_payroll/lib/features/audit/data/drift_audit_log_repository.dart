import 'dart:convert';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/platform/device_identity_repository.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:drift/drift.dart';

final class DriftAuditLogRepository implements AuditLogRepository {
  DriftAuditLogRepository(
    this._db,
    this._devices, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final DeviceIdentityRepository _devices;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<void>> record(AuditEntry entry) {
    return guardDatabase(() async {
      final deviceId = (await _devices.currentDeviceId()).unwrap();
      await _db
          .into(_db.auditLog)
          .insert(
            AuditLogCompanion.insert(
              id: _newId(),
              companyId: entry.companyId,
              actorType: entry.actorType.name,
              actorId: Value(entry.actorId),
              action: entry.action.code,
              entityType: entry.entityType,
              entityId: Value(entry.entityId),
              occurredAt: _clock(),
              deviceId: deviceId,
              metadata: Value(
                entry.metadata.isEmpty ? null : jsonEncode(entry.metadata),
              ),
            ),
          );
    });
  }

  @override
  Future<Result<List<AuditRecord>>> forEntity(
    String entityType,
    String entityId,
  ) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.auditLog)
                ..where(
                  (a) =>
                      a.entityType.equals(entityType) &
                      a.entityId.equals(entityId),
                )
                ..orderBy([
                  (a) => OrderingTerm.desc(a.occurredAt),
                  (a) => OrderingTerm.desc(a.id),
                ]))
              .get();
      return [
        for (final row in rows)
          AuditRecord(
            action: row.action,
            actorType: AuditActorType.values.byName(row.actorType),
            actorId: row.actorId,
            occurredAt: row.occurredAt,
            metadata: row.metadata == null
                ? const {}
                : jsonDecode(row.metadata!) as Map<String, Object?>,
          ),
      ];
    });
  }
}
