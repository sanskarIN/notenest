# NoteNest Troubleshooting

Use this guide for common development/setup problems. Do not delete a real user's database or signing configuration as a first response to a build error.

## `flutter` is not recognized / command not found

Check whether the Flutter SDK `bin` directory is on `PATH`:

```bash
flutter --version
```

If the command is not found, fix `PATH`, restart the terminal/editor, and try again. Do not install a random package named Flutter from an unrelated package source.

## `dart` is not recognized

Dart ships with Flutter. If `flutter` works but `dart` does not, inspect your Flutter installation/path configuration:

```bash
flutter --version
dart --version
```

Reopen the terminal after PATH changes.

## `flutter doctor` reports missing platform tooling

Run:

```bash
flutter doctor -v
```

Only the toolchains for targets you intend to build must be resolved immediately. Examples:

- Android: Android SDK/JDK/licenses.
- Windows: Visual Studio C++ desktop workload.
- Linux: compiler/CMake/Ninja/GTK development packages.
- macOS/iOS: Xcode and related tooling.

Use current Flutter platform setup documentation because native dependency versions can change independently of NoteNest.

## Python bootstrap fails with “Flutter is required”

`tool/bootstrap_platforms.py` calls the `flutter` executable. Make sure Flutter works in the same terminal:

```bash
flutter --version
python tool/bootstrap_platforms.py
```

On Windows try:

```powershell
py tool/bootstrap_platforms.py
```

## Bootstrap reports expected Android/iOS file missing

This usually means the Flutter project generator changed its template path/format or platform generation failed.

1. Read the Flutter command output above the Python exception.
2. Check `flutter doctor -v`.
3. Run `flutter create --help` and verify the installed version supports requested platforms.
4. Do not simply remove the patch from the script if it is still required by `local_auth`.
5. Update the script/documentation in a dedicated compatibility commit once the new template is understood.

## `flutter pub get` fails

Collect:

```bash
flutter --version
dart --version
flutter pub get
```

Common causes:

- Flutter/Dart is below the minimum in `pubspec.yaml`.
- A package constraint is incompatible with the current SDK.
- Network/package registry is temporarily unavailable.
- A dependency update introduced an incompatible transitive constraint.

Do not resolve a solver error by deleting type-safety constraints or blindly changing every package to `any`.

## Drift generated class/types are missing

Symptoms include missing `_$AppDatabase`, `$NotesTable`, or `NotesCompanion`-related generated symbols.

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Then:

```bash
flutter analyze
```

Generated `*.g.dart` files are intentionally not committed.

## build_runner reports conflicting outputs

Regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If the conflict remains after a dependency/SDK upgrade:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Do not manually edit generated `app_database.g.dart`.

## Analyzer errors after Flutter upgrade

1. Regenerate platform files/code.
2. Run formatter/analyzer.
3. Read the specific deprecated/removed API migration guidance.
4. Update source in focused commits.
5. Re-run tests and native builds.

Do not disable strict analysis globally to make upgrade errors disappear.

## FTS search returns unexpected results

First verify normal note creation/listing works. In a development/test database, check:

- The note row exists.
- FTS infrastructure was created.
- Search query is non-empty.
- Collection filters are not excluding the result (archive/trash/favorites).

The initial database creates FTS triggers/index on `onCreate`. Future migrations that change indexed columns must also update FTS infrastructure.

For a reproducible defect, use an in-memory database test with fictional data instead of sending a real user database.

## Search with punctuation throws an error

Search input should be normalized and supplied as a bound FTS variable. If an input can break FTS syntax, add the exact fictional input as a regression test and fix `_ftsQuery`/search handling rather than sanitizing by deleting arbitrary user content.

## Note does not appear in All Notes

Check whether it is:

- Archived.
- In trash.
- Excluded by folder/tag filter.
- Excluded by current search query.

`All notes` intentionally excludes archive and trash.

## An edited note did not create a version

A snapshot is created when `NoteRepository.saveContent` detects changed title/body/folder/tags/color. An unchanged autosave should not create redundant snapshots.

Pin/favorite/archive/trash flag operations are not currently part of content snapshot creation.

## Backup restore is rejected

NoteNest rejects malformed/unrecognized backups deliberately. Check that the file:

- Is valid UTF-8 JSON.
- Has root object field `"app": "NoteNest"`.
- Uses a supported backup `schemaVersion`.
- Contains `notes` and `versions` lists with required typed fields.
- Contains valid timestamp strings.

Do not hand-edit a personal backup unless you have another untouched copy. For testing, create a fictional export.

## Restore says it kept newer local notes

This is expected conflict-safe behavior. If the current device's `updatedAt` is later than the incoming backup note's timestamp, the local note is not overwritten.

If users later need a conflict UI instead of timestamp-based preservation, that should be implemented as a deliberate new feature with tests/backup semantics.

## File picker returns no data

Platform file-picker behavior varies. Confirm:

- The selected file is accessible to the app.
- The picker operation was not cancelled.
- The target plugin/platform is supported by the installed package version.
- Platform runner generation and native build succeeded.

If `PlatformFile.bytes` is unexpectedly null despite `withData: true`, capture platform/package versions with a fictional file and file a reproducible issue.

## App lock cannot be enabled

NoteNest checks whether device authentication is supported. Common reasons include:

- No device authentication configured.
- Target platform/plugin capability unavailable.
- Native runner configuration missing.
- Android activity not using the required fragment activity setup for the plugin version.
- iOS Face ID usage description missing for Face ID use.

Regenerate native runners with:

```bash
python tool/bootstrap_platforms.py
```

Then rebuild. App lock should fail closed/safely rather than pretending authentication succeeded.

## App lock is not database encryption

This is not a bug. Current app lock gates UI access through operating-system authentication. The SQLite database is not independently encrypted by NoteNest. See `SECURITY.md` and `PRIVACY.md`.

## About links do not open

External links use `url_launcher`. Verify the device has an application able to handle the selected `https:` or `mailto:` URI and that native plugin registration/build succeeded.

A failed external link should not affect local note data.

## Android `local_auth` build/runtime problems

Regenerate runners:

```bash
python tool/bootstrap_platforms.py
```

The NoteNest bootstrap patches the Android activity to use `FlutterFragmentActivity` and sets the project Android minimum SDK baseline. Review generated Android configuration after Flutter/plugin upgrades.

## Windows build says Visual Studio is missing

Flutter Windows desktop requires native Visual Studio build tools/workload; VS Code is not a substitute.

Install/modify Visual Studio with the **Desktop development with C++** workload and Windows SDK components recommended by `flutter doctor -v`.

## Linux build cannot find GTK/CMake/Ninja/pkg-config

Install the current Flutter Linux desktop native prerequisites for your Linux distribution. Package names differ across distributions/releases. After installing, rerun:

```bash
flutter doctor -v
flutter build linux --release
```

## macOS/iOS CocoaPods errors

Native plugins may require CocoaPods. Follow `flutter doctor -v` guidance, repair/install CocoaPods, then regenerate/install dependencies as required by Flutter.

Do not commit `Pods/` simply to hide a local CocoaPods installation problem.

## iOS signing failure

`flutter build ios --release --no-codesign` can validate compilation without a distribution identity. Installing/publishing requires valid Apple signing/provisioning owned by the developer/distributor.

Signing identities cannot be created or safely stored by NoteNest source code.

## Tests fail only on time/date assertions

Store domain timestamps in UTC and convert at display boundaries. In tests, prefer explicit fixed UTC timestamps where ordering/calendar logic is being asserted. Do not rely on the machine's local timezone accidentally.

## CI format failure

Apply formatter locally:

```bash
dart format lib test
```

Then verify:

```bash
dart format --output=none --set-exit-if-changed lib test
```

Commit only the intentional formatting diff.

## Repository policy check fails

Run:

```bash
python tool/check_repo.py
```

The output lists missing required files or unfinished source markers. This script protects the project's documentation/handoff baseline; update it if the repository's deliberate structure changes.

## Secret scan fails

`tool/security_scan.py` reports path, line, and rule without echoing the matched credential value.

If the match is a real secret:

1. Revoke/rotate it immediately.
2. Remove it from the current tree.
3. Assess/remove history exposure as appropriate.
4. Do not simply add the secret to an allowlist.

If it is a false positive from a clearly fictional test fixture, adjust the fixture or narrowly improve the scanner rule without weakening protection for real tokens.

## `what_changed.md` appears stale

That file is the cross-chat/session handoff. Update it after a meaningful phase with:

- Completed work.
- Verification commands/results.
- Known limitations.
- Exact next tasks.
- Recent commit hashes/messages.

Do not use it as marketing copy; it should remain an engineering record.

## Still blocked?

Read [SUPPORT.md](../SUPPORT.md) and open a bug/support request with the smallest reproducible fictional case. For security issues, follow [SECURITY.md](../SECURITY.md) instead of posting details publicly.
