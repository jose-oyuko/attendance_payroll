# Security review

Payroll and attendance data are sensitive. This is the Phase 12 review: what
is protected, how, what is deliberately not protected, and which tests keep
each promise true. It is meant to be read by someone deciding whether the app
is safe enough for their business.

## What is being protected

| Asset | Where it lives |
|---|---|
| Employee, attendance and payroll data | SQLite database in the app's private storage |
| Administrator passwords, employee PINs | Only as salted PBKDF2 hashes in the database |
| Backup password | Android Keystore (secure storage) |
| Backups | Encrypted files, in the app's private folder or wherever the administrator exports them |

## Who might attack, and what stops them

| Threat | Protection |
|---|---|
| A colleague uses the unlocked app while the administrator is away | Automatic sign-out after 15 minutes without a touch, and after 15 minutes in the background (`SessionTimeoutGuard`). The kiosk is separate and exposes no administrative function |
| Someone guesses a password or PIN | PBKDF2-HMAC-SHA256 hashes; lockout after 5 wrong attempts, doubling up to an hour, enforced in the domain layer, for administrators and employees alike. A locked credential is not even checked |
| Someone takes over an unattended signed-in account | Changing the password asks for the current one and shares the lockout; the change is audited |
| An employee tries to read others' data or reach admin screens | Every service checks the session's permission itself (`Permission`); hiding UI is never the protection. The kiosk has its own service that only accepts that company's employees |
| Someone changes finalized payroll | Locked at the business layer: attendance corrections, rate changes and recalculation affecting a finalized period are refused until it is explicitly reopened with a reason, and every step is audited |
| Someone reads the phone's recent-apps screen or screenshots | Release builds mark the window secure (`FLAG_SECURE`): blacked out in recents, no screenshots or screen recording |
| Android copies the database to a Google account | `allowBackup="false"`. The app's own encrypted backups are the only copy mechanism |
| The app is made to talk to a server | The `INTERNET` permission is removed from the manifest, clear-text traffic is forbidden, and a test fails if network code appears in the source |
| A stolen or lost backup file | AES-256 encrypted with a key derived from the backup password (PBKDF2, 150,000 iterations); the file is authenticated (HMAC-SHA256, checked in constant time before decrypting), so tampering is detected, not just hidden |
| A malicious backup file is imported | Validated before anything changes: format and version, integrity check of the database, schema version, foreign keys; restored in one transaction that rolls back on any failure. A backup of another company needs an explicit confirmation |
| SQL injection | Drift builds queries with bound parameters. The few hand-written statements are constants; the only interpolation is of table names taken from the schema itself, and a test fails if SQL is built from text anywhere else |
| Secrets in logs | Logging redacts by field name (`Redactor`); nothing prints to the console (tested); technical detail never reaches the user |
| Path tricks in backup file names | Names are validated against a strict pattern in the service and again in the storage |
| Predictable "random" numbers for secrets | Temporary PINs, salts and nonces use `Random.secure()` (tested: no unseeded `Random()` in the app) |

## Authentication details

- Administrator passwords: 8 to 128 characters, no composition rules (current
  NIST guidance). PBKDF2-HMAC-SHA256 with 100,000 iterations and a random
  salt; the work factor is stored with each hash, so it can be raised later
  without invalidating old ones.
- Employee PINs: 4 to 6 digits (see `PinPolicy`), hashed separately from
  administrator passwords (PBKDF2-HMAC-SHA256, 20,000 iterations, so the
  kiosk stays quick), with their own lockout. Administrators can reset a PIN but never read it;
  a reset PIN is temporary and must be changed at first use.
- Wrong username and wrong password give the same message, and a missing
  account is hashed against a dummy so timing does not reveal which usernames
  exist.

## Known limits (decisions, not oversights)

1. **The database is not encrypted at rest.** The data is in the app's private
   storage, which Android protects with file-based encryption tied to the
   device lock, and which other apps cannot read. A rooted phone, or a device
   without a screen lock, can expose it. Encrypting the database itself
   (SQLCipher) was weighed and left for a later version because it needs a
   key that must itself be kept somewhere, and because encrypted *backups*
   already protect everything that leaves the device. Use a device lock.
2. **No password recovery.** There is no server and no e-mail. A forgotten
   administrator password is recoverable only by restoring a backup made
   before it was changed (which restores the old password), or reinstalling.
   Keep a backup and write the owner password down somewhere safe.
3. **The backup password cannot be recovered**, by design. The Backup screen
   says so before it is set.
4. **One role.** V1 has a single all-powerful `owner` role. The permission
   model is in place for finer roles (payroll administrator, supervisor,
   auditor) without changing the services.
5. **Attendance trusts the device clock.** Someone who can change the
   device's time can record events at the wrong time. The recorded-at
   instant is stored beside the event time, corrections are audited, and
   events are append-only, so it is visible afterwards; it is not prevented.
6. **A 4-digit PIN is guessable** by someone who can try 5 times, wait a
   minute, and repeat. The lockout makes this slow (hours for a meaningful
   share of the 10,000 possibilities) and every lockout is audited, but a
   longer PIN is safer. Sensitive workplaces should use 6 digits.
7. **No remote wipe or remote lock** (no server).

## How the promises are checked

| Promise | Test |
|---|---|
| Password change rules, lockout, audit | `test/features/authentication/domain/admin_auth_service_test.dart` |
| Sessions expire | `test/features/authentication/presentation/session_security_test.dart` |
| No network code, no printing, no unseeded randomness, no SQL from text, manifest settings, signing keys not committable | `test/security/source_hygiene_test.dart` |
| Release APK has no `INTERNET` and no Auto Backup | CI job `android` (`.github/workflows/ci.yml`) |
| Backup tamper detection, wrong password, old formats | `test/features/backup/data/apbackup_codec_test.dart` |
| Restore is all-or-nothing | `test/features/backup/data/drift_backup_database_test.dart` |
| Finalized payroll is never rewritten | `test/integration/payroll_cycle_test.dart` |
| Every service refuses a session without permission | the `every operation checks the session` tests of each service |

## Reporting a problem

This is a private application; report findings to the owner of the codebase.
