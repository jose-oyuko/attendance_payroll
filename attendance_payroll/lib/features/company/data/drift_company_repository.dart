import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/database/versioned_update.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/features/company/domain/company_repository.dart';
import 'package:drift/drift.dart';

const String _entity = 'company';

final class DriftCompanyRepository implements CompanyRepository {
  DriftCompanyRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<Company>> create(CompanyDetails details) async {
    final normalized = details.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(() async {
      final now = _clock();
      final row = await _db
          .into(_db.companies)
          .insertReturning(
            _companion(normalized).copyWith(
              id: Value(_newId()),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      return _toDomain(row);
    });
  }

  @override
  Future<Result<Company>> getById(String id) {
    return guardDatabase(() async => _toDomain(await _db.requireCompany(id)));
  }

  @override
  Future<Result<List<Company>>> list() {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.companies)
                ..where((c) => c.deletedAt.isNull())
                ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  @override
  Future<Result<Company>> update(
    String id,
    CompanyDetails details, {
    required int expectedVersion,
  }) async {
    final normalized = details.normalized();
    if (normalized.validate() case final failure?) {
      return Err(failure);
    }
    return guardDatabase(
      () => _db.transaction(() async {
        await updateVersioned(
          _db,
          _db.companies,
          id: id,
          expectedVersion: expectedVersion,
          entity: _entity,
          changes: _companion(normalized).copyWith(
            updatedAt: Value(_clock()),
            version: Value(expectedVersion + 1),
          ),
        );
        return _toDomain(await _db.requireCompany(id));
      }),
    );
  }

  CompaniesCompanion _companion(CompanyDetails d) {
    return CompaniesCompanion(
      name: Value(d.name),
      legalName: Value(d.legalName),
      registrationNumber: Value(d.registrationNumber),
      phone: Value(d.phone),
      email: Value(d.email),
      address: Value(d.address),
      currencyCode: Value(d.currencyCode),
      timezone: Value(d.timezone),
      logoPath: Value(d.logoPath),
    );
  }

  Company _toDomain(CompanyRow row) {
    return Company(
      id: row.id,
      details: CompanyDetails(
        name: row.name,
        legalName: row.legalName,
        registrationNumber: row.registrationNumber,
        phone: row.phone,
        email: row.email,
        address: row.address,
        currencyCode: row.currencyCode,
        timezone: row.timezone,
        logoPath: row.logoPath,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
