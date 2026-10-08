# MASTER ENGINEERING PROMPT

## Offline-First Employee Attendance & Payroll Application

You are acting as a senior Flutter software architect and engineer.

We are going to build a production-quality, offline-first employee attendance and payroll application using Flutter and Dart.

Do not treat this as a simple demo application or tutorial project.

The application should be architected like a real commercial business application, with clean separation of concerns, maintainability, testability, database migrations, responsive UI, security, auditability and a clear path toward future cloud synchronization.

We will implement the project in multiple phases.

Do NOT attempt to generate the entire application in one response.

For each phase:

1. Explain the architecture being implemented.
2. Implement only the scope of that phase.
3. Make sure the project remains compilable and runnable.
4. Add appropriate tests.
5. Explain files created or modified.
6. Explain how to run and test the phase.
7. Do not implement features belonging to later phases unless they are required as architectural foundations.

---

# 1. PRODUCT OVERVIEW

The application is an employee attendance and payroll management system.

The primary user is an employer/administrator.

Employees interact mainly with the attendance functionality.

The application must work completely offline for its core functionality.

The first version does NOT require a backend or Internet connection.

The architecture must nevertheless be designed so that future versions can add:

- Cloud backup
- Google account authentication
- Cloud storage
- Multi-device synchronization
- Multiple attendance terminals
- Conflict resolution
- Remote administration
- Cloud database
- Centralized company management

without requiring a complete rewrite of the application.

The application should work well on:

- Android phones
- Android tablets
- Large Android screens

The architecture should also avoid unnecessarily coupling business logic to Android-specific APIs so that iOS/web/desktop support could potentially be introduced later.

---

# 2. CORE PRODUCT CONCEPT

The fundamental business flow is:

COMPANY
↓
EMPLOYEES
↓
EMPLOYEE PROFILE
↓
WORK SCHEDULE
↓
ATTENDANCE EVENTS
↓
ATTENDANCE SESSIONS
↓
ATTENDANCE EXCEPTIONS
↓
ADMIN REVIEW/CORRECTION
↓
VALIDATED TIMESHEETS
↓
PAYROLL PERIOD
↓
PAYROLL CALCULATION
↓
PAYROLL RUN
↓
PAYSLIPS / REPORTS / PDF / THERMAL PRINT

Attendance is the source data.

Payroll is calculated from validated attendance/timesheet data.

Do not tightly couple payroll calculations to UI widgets or raw database queries.

---

# 3. IMPORTANT TERMINOLOGY

Use these concepts consistently.

## Administrator

A person who manages the company and application.

Administrator capabilities include:

- Manage employees
- Configure rates
- Configure schedules
- Review attendance
- Correct attendance
- Review exceptions
- Create payroll periods
- Calculate payroll
- Approve/finalize payroll
- Generate reports
- Print/export payroll
- Configure application settings
- Manage backups
- Reset employee PINs

## Employee

An employee whose attendance and payroll are managed by the system.

Employees primarily interact through:

- PIN authentication
- Clock in
- Clock out
- View current attendance status
- Change their PIN

## Attendance Event

A raw action such as:

- CLOCK_IN
- CLOCK_OUT

Events should be treated as the fundamental attendance record.

## Attendance Session

A derived/processed period between a clock-in and corresponding clock-out.

Example:

CLOCK_IN:
2026-10-05 08:02

CLOCK_OUT:
2026-10-05 17:04

Session:
8h 02m after applicable break rules.

## Attendance Exception

An unusual or potentially incorrect attendance situation.

Examples:

- Missing clock-out
- Clock-out on a different day
- Excessive hours
- Late arrival
- Early departure
- Duplicate clock-in
- Duplicate clock-out
- Unexpected overnight session
- Missing attendance
- Other configurable anomalies

## Payroll Period

A defined period such as:

2026-10-01 → 2026-10-31

## Payroll Run

A calculation of employee compensation for a payroll period.

## Payroll Item

Individual components of compensation.

Examples:

- Regular hours
- Overtime
- Allowance
- Bonus
- Deduction

---

# 4. TECHNOLOGY STACK

Use modern, actively maintained Flutter/Dart packages.

Before selecting packages, verify that the chosen versions are compatible with the current stable Flutter/Dart ecosystem.

Preferred architecture/tools:

## Framework

Flutter

## Language

Dart

Use sound null safety.

## State management

Riverpod.

Prefer the modern Riverpod approach appropriate for the current stable version.

## Navigation

go_router.

## Database

SQLite through Drift.

Do not make UI code directly execute SQL.

Use Drift as the typed database abstraction and migration layer.

## Models

Use immutable domain models where appropriate.

Freezed may be used where it materially improves maintainability.

Do not introduce packages merely because they are popular.

Every dependency should have a clear architectural purpose.

## PDF

Use a maintained Flutter/Dart PDF solution.

Prefer:

- pdf
- printing

or their current maintained equivalents.

## Thermal printing

Design a printer abstraction.

Initial support may target Bluetooth thermal receipt printers.

The architecture should allow future support for:

- Bluetooth
- USB
- Network printers

Do not make payroll logic dependent on a specific printer implementation.

## Local storage

Use SQLite/Drift for structured application data.

Use secure platform storage where credentials/secrets are required.

Do not store sensitive PINs as plain text.

---

# 5. ARCHITECTURE

Use a feature-first architecture combined with clean architecture principles.

A recommended structure is:

lib/
app/
app.dart
router/
theme/
configuration/

core/
errors/
logging/
result/
utils/
constants/
extensions/
security/
database/
platform/

features/
authentication/
data/
domain/
presentation/

```
employees/
  data/
  domain/
  presentation/

attendance/
  data/
  domain/
  presentation/

schedules/
  data/
  domain/
  presentation/

payroll/
  data/
  domain/
  presentation/

reports/
  data/
  domain/
  presentation/

printing/
  data/
  domain/
  presentation/

backup/
  data/
  domain/
  presentation/

settings/
  data/
  domain/
  presentation/
```

shared/
widgets/
models/
components/

Avoid creating one giant "services" folder containing unrelated business logic.

Business logic should live close to its feature/domain.

---

# 6. LAYERING

Maintain a clear dependency direction:

Presentation
↓
Application / Domain
↓
Repositories
↓
Data Sources
↓
Database / Platform

The domain layer must not depend directly on Flutter widgets.

Business logic should be testable without rendering a UI.

Database-specific implementation should remain in the data layer.

---

# 7. DATABASE DESIGN

Use SQLite through Drift.

Design the database using migrations from the beginning.

Do NOT rely on deleting and recreating the database during development once migrations exist.

Use UUIDs or another robust globally unique identifier for business entities.

Do not use auto-increment integer IDs as the only identity mechanism because future synchronization may require IDs generated independently on different devices.

All important entities should have fields similar to:

- id
- createdAt
- updatedAt
- version
- syncState or equivalent future synchronization metadata
- deletedAt where soft deletion is appropriate

Do not blindly add these fields to every table if they have no semantic meaning, but design persistent business entities with future synchronization in mind.

---

# 8. DATABASE ENTITIES

Design and implement the following conceptual schema.

You may refine field names and normalization if necessary, but preserve the business meaning.

---

## COMPANY

Represents the business using the application.

Fields should include concepts such as:

- id
- name
- legalName
- registrationNumber if applicable
- phone
- email
- address
- currency
- timezone
- logo reference if applicable
- createdAt
- updatedAt
- version
- deletedAt

The application should support the possibility of multiple companies in the future, even if V1 primarily operates with one company per installation.

---

# 9. ADMINISTRATIVE USERS

Do not treat administrators as employees.

Create a separate concept for application users/admins.

Possible fields:

- id
- companyId
- username/email where appropriate
- displayName
- password/authentication metadata
- role
- active
- createdAt
- updatedAt
- lastLoginAt
- version

V1 can support a simple local administrator authentication mechanism.

Design the system so roles/permissions can be expanded later.

Possible future roles:

- Owner
- Payroll Administrator
- HR Administrator
- Attendance Manager
- Supervisor
- Auditor

Do not hard-code authorization logic throughout widgets.

---

# 10. EMPLOYEES

Fields should include:

- id
- companyId
- employeeNumber
- firstName
- middleName if needed
- lastName
- displayName
- phone
- email
- jobTitle
- departmentId if departments are introduced
- employmentStatus
- employmentStartDate
- employmentEndDate
- createdAt
- updatedAt
- version
- deletedAt

Possible employment statuses:

ACTIVE
INACTIVE
SUSPENDED
ARCHIVED

Never physically delete an employee if historical payroll/attendance records depend on them.

Use soft deletion/archive semantics where appropriate.

---

# 11. EMPLOYEE PIN SECURITY

Do not store employee PINs as plain text.

Create an appropriate PIN credential representation.

The system must support:

- Employee changes PIN
- Administrator resets PIN
- Temporary PIN if desired
- PIN lockout/rate limiting if appropriate
- Secure hashing

The administrator must NOT be able to retrieve an employee's existing PIN.

The administrator may reset it.

Employee PIN authentication should be separated from administrator authentication.

---

# 12. EMPLOYEE RATE HISTORY

Do not store only the employee's current hourly rate.

Create historical rate records.

Example:

John:

2026-01-01 → 2026-06-30 = KSh 400/hour
2026-07-01 → current = KSh 500/hour

Fields should conceptually include:

- id
- employeeId
- rateType
- amount
- currency
- effectiveFrom
- effectiveTo
- createdAt
- updatedAt
- version

The payroll engine must use the rate applicable to the payroll period/date.

Never retroactively modify historical payroll merely because an employee's current rate changes.

---

# 13. WORK SCHEDULES

Create configurable work schedules.

Example:

Monday:
08:00 → 17:00

Tuesday:
08:00 → 17:00

...

Saturday:
OFF

Sunday:
OFF

Schedule fields should support:

- schedule
- schedule days
- expected start time
- expected end time
- break rules
- expected working duration
- overnight schedules where appropriate
- effective dates

Employees should be assignable to schedules.

Do not hard-code Monday-Friday 08:00-17:00.

---

# 14. ATTENDANCE EVENTS

This is one of the most important tables.

Create an attendance event model.

Conceptually:

attendance_events

- id
- employeeId
- eventType
- occurredAt
- recordedAt
- source
- deviceId
- createdBy
- correction/reference metadata
- createdAt
- updatedAt
- version
- deletedAt

eventType:

CLOCK_IN
CLOCK_OUT

Potential future types:

BREAK_START
BREAK_END
MANUAL_ADJUSTMENT
SYSTEM_EVENT

The event timestamp should represent when the attendance action occurred.

The recorded timestamp represents when the application actually recorded it.

This distinction is important for corrections and synchronization.

---

# 15. ATTENDANCE SESSIONS

Do not make sessions the primary source of truth.

Sessions are derived from attendance events.

A session should conceptually contain:

- id
- employeeId
- clockInEventId
- clockOutEventId
- startTime
- endTime
- duration
- breakDuration
- payableDuration
- status
- validation state
- createdAt
- updatedAt

Possible statuses:

OPEN
COMPLETED
EXCEPTION
CORRECTED
APPROVED

The system should be able to rebuild/derive sessions from events where necessary.

---

# 16. ATTENDANCE EXCEPTIONS

Create a dedicated exception entity.

Examples:

MISSING_CLOCK_OUT
OVERNIGHT_SESSION
EXCESSIVE_DURATION
LATE_ARRIVAL
EARLY_DEPARTURE
DUPLICATE_CLOCK_IN
DUPLICATE_CLOCK_OUT
MISSING_ATTENDANCE
OTHER

Fields:

- id
- employeeId
- attendanceSessionId where applicable
- type
- severity
- detectedAt
- description
- status
- resolvedAt
- resolvedBy
- resolutionReason
- relatedCorrectionId

Statuses:

OPEN
REVIEWED
RESOLVED
DISMISSED

The exception engine should be configurable and testable.

---

# 17. ATTENDANCE CORRECTIONS

Do not silently overwrite attendance history.

Create an auditable correction model.

A correction should capture:

- original event/session
- corrected value
- reason
- administrator who performed correction
- timestamp
- previous value
- new value

Example:

Original clock-out:
14:00

Corrected:
17:00

Reason:
Employee forgot to clock out.

Administrator:
Admin User

Timestamp:
2026-10-05 18:21

The audit trail must remain intact.

---

# 18. AUDIT LOG

Create an audit log mechanism.

Record significant business actions:

- Employee created
- Employee edited
- Employee archived
- PIN reset
- PIN changed
- Attendance correction
- Payroll created
- Payroll recalculated
- Payroll approved
- Payroll finalized
- Payroll reopened
- Backup created
- Backup restored
- Settings changed

Fields should include:

- id
- actorId
- companyId
- action
- entityType
- entityId
- timestamp
- metadata/details
- deviceId

Do not store sensitive information unnecessarily in audit metadata.

---

# 19. PAYROLL PERIODS

Create payroll periods.

Example:

October 2026:

startDate:
2026-10-01

endDate:
2026-10-31

Statuses:

DRAFT
OPEN
PROCESSING
REVIEW
APPROVED
FINALIZED
REOPENED

A finalized payroll must not silently change.

---

# 20. PAYROLL RUNS

A payroll period can have a payroll calculation/run.

Separate the concept of:

Payroll Period

from:

Payroll Run

This allows recalculation while maintaining a controlled payroll lifecycle.

Payroll run fields should include:

- id
- payrollPeriodId
- status
- calculatedAt
- approvedAt
- finalizedAt
- approvedBy
- finalizedBy
- createdAt
- updatedAt
- version

---

# 21. PAYROLL ITEMS

Payroll should be composed of individual items.

Examples:

REGULAR_PAY
OVERTIME_PAY
ALLOWANCE
BONUS
DEDUCTION
OTHER

A payroll record should support:

- employee
- payroll run
- regular hours
- overtime hours
- regular pay
- overtime pay
- allowances
- bonuses
- deductions
- gross pay
- net pay
- currency

Do not hard-code a payroll calculation directly into a widget.

Create a dedicated payroll calculation/domain service.

---

# 22. OVERTIME

Support configurable overtime rules.

Example:

Normal:
KSh 500/hour

Overtime:
1.5 × normal rate

Overtime:
KSh 750/hour

The rules should eventually support:

- Daily overtime
- Weekly overtime
- Weekend overtime
- Holiday overtime

V1 can implement a simpler configurable overtime rule, but the domain model should not prevent future expansion.

---

# 23. BREAKS

Support breaks in the architecture.

For example:

08:00 clock in
13:00 break
14:00 break end
17:00 clock out

Payable time:

9 hours present
minus 1 hour break
==================

8 hours payable

V1 may use a configured automatic break deduction if manual break tracking is not implemented initially.

Do not make future manual break tracking impossible.

---

# 24. PAYROLL ADJUSTMENTS

Create support for:

- Allowances
- Bonuses
- Deductions
- Manual adjustments

Each adjustment should have:

- type
- amount
- description
- employee
- payroll period/run
- createdBy
- createdAt
- audit information

---

# 25. PAYROLL LOCKING

Finalized payroll must be protected.

Example:

October payroll:
FINALIZED

If someone attempts to change attendance affecting that payroll:

Display:

"Payroll has already been finalized. This change may affect a finalized payroll."

Require explicit administrative action to reopen/recalculate payroll.

Never silently modify finalized payroll.

---

# 26. BACKUP ARCHITECTURE

V1 should support local backup/restore where practical.

Backups should be designed for future cloud integration.

Do not build backup logic directly into UI screens.

Create a BackupService abstraction.

Conceptually:

BackupService
↓
Backup provider
↓
Encrypted backup artifact

Future:

Local Backup
Cloud Backup
Google Drive Backup
Other providers

The backup format should be versioned.

Example:

backupVersion:
1

This allows future versions of the application to migrate old backups.

---

# 27. FUTURE CLOUD SYNCHRONIZATION

Do NOT implement cloud synchronization in V1.

However, design entities with future synchronization in mind.

Potential metadata:

- id
- createdAt
- updatedAt
- deletedAt
- version
- deviceId
- sync status
- serverUpdatedAt later

Do not assume local timestamps alone are sufficient for conflict resolution.

Future synchronization architecture should be able to distinguish:

LOCAL_ONLY
PENDING_SYNC
SYNCED
CONFLICT
FAILED

Do not build the cloud backend now.

---

# 28. DEVICE IDENTITY

Introduce a device identity concept early.

A device should have a stable local identifier.

This will later allow synchronization and auditing to identify:

"Recorded on Tablet A"

versus:

"Recorded on Phone B"

The implementation must not expose unnecessary device information to users.

---

# 29. ATTENDANCE KIOSK MODE

The application should have two broad experiences.

## Administrator Mode

Dashboard
Employees
Attendance
Schedules
Payroll
Reports
Backup
Settings

## Attendance/Kiosk Mode

Large-screen interface:

"Enter your PIN"

After authentication:

"Good morning John"

"Clock In"

or:

"Clock Out"

Kiosk mode must not expose administrative functionality.

Provide an administrator-controlled way to exit/unlock kiosk mode.

This should work particularly well on tablets.

---

# 30. ATTENDANCE LOGIC

Implement robust rules.

Example:

Employee clocks in:

2026-10-05 08:02

Employee clocks out:

2026-10-05 17:04

Normal session.

---

If employee forgets to clock out:

Monday:
08:02 CLOCK_IN

Tuesday:
08:01 CLOCK_OUT

Do NOT automatically calculate:

23h 59m worked.

Instead:

1. Detect an overnight/duration anomaly.
2. Create an attendance exception.
3. Flag it for administrator review.
4. Allow correction.
5. Preserve the original event.
6. Recalculate the session after correction.

---

# 31. LATE ARRIVAL

Compare actual clock-in against the employee's effective schedule.

Example:

Expected:
08:00

Actual:
08:17

Create a late-arrival exception according to configurable tolerance.

Do not hard-code a zero-minute tolerance.

Allow configuration such as:

0 minutes
5 minutes
10 minutes
15 minutes

---

# 32. EARLY DEPARTURE

Compare clock-out with the expected schedule.

Example:

Expected:
17:00

Actual:
15:30

Create an exception according to configuration.

---

# 33. EXCESSIVE WORKING HOURS

Detect unusually long sessions.

Do not automatically classify every long session as invalid.

Flag it for review.

Example:

08:00 → 23:30

Potential excessive-hours exception.

---

# 34. DUPLICATE EVENTS

Detect suspicious sequences.

Example:

08:01 CLOCK_IN
08:02 CLOCK_IN

Flag the second event.

Similarly:

17:00 CLOCK_OUT
17:02 CLOCK_OUT

Do not silently discard data.

Preserve events and create exceptions.

---

# 35. PAYROLL CALCULATION PRINCIPLE

Use this conceptual flow:

Raw attendance events
↓
Sessions
↓
Exception detection
↓
Correction/review
↓
Approved/validated work time
↓
Payroll calculation

Payroll should never blindly calculate from unreviewed anomalous attendance.

---

# 36. PAYROLL CALCULATION EXAMPLE

Employee:

John Kamau

Rate:

KSh 500/hour

Payroll period:

01 Oct 2026 → 31 Oct 2026

Regular hours:

176.5

Overtime:

8

Overtime multiplier:

1.5

Regular pay:

# 176.5 × 500

KSh 88,250

Overtime rate:

# 500 × 1.5

KSh 750

Overtime pay:

# 8 × 750

KSh 6,000

Gross:

KSh 94,250

Then apply configured adjustments:

Allowances
Bonuses
Deductions

Finally:

Net Pay

The calculation must be deterministic and unit-testable.

---

# 37. PAYROLL OUTPUT

Support:

## Individual Payslip

Include:

- Company details
- Employee
- Employee number
- Payroll period
- Regular hours
- Overtime
- Rate
- Earnings
- Allowances
- Bonuses
- Deductions
- Gross pay
- Net pay
- Date generated
- Payroll status

## Payroll Summary

Include all employees.

## Attendance Report

Include:

- Employee
- Date
- Clock in
- Clock out
- Duration
- Exception status

## Exception Report

Include unresolved attendance issues.

---

# 38. PDF

PDF generation should be implemented through an abstraction.

Example:

PayrollDocumentService

Methods/concepts:

generatePayslip()
generatePayrollSummary()
generateAttendanceReport()
generateExceptionReport()

The UI should not contain PDF layout logic.

---

# 39. THERMAL PRINTING

Create a printer abstraction.

Example concept:

PrinterService

Capabilities:

- discover printers
- connect
- print
- disconnect
- check printer status

Initial implementation may target Bluetooth thermal printers.

Design so USB/network printing can be added later.

Payroll logic should not know which printer is being used.

---

# 40. RESPONSIVE UI

The UI must be designed for multiple screen sizes from the beginning.

Do NOT simply scale a phone UI.

Use adaptive layouts.

## Phone

Use:

- Bottom navigation where appropriate
- Compact cards
- Single-column layouts
- Navigation drawer if appropriate

## Tablet

Use:

- Navigation rail
- Side navigation
- Two-column layouts
- Wider tables
- Dashboard cards
- Split views where useful

## Large tablet

Use:

- Persistent navigation
- Multi-column dashboards
- Data tables
- More information density

Use Flutter's modern responsive/adaptive techniques.

Avoid hard-coded screen widths.

Avoid arbitrary pixel positioning.

---

# 41. UI DESIGN LANGUAGE

The UI should feel like a modern professional business application.

Visual principles:

- Clean
- Minimal
- Professional
- Accessible
- Consistent
- Clear hierarchy
- Appropriate whitespace
- Strong typography
- Consistent component system

Avoid:

- Excessive gradients
- Overly decorative animations
- Huge unnecessary cards
- Excessive rounded containers
- Cluttered dashboards
- Inconsistent spacing
- Random colors

Create a centralized theme.

Use Material 3 where appropriate.

Support:

- Light mode
- Dark mode

Make colors semantic.

Example:

Success
Warning
Error
Info
Neutral

Do not scatter hard-coded colors throughout the application.

---

# 42. ACCESSIBILITY

Consider:

- Adequate touch targets
- Text scaling
- Color contrast
- Semantic labels
- Keyboard navigation where applicable
- Screen reader compatibility where practical
- Clear error messages

Kiosk buttons should be particularly easy to press.

---

# 43. ERROR HANDLING

Do not expose raw exceptions to users.

Use structured application errors.

Example:

Database error:

DO NOT display:
"SqliteException: UNIQUE constraint failed..."

Instead:

"Unable to save the employee. Please try again."

Log technical details for debugging.

---

# 44. LOGGING

Create structured logging.

Use appropriate log levels:

DEBUG
INFO
WARNING
ERROR

Do not log:

- PINs
- passwords
- sensitive payroll data unnecessarily
- authentication secrets

Production logging should be configurable.

---

# 45. VALIDATION

Validate at multiple layers.

UI validation:

- Required fields
- Valid numbers
- Valid dates

Domain validation:

- Invalid payroll period
- Negative rates where not allowed
- Invalid schedule
- Invalid attendance transition

Database constraints:

- Foreign keys
- Unique employee number within company
- Appropriate indexes
- Not-null constraints

Never rely solely on UI validation.

---

# 46. DATABASE INDEXING

Create appropriate indexes.

At minimum consider indexes for:

employees.companyId
employees.employeeNumber
attendanceEvents.employeeId
attendanceEvents.occurredAt
attendanceEvents.employeeId + occurredAt
attendanceSessions.employeeId
attendanceSessions.startTime
attendanceExceptions.status
payrollPeriods.companyId
payrollPeriods.startDate
payrollRuns.payrollPeriodId
payrollItems.employeeId

Analyze query patterns before adding excessive indexes.

---

# 47. TRANSACTIONS

Use database transactions for operations that must be atomic.

Examples:

Clock-in:

1. Validate employee.
2. Validate current attendance state.
3. Create event.
4. Update/derive attendance state.
5. Create exception if required.
6. Commit.

Payroll finalization:

1. Validate payroll.
2. Verify unresolved exceptions according to policy.
3. Finalize payroll.
4. Record audit event.
5. Commit.

If any critical step fails, the transaction should roll back.

---

# 48. CLOCK-IN/CLOCK-OUT BUSINESS RULES

Implement a state machine rather than scattered if statements.

Example:

NO_OPEN_SESSION
↓ CLOCK_IN
OPEN_SESSION
↓ CLOCK_OUT
COMPLETED_SESSION

Invalid:

NO_OPEN_SESSION
↓ CLOCK_OUT

OPEN_SESSION
↓ CLOCK_IN

These should generate appropriate errors/exceptions.

Design the state machine so future break events can be incorporated.

---

# 49. TIMEZONE

Do not casually assume UTC or device-local time.

The company should have a configured timezone.

Attendance should be interpreted according to the company's configured timezone.

Store timestamps in a consistent representation and convert appropriately for display/calculation.

This becomes very important for future synchronization.

---

# 50. MONEY

Do not use floating-point doubles for financial calculations where precision matters.

Use an appropriate money representation.

For example:

Store monetary values in the smallest currency unit where practical, or use a decimal-safe representation.

The domain model must avoid floating-point rounding errors.

Payroll calculations must be deterministic.

---

# 51. TESTING STRATEGY

Testing is mandatory.

Implement:

## Unit tests

For:

- Payroll calculations
- Overtime
- Rate selection
- Schedule calculations
- Attendance state transitions
- Exception detection
- Payroll period calculations
- Money calculations

## Repository tests

For:

- Employee persistence
- Attendance persistence
- Payroll persistence
- Migrations

## Widget tests

For:

- Employee forms
- PIN screen
- Clock-in/out flow
- Payroll screens
- Exception resolution

## Integration tests

For critical workflows.

Example:

Create employee
→ set rate
→ clock in
→ clock out
→ create payroll
→ calculate
→ finalize
→ generate payslip

---

# 52. DEVELOPMENT QUALITY

Use:

- dart format
- dart analyze
- flutter test

Configure linting appropriately.

Do not ignore analyzer warnings just to make the build pass.

Avoid:

- unnecessary dynamic
- giant widgets
- duplicated business logic
- magic numbers
- magic strings
- global mutable state
- direct database access from widgets

---

# 53. DEPENDENCY MANAGEMENT

Before introducing a package:

1. Determine whether Flutter/Dart already provides the capability.
2. Determine whether the package is actively maintained.
3. Confirm compatibility with the current Flutter/Dart version.
4. Prefer mature packages.
5. Keep dependencies minimal.

Do not introduce a package merely because it makes a small task slightly easier.

---

# 54. PHASED IMPLEMENTATION

The entire project should be implemented in these phases.

## PHASE 0 — Project Foundation

Implement:

- Flutter project
- Folder architecture
- Dependencies
- Theme
- Routing
- Riverpod setup
- Error handling
- Logging
- Environment/configuration structure
- Basic responsive layout infrastructure
- CI-friendly project structure
- Linting

Deliverable:

A clean Flutter application that runs successfully.

---

# PHASE 1 — Database Foundation

Implement:

- Drift database
- Initial schema
- Database configuration
- Migrations
- UUID strategy
- Timestamps
- Company
- Admin user foundation
- Employee foundation
- Rate history
- Database repositories
- Seed/demo data only if appropriate

Write database tests.

Deliverable:

Application can create/read/update employees and persist data after restart.

---

# PHASE 2 — Authentication & Employee Management

Implement:

- Admin authentication
- Employee management
- Employee creation
- Employee editing
- Employee activation/deactivation
- Employee IDs
- PIN creation
- PIN hashing
- Employee PIN change
- Admin PIN reset
- Basic security protections

Deliverable:

Admin can manage employees securely.

---

# PHASE 3 — Attendance Engine

Implement the core attendance engine before building a complex UI.

Implement:

- Attendance events
- Clock-in
- Clock-out
- Attendance state machine
- Attendance sessions
- Local timestamps
- Timezone handling
- Duplicate detection
- Invalid transition detection
- Attendance repositories
- Attendance service

Write extensive unit tests.

Deliverable:

A reliable attendance domain engine.

---

# PHASE 4 — Attendance UI & Kiosk Mode

Implement:

- Employee PIN screen
- Clock-in/out screen
- Employee confirmation
- Current attendance status
- Admin attendance dashboard
- Daily attendance
- Employee attendance history
- Kiosk mode
- Responsive tablet layout
- Responsive phone layout

Deliverable:

Employees can actually use the app to clock in/out.

---

# PHASE 5 — Attendance Exceptions & Corrections

Implement:

- Missing clock-out detection
- Overnight detection
- Excessive-hours detection
- Late arrival
- Early departure
- Duplicate events
- Exception dashboard
- Exception details
- Correction workflow
- Audit trail
- Resolution reasons

Deliverable:

The application can identify and safely resolve attendance problems.

---

# PHASE 6 — Work Schedules

Implement:

- Work schedules
- Schedule days
- Start/end times
- Break configuration
- Employee schedule assignment
- Effective dates
- Schedule comparison
- Late/early calculations

Deliverable:

Attendance can be evaluated against actual employee schedules.

---

# PHASE 7 — Payroll Engine

Implement the payroll domain independently from the UI.

Implement:

- Payroll periods
- Payroll runs
- Rate selection
- Regular hours
- Overtime
- Overtime rules
- Allowances
- Bonuses
- Deductions
- Gross pay
- Net pay
- Payroll calculations
- Money precision
- Payroll validation

Write extensive unit tests.

Deliverable:

A deterministic payroll calculation engine.

---

# PHASE 8 — Payroll UI

Implement:

- Payroll period creation
- Payroll dashboard
- Payroll calculation
- Employee payroll details
- Payroll review
- Payroll adjustments
- Payroll approval
- Payroll finalization
- Payroll locking
- Reopen workflow
- Audit history

Deliverable:

Administrator can run a complete payroll cycle.

---

# PHASE 9 — Reports & PDF

Implement:

- Employee payslip
- Payroll summary
- Attendance report
- Timesheet
- Exception report
- PDF generation
- PDF preview
- Share/export functionality

Deliverable:

Professional printable documents.

---

# PHASE 10 — Thermal Printing

Implement:

- Printer abstraction
- Bluetooth printer support
- Printer discovery
- Pair/connect workflow
- Test print
- Payroll receipt
- Payslip receipt
- Printer settings

Deliverable:

Administrator can print payroll documents using supported thermal printers.

---

# PHASE 11 — Backup & Restore

Implement:

- Backup service
- Local backup
- Backup versioning
- Encryption where appropriate
- Restore
- Backup validation
- Backup history
- Backup settings
- Safe restore workflow

Deliverable:

Users can protect and restore their local payroll database.

---

# PHASE 12 — Hardening & Production Readiness

Implement:

- Security review
- Database migration review
- Performance review
- Error handling review
- Accessibility review
- Responsive UI review
- Offline behavior review
- Backup/restore testing
- Payroll calculation tests
- Integration tests
- Build configuration
- Release configuration
- Documentation

Deliverable:

Production-ready V1 candidate.

---

# PHASE 13 — FUTURE CLOUD ARCHITECTURE

Do NOT implement the cloud backend unless explicitly requested later.

At this stage document the architecture for:

- Authentication
- Cloud backup
- Synchronization
- Device registration
- Conflict resolution
- Server timestamps
- Sync queues
- Retry policies
- Offline mutations
- Multiple devices
- Cloud database

The existing local architecture must make this possible without rewriting the domain layer.

---

# 55. FUTURE FEATURES

Do not implement these in V1 unless explicitly requested:

- Full cloud synchronization
- Multiple companies per cloud account
- Employee self-service portal
- Leave management
- Public holiday management
- Loans
- Salary advances
- Government statutory deductions
- Tax calculation
- Bank payment integration
- Accounting integration
- Odoo integration
- Biometric attendance
- GPS/geofencing
- Face recognition

However, avoid architectural decisions that make these impossible later.

---

# 56. SECURITY PRINCIPLES

Treat payroll information as sensitive.

Important principles:

- Never store PINs in plain text.
- Never log PINs.
- Do not expose payroll information unnecessarily.
- Use secure local storage where appropriate.
- Validate authorization at the business/application layer.
- Do not rely solely on hidden UI elements for security.
- Use audit logging for sensitive operations.
- Protect finalized payroll.
- Validate backup integrity.
- Avoid leaking sensitive information in exceptions/logs.

---

# 57. UX PRINCIPLES

The application should make the most common operations extremely fast.

For an employee:

Open app
→ Enter PIN
→ Clock in/out
→ Receive confirmation

This should require minimal interaction.

For an administrator:

Dashboard
→ Identify exceptions
→ Resolve them
→ Run payroll
→ Review
→ Finalize
→ Print/export

The UI should make these workflows obvious.

---

# 58. DASHBOARD

Create a professional administrator dashboard.

Potential cards:

Today's attendance:
24 employees

Present:
21

Late:
2

Missing clock-out:
1

Currently working:
18

Current payroll:
October 2026

Payroll status:
REVIEW

Recent exceptions:

John — Missing clock-out
Mary — Late arrival

The dashboard should be responsive.

On phones, cards can stack.

On tablets, use grids/columns.

---

# 59. EMPTY STATES

Every major screen should have a meaningful empty state.

Example:

No employees:

"No employees yet."

[ Add Employee ]

No exceptions:

"Everything looks good."

No payroll:

"No payroll periods have been created."

Do not leave screens blank.

---

# 60. LOADING STATES

Use appropriate:

- Loading indicators
- Skeletons where useful
- Disabled actions during operations

Avoid freezing the UI during database/report generation.

---

# 61. CONFIRMATION AND DESTRUCTIVE ACTIONS

Actions such as:

- Archive employee
- Reset PIN
- Delete backup
- Restore backup
- Reopen payroll
- Finalize payroll

should have appropriate confirmation.

For highly destructive actions, explain the consequence.

---

# 62. DATABASE MIGRATION POLICY

Every schema change must create a migration.

Never instruct the developer to simply delete the local database to resolve a migration issue.

During development, migration scripts should be tested.

Document migration versions.

Future users must be able to upgrade without losing attendance/payroll data.

---

# 63. CODE GENERATION POLICY

When generating code:

- Generate complete files when appropriate.
- Do not provide pseudo-code where actual implementation is expected.
- Do not leave unexplained TODOs in production paths.
- Do not create placeholder methods that silently return fake values.
- If something is intentionally deferred to a later phase, explicitly mark the architectural boundary.
- Keep classes focused.
- Keep widgets reasonably small.
- Extract reusable components.
- Use dependency injection.
- Use repositories/interfaces between domain and data layers.
- Prefer composition over inheritance where appropriate.

---

# 64. IMPORTANT: DO NOT OVERENGINEER

Use good architecture, but do not create unnecessary abstractions.

A class/interface should exist because it solves a real architectural problem.

Avoid:

- 10 layers for a simple boolean
- unnecessary generic frameworks
- excessive design patterns
- unnecessary micro-services
- unnecessary state management complexity

The goal is:

Professional
Maintainable
Testable
Extensible

not:

"as many abstractions as possible."

---

# 65. PHASE EXECUTION RULE

We will work one phase at a time.

When I ask you to implement a phase:

1. Review the current project state.
2. Explain what will be added.
3. Identify affected architectural layers.
4. Implement the phase.
5. Add tests.
6. Run/analyze the project where possible.
7. Identify any migration implications.
8. Summarize files changed.
9. Explain how I can test the result manually.
10. Stop at the end of the phase.

Do not automatically jump to the next phase.

---

# 66. FIRST TASK

Do NOT immediately implement the entire application.

Start with:

PHASE 0 — PROJECT FOUNDATION

Before writing code:

1. Confirm the proposed architecture.
2. Confirm the package choices against the current Flutter ecosystem.
3. Propose the initial folder structure.
4. Propose the initial dependency list and explain why each dependency is needed.
5. Propose the initial database architecture at a high level.
6. Explain how future synchronization will fit into the architecture.
7. Explain the responsive UI strategy.
8. Explain the testing strategy.

Then implement Phase 0 only.

The project must compile and run before moving to Phase 1.

---

# 67. ENGINEERING MINDSET

Treat every decision as if this application could eventually be used by real businesses with hundreds of employees and years of payroll history.

At the same time, keep V1 practical and focused.

Prioritize:

Correctness
Data integrity
Security
Auditability
Offline reliability
Maintainability
Responsive UX
Testability
Future extensibility

Do not sacrifice database integrity or payroll correctness for UI convenience.

The application should be designed so that a payroll calculation can be independently explained and audited.

The final product should feel like a professional business application, not a student CRUD project.

Begin with PHASE 0.
