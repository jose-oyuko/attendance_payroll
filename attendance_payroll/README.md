# Attendance & Payroll

Offline-first employee attendance and payroll application built with Flutter.
Target platforms: Android phones, tablets and large Android screens.

**Current status: Phase 0 — project foundation.** See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the architecture and the
phase plan.

## Requirements

- Flutter **3.44 or newer** (stable channel, Dart 3.12 or newer). `go_router`
  18 requires it.

## First-time setup

This repository contains the Dart code, tests and configuration but not the
generated Android platform folder. Create it once:

```bash
git init && git add -A && git commit -m "Phase 0 foundation"   # so you can review what follows
flutter create --platforms=android --project-name attendance_payroll --org <your.reverse.domain> .
git status                                                     # review what flutter create added or changed
```

`flutter create` should only add platform files (`android/`, `.metadata`).
Check that `lib/main.dart`, `pubspec.yaml` and `analysis_options.yaml` were not
changed (restore them from git if they were), and delete
`test/widget_test.dart` if it was generated.

Then:

```bash
flutter pub get
dart run build_runner build   # only after changing tables; generated code is committed
dart format .
flutter analyze
flutter test
flutter run
```

## Build environments

The environment is chosen at build time and defaults to `development`:

```bash
flutter run --dart-define=APP_ENV=staging
flutter build apk --dart-define=APP_ENV=production
```

An unknown `APP_ENV` value fails at startup rather than silently falling back.

| Environment | Log level |
|---|---|
| development | debug |
| staging | info |
| production | warning |

## What Phase 0 contains

- Riverpod wiring and an explicit configuration provider
- `go_router` with a stateful admin shell (one branch per area)
- Adaptive navigation: drawer on phones, rail on small tablets, extended rail
  on large tablets
- Material 3 light/dark theme with semantic status colours
- Structured failures (`AppFailure`) and `Result<T>`
- Structured logging with automatic redaction of secrets
- Global error handlers that log technical details
- Responsive layout primitives (`WindowSize`, `AdaptiveGrid`, `PageContainer`)
- Reusable empty, error and loading states
- Unit and widget tests, strict lints, CI workflow

Areas that are not built yet (Employees, Attendance, Schedules, Payroll,
Reports, Backup) are shown as clearly labelled "not available yet" screens that
name the phase delivering them.

## What Phase 1 adds

- Drift/SQLite database with schema version 1 and migration tests
  ([docs/DATABASE.md](docs/DATABASE.md))
- Companies, administrator users, employees and pay rate history
- Repositories with validation, optimistic concurrency and friendly errors
- Tests against real SQLite, including persistence across a restart

## What Phase 2 adds

- First-run setup (company and owner account) and administrator sign-in/out
- Employee list with search and archived filter, create/edit form, detail page
- Activate, deactivate, suspend, archive and restore, each confirmed
- Pay rate history: set and change rates (old rates are kept)
- Employee PINs: issue/reset a temporary PIN shown once; hashing, lockout
- Audit log of employee, PIN and sign-in events; stable device identity
- Database schema version 2, with a tested migration from version 1

## What Phase 3 adds

- Append-only attendance events (clock-in/clock-out) with device and source
- A state machine for clock actions; forgotten clock-outs never block the
  next day; device clocks set back are detected
- Sessions derived from events, with issues flagged for review (missing
  clock-out, overnight, excessive hours, duplicates, clock-out without
  clock-in); flagged sessions are never paid automatically
- Company timezone handling with the IANA database, including DST
- Database schema version 3, with tested migrations

Follow-up to Phase 3:

- Attendance rules are per company and editable under Settings
- Administrators can correct attendance from an employee's page (Employees →
  employee → View attendance): add a missed clock-in/out, change a time, or
  remove an entry, each with a reason; originals are kept and every change is
  audited
- Database schema version 4

## What Phase 4 adds

- Kiosk mode for a shared tablet: tap your name, enter your PIN (choose your
  own PIN the first time), confirm Clock in / Clock out, see a confirmation.
  Started from Attendance → Start kiosk; it signs the administrator out,
  survives restarts, and only an administrator's password leaves it
- Employees can change their PIN at the kiosk
- Attendance area: everyone's attendance for any day, with status and hours;
  tap a person for their history and corrections
- Dashboard: today's present / working now / needs review / not clocked in
- Database schema version 5

## Project layout

```
lib/
  app/        wiring only: app widget, router, theme, configuration, shell
  core/       framework-agnostic building blocks: errors, result, logging, constants
  features/   one folder per feature, each with data/ domain/ presentation/
  shared/     widgets and responsive helpers used by several features
test/         mirrors lib/
docs/         architecture and database notes
drift_schemas/  exported schema snapshots, one per schema version
```

Empty `.gitkeep` files hold the folders reserved for later phases.
