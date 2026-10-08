import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';

/// A company's attendance policy and the version to pass back when saving.
final class StoredAttendancePolicy {
  const StoredAttendancePolicy({required this.policy, required this.version});

  final AttendancePolicy policy;

  /// 0 while the company still uses the defaults (nothing saved yet).
  final int version;

  bool get isDefault => version == 0;
}

abstract interface class AttendanceSettingsRepository {
  /// The company's policy, or the defaults if it never saved one.
  Future<Result<StoredAttendancePolicy>> forCompany(String companyId);

  /// Saves [policy]. Fails with a `ConflictFailure` when [expectedVersion] is
  /// stale (pass 0 when replacing the defaults).
  Future<Result<StoredAttendancePolicy>> save(
    String companyId,
    AttendancePolicy policy, {
    required int expectedVersion,
  });
}
