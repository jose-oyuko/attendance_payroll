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
