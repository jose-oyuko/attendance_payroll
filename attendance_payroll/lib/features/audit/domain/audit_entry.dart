/// Significant business actions. Codes are stored, so never change one;
/// add a new value instead.
enum AuditAction {
  companyCreated('company.created'),
  adminCreated('admin.created'),
  adminSignedIn('admin.signed_in'),
  adminLockedOut('admin.locked_out'),
  employeeCreated('employee.created'),
  employeeUpdated('employee.updated'),
  employeeStatusChanged('employee.status_changed'),
  employeeRateAdded('employee.rate_added'),
  employeePinReset('employee.pin_reset'),
  employeePinChanged('employee.pin_changed'),
  employeePinLockedOut('employee.pin_locked_out');

  const AuditAction(this.code);

  final String code;
}

/// Who performed an audited action.
enum AuditActorType { admin, employee, system }

/// An action to record.
///
/// [metadata] must never contain secrets (PINs, passwords, hashes) and should
/// avoid personal or payroll values the referenced records already hold:
/// record which fields changed, not their contents.
final class AuditEntry {
  const AuditEntry({
    required this.companyId,
    required this.actorType,
    required this.actorId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.metadata = const <String, Object?>{},
  });

  final String companyId;
  final AuditActorType actorType;
  final String? actorId;
  final AuditAction action;

  /// For example `employee` or `company`.
  final String entityType;
  final String? entityId;
  final Map<String, Object?> metadata;
}
