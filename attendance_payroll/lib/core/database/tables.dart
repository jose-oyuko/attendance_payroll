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

/// Hashed secrets: administrator passwords and employee PINs. Exactly one
/// owner column is set. Plain secrets are never stored.
///
/// This is device-local security state (attempt counters, locks), so it has no
/// sync metadata.
@DataClassName('CredentialRow')
class Credentials extends Table {
  TextColumn get id => text()();

  /// `adminPassword` or `employeePin`.
  TextColumn get kind => text()();
  TextColumn get adminUserId =>
      text().nullable().unique().references(AdminUsers, #id)();
  TextColumn get employeeId =>
      text().nullable().unique().references(Employees, #id)();

  /// Self-describing hash; see `SecretHasher`.
  TextColumn get secretHash => text()();

  /// Issued by an administrator; the owner must replace it on first use.
  BoolColumn get isTemporary => boolean().withDefault(const Constant(false))();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  DateTimeColumn get changedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ((admin_user_id IS NULL) <> (employee_id IS NULL))',
    'CHECK (failed_attempts >= 0)',
  ];
}

/// Append-only record of significant business actions. Rows are never
/// updated, so there is no `version` or `updatedAt`; they do sync later.
@DataClassName('AuditLogRow')
@TableIndex(name: 'audit_log_company_time', columns: {#companyId, #occurredAt})
@TableIndex(name: 'audit_log_entity', columns: {#entityType, #entityId})
class AuditLog extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text().references(Companies, #id)();

  /// `admin`, `employee` or `system`.
  TextColumn get actorType => text()();
  TextColumn get actorId => text().nullable()();

  /// Stable dotted code, for example `employee.pin_reset`.
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get deviceId => text()();

  /// JSON object with non-sensitive details, or null.
  TextColumn get metadata => text().nullable()();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(Constant(SyncState.localOnly.name))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The stable identity of this installation (one row), recorded on audit
/// entries and, later, attendance events and synchronised records.
@DataClassName('DeviceIdentityRow')
class DeviceIdentity extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Raw clock-in and clock-out actions: the source of truth for attendance.
/// Append-only; corrections (Phase 5) are recorded as new data, never edits.
/// Sessions are derived from these rows and not stored.
@DataClassName('AttendanceEventRow')
@TableIndex(
  name: 'attendance_events_employee_time',
  columns: {#employeeId, #occurredAt},
)
@TableIndex(name: 'attendance_events_time', columns: {#occurredAt})
class AttendanceEvents extends Table with EntityColumns {
  TextColumn get employeeId => text().references(Employees, #id)();

  /// `clockIn` or `clockOut`.
  TextColumn get eventType => text()();

  /// When the action happened (UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// When this device stored it (UTC).
  DateTimeColumn get recordedAt => dateTime()();

  /// For example `kiosk`.
  TextColumn get source => text()();
  TextColumn get deviceId => text()();

  /// Who recorded it (employee or administrator id).
  TextColumn get createdBy => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Each company's attendance thresholds. A company without a row uses the
/// defaults. Durations are whole minutes.
@DataClassName('AttendanceSettingsRow')
class AttendanceSettings extends Table with EntityColumns {
  TextColumn get companyId => text().unique().references(Companies, #id)();
  IntColumn get duplicateWindowMinutes => integer()();
  IntColumn get staleOpenSessionMinutes => integer()();
  IntColumn get excessiveDurationMinutes => integer()();

  /// Both set, or both null when there is no automatic break.
  IntColumn get breakAfterMinutes => integer().nullable()();
  IntColumn get breakMinutes => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (duplicate_window_minutes >= 0)',
    'CHECK (stale_open_session_minutes > 0)',
    'CHECK (excessive_duration_minutes > 0)',
    'CHECK ((break_after_minutes IS NULL) = (break_minutes IS NULL))',
  ];
}

/// Administrator corrections to attendance. Events are never edited: a
/// correction adds a replacement event and/or supersedes an original one,
/// and records why, by whom and when, so the history stays intact.
///
/// - `added`: a missed clock action; `replacement_event_id` only.
/// - `timeChanged`: `original_event_id` is superseded by
///   `replacement_event_id`.
/// - `removed`: `original_event_id` is superseded with no replacement.
@DataClassName('AttendanceCorrectionRow')
@TableIndex(
  name: 'attendance_corrections_original',
  columns: {#originalEventId},
)
@TableIndex(
  name: 'attendance_corrections_employee',
  columns: {#employeeId, #correctedAt},
)
class AttendanceCorrections extends Table with EntityColumns {
  TextColumn get employeeId => text().references(Employees, #id)();

  /// `added`, `timeChanged` or `removed`.
  TextColumn get kind => text()();

  /// `clockIn` or `clockOut`.
  TextColumn get eventType => text()();
  TextColumn get originalEventId =>
      text().nullable().unique().references(AttendanceEvents, #id)();
  TextColumn get replacementEventId =>
      text().nullable().references(AttendanceEvents, #id)();
  DateTimeColumn get previousOccurredAt => dateTime().nullable()();
  DateTimeColumn get newOccurredAt => dateTime().nullable()();
  TextColumn get reason => text()();

  /// Administrator who made the correction.
  TextColumn get correctedBy => text().references(AdminUsers, #id)();
  DateTimeColumn get correctedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (original_event_id IS NOT NULL OR replacement_event_id IS NOT NULL)',
  ];
}

/// Settings of this installation that are never shared with other devices.
/// Exactly one row, with id [DeviceSettings.singletonId].
@DataClassName('DeviceSettingsRow')
class DeviceSettings extends Table {
  static const String singletonId = 'this_device';

  TextColumn get id => text()();

  /// The company whose employees use this device as an attendance kiosk, or
  /// null when kiosk mode is off.
  TextColumn get kioskCompanyId =>
      text().nullable().references(Companies, #id)();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // A literal, not interpolated: drift_dev reads constraints statically when
  // exporting schema snapshots. Must match [singletonId].
  @override
  List<String> get customConstraints => ["CHECK (id = 'this_device')"];
}

/// Administrator decisions about attendance exceptions. Exceptions are
/// derived from events like sessions; only the decisions are stored, keyed by
/// the exception's stable `issue_key` (`<type>:<event id>`). Rows are never
/// changed: a later decision is a new row, so the review history is kept.
@DataClassName('ExceptionReviewRow')
@TableIndex(name: 'exception_reviews_issue', columns: {#issueKey})
@TableIndex(
  name: 'exception_reviews_company_time',
  columns: {#companyId, #issueOccurredAt},
)
class ExceptionReviews extends Table with EntityColumns {
  TextColumn get companyId => text().references(Companies, #id)();
  TextColumn get employeeId => text().references(Employees, #id)();
  TextColumn get issueKey => text()();

  /// The issue as it was when reviewed, so the record stays meaningful after
  /// a correction makes the issue disappear.
  TextColumn get issueType => text()();

  /// The event that revealed it; null for issues about a whole day (missing
  /// attendance), whose key is anchored to the employee and date.
  TextColumn get eventId =>
      text().nullable().references(AttendanceEvents, #id)();
  TextColumn get sessionKey => text().nullable()();
  DateTimeColumn get issueOccurredAt => dateTime()();

  /// `reviewed`, `resolved` or `dismissed`.
  TextColumn get status => text()();
  TextColumn get reason => text()();
  TextColumn get reviewedBy => text().references(AdminUsers, #id)();
  DateTimeColumn get reviewedAt => dateTime()();

  /// The correction that resolved it, if any.
  TextColumn get relatedCorrectionId =>
      text().nullable().references(AttendanceCorrections, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Named weekly working patterns, e.g. "Day shift" Mon–Fri 08:00–17:00.
/// Durations are whole minutes. Changing a schedule changes how all dates
/// are evaluated; finalized payroll keeps its own figures.
@DataClassName('WorkScheduleRow')
class WorkSchedules extends Table with EntityColumns {
  TextColumn get companyId => text().references(Companies, #id)();
  TextColumn get name => text()();
  IntColumn get lateToleranceMinutes => integer()();
  IntColumn get earlyDepartureToleranceMinutes => integer()();

  /// Both set, or both null when the schedule has no automatic break.
  IntColumn get breakAfterMinutes => integer().nullable()();
  IntColumn get breakMinutes => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {companyId, name},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (late_tolerance_minutes >= 0)',
    'CHECK (early_departure_tolerance_minutes >= 0)',
    'CHECK ((break_after_minutes IS NULL) = (break_minutes IS NULL))',
  ];
}

/// The working days of a schedule; a weekday without a row is a day off.
/// `end_minute` before `start_minute` means the shift ends the next day.
@DataClassName('WorkScheduleDayRow')
class WorkScheduleDays extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(WorkSchedules, #id)();

  /// ISO weekday: 1 = Monday … 7 = Sunday.
  IntColumn get weekday => integer()();

  /// Minutes after local midnight.
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {scheduleId, weekday},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (weekday BETWEEN 1 AND 7)',
    'CHECK (start_minute BETWEEN 0 AND 1439)',
    'CHECK (end_minute BETWEEN 0 AND 1439)',
    'CHECK (start_minute <> end_minute)',
  ];
}

/// Which schedule an employee follows, over time. A new assignment closes
/// the previous one the day before; history is never rewritten. A null
/// schedule means "no schedule" from that date.
@DataClassName('ScheduleAssignmentRow')
class ScheduleAssignments extends Table with EntityColumns {
  TextColumn get employeeId => text().references(Employees, #id)();
  TextColumn get scheduleId =>
      text().nullable().references(WorkSchedules, #id)();
  TextColumn get effectiveFrom => text().map(const LocalDateConverter())();

  /// Inclusive last day; null while current.
  TextColumn get effectiveTo =>
      text().map(const LocalDateConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {employeeId, effectiveFrom},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (effective_to IS NULL OR effective_to >= effective_from)',
  ];
}

/// Each company's overtime rules and rate conversions. No row means the
/// defaults (no overtime). Durations are whole minutes.
@DataClassName('PayrollSettingsRow')
class PayrollSettingsTable extends Table with EntityColumns {
  @override
  String get tableName => 'payroll_settings';

  TextColumn get companyId => text().unique().references(Companies, #id)();
  IntColumn get dailyOvertimeAfterMinutes => integer().nullable()();
  IntColumn get weeklyOvertimeAfterMinutes => integer().nullable()();
  IntColumn get overtimePercent => integer()();
  IntColumn get standardDayMinutes => integer()();
  IntColumn get standardWeekMinutes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (overtime_percent BETWEEN 100 AND 400)',
    'CHECK (standard_day_minutes > 0)',
    'CHECK (standard_week_minutes > 0)',
  ];
}

/// Spans of dates paid together. Periods of a company never overlap, so no
/// day is paid twice.
@DataClassName('PayrollPeriodRow')
@TableIndex(
  name: 'payroll_periods_company_start',
  columns: {#companyId, #startDate},
)
class PayrollPeriods extends Table with EntityColumns {
  TextColumn get companyId => text().references(Companies, #id)();
  TextColumn get name => text()();
  TextColumn get startDate => text().map(const LocalDateConverter())();
  TextColumn get endDate => text().map(const LocalDateConverter())();

  /// See `PayrollPeriodStatus`.
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (end_date >= start_date)'];
}

/// Allowances, bonuses and deductions for one employee in one period.
@DataClassName('PayrollAdjustmentRow')
@TableIndex(name: 'payroll_adjustments_period', columns: {#periodId})
class PayrollAdjustments extends Table with EntityColumns {
  TextColumn get periodId => text().references(PayrollPeriods, #id)();
  TextColumn get employeeId => text().references(Employees, #id)();

  /// `allowance`, `bonus` or `deduction`.
  TextColumn get type => text()();

  /// Always positive, in the minor unit; [type] decides the sign.
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get description => text()();
  TextColumn get createdBy => text().references(AdminUsers, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (amount_minor > 0)'];
}

/// One calculation of a period. A run's lines, items and issues are an
/// immutable snapshot; recalculating writes a new run and marks the previous
/// one superseded, so earlier results stay explainable.
@DataClassName('PayrollRunRow')
@TableIndex(name: 'payroll_runs_period', columns: {#periodId})
class PayrollRuns extends Table with EntityColumns {
  TextColumn get periodId => text().references(PayrollPeriods, #id)();

  /// See `PayrollRunStatus`.
  TextColumn get status => text()();
  DateTimeColumn get calculatedAt => dateTime()();
  TextColumn get calculatedBy => text().references(AdminUsers, #id)();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  TextColumn get approvedBy => text().nullable().references(AdminUsers, #id)();
  DateTimeColumn get finalizedAt => dateTime().nullable()();
  TextColumn get finalizedBy => text().nullable().references(AdminUsers, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One employee's totals in a run, stored as calculated.
@DataClassName('PayrollLineRow')
@TableIndex(name: 'payroll_lines_run', columns: {#runId})
@TableIndex(name: 'payroll_lines_employee', columns: {#employeeId})
class PayrollLines extends Table {
  TextColumn get id => text()();
  TextColumn get runId => text().references(PayrollRuns, #id)();
  TextColumn get employeeId => text().references(Employees, #id)();
  TextColumn get currencyCode => text()();
  IntColumn get regularSeconds => integer()();
  IntColumn get overtimeSeconds => integer()();
  IntColumn get regularPayMinor => integer()();
  IntColumn get overtimePayMinor => integer()();
  IntColumn get allowancesMinor => integer()();
  IntColumn get bonusesMinor => integer()();
  IntColumn get deductionsMinor => integer()();
  IntColumn get grossMinor => integer()();
  IntColumn get netMinor => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {runId, employeeId},
  ];
}

/// The explainable lines making up a payroll line.
@DataClassName('PayrollItemRow')
@TableIndex(name: 'payroll_items_line', columns: {#lineId})
class PayrollItems extends Table {
  TextColumn get id => text()();
  TextColumn get lineId => text().references(PayrollLines, #id)();

  /// Order within the line.
  IntColumn get position => integer()();

  /// See `PayrollItemKind`.
  TextColumn get kind => text()();
  TextColumn get description => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get rateType => text().nullable()();
  IntColumn get rateMinor => integer().nullable()();
  IntColumn get seconds => integer().nullable()();
  IntColumn get days => integer().nullable()();
  IntColumn get percent => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Problems found when a run was calculated.
@DataClassName('PayrollRunIssueRow')
@TableIndex(name: 'payroll_run_issues_run', columns: {#runId})
class PayrollRunIssues extends Table {
  TextColumn get id => text()();
  TextColumn get runId => text().references(PayrollRuns, #id)();
  TextColumn get employeeId => text().nullable().references(Employees, #id)();

  /// See `PayrollIssueCode`.
  TextColumn get code => text()();
  TextColumn get message => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
