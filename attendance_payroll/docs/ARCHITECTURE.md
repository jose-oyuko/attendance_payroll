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
  `shared/`. A feature's `*_formatting.dart` (labels for its enums, no
  widgets) and `*_routes.dart` (locations) may also be used elsewhere, so a
  status reads the same on screen and on paper, and screens can link to
  each other.

Riverpod providers are the dependency-injection container. Failed providers
are never retried automatically (`app/configuration/provider_retry.dart`):
local failures do not go away on their own, and Riverpod's default retries
would show a spinner for about 40 seconds instead of the error. Screens
offer "Try again".

Anything environment-specific (configuration, logger, the database and device
id) is a provider that `bootstrap()` overrides, so tests can substitute fakes.

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

- **Kiosk mode** is a device setting (`device_settings`). It is the app's
  **locked state, and the state it starts in** (see "Locked by default"
  under Hardening): the router allows only `/kiosk` and `/kiosk/unlock`
  (`redirectForAuth`), outside the admin shell, so no administrator screen
  is reachable. Getting out requires an administrator to sign in at
  `/kiosk/unlock`.
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
- **Range view** (Attendance -> Range, added after Phase 8):
  `AttendanceService.range` returns one `EmployeeDay` per employee per date
  (at most `maxRangeDays` = 62), built by the same helper as `day`, so each
  row matches the daily view of its date. `AttendanceTotals` sums an
  employee's days (present, late, left early, absent, to review, payable
  time). The screen filters by employee and "only days with problems"; it
  shows a table with a total row per employee from medium widths, and
  cards grouped by employee on phones. Rows open the employee's history.

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

## Work schedules (Phase 6)

- **Schedules** name working weekdays with start/end times (a shift may
  cross midnight), late and early-departure tolerances, and an optional
  automatic break that replaces the company default on scheduled days.
- **Assignments** are effective-dated like pay rates: a new one closes the
  previous one; history is never rewritten; "no schedule" is allowed.
- **Dependency direction**: attendance defines `ScheduleSource` and
  `DaySchedule` (`Unscheduled`, `DayOff`, `ScheduledShift`); the schedules
  feature implements it (`CompanyScheduleSource`). Attendance does not depend
  on schedules.
- **Comparison** (in `SessionBuilder`): the day's first clock-in later than
  start + tolerance is `lateArrival`; the day's last clock-out earlier than
  end − tolerance is `earlyDeparture`; a scheduled shift that ended with no
  attendance is `missingAttendance`; a scheduled night shift does not raise
  `overnightSession`. These three are informational: pay follows time
  worked. They can be excused or noted, or corrected.
- **Daily statuses** now distinguish expected (before start + tolerance),
  absent, day off and no schedule; the dashboard and day view count late and
  absent.
- **Issue keys** are `<type>:<anchor>`: the event id, or
  `<employee>@<date>` for missing attendance. Existing keys are unchanged.
- Editing a schedule re-evaluates all dates its employees are on it, past
  ones included; finalized payroll keeps its own figures.

## Payroll engine (Phase 7)

- **Money** (`core/money/money.dart`) is integer minor units plus a
  currency; amounts of different currencies cannot be combined. Every
  calculated amount comes from one exact big-integer ratio rounded once,
  half away from zero (`Money.ofRatio`).
- **`PayrollCalculator`** is pure and deterministic. Inputs: per-day
  payable time (completed and approved sessions only), rate history,
  adjustments, settings. Rules:
  - each day is paid at the rate in force that day (one item per rate);
  - hourly: hours × rate; daily: days worked × rate; monthly: salary × days
    employed in the month ÷ days in the month;
  - overtime: daily threshold first, then weekly threshold over whole ISO
    weeks (a week spanning two periods is judged as one), paid at
    `overtimePercent` of the hourly equivalent (daily rate ÷ standard day;
    salary × 12 ÷ 52 ÷ standard week). No overtime until a threshold is set;
  - gross = regular + overtime + allowances + bonuses; net = gross −
    deductions.
- **Issues**: blocking — attendance awaiting review, time without a rate,
  rate in another currency, negative net pay; warnings — still clocked in,
  archived without an end date. Nothing is hidden or clamped.
- **`PayrollService`** creates non-overlapping periods, manages
  adjustments, reads attendance through `AttendanceReader` for the whole
  weeks around the period, calculates, and stores the run. A stored run never
  changes; a later rate change only affects a recalculation. Approved or
  finalized periods refuse changes (`payroll_locked`).

## Payroll lifecycle and screens (Phase 8)

- **Lifecycle**: `draft` → calculate → `review` → approve → `approved` →
  finalize → `finalized`; reopen returns approved payroll to `review` and
  finalized payroll to `reopened` (recalculate, approve and finalize again).
  `open` and `processing` are reserved. Approve, finalize and reopen need
  the new `approvePayroll` permission; reopen needs a reason.
- **No stale approvals**: approve and finalize recompute the period and
  compare the result's `fingerprint` with the stored run; any difference
  (attendance, rates, adjustments, settings changed) is a conflict asking
  for a recalculation. Blocking issues prevent approval.
- **Locking (§25)** goes through a core port, `core/locking/PayrollLock`,
  implemented by payroll (`PayrollPeriodLock`) and injected into
  attendance and employees, so features do not depend on each other.
  While a period is approved or finalized:
  - attendance corrections are refused at both the original and the new
    time (a clock-out is also checked against the previous day, because it
    closes a shift that may have started there);
  - exception decisions that change pay are refused (notes are allowed);
  - a rate covering any day of the period is refused: a new current rate
    covers every day from its start, a gap-filling rate only the days up
    to the next rate (`PayrollLock.lockedPeriodBetween`);
  - adjustments and recalculation are refused.
  The message says the payroll is finalized and must be reopened first.
- **History** is the audit log: every payroll action is recorded against
  the period (`entityType = payroll_period`) with the run or adjustment in
  its metadata, and `AuditLogRepository.forEntity` reads it back.
- **Screens** (`features/payroll/presentation`): the period list (new
  period defaulting to the current company month, overtime rules) and the
  period page — status actions, lock banner, totals per currency
  (`PayrollResult.totals`), problems with a link to exceptions, employees
  with a per-item pay breakdown, adjustments, and history. Wide windows use
  two columns. `payrollRevisionProvider` refreshes every payroll view,
  including the dashboard's current-payroll card.

## Reports and PDF (Phase 9)

- **Flow**: `ReportService` (domain) gathers each document's data through
  the features' own services, so documents show exactly what the screens
  and payroll use, under the same permissions. The result is plain data
  (`report_documents.dart`) with times already on the company's clock.
  `PayrollDocumentService` (domain interface, spec §38) lays it out;
  `PdfPayrollDocumentService` (data) does so with the `pdf` package on a
  background isolate (`Isolate.run`), so long reports never freeze the
  screen. Screens contain no layout code.
- **Documents**: payslips (one page each, from the period's current
  calculation: company, employee, period, hours, rate, earnings,
  deductions, gross, net, status, generated time), payroll summary (all
  employees, totals per currency, problems, signature lines), attendance
  report (one row per employee per day with a total per employee; any
  range up to 366 days, read in windows of the attendance service's
  62-day limit), timesheet (one employee, signature lines) and exception
  report (exceptions still needing a decision). Payroll that is not
  finalized is marked "Not final" on every page.
- **Fonts**: Roboto (Apache 2.0) is bundled in `assets/fonts/` and embedded,
  so documents render identically offline and support accented names.
  Dates and times on paper use one unambiguous style ("05 Oct 2026",
  "08:02") independent of device settings.
- **Preview** (`/document?kind=…`) is a route outside the admin shell, so
  a document opened from payroll or attendance returns there on back. It
  uses `printing`'s `PdfPreview` for print and share; the viewer is a
  provider (`documentViewerProvider`) because the printing plugin does not
  exist on a test host. Entry points: the Reports area, the payroll period
  page (Payslips, Summary, one employee's payslip from the pay breakdown)
  and Attendance → Range (PDF report, or the timesheet when one employee is
  selected).
- No schema change; generating a document is not audited (nothing changes).

## Thermal printing (Phase 10)

- **Layers** (spec §39): `PrinterService` (domain interface: status,
  discover, connect, disconnect, print) is all the app knows of a printer.
  `BluetoothPrinterService` (data) implements it for Bluetooth receipt
  printers speaking ESC/POS; USB or network printers are further
  implementations (their `PrinterConnection` values already exist), chosen
  in `printerServiceProvider`. Payroll code never learns which printer is
  used.
- **Receipt model**: `Receipt` (domain) is a list of lines (text, label
  and value columns, rule, feed, cut) with no printer language and no
  paper width. `EscPosEncoder` (data) wraps and aligns it for 58 mm (32
  characters) or 80 mm (48 characters) paper and emits ESC/POS. Text is
  reduced to ASCII ("José" prints as "Jose") because printers disagree
  on code pages, and control characters in names are dropped so a name
  cannot send printer commands.
- **Documents**: `payslipsReceipt` and `payrollSummaryReceipt`
  (`payroll_receipts.dart`) are plain functions of the same document data
  the PDFs use (`ReportService`), so a receipt and the PDF of one payslip
  always agree. Payroll that is not final says "NOT FINAL" on paper.
  Several payslips print as one job, cut between employees. Attendance
  reports are wide tables and have no receipt.
- **Bluetooth**: `BluetoothGateway` is the seam around the
  `print_bluetooth_thermal` plugin (classic Bluetooth/SPP), so the service
  is tested with a fake: a test host has no Bluetooth. Printers are
  paired in the phone's Bluetooth settings; the app lists the paired
  devices, connects to the chosen one and remembers it. The plugin's
  permission check shows the Android 12+ prompt, so status is read only
  when the administrator acts on a printer (opening the screen, refresh,
  printing), never polled.
- **PrintingService** (domain): chooses a printer (connects first; a printer
  that cannot be reached is never saved), sets the paper width, forgets the
  printer, prints a test page, and prints receipts, connecting when needed
  and reopening a dropped link once before giving up. Choosing the printer
  or paper is permission-checked (`managePrinter`) and audited
  (`printer.settings_changed`, naming the field, not the values). Printing
  a document, like generating a PDF, is not audited; it requires
  `viewPayroll`.
- **Settings**: `printer_settings` (schema 9) is one device-local row.
- **Screens**: Settings → Printer (current printer with status, test page,
  forget, paper width, paired printers with Use), and a "Print receipt"
  action on the payslip and payroll summary previews.
- **Android**: the manifest declares the Bluetooth permissions (legacy ones
  capped at Android 11, `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` for 12+).
  Receipt printing needs a physical Android device with a paired printer;
  the emulator has no Bluetooth.
- Deferred: USB and network printers, logos and barcodes on receipts,
  printing attendance reports on a receipt printer.

## Backup and restore (Phase 11)

- **Layers** (spec §26): `BackupService` (domain) holds the rules. It
  uses ports: `BackupStorage` (where files live; the local app folder now,
  Google Drive or another provider later as another implementation, with no
  change to the rules), `BackupCodec` (the file format), `BackupDatabase`
  (snapshot and replace the data), `BackupSecretStore` (the password) and
  `BackupSettingsRepository`. Screens never touch files or SQL.
- **File format** (`.apbackup`, `backupVersion` 1): `APBK`, a container
  version byte, the header length, a readable JSON header, then the data.
  The header says what the file is without the password: backup version, app
  version, schema version, date, kind, who made it, device, company and a
  few counts, and how it is protected. The data is the SQLite database,
  gzip-compressed and encrypted with AES-256-CTR under a key derived with
  PBKDF2-HMAC-SHA256 (150,000 iterations; salt and work factor are in the
  header, so the factor can be raised later). An HMAC-SHA256 tag over the
  header and the data is checked before anything is decrypted, so changing
  any byte makes decryption fail; a SHA-256 of the data in the header is a
  second check. (The first backups used AES-GCM, which was about 30 times
  slower; they still open. See Hardening.) A wrong password and a damaged
  file are indistinguishable by design. Derivation, compression and
  encryption run on a background isolate.
- **Protection**: every backup is encrypted. The key comes either from a
  **backup password** the administrator chose, or, when there is none
  (**standard protection**, the default), from a secret built into the app.
  Standard protection keeps a backup unreadable as a file, tamper-evident and
  restorable on any phone with the app, without a password to lose; anyone
  who has both the app and the file can open it, so a password is the choice
  for backups that leave the device. The header's `protection` field says
  which applies, so restoring asks for a password only when one is needed.
- **Creating**: `VACUUM INTO` takes a consistent snapshot while the app keeps
  running. The result is encrypted, then decrypted again and the database
  checked (`integrity_check`) **before** it is kept, so a backup that cannot
  be restored is never listed. Files are written under a temporary name and
  renamed, so a full disk never leaves a half-written backup. An unreadable
  folder or a bad file in it is reported, not fatal.
- **Restoring never swaps the database file or restarts the app.** The
  backup is decrypted and checked (not damaged, not from a newer schema),
  migrated to the current schema with the same tested migrations as an app
  update, attached to the live connection, and every company table is
  replaced in **one transaction** with foreign keys checked at commit. Any
  failure rolls everything back and the data is exactly as it was. Before
  that a **safety backup** of the current data is made (the last three are
  kept), so a restore can be undone. Tables that describe the device (its
  identity, kiosk mode, printer, backup settings) are never replaced. The
  audit entry is written inside the same transaction, so it is part of the
  restored data. Afterwards the app locks (the kiosk shows): the
  administrators now come from the backup.
- **Safeguards**: restoring needs the `manageBackups` permission, is refused
  on a kiosk device, and a backup of another company needs an explicit
  confirmation. A newer app version's backup says to update the app. Backup
  file names are validated so a name can never point outside the folder.
- **New installation**: first-run setup offers "Restore from a backup
  instead" (new phone, reinstall). It works only while the device has no
  company, so nothing can be lost and no administrator is needed.
- **Password** (optional): added in the Backup screen (8+ characters, with
  a warning that it cannot be recovered) and kept in the platform's secure
  storage (Android Keystore) so automatic backups can use it without asking.
  It can be removed again (back to standard protection, audited); backups
  already made keep the protection they had. It is never in the database, a
  backup, the audit log or a log. Restoring a password-protected file from
  elsewhere asks for its password.
- **Automatic backups**: when an administrator signs in and the newest
  backup is over a day old, one is made in the background (on by default;
  no password needed). Only automatic backups are pruned (default: keep 10);
  manual backups are never deleted by the app. A failure is remembered and
  shown on the Backup screen and is not retried for an hour.
- **Screens**: Backup (status and reminder, "Back up now", password, the
  backups with Export / Restore / Delete, restore from a file, settings).
  Export uses the system share sheet (Drive, email, ...).
- **Audit**: `backup.created`, `backup.restored`, `backup.deleted`,
  `backup.exported`, `backup.settings_changed`, `backup.password_changed`.
  None records the password or any business data.
- **Limits and deferred**: a backup is held in memory while it is made
  (fine for tens of megabytes; very large databases would need streaming).
  Deferred: Google Drive provider and scheduled background uploads (next
  phase), a dashboard reminder, backup of the company logo file.

## Hardening (Phase 12)

The review is written up where it belongs: security in
[SECURITY.md](SECURITY.md), database in [DATABASE.md](DATABASE.md), building
and shipping in [RELEASE.md](RELEASE.md). What changed in the code:

- **Security**: administrator password change (current password required,
  shares the sign-in lockout, audited); the app locks itself after a time
  an administrator chooses (15 minutes by default) without a touch or in the
  background (`SessionTimeoutGuard`, with the reason shown where they sign
  in); release builds hide the app from screenshots and
  the recent-apps list; Android Auto Backup is off; the network permission is
  removed; release signing is read from an uncommitted `key.properties`.
- **Backup speed**: backups moved from AES-GCM to AES-256-CTR with an
  HMAC-SHA256 tag (encrypt-then-MAC, checked before decrypting). GCM's
  authentication runs at about 0.5 MB/s in pure Dart; the new construction is
  about 30 times faster, so a large company's backup takes seconds, not
  minutes. Files made with GCM still open.
- **Database**: write-ahead logging and full synchronous writes; query-plan
  and scale tests (see DATABASE.md).
- **Accessibility and layout**: a sweep opens every screen with realistic data
  at phone, small-tablet and tablet sizes and at the largest text size, and
  fails on any overflow, any control smaller than 48 dp or without a label,
  and any text with too little contrast in light or dark. It found and fixed
  overflows in the employee list, employee detail, attendance range,
  schedules, schedule form, payroll period and dashboard, and a rail whose
  items were 44 dp high. `BuildContext.largeText` is the shared way for a
  layout to stack what it would otherwise put side by side.
- **Tests that guard promises**: `test/security/source_hygiene_test.dart` (no
  network code, nothing printed, secure randomness, no SQL from text, manifest
  settings), `test/integration/payroll_cycle_test.dart` (the whole workflow
  from the spec, finalized payroll surviving a later rate change and a backup
  restore), `payroll_properties_test.dart` (random months against an
  independent exact calculation) and the scale tests.
- **Locked by default** (changes made before the first release): the
  attendance kiosk is the app's resting state. The app **starts locked**
  (`AuthController.build` asks `KioskService.lockIfNeeded`, which turns the
  device's kiosk flag on, recorded as the app's own action), **locks itself**
  after the chosen idle time, and locks when an administrator presses Lock
  app. There is no separate sign-in screen any more: an administrator
  unlocks from the kiosk's "Administrator" button, which signs in and turns
  the flag off. Locking after a restore is the app's own action, because the
  restoring administrator may no longer exist in the restored data. The idle
  time is a device setting (`device_settings.lock_after_minutes`, schema 11;
  null means 15 minutes, 0 means never) read through `AppLockService`,
  changed by an administrator in Settings → App lock and audited.
  `inactivityLimitProvider` turns it into the timer; a new value applies to
  the session in progress. The kiosk is never timed out.
- **Backups encrypted by default**: a backup no longer needs a password
  (see Backup and restore → Protection), so "Back up now" and automatic
  backups work from the first minute.
- **Release**: version 1.0.0; CI also builds the release APK and fails if it
  asks for the network or allows Android backup.

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
| 5 | Exceptions and corrections |
| 6 | Work schedules |
| 7 | Payroll engine |
| 8 | Payroll UI |
| 9 | Reports and PDF |
| 10 | Thermal printing |
| 11 | Backup and restore |
| 12 | Hardening (current) |
| 13 | Cloud architecture (documentation only) |

## Current boundaries

After Phase 12 the V1 feature set is complete and reviewed (version 1.0.0):
attendance, schedules, exceptions, the full payroll cycle (calculate, adjust,
approve, finalize, reopen, with locking and history), printable documents
(PDF with preview, print and share), Bluetooth thermal receipts, and encrypted
local backup and restore, with sessions that expire and a changeable
administrator password.

Deliberately not in V1 (see SECURITY.md and the spec's section 55): cloud
backup and synchronization (Phase 13 describes the design), administrator
password recovery (there is no server; restore a backup), encryption of the
database file itself, finer administrator roles, and remembering the theme
choice between launches.
