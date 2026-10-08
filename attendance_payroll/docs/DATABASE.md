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

Indexes come from the unique keys: `(company_id, employee_number)` serves
lookups by company and by number; `(company_id, username)` and
`(employee_id, effective_from)` likewise. Further indexes are added with the
queries that need them (attendance, payroll).

## Changing the schema

Never delete a user's database to get past a schema change.

1. Change the tables and increment `schemaVersion` in `app_database.dart`.
2. `dart run build_runner build`
3. `dart run drift_dev make-migrations` — exports
   `drift_schemas/app_database/drift_schema_vN.json`, generates
   `app_database.steps.dart` and step-by-step migration tests.
4. Write the step in `migration` using `stepByStep(...)`, keeping existing data.
5. Add a row to the table above, then run `flutter test`.

Commit the schema snapshots and generated files together with the change.
