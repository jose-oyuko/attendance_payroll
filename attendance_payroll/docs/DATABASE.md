# Database

SQLite through Drift. The database class is `lib/core/database/app_database.dart`;
tables are in `lib/core/database/tables.dart`. Only repositories in feature
`data/` folders use it.

## Conventions

| Concern | Rule |
|---|---|
| Identity | Text UUIDv7 primary keys generated on the device (`generateUuidV7`). Time-ordered, so inserts append to indexes. |
| Instants | UTC `DateTime`, stored as ISO-8601 text (`store_date_time_values_as_text` in `build.yaml`), millisecond precision. |
| Calendar dates | `LocalDate`, stored as `YYYY-MM-DD` text, which sorts chronologically. |
| Money | Integer amount in the currency's minor unit (`amountMinor`), never `double`. |
| Enums | Stored by name, without CHECK constraints, so adding a value needs no table rebuild. Unknown names fail when read. |
| Concurrency | `version` starts at 1 and increments on each update. Updates name the version they were based on (`updateVersioned`); a stale version is a `ConflictFailure`. |
| Sync metadata | `syncState` (`localOnly` in V1) and `deletedAt` tombstones on every business table. |
| Foreign keys | Enabled on every connection (`PRAGMA foreign_keys = ON` in `beforeOpen`). |
| Errors | `guardDatabase` turns unique violations into `ConflictFailure` and everything else into `DatabaseFailure`. Raw SQLite messages never reach the UI. |
| Transactions | Multi-step writes run in `transaction`; throwing an `AppFailure` inside rolls back. |

## Schema versions

| Version | App phase | Changes |
|---|---|---|
| 1 | Phase 1 | `companies`, `admin_users`, `employees`, `employee_rates` |
| 2 | Phase 2 | `credentials`, `audit_log`, `device_identity` |
| 3 | Phase 3 | `attendance_events` |
| 4 | Phase 3 follow-up | `attendance_settings`, `attendance_corrections` |
| 5 | Phase 4 | `device_settings` |
| 6 | Phase 5 | `exception_reviews` |

### Version 1

- **companies** — name, legal/contact details, `currency_code` (ISO 4217),
  `timezone` (IANA), `logo_path`.
- **admin_users** — `company_id`, `username` (lower-case, unique per company),
  `display_name`, `role`, `active`, `last_login_at`. Credentials arrive in
  Phase 2 as a separate table.
- **employees** — `company_id`, `employee_number` (unique per company, never
  reused), names, contact, `job_title`, `employment_status`, start/end dates.
  CHECK: end date not before start date.
- **employee_rates** — `employee_id`, `rate_type`, `amount_minor` (> 0),
  `currency_code`, `effective_from`, `effective_to` (inclusive, null while
  current). Unique per employee and start date. CHECK: period not reversed.
  Adding a rate closes the current one on the previous day; back-dated rates are
  rejected so history is never rewritten.

### Version 2

- **credentials** — hashed administrator passwords and employee PINs.
  Exactly one of `admin_user_id` / `employee_id` is set (CHECK), each unique.
  `kind`, `secret_hash` (self-describing PBKDF2 hash, never the secret),
  `is_temporary`, `failed_attempts`, `locked_until`, `changed_at`. Device-local
  security state, so no sync metadata.
- **audit_log** — append-only: `company_id`, `actor_type`, `actor_id`,
  `action` (stable dotted code), `entity_type`, `entity_id`, `occurred_at`,
  `device_id`, `metadata` (JSON, never secrets), `sync_state`. Indexed by
  `(company_id, occurred_at)` and `(entity_type, entity_id)`.
- **device_identity** — one row: this installation's stable id.

Migration 1 → 2 only creates these tables and indexes; existing rows are
untouched (verified by a data-integrity migration test).

### Version 3

- **attendance_events** — append-only raw clock actions: `employee_id`,
  `event_type` (`clockIn`/`clockOut`), `occurred_at` (when it happened),
  `recorded_at` (when this device stored it), `source`, `device_id`,
  `created_by`, plus entity metadata. Indexed by `(employee_id, occurred_at)`
  for per-employee history and `(occurred_at)` for company-wide days.
  Sessions are **not** stored: they are derived from these rows on demand.

Migration 2 → 3 only creates this table and its indexes.

### Version 4

- **attendance_settings** — one row per company (unique `company_id`):
  `duplicate_window_minutes`, `stale_open_session_minutes`,
  `excessive_duration_minutes`, and `break_after_minutes` / `break_minutes`
  (both set or both null). No row means the defaults.
- **attendance_corrections** — administrator corrections, kept forever:
  `kind` (`added`, `timeChanged`, `removed`), `event_type`,
  `original_event_id` (superseded event; unique, so an event is corrected at
  most once), `replacement_event_id` (the admin-entered event that now
  counts), previous and new times, `reason`, `corrected_by`, `corrected_at`.
  Events are never edited: an event counts unless a correction names it as
  its original.

Migration 3 → 4 only creates these tables and indexes.

### Version 5

- **device_settings** — one row (`id = 'this_device'`, enforced by CHECK)
  holding this installation's own settings: `kiosk_company_id` (the company
  whose kiosk this device is, or null). Device-local, never synchronised.

Migration 4 → 5 only creates this table.

### Version 6

- **exception_reviews** — administrator decisions about attendance
  exceptions, append-only (a later decision is a new row): `issue_key`
  (`<issue type>:<event id>`), the issue as reviewed (`issue_type`,
  `event_id`, `session_key`, `issue_occurred_at`), `status` (`reviewed`,
  `resolved`, `dismissed`), `reason`, `reviewed_by`, `reviewed_at`,
  `related_correction_id`. Exceptions themselves are derived, not stored.

Migration 5 → 6 only creates this table and its indexes.

Indexes come from the unique keys: `(company_id, employee_number)` serves
lookups by company and by number; `(company_id, username)` and
`(employee_id, effective_from)` likewise. Further indexes are added with the
queries that need them (attendance, payroll).

## Changing the schema

Never delete a user's database to get past a schema change.

1. Change the tables and increment `schemaVersion` in `app_database.dart`.
2. `dart run build_runner build`
3. `dart run drift_dev make-migrations` — exports
   `drift_schemas/app_database/drift_schema_vN.json`, regenerates
   `app_database.steps.dart` and the schema helpers in
   `test/core/database/migrations/app_database/generated/`.
4. Write the step in `migration` using `stepByStep(...)`, keeping existing data.
5. Extend the data-integrity test in
   `test/core/database/migrations/app_database/migration_test.dart` for the new
   version (the command does not overwrite that file).
6. Add a row to the table above, then run `flutter test`.

Write the step only after step 3: `app_database.steps.dart` must exist for
`stepByStep` to compile.

Write `customConstraints` as string literals. drift_dev reads them
statically when exporting snapshots; an interpolated constant is silently
left out of the snapshot and the schema test then fails.

Commit the schema snapshots and generated files together with the change.
