# Architecture

## Principles

- Offline-first: every core workflow works without a network.
- Feature-first folders with clean-architecture layering.
- Payroll and attendance rules are pure Dart and testable without a UI.
- Never lose or silently rewrite history: attendance events are append-only,
  corrections are separate audited records, finalized payroll is locked.

## Layers and dependency direction

```
presentation  ->  domain  ->  repository interfaces  <-  data (Drift / platform)
```

- `presentation/` holds widgets and Riverpod notifiers. It never talks to the
  database directly.
- `domain/` holds entities, value objects, business rules and repository
  interfaces. It has no Flutter imports.
- `data/` implements repository interfaces on top of Drift and platform APIs.
- `app/` only wires things together (router, theme, configuration, shell).
- `core/` contains framework-agnostic building blocks and must not depend on
  `app/`, `features/` or `shared/`.
- Features may use another feature's `domain/` (entities, repository
  interfaces, services), its public providers (`data/*_providers.dart`) and
  its read-only presentation providers (files named `*_provider.dart` /
  `*_providers.dart`, plus the session in
  `authentication/presentation/auth_controller.dart`). They never use another
  feature's Drift classes, widgets or screens. Shared UI and formatting go in
  `shared/`.

Riverpod providers are the dependency-injection container. Anything
environment-specific (configuration, logger, later the database and device id)
is a provider that `bootstrap()` overrides, so tests can substitute fakes.

## Conventions established in Phase 0

### Errors

Expected failures are `AppFailure` subclasses (`core/errors/app_failure.dart`).
Each has a stable `code`, a `userMessage` that is safe to show, and an optional
technical `cause` that is only for logs. `toString()` omits the cause. Domain
and data code return `Result<T>` (`core/result/result.dart`) instead of
throwing. `Result.guard` converts anything thrown into an `Err`.

`guardDatabase` (`core/database/database_guard.dart`) maps Drift/SQLite
exceptions to `ConflictFailure` (unique violations) and `DatabaseFailure`.

### Logging

`AppLogger` writes `LogRecord`s to `LogSink`s. Structured `fields` are passed
through `Redactor`, which masks keys such as `pin`, `password`, `token`, `hash`
and `secret`. Secrets must never be placed in the message string. Verbosity is
set by the environment (debug / info / warning).

### Configuration

`AppConfig` is immutable and chosen at build time with
`--dart-define=APP_ENV=...`. It is exposed through `appConfigProvider`, which
throws unless overridden, so a missing override is caught immediately.

### Theme

Material 3 from a single seed colour. Status colours that Material does not
provide (success, warning, info, neutral) live in the `SemanticColors` theme
extension. Widgets read `context.semanticColors` and `context.colors`; they do
not hard-code colours. Spacing comes from `AppSpacing`, sizes from
`AppConstants`.

### Responsive layout

`WindowSize` implements the Material 3 window size classes (compact < 600,
medium < 840, expanded < 1200, large < 1600, extra large above). Widgets measure
the space they are given (`WindowSizeBuilder`, `AdaptiveGrid`) rather than the
screen, so they behave inside panes.

| Size | Admin navigation |
|---|---|
| compact | app bar + navigation drawer |
| medium | navigation rail, selected label only |
| expanded and up | extended navigation rail |

Kiosk mode is a separate route tree with large touch targets and no
administrative navigation (see Phase 4 below).

### Routing

`AdminDestination` is the single source of truth for areas, their paths, icons
and the phase that builds them. The router creates one `StatefulShellBranch` per
destination so each area keeps its navigation state.

## Authentication and authorisation (Phase 2)

- **Administrators** sign in with a username and password. First run creates
  the company and its owner (`AdminAuthService.setUp`); afterwards the router
  only shows administrator screens to a signed-in session.
- **Employees** authenticate with a PIN through `EmployeePinService`, separate
  from administrator sign-in, with its own lockout policy. Administrators can
  issue a temporary PIN (shown once, must be changed on first use) but can
  never read a PIN.
- **Secrets** are hashed with PBKDF2-HMAC-SHA256 (`SecretHasher`, verified
  against RFC 7914) with a random salt, on a background isolate. Each hash
  records its work factor, so it can be raised later. Unknown accounts take the
  same time as wrong passwords.
- **Lockout**: five failures lock the credential; each further lock doubles
  (passwords up to 1 hour, PINs up to 1 day). A locked credential is not even
  checked.
- **Authorisation** lives in application services: each takes an
  `AdminSession`, checks a `Permission` and keeps the session inside its own
  company. Hiding UI is never the only protection. Roles map to permission
  sets (`AdminRole.permissions`); V1 has only `owner`.
- **Audit**: changes and their `AuditLogRepository.record` entry are written in
  one transaction (`TransactionRunner`), so neither exists without the other.
  Metadata records which fields changed, never secrets or values.

## Attendance engine (Phase 3)

- **Events are the source of truth.** `attendance_events` is append-only:
  clock actions are never edited or deleted. `occurredAt` is when the action
  happened, `recordedAt` when this device stored it.
- **Sessions are derived, not stored.** `SessionBuilder` turns one employee's
  events into sessions and issues: a pure, deterministic function that never
  drops an event. A session's key is its clock-in event id, stable across
  rebuilds, so later phases can attach exceptions and approvals to it.
- **Issues** flagged during derivation: missing clock-out, overnight session,
  excessive duration (these block payroll: such a session has no payable time
  until reviewed), duplicate clock-in/out within the duplicate window, and
  clock-out without clock-in. Phase 5 turns them into reviewable exceptions;
  late arrival and early departure need schedules (Phase 6).
- **State machine** (`AttendanceStateMachine`): not clocked in → clock in →
  clocked in → clock out. A clock-in older than the stale threshold allows a
  new clock-in, so a forgotten clock-out never blocks the next day. Recording
  before the latest event (device clock moved back) is refused.
- **Time zones**: instants are UTC; `CompanyTimeZone` (IANA database from
  `package:timezone`) gives company-local dates and times, including DST, so
  the device's own timezone setting never matters. A session belongs to the
  company date of its clock-in.
- **Thresholds are per company** (`AttendancePolicy`, stored in
  `attendance_settings`, edited under Settings → Attendance rules, audited):
  duplicate window (default 10 min), forgotten clock-out after (16 h), flag
  sessions longer than (12 h), optional automatic break. Values are
  range-checked. The PIN check validity (2 min) is a fixed security setting.
- **Kiosk actions** require a fresh `PinVerification` (and a changed
  temporary PIN); the check and the new event run in one transaction.
- **Kiosk identification (Phase 4 design):** the employee taps their name,
  enters their PIN, then confirms the action ("Good morning John — Clock in").
- **Corrections** (`AttendanceCorrectionService`): an administrator with
  `correctAttendance` can add a missed clock-in/out, change an entry's time,
  or remove an entry, always with a reason. Nothing is overwritten: a
  correction record plus, where needed, a new admin-sourced event; the
  original event stays, superseded. The correction, its event and its audit
  entry are one transaction. Sessions rebuild from the counting events, so a
  correction takes effect everywhere, including the kiosk state. Approving or
  dismissing flagged sessions remains Phase 5.

## Kiosk mode and attendance screens (Phase 4)

- **Kiosk mode** is a device setting (`device_settings`), started by an
  administrator from Attendance → Start kiosk. Starting it signs the
  administrator out; it survives restarts. While on, the router allows only
  `/kiosk` and `/kiosk/unlock` (`redirectForAuth`), outside the admin shell,
  so no administrator screen is reachable. Leaving it requires an
  administrator to sign in at `/kiosk/unlock`.
- **The kiosk has no session.** `KioskService` is its only door to employee
  data: it lists active employees (names only) and checks PINs, and refuses
  everything unless kiosk mode is on for that company. Clock actions then
  need the resulting `PinVerification`, as before.
- **Flow** (`KioskFlow`): tap name → PIN → (choose a new PIN if it is
  temporary) → greeting with current status and the allowed action → clock
  in/out → confirmation. Unfinished steps return to the start after 30 s
  idle; the confirmation after 5 s. The back button never leaves the kiosk.
  Keys are 76 dp; the PIN pad announces how many digits are entered.
- **Admin attendance**: the Attendance area shows one day for everyone
  (`AttendanceService.day`): present, working now, needs review, not clocked
  in, with times and payable hours; each row opens the employee's history and
  corrections. The dashboard shows today's counts. Until schedules exist
  (Phase 6) "not clocked in" cannot distinguish absence from a day off.

## Exceptions and review (Phase 5)

- **Exceptions are derived** like sessions; only decisions are stored
  (`exception_reviews`). An exception's key is `<type>:<event id>`, stable
  across rebuilds. If a correction replaces the event, the key changes and
  the new fact needs a fresh review; an earlier acceptance never carries over.
- **Statuses**: open → (reviewed) → resolved or dismissed. Allowed decisions
  depend on the type (`AttendanceExceptionService.decisionsFor`): a missing
  clock-out can only be fixed by a correction; overnight and excessive
  sessions can be accepted as recorded; informational issues (duplicates,
  clock-out without clock-in) can be dismissed; any can get a note.
- **Payroll effect**: a session whose blocking issues are all accepted is
  `approved` and payable; one with any unaccepted blocking issue has no
  payable time. A session without a clock-out is never approvable.
- **Corrections can resolve exceptions**: passing `resolves:` records a
  `resolved` decision linked to the correction in the same transaction.
- **One reader** (`AttendanceReader`) loads events, policy, timezone and
  decisions and derives attendance for the timeline, the daily view, the
  exception list and, later, payroll, so they always agree.
- **UI**: Attendance → Exceptions (badge with the open count): needs action /
  settled / all, a split view on tablets and a bottom sheet on phones, with
  the actions above and the review history. Every change bumps
  `attendanceRevisionProvider`, which all derived attendance views watch, so
  no screen shows stale data.
- Late arrival, early departure and missing attendance need schedules and are
  added in Phase 6 as further issue types.

## Database

Drift over SQLite with versioned, tested migrations. Conventions (UUIDv7 keys,
UTC instants, `LocalDate` calendar dates, integer money, optimistic
concurrency, sync metadata), the schema history and the procedure for changing
the schema are in [DATABASE.md](DATABASE.md).

Repository interfaces live in each feature's `domain/`, Drift implementations
in `data/`, exposed through Riverpod providers. Domain entities validate
themselves (`validate()`); repositories validate again before writing, and the
database enforces keys, foreign keys and CHECK constraints underneath.

## Future synchronization

Nothing in V1 talks to a server, but the design leaves room:

- Repositories are interfaces, so a cloud-backed implementation can sit beside
  the local one.
- `version` supports optimistic concurrency; `syncState`
  (`LOCAL_ONLY`, `PENDING_SYNC`, `SYNCED`, `CONFLICT`, `FAILED`) tracks status.
- A stable local device id (introduced early) identifies where a record was
  created.
- Append-only events merge without conflicts; mutable entities use `version`
  and, later, server timestamps.
- A sync outbox table and retry policy can be added later as migrations without
  touching the domain layer.

## Testing strategy

| Kind | Scope |
|---|---|
| Unit | domain rules, payroll, money, attendance state machine, exception detection, core utilities |
| Repository | in-memory Drift: persistence, constraints, migrations |
| Widget | provider overrides and view sizes: forms, PIN screen, clock flow, navigation |
| Integration | critical end-to-end workflow (create employee through payslip) |

`dart format`, `flutter analyze` and `flutter test` run in CI
(`.github/workflows/ci.yml`).

## Phase plan

| Phase | Scope |
|---|---|
| 0 | Foundation |
| 1 | Database foundation |
| 2 | Authentication and employee management |
| 3 | Attendance engine |
| 4 | Attendance UI and kiosk mode |
| 5 | Exceptions and corrections (current) |
| 6 | Work schedules |
| 7 | Payroll engine |
| 8 | Payroll UI |
| 9 | Reports and PDF |
| 10 | Thermal printing |
| 11 | Backup and restore |
| 12 | Hardening |
| 13 | Cloud architecture (documentation only) |

## Current boundaries

After Phase 5: employees clock in and out at the kiosk; administrators see
daily attendance, review and settle exceptions, and correct attendance.
Still deferred: schedules with late/early detection (Phase 6), administrator
password change and recovery, session timeout, settings persistence, and
payroll.
