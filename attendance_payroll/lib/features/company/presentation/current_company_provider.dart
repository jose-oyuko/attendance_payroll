import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/company/data/company_providers.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in administrator's company.
final currentCompanyProvider = FutureProvider.autoDispose<Company>((ref) async {
  final session = requireSession(ref);
  return (await ref.watch(companyRepositoryProvider).getById(session.companyId))
      .unwrap();
});

/// The signed-in company's timezone, for showing and entering times.
final companyTimeZoneProvider = FutureProvider.autoDispose<CompanyTimeZone>((
  ref,
) async {
  final company = await ref.watch(currentCompanyProvider.future);
  return CompanyTimeZone(company.details.timezone);
});
