import 'package:attendance_payroll/core/locking/payroll_lock.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';

/// [PayrollLock] backed by the company's payroll periods: approved and
/// finalized periods are locked.
final class PayrollPeriodLock implements PayrollLock {
  PayrollPeriodLock({required this._periods, required this._companies});

  final PayrollPeriodRepository _periods;
  final CompanyRepository _companies;

  static bool _locked(PayrollPeriod p) =>
      p.status == PayrollPeriodStatus.approved ||
      p.status == PayrollPeriodStatus.finalized;

  @override
  Future<Result<String?>> lockedPeriodOn(
    String companyId,
    LocalDate date, {
    bool orLater = false,
  }) async {
    final periods = await _periods.listByCompany(companyId);
    return periods.map((all) {
      for (final p in all.where(_locked)) {
        final affected = orLater ? !p.endDate.isBefore(date) : p.contains(date);
        if (affected) {
          return p.name;
        }
      }
      return null;
    });
  }

  @override
  Future<Result<String?>> lockedPeriodAt(
    String companyId,
    DateTime instant, {
    bool includePreviousDay = false,
  }) async {
    final company = await _companies.getById(companyId);
    if (company case Err(:final failure)) {
      return Err(failure);
    }
    final zone = CompanyTimeZone(company.valueOrNull!.details.timezone);
    final date = zone.dateOf(instant);
    final first = await lockedPeriodOn(companyId, date);
    if (first case Ok(value: final name?)) {
      return Ok(name);
    }
    if (!includePreviousDay || first.isErr) {
      return first;
    }
    return lockedPeriodOn(companyId, date.addDays(-1));
  }
}
