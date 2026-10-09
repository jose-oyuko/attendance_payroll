import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/money/money.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_repositories.dart';
import 'package:attendance_payroll/features/payroll/domain/payroll_result.dart';
import 'package:drift/drift.dart';

final class DriftPayrollRunRepository implements PayrollRunRepository {
  DriftPayrollRunRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<PayrollRun>> saveCalculated(
    String periodId,
    PayrollResult result, {
    required String calculatedBy,
    required DateTime calculatedAt,
  }) {
    return guardDatabase(
      () => _db.transaction(() async {
        final now = _clock();
        await (_db.update(_db.payrollRuns)..where(
              (r) =>
                  r.periodId.equals(periodId) &
                  r.status.equals(PayrollRunStatus.calculated.name),
            ))
            .write(
              PayrollRunsCompanion(
                status: Value(PayrollRunStatus.superseded.name),
                updatedAt: Value(now),
              ),
            );
        final runId = _newId();
        await _db
            .into(_db.payrollRuns)
            .insert(
              PayrollRunsCompanion.insert(
                id: runId,
                periodId: periodId,
                status: PayrollRunStatus.calculated.name,
                calculatedAt: calculatedAt,
                calculatedBy: calculatedBy,
                createdAt: now,
                updatedAt: now,
              ),
            );
        for (final line in result.lines) {
          final lineId = _newId();
          await _db
              .into(_db.payrollLines)
              .insert(
                PayrollLinesCompanion.insert(
                  id: lineId,
                  runId: runId,
                  employeeId: line.employeeId,
                  currencyCode: line.currency,
                  regularSeconds: line.regularHours.inSeconds,
                  overtimeSeconds: line.overtimeHours.inSeconds,
                  regularPayMinor: line.regularPay.minorUnits,
                  overtimePayMinor: line.overtimePay.minorUnits,
                  allowancesMinor: line.allowances.minorUnits,
                  bonusesMinor: line.bonuses.minorUnits,
                  deductionsMinor: line.deductions.minorUnits,
                  grossMinor: line.gross.minorUnits,
                  netMinor: line.net.minorUnits,
                ),
              );
          for (final (position, item) in line.items.indexed) {
            await _db
                .into(_db.payrollItems)
                .insert(
                  PayrollItemsCompanion.insert(
                    id: _newId(),
                    lineId: lineId,
                    position: position,
                    kind: item.kind.name,
                    description: item.description,
                    amountMinor: item.amount.minorUnits,
                    rateType: Value(item.rateType?.name),
                    rateMinor: Value(item.rate?.minorUnits),
                    seconds: Value(item.hours?.inSeconds),
                    days: Value(item.days),
                    percent: Value(item.percent),
                  ),
                );
          }
        }
        for (final issue in result.issues) {
          await _db
              .into(_db.payrollRunIssues)
              .insert(
                PayrollRunIssuesCompanion.insert(
                  id: _newId(),
                  runId: runId,
                  employeeId: Value(issue.employeeId),
                  code: issue.code.name,
                  message: issue.message,
                ),
              );
        }
        return (await _load(runId))!;
      }),
    );
  }

  @override
  Future<Result<PayrollRun?>> currentForPeriod(String periodId) {
    return guardDatabase(() async {
      final row =
          await (_db.select(_db.payrollRuns)
                ..where(
                  (r) =>
                      r.periodId.equals(periodId) &
                      r.deletedAt.isNull() &
                      r.status.equals(PayrollRunStatus.superseded.name).not(),
                )
                ..orderBy([(r) => OrderingTerm.desc(r.calculatedAt)])
                ..limit(1))
              .getSingleOrNull();
      return row == null ? null : _load(row.id);
    });
  }

  @override
  Future<Result<int>> countForPeriod(String periodId) {
    return guardDatabase(() async {
      final count = _db.payrollRuns.id.count();
      final query = _db.selectOnly(_db.payrollRuns)
        ..addColumns([count])
        ..where(_db.payrollRuns.periodId.equals(periodId));
      return (await query.getSingle()).read(count) ?? 0;
    });
  }

  Future<PayrollRun?> _load(String runId) async {
    final run = await (_db.select(
      _db.payrollRuns,
    )..where((r) => r.id.equals(runId))).getSingleOrNull();
    if (run == null) {
      return null;
    }
    final lineRows =
        await (_db.select(_db.payrollLines)
              ..where((l) => l.runId.equals(runId))
              ..orderBy([(l) => OrderingTerm.asc(l.employeeId)]))
            .get();
    final itemRows =
        await (_db.select(_db.payrollItems)
              ..where((i) => i.lineId.isIn(lineRows.map((l) => l.id)))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    final issueRows = await (_db.select(
      _db.payrollRunIssues,
    )..where((i) => i.runId.equals(runId))).get();

    final itemsByLine = <String, List<PayrollItem>>{};
    for (final row in itemRows) {
      final currency = lineRows
          .firstWhere((l) => l.id == row.lineId)
          .currencyCode;
      final rateMinor = row.rateMinor;
      final seconds = row.seconds;
      final rateType = row.rateType;
      (itemsByLine[row.lineId] ??= []).add(
        PayrollItem(
          kind: PayrollItemKind.values.byName(row.kind),
          description: row.description,
          amount: Money(row.amountMinor, currency),
          rateType: rateType == null ? null : RateType.values.byName(rateType),
          rate: rateMinor == null ? null : Money(rateMinor, currency),
          hours: seconds == null ? null : Duration(seconds: seconds),
          days: row.days,
          percent: row.percent,
        ),
      );
    }
    return PayrollRun(
      id: run.id,
      periodId: run.periodId,
      status: PayrollRunStatus.values.byName(run.status),
      calculatedAt: run.calculatedAt,
      calculatedBy: run.calculatedBy,
      result: PayrollResult(
        lines: [
          for (final row in lineRows)
            PayrollLine(
              employeeId: row.employeeId,
              currency: row.currencyCode,
              regularHours: Duration(seconds: row.regularSeconds),
              overtimeHours: Duration(seconds: row.overtimeSeconds),
              items: itemsByLine[row.id] ?? const [],
            ),
        ],
        issues: [
          for (final row in issueRows)
            PayrollIssue(
              code: PayrollIssueCode.values.byName(row.code),
              employeeId: row.employeeId,
              message: row.message,
            ),
        ],
      ),
    );
  }
}
