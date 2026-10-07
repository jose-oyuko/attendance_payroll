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

## Project layout

```
lib/
  app/        wiring only: app widget, router, theme, configuration, shell
  core/       framework-agnostic building blocks: errors, result, logging, constants
  features/   one folder per feature, each with data/ domain/ presentation/
  shared/     widgets and responsive helpers used by several features
test/         mirrors lib/
docs/         architecture notes
```

Empty `.gitkeep` files hold the folders reserved for later phases.
