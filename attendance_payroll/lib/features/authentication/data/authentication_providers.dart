import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/authentication/data/drift_admin_user_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>(
  (ref) => DriftAdminUserRepository(ref.watch(appDatabaseProvider)),
);
