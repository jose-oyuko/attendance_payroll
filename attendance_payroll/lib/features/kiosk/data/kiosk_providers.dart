import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/audit/data/audit_providers.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/company/data/company_providers.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/kiosk/data/drift_kiosk_mode_repository.dart';
import 'package:attendance_payroll/features/kiosk/domain/kiosk_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final kioskModeRepositoryProvider = Provider<KioskModeRepository>(
  (ref) => DriftKioskModeRepository(ref.watch(appDatabaseProvider)),
);

final kioskServiceProvider = Provider<KioskService>(
  (ref) => KioskService(
    kioskMode: ref.watch(kioskModeRepositoryProvider),
    companies: ref.watch(companyRepositoryProvider),
    employees: ref.watch(employeeRepositoryProvider),
    pins: ref.watch(employeePinServiceProvider),
    audit: ref.watch(auditLogRepositoryProvider),
    transactions: ref.watch(transactionRunnerProvider),
  ),
);
