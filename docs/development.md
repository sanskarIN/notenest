# NoteNest Development Guide

Current release candidate: **2.0.12** (`2.0.12+2012`).

NoteNest is developed as one Flutter application targeting **Android, iOS/iPadOS, Windows, macOS, Linux, and Web**. Platform-sensitive behavior belongs behind explicit services, conditional imports, or the reproducible platform bootstrap rather than being scattered through feature widgets.

## Daily workflow

Use the committed dependency graph for ordinary work:

```bash
python tool/check_version_sync.py
flutter pub get --enforce-lockfile
dart run build_runner build
dart format lib test
flutter analyze
flutter test
```

For browser/platform-sensitive work also run:

```bash
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Run a target:

```bash
flutter devices
flutter run -d <device-id>
```

## Repository layout

```text
assets/branding/               Project artwork
docs/                          Engineering/product/release docs
lib/app/                       Composition root and app-wide state
lib/core/                      Constants, errors, logging, theme, utilities
lib/data/database/             Drift schema/database/FTS + Web configuration
lib/data/repositories/         Persistence/invariant boundaries
lib/domain/                    UI-independent models
lib/features/                  Feature presentation/controllers
lib/services/                  File/auth/link platform boundaries
lib/widgets/                   Reusable controls
test/app/                      Application controller tests
test/core/                     Pure/native-boundary regressions
test/data/                     Repository/database/settings tests
test/features/                 Feature-controller tests
test/services/                 Service tests
test/web/                      Chrome/Web platform-boundary tests
test/widgets/                  Widget/accessibility tests
tool/                          Bootstrap/repository quality tooling
.github/                       Workflows/templates/automation
```

Every tracked path is documented exactly once in [`repository-reference.md`](repository-reference.md). The current contract contains **109 tracked files**, including the application `pubspec.lock`.

## Dependency direction

```text
widgets/features
      ↓
controllers
      ↓
repositories/services
      ↓
database/plugins/platform implementations
```

Do not leak database or plugin implementation details across feature widgets.

## Reproducible dependency rule

`pubspec.lock` is application source-of-truth for the resolved graph. Normal development, CI, platform builds, and release packaging use:

```bash
flutter pub get --enforce-lockfile
```

Only deliberate dependency maintenance should run an unlocked resolver:

```bash
flutter pub get
```

When doing so:

1. Use Flutter **3.44.7**.
2. Review the direct manifest change.
3. Review every relevant lockfile version/hash change.
4. Never hand-author hosted-package hashes.
5. Re-run analyzer/tests/security/dependency review.
6. Rebuild every affected target.
7. Update platform minimum-version/tooling documentation when a plugin changes those requirements.

The current graph includes `file_picker 12.0.0`, which introduced the explicit iOS 14 floor and federated platform packages.

## Cross-platform design rule

Before adding platform-sensitive behavior ask:

1. Does the shared API compile on Web?
2. Does the plugin actually implement all six targets?
3. What should unsupported targets do?
4. Does the implementation import `dart:io` or another native-only library?
5. Can platform selection be isolated behind conditional imports/exports?
6. Can the unsupported path remain useful rather than failing startup?
7. What native permissions, minimum versions, or build-tool requirements change?
8. What browser-hosting/storage behavior changes?
9. How will it be tested on representative native and browser targets?
10. Does it change privacy/security/release documentation?

Unsupported capability must be explicit and safe. Do not fake parity with a weaker home-grown security mechanism.

## Platform bootstrap as source of truth

Run:

```bash
python tool/bootstrap_platforms.py
```

The generated runner directories are deliberately untracked. The source of truth is the pinned Flutter SDK plus bootstrap policy.

The bootstrap currently enforces:

### Android

- `FlutterFragmentActivity`.
- Biometric permission.
- Minimum SDK 24.
- AppCompat dependency/theme requirements.

### iOS / iPadOS

- Face ID usage text.
- Deployment target **iOS 14.0+**.

### Windows

- Batch-file execution compatible with Python on Windows.
- MSVC compatibility definition required by the current `local_auth_windows` implementation on modern Visual Studio toolchains.

### Web

- Drift 2.34.3 `sqlite3.wasm`.
- Matching `drift_worker.js`.
- Basic asset payload checks.
- Failure when the direct Drift pin and bootstrap runtime pair disagree.

Do not manually patch a generated runner and treat it as durable source. Update `tool/bootstrap_platforms.py` and its verification instead.

## Adding a note feature

Decide before coding:

- persisted note data vs preference vs transient UI state;
- database schema/migration impact;
- backup compatibility;
- FTS/filter behavior;
- native/browser differences;
- privacy/permission/security impact;
- keyboard/touch/screen-reader behavior;
- compact/wide layout behavior;
- smallest deterministic regression layer;
- release/documentation impact.

## Database development

Application version **2.0.12** and Drift schema **1** are independent version domains.

A future schema migration must:

- increment `schemaVersion` deliberately;
- implement deterministic migration logic;
- test representative fictional previous-schema data;
- review backup compatibility;
- review FTS table/trigger migration or rebuild behavior;
- verify native SQLite and Drift Web SQLite behavior.

Do not assume a passing `NativeDatabase.memory()` test proves browser runtime behavior.

## Web database runtime

`AppDatabase` supplies Web locations for `sqlite3.wasm` and `drift_worker.js`. `tool/bootstrap_platforms.py` ties those assets to direct dependency Drift **2.34.3**.

When changing Drift:

1. Review Drift release/migration notes.
2. Update `pubspec.yaml` deliberately.
3. Update/review the bootstrap Web version pair.
4. Resolve and review `pubspec.lock`.
5. Regenerate Web assets.
6. Run database/unit regressions.
7. Run Chrome platform smoke.
8. Run Web release build.
9. Deploy/test a representative origin.
10. Update architecture/testing/release documentation.

Never quietly mix a worker/WASM pair from another Drift release.

## Repository boundaries

Repositories own persistence invariants. Prefer intention-specific methods (`archive`, `trash`, `restore`, `setPinned`) over arbitrary column mutation from UI code. Use a transaction when several writes form one logical operation.

- `NoteRepository` owns note lifecycle, snapshots, search/filter metadata, and the no-pinned-trash invariant.
- `BackupRepository` owns portable interchange validation and conflict-safe restore.
- `SettingsRepository` owns durable preference access.

## Controllers

Controllers own feature/application state, not platform APIs.

Rules:

- Dispose listeners and timers.
- Guard async completions after disposal.
- Protect newer state from stale asynchronous requests.
- Serialize order-sensitive writes.
- Debounce high-frequency submissions where useful.
- Keep unrelated settings/features out of a controller.
- Propagate actionable failure state instead of pretending persistence succeeded.

## Editor and autosave

The editor stores raw text plus note metadata rather than a rich-document graph.

`Debouncer` reduces high-frequency submissions; `AsyncSerialQueue` guarantees submitted writes execute in order. Each save captures an immutable draft. A completion may mark the UI saved only if that draft is still current.

Normal Back waits for the current-draft save. Export/history also requires a successful current-draft save. Preserve those ordering guarantees when changing navigation or autosave logic.

Current-line prefix actions must retain the offset-zero empty-first-line regression coverage.

## Settings and onboarding

Preferences remain behind `SettingsStore` → `SettingsRepository` → `AppSettingsController`.

- Never store credentials, biometric material, or note bodies there.
- Treat setter failure as real persistence failure.
- Serialize order-sensitive writes.
- Roll back failed optimistic state where appropriate.
- Keep stale failures from overwriting newer state.
- Persist onboarding before leaving onboarding.

## Lifecycle ownership

`AppDependencies` owns long-lived resources it creates. Startup failure and permanent root teardown must release those resources exactly once.

Any new long-lived dependency needs:

- an explicit owner;
- partial-bootstrap cleanup;
- final dispose/close path;
- regression/manual lifecycle verification.

## Cross-platform file transfer

All selected content is untrusted. Current implementation uses `file_picker 12.0.0`.

### Selection/read path

- Select one file with `FilePicker.pickFile()`.
- Validate `PlatformFile.length()` before processing.
- If a native cached path exists, use `BoundedFileReader` for bounded filesystem streaming.
- Otherwise consume `PlatformFile.readAsByteStream()` and validate cumulative bytes.
- Decode UTF-8 only after byte bounds pass.
- Translate platform/filesystem failures to domain-level import/export errors.

Current limits:

- Markdown/text: **16 MiB**.
- JSON backup: **64 MiB**.

### Export path

Use file-picker save behavior through `FileTransferService` with explicit filenames/MIME types. Native platforms typically expose save dialogs while Web produces browser download behavior.

Do not assume selected files always have native filesystem paths.

## Backup development

Backup schema is independent from application and database versions.

Preserve fail-before-write validation for:

- app/schema identity;
- JSON/value types;
- tags;
- IDs/relationships;
- UTC timestamps/order;
- ARGB values;
- lifecycle invariants.

Then use transactional conflict-safe restore. JSON backup—not raw native/browser database files—is the supported portable interchange format.

## External links

Do not call launcher plugins directly from feature widgets. Use `ExternalLinkService`, handle the safe `false` result, and add regression/platform checks for new URI schemes.

## App-lock development

`AppLockService` is a capability boundary.

Current behavior:

- supported native `local_auth` implementations authenticate through OS APIs;
- Linux reports unavailable with the current dependency;
- Web uses a conditional unavailable implementation and never imports native auth code;
- the root lock gate remains usable even if a stale `appLockEnabled=true` preference exists on an unsupported target.

Never add plaintext/home-grown credentials merely to advertise parity. App lock is not database encryption.

## Version/toolchain metadata

Keep synchronized:

- `pubspec.yaml` semantic/build version;
- visible `AppStrings.version`;
- changelog section;
- matching version release notes;
- `.flutter-version`;
- exact Flutter pins in CI/platform/release workflows.

Verify:

```bash
python tool/check_version_sync.py
```

## Tests

Core test commands:

```bash
flutter test
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

See [`testing.md`](testing.md).

## Formatting and analysis

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

The repository uses the canonical Dart **3.12.2** formatter output. Fix diagnostics instead of weakening analysis merely to silence difficult code.

## Debugging database behavior

Use fictional data. Never require users to publish real SQLite databases, browser storage dumps, or backups.

For FTS, inspect expected rows/triggers and keep user input bound as variables. For Web, inspect worker/WASM requests, MIME type, browser console/storage backend, and persistence after reload/restart.

## Error messages and diagnostics

User-facing failures should be actionable, concise, truthful about preserved data, and free of note content, credentials, or unnecessary path details. Raw platform exceptions belong only in safe redacted diagnostics when useful.

## Accessibility during development

For UI changes review:

- keyboard operation on desktop/Web;
- browser focus visibility;
- touch target size;
- semantics/tooltips;
- increased text size and browser zoom;
- narrow/wide layouts;
- non-color status/selection cues;
- reduced motion;
- readable failure/status feedback.

See [`accessibility.md`](accessibility.md).

## Documentation discipline

Update coupled truth together:

- setup/bootstrap → README + setup docs;
- architecture/platform boundary → architecture + ADR when material;
- data behavior → privacy/security where relevant;
- release/toolchain/platform matrix → changelog + release docs + workflows;
- dependency graph → `pubspec.yaml` + `pubspec.lock` + affected platform docs;
- tracked file set → repository reference;
- current checkpoint → `what_changed.md`.

## Commit discipline

Prefer small cohesive Conventional Commits.

```bash
git config user.name "Sanskar"
git config user.email "sanskarin@outlook.in"
```

## Finishing a change

```bash
python tool/check_version_sync.py
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Then run every affected platform build and appropriate runtime/manual checks. Document blocked or unrun verification accurately; never turn “implemented” into “verified” without evidence.
