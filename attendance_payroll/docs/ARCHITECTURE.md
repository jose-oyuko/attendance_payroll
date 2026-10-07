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
- Features do not import each other's `data/` or `presentation/`. Shared UI
  goes in `shared/`.

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

Phase 1 adds a mapper from Drift/SQLite exceptions to `DatabaseFailure` and
`ConflictFailure` (for example a unique-constraint violation).

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

Kiosk mode (Phase 4) is a separate route tree with large touch targets and no
administrative navigation.

### Routing

`AdminDestination` is the single source of truth for areas, their paths, icons
and the phase that builds them. The router creates one `StatefulShellBranch` per
destination so each area keeps its navigation state.

## Database design (Phase 1)

- Drift over SQLite, `schemaVersion` plus step-by-step migrations. Schema dumps
  are checked in so migrations can be tested.
- UUID text primary keys generated in the app, so devices can create records
  independently.
- Shared metadata columns where meaningful: `createdAt`, `updatedAt`, `version`,
  `syncState`, `deletedAt`.
- Timestamps stored as UTC; the company timezone is applied in the domain layer.
- Money stored as integer minor units (never doubles).
- Attendance events are append-only; corrections reference the original event.
- Foreign keys enabled; unique employee number per company.

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
| 0 | Foundation (this phase) |
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
| 12 | Hardening |
| 13 | Cloud architecture (documentation only) |

## Phase 0 boundaries

Deliberately not in Phase 0: database, authentication, persistence of settings
(the theme choice is in memory only), device identity, and any attendance or
payroll logic. Screens for those areas state which phase delivers them.
