import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/audit/data/drift_audit_log_repository.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => DriftAuditLogRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(deviceIdentityRepositoryProvider),
  ),
);
