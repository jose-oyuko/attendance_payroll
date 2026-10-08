import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';

abstract interface class CompanyRepository {
  Future<Result<Company>> create(CompanyDetails details);

  Future<Result<Company>> getById(String id);

  /// Companies that are not deleted, oldest first. V1 normally has one.
  Future<Result<List<Company>>> list();

  /// Replaces the company's details. Fails with a `ConflictFailure` when
  /// [expectedVersion] is stale, so concurrent edits are never lost silently.
  Future<Result<Company>> update(
    String id,
    CompanyDetails details, {
    required int expectedVersion,
  });
}
