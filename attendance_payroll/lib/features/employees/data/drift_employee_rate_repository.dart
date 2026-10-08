import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/converters.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate_repository.dart';
import 'package:drift/drift.dart';

final class DriftEmployeeRateRepository implements EmployeeRateRepository {
  DriftEmployeeRateRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<EmployeeRate>> addRate(
    String employeeId,
    NewEmployeeRate rate,
  ) async {
    final normalized = rate.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        final employee = await _db.requireEmployee(employeeId);
        final company = await _db.requireCompany(employee.companyId);
        if (normalized.currencyCode != company.currencyCode) {
          throw BusinessRuleFailure(
            rule: EmployeeRateRules.currencyMismatch,
            userMessage:
                'Rates must be in the company currency '
                '(${company.currencyCode}).',
          );
        }

        final now = _clock();
        final latest = await _latestRow(employeeId);
        if (latest != null) {
          if (!normalized.effectiveFrom.isAfter(latest.effectiveFrom)) {
            throw BusinessRuleFailure(
              rule: EmployeeRateRules.mustStartAfterLatest,
              userMessage:
                  'The new rate must start after '
                  '${latest.effectiveFrom.toIsoString()}, when the latest '
                  'rate started.',
            );
          }
          final closesOn = normalized.effectiveFrom.addDays(-1);
          // A latest rate that already ended earlier stays as it is.
          if (latest.effectiveTo == null ||
              latest.effectiveTo!.isAfter(closesOn)) {
            await updateVersioned(
              _db,
              _db.employeeRates,
              id: latest.id,
              expectedVersion: latest.version,
              entity: 'rate',
              changes: EmployeeRatesCompanion(
                effectiveTo: Value(closesOn),
                updatedAt: Value(now),
                version: Value(latest.version + 1),
              ),
            );
          }
        }

        final row = await _db
            .into(_db.employeeRates)
            .insertReturning(
              EmployeeRatesCompanion.insert(
                id: _newId(),
                employeeId: employeeId,
                rateType: normalized.rateType.name,
                amountMinor: normalized.amountMinor,
                currencyCode: normalized.currencyCode,
                effectiveFrom: normalized.effectiveFrom,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return _toDomain(row);
      }),
    );
  }

  @override
  Future<Result<List<EmployeeRate>>> history(String employeeId) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.employeeRates)
                ..where(
                  (r) => r.employeeId.equals(employeeId) & r.deletedAt.isNull(),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.effectiveFrom)]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<EmployeeRate?>> rateOn(String employeeId, LocalDate date) {
    const converter = LocalDateConverter();
    final day = converter.toSql(date);
    return guardDatabase(() async {
      // Dates are ISO text, so string comparison is chronological.
      final row =
          await (_db.select(_db.employeeRates)
                ..where(
                  (r) =>
                      r.employeeId.equals(employeeId) &
                      r.deletedAt.isNull() &
                      r.effectiveFrom.isSmallerOrEqualValue(day) &
                      (r.effectiveTo.isNull() |
                          r.effectiveTo.isBiggerOrEqualValue(day)),
                )
                ..orderBy([(r) => OrderingTerm.desc(r.effectiveFrom)])
                ..limit(1))
              .getSingleOrNull();
      return row == null ? null : _toDomain(row);
    });
  }

  Future<EmployeeRateRow?> _latestRow(String employeeId) {
    return (_db.select(_db.employeeRates)
          ..where((r) => r.employeeId.equals(employeeId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.effectiveFrom)])
          ..limit(1))
        .getSingleOrNull();
  }

  EmployeeRate _toDomain(EmployeeRateRow row) {
    return EmployeeRate(
      id: row.id,
      employeeId: row.employeeId,
      rateType: RateType.values.byName(row.rateType),
      amountMinor: row.amountMinor,
      currencyCode: row.currencyCode,
      effectiveFrom: row.effectiveFrom,
      effectiveTo: row.effectiveTo,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
