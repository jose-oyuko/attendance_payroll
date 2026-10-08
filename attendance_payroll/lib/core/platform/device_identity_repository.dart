import 'package:attendance_payroll/core/result/result.dart';

/// The stable identifier of this installation.
///
/// Generated once and kept for the life of the database. It identifies the
/// device on audit entries and, later, attendance events and synchronised
/// records; it carries no hardware or personal information.
abstract interface class DeviceIdentityRepository {
  Future<Result<String>> currentDeviceId();
}
