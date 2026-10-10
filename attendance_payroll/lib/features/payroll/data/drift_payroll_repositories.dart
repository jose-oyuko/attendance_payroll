import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/converters.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_period.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_settings.dart';
import 'package:drift/drift.dart';

final class DriftPayrollSettingsRepository
    implements PayrollSettingsRepository {
  DriftPayrollSettingsRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  static const String _conflict =
      'The payroll settings were changed by someone else. Reload them and try '
      'again.';

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<StoredPayrollSettings>> forCompany(String companyId) {
    return guardDatabase(() async {
      final row = await _rowFor(companyId);
      return row == null
          ? const StoredPayrollSettings(settings: PayrollSettings(), version: 0)
          : _toDomain(row);
    });
  }

  @override
  Future<Result<StoredPayrollSettings>> save(
    String companyId,
    PayrollSettings settings, {
    required int expectedVersion,
  }) async {
    if (settings.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireCompany(companyId);
        final now = _clock();
        final values = PayrollSettingsTableCompanion(
          dailyOvertimeAfterMinutes: Value(
            settings.dailyOvertimeAfter?.inMinutes,
          ),
          weeklyOvertimeAfterMinutes: Value(
            settings.weeklyOvertimeAfter?.inMinutes,
          ),
          overtimePercent: Value(settings.overtimePercent),
          standardDayMinutes: Value(settings.standardDay.inMinutes),
          standardWeekMinutes: Value(settings.standardWeek.inMinutes),
          updatedAt: Value(now),
        );
        final existing = await _rowFor(companyId);
        if (existing == null) {
          if (expectedVersion != 0) {
            throw const ConflictFailure(userMessage: _conflict);
          }
          await _db
              .into(_db.payrollSettingsTable)
              .insert(
                values.copyWith(
                  id: Value(_newId()),
                  companyId: Value(companyId),
                  createdAt: Value(now),
                ),
              );
        } else {
          await updateVersioned(
            _db,
            _db.payrollSettingsTable,
            id: existing.id,
            expectedVersion: expectedVersion,
            entity: 'payroll settings',
            changes: values.copyWith(version: Value(expectedVersion + 1)),
          );
        }
        return _toDomain((await _rowFor(companyId))!);
      }),
      conflictMessage: _conflict,
    );
  }

  Future<PayrollSettingsRow?> _rowFor(String companyId) {
    return (_db.select(_db.payrollSettingsTable)
          ..where((s) => s.companyId.equals(companyId) & s.deletedAt.isNull()))
        .getSingleOrNull();
  }

  StoredPayrollSettings _toDomain(PayrollSettingsRow row) {
    Duration? minutes(int? value) =>
        value == null ? null : Duration(minutes: value);
    return StoredPayrollSettings(
      version: row.version,
      settings: PayrollSettings(
        dailyOvertimeAfter: minutes(row.dailyOvertimeAfterMinutes),
        weeklyOvertimeAfter: minutes(row.weeklyOvertimeAfterMinutes),
        overtimePercent: row.overtimePercent,
        standardDay: Duration(minutes: row.standardDayMinutes),
        standardWeek: Duration(minutes: row.standardWeekMinutes),
      ),
    );
  }
}

final class DriftPayrollPeriodRepository implements PayrollPeriodRepository {
  DriftPayrollPeriodRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<PayrollPeriod>> create(
    String companyId,
    NewPayrollPeriod period,
  ) async {
    if (period.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await _db.requireCompany(companyId);
        const converter = LocalDateConverter();
        final start = converter.toSql(period.startDate);
        final end = converter.toSql(period.endDate);
        // Overlap: an existing period starts on or before our end and ends
        // on or after our start. ISO dates compare correctly as text.
        final clash =
            await (_db.select(_db.payrollPeriods)
                  ..where(
                    (p) =>
                        p.companyId.equals(companyId) &
                        p.deletedAt.isNull() &
                        p.startDate.isSmallerOrEqualValue(end) &
                        p.endDate.isBiggerOrEqualValue(start),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (clash != null) {
          throw BusinessRuleFailure(
            rule: PayrollPeriodRules.overlap,
            userMessage:
                'These dates overlap "${clash.name}" '
                '(${clash.startDate} – ${clash.endDate}). Each day can be '
                'paid only once.',
          );
        }
        final now = _clock();
        final row = await _db
            .into(_db.payrollPeriods)
            .insertReturning(
              PayrollPeriodsCompanion.insert(
                id: _newId(),
                companyId: companyId,
                name: period.name.trim(),
                startDate: period.startDate,
                endDate: period.endDate,
                status: PayrollPeriodStatus.draft.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
        return _toDomain(row);
      }),
    );
  }

  @override
  Future<Result<PayrollPeriod>> getById(String id) {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.payrollPeriods)
                ..where((p) => p.id.equals(id) & p.deletedAt.isNull()))
              .getSingleOrNull();
      return _toDomain(
        row ?? (throw const NotFoundFailure(entity: 'payroll period')),
      );
    });
  }

  @override
  Future<Result<List<PayrollPeriod>>> listByCompany(String companyId) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.payrollPeriods)
                ..where(
                  (p) => p.companyId.equals(companyId) & p.deletedAt.isNull(),
                )
                ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<PayrollPeriod>> setStatus(
    String id,
    PayrollPeriodStatus status, {
    required int expectedVersion,
  }) {
    return guardDatabase(
      () => _db.transaction(() async {
        await updateVersioned(
          _db,
          _db.payrollPeriods,
          id: id,
          expectedVersion: expectedVersion,
          entity: 'payroll period',
          changes: PayrollPeriodsCompanion(
            status: Value(status.name),
            updatedAt: Value(_clock()),
            version: Value(expectedVersion + 1),
          ),
        );
        return (await getById(id)).unwrap();
      }),
    );
  }

  PayrollPeriod _toDomain(PayrollPeriodRow row) {
    return PayrollPeriod(
      id: row.id,
      companyId: row.companyId,
      name: row.name,
      startDate: row.startDate,
      endDate: row.endDate,
      status: PayrollPeriodStatus.values.byName(row.status),
      version: row.version,
    );
  }
}

final class DriftPayrollAdjustmentRepository
    implements PayrollAdjustmentRepository {
  DriftPayrollAdjustmentRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<PayrollAdjustment>> add(
    String periodId,
    NewPayrollAdjustment adjustment, {
    required String createdBy,
  }) async {
    if (adjustment.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(() async {
      final now = _clock();
      final row = await _db
          .into(_db.payrollAdjustments)
          .insertReturning(
            PayrollAdjustmentsCompanion.insert(
              id: _newId(),
              periodId: periodId,
              employeeId: adjustment.employeeId,
              type: adjustment.type.name,
              amountMinor: adjustment.amount.minorUnits,
              currencyCode: adjustment.amount.currency,
              description: adjustment.description.trim(),
              createdBy: createdBy,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toDomain(row);
    });
  }

  @override
  Future<Result<PayrollAdjustment>> getById(String id) {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.payrollAdjustments)
                ..where((a) => a.id.equals(id) & a.deletedAt.isNull()))
              .getSingleOrNull();
      return _toDomain(
        row ?? (throw const NotFoundFailure(entity: 'adjustment')),
      );
    });
  }

  @override
  Future<Result<void>> remove(String id) {
    return guardDatabase(() async {
      final now = _clock();
      final changed =
          await (_db.update(
            _db.payrollAdjustments,
          )..where((a) => a.id.equals(id) & a.deletedAt.isNull())).write(
            PayrollAdjustmentsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      if (changed == 0) {
        throw const NotFoundFailure(entity: 'adjustment');
      }
    });
  }

  @override
  Future<Result<List<PayrollAdjustment>>> forPeriod(String periodId) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.payrollAdjustments)
                ..where(
                  (a) => a.periodId.equals(periodId) & a.deletedAt.isNull(),
                )
                ..orderBy([
                  (a) => OrderingTerm.asc(a.createdAt),
                  (a) => OrderingTerm.asc(a.id),
                ]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  PayrollAdjustment _toDomain(PayrollAdjustmentRow row) {
    return PayrollAdjustment(
      id: row.id,
      periodId: row.periodId,
      employeeId: row.employeeId,
      type: AdjustmentType.values.byName(row.type),
      amount: Money(row.amountMinor, row.currencyCode),
      description: row.description,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
    );
  }
}
