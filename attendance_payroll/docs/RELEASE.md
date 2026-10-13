# Releasing

How to build, sign, check and ship the Android app, and what to do before you
do. Nothing here needs a server: the app is offline.

## Decide before the first release

These cannot be changed later without consequences, so decide them once.

1. **The application id** is `com.example.attendance_payroll` in
   `android/app/build.gradle.kts` (`namespace` and `applicationId`) and in
   `android/app/src/main/kotlin/.../MainActivity.kt`'s package. It is the
   identity of the app on a phone and in the Play Store. **Changing it later
   makes Android treat the new build as a different app: an update would
   install beside the old one, not replace it, and the old data would not
   carry over** (a backup/restore would). Choose your own (for example
   `ke.co.yourcompany.attendancepayroll`) before anyone installs the app.
2. **The signing key** (below). If it is lost, the app can never be updated
   under the same identity. Keep two copies, offline, away from the repository.
3. **The version** (below).

## Versioning

The version lives in `pubspec.yaml` as `version: 1.0.0+1`:

- `1.0.0` is the version people see (`versionName`).
- `+1` is the build number Android uses to decide what is newer
  (`versionCode`). It must go up with every build you hand to anyone.

`AppConstants.appVersion` (`lib/core/constants/app_constants.dart`) must equal
the part before the `+`: it is written into every backup. A test fails if they
differ.

Raise the build number for every release. Raise the version for changes people
should notice. If the database schema changes, follow
[DATABASE.md](DATABASE.md) (a migration, its tests, the snapshot) *in the same
change*: an update must never need the data deleted.

## Signing

Create the key once (on a trusted computer; keep the file and its passwords):

```
keytool -genkey -v -keystore attendance-payroll.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Then copy `android/key.properties.example` to `android/key.properties` and fill
it in (the file and `*.jks` are git-ignored; a test checks that they stay so).
Without `key.properties` the release build still works but is signed with the
debug key and prints a warning: that build is for checking only and must not be
given to anyone.

## Building

```
flutter pub get
flutter build apk --release --split-per-abi     # one smaller APK per phone type
flutter build appbundle --release               # for the Play Store
```

`--split-per-abi` matters: one universal APK is about 70 MB, because it carries
the native code for every phone type; the per-type APKs are about a third of
that. Most current phones want `app-arm64-v8a-release.apk`.

## Before you hand it over

Run, in this order, and do not release if any step fails:

1. `dart format --output=none --set-exit-if-changed .`
2. `flutter analyze`
3. `flutter test` — runs about 700 tests, including the migration tests (every
   path from schema 1 to the latest), the large-company performance guards,
   the accessibility and text-size sweep, the security checks and the
   end-to-end payroll workflow. CI runs the same on every push.
4. Build the release APK and check it:
   ```
   aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
   ```
   There must be **no `INTERNET`** (only the Bluetooth permissions). CI does
   this check too.
5. Install the release APK on a **real Android phone or tablet** and do the
   checklist below. The emulator has no Bluetooth, and a few things cannot be
   proven by tests.

### Device checklist

On a physical device, with a Bluetooth receipt printer paired:

- [ ] First start: set up a company; press Settings → Lock app; the kiosk
      shows; unlock it with the administrator password. Close and reopen the
      app: it starts locked, on the kiosk.
- [ ] Add an employee with a rate; give them a PIN; start the kiosk; clock in
      and out as the employee; leave the kiosk with the administrator password.
- [ ] Open Payroll: create a period, calculate, approve, finalize.
- [ ] Reports: preview a payslip PDF; share it.
- [ ] Settings → Printer: pick the printer; print the test page (does the ruler
      fit the paper?); print a payslip and the payroll summary.
- [ ] Backup: back up with no password (the default); export the file
      through the share sheet; add a backup password and back up again;
      change something; restore a backup; unlock the app again.
- [ ] On a second phone (or after a reinstall): "Restore from a backup instead"
      on the setup screen, with the exported file (it asks for a password only
      if that backup has one).
- [ ] Settings → App lock: choose 1 minute; leave the app alone for a
      minute: it locks and shows the kiosk, and an employee can still clock
      in; the administrator unlocks it and sees why it locked. Put it back
      to a sensible time.
- [ ] The recent-apps screen shows a blank card and screenshots are blocked.
- [ ] Rotate the phone; try the largest text size in the phone's settings.
- [ ] Turn Wi-Fi and mobile data off for the whole checklist: nothing may need
      them.

## Updating an installed app

An update is installing a newer build with the same application id and signing
key over the old one. The app opens the existing database and migrates it to
the new schema on first start. Before a release that changes the schema, take
a backup on a test phone with the *previous* version, install the new one over
it, and check the data is intact.

If an update must be undone, install the previous build **only if the schema
did not change**: Android refuses to downgrade the version, and an older app
cannot read a newer database (it says so rather than guessing). The safe
rollback is to restore the backup the app made (or the administrator took)
before the update.

## Backups across versions

Backup files carry their own format version and the schema version of the data.
A newer app restores older backups (it migrates them first); an older app
refuses a newer backup with a message to update. The first backups of the app
used a slower cipher (AES-GCM); they are still readable.

## Continuous integration

`.github/workflows/ci.yml` runs on every push: format, analyze, all tests; then
builds the release APK and fails if it requests the network or allows Android
backup. CI-built APKs are debug-signed and are not for distribution.
