import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/company/data/drift_company_repository.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => DriftCompanyRepository(ref.watch(appDatabaseProvider)),
);
