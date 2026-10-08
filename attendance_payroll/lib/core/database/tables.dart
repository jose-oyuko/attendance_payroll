import 'package:attendance_payroll/core/database/converters.dart';
import 'package:attendance_payroll/core/database/sync_state.dart';
import 'package:drift/drift.dart';

// Schema conventions (see docs/DATABASE.md):
// - Text UUID primary keys generated on the device.
// - Instants are UTC, stored as ISO-8601 text (see build.yaml).
// - Calendar dates are `YYYY-MM-DD` text via [LocalDateConverter].
// - Money is an integer amount in the currency's minor unit.
// - Enums are stored by name. They have no CHECK constraint, so adding a value
//   later does not force a table rebuild; the data layer rejects unknown names.
// - Row classes end in `Row` so they never clash with domain entities.

/// Metadata shared by persistent business entities.
///
/// - `version` starts at 1 and increments on every update. Updates name the
///   version they were based on and are rejected when it is stale.
/// - `syncState` and `deletedAt` prepare for synchronisation: deletions are
///   tombstones so they can be propagated later.
mixin EntityColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(Constant(SyncState.localOnly.name))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// The business using the application. V1 normally has one per installation.
@DataClassName('CompanyRow')
class Companies extends Table with EntityColumns {
  TextColumn get name => text()();
  TextColumn get legalName => text().nullable()();
  TextColumn get registrationNumber => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();

  /// ISO 4217 code, for example `KES`.
  TextColumn get currencyCode => text()();

  /// IANA timezone name, for example `Africa/Nairobi`.
  TextColumn get timezone => text()();
  TextColumn get logoPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// People who administer the application. Deliberately separate from
/// employees. Credentials are added in Phase 2 as their own table.
@DataClassName('AdminUserRow')
class AdminUsers extends Table with EntityColumns {
  TextColumn get companyId => text().references(Companies, #id)();

  /// Normalised (trimmed, lower-case) login name.
  TextColumn get username => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // The unique index also serves lookups by company.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {companyId, username},
  ];
}

/// People whose attendance and pay are managed. Never physically deleted
/// once attendance or payroll refers to them; archive them instead.
@DataClassName('EmployeeRow')
class Employees extends Table with EntityColumns {
  TextColumn get companyId => text().references(Companies, #id)();
  TextColumn get employeeNumber => text()();
  TextColumn get firstName => text()();
  TextColumn get middleName => text().nullable()();
  TextColumn get lastName => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get jobTitle => text().nullable()();
  TextColumn get employmentStatus => text()();
  TextColumn get employmentStartDate =>
      text().map(const LocalDateConverter())();
  TextColumn get employmentEndDate =>
      text().map(const LocalDateConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // Employee numbers are never reused within a company, even after archiving.
  // The unique index also serves lookups by company and by employee number.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {companyId, employeeNumber},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (employment_end_date IS NULL '
        'OR employment_end_date >= employment_start_date)',
  ];
}

/// Pay rate history. A new rate closes the previous one instead of
/// overwriting it, so past payroll can always be explained.
@DataClassName('EmployeeRateRow')
class EmployeeRates extends Table with EntityColumns {
  TextColumn get employeeId => text().references(Employees, #id)();
  TextColumn get rateType => text()();

  /// Amount in the currency's minor unit (for example cents). Never a double.
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get effectiveFrom => text().map(const LocalDateConverter())();

  /// Inclusive last day; `null` while the rate is current.
  TextColumn get effectiveTo =>
      text().map(const LocalDateConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // Also serves "rate history for employee" queries.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {employeeId, effectiveFrom},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    'CHECK (effective_to IS NULL OR effective_to >= effective_from)',
  ];
}
