# NoteNest Development Guide

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

NoteNest is developed as one Flutter application targeting Android, iOS/iPadOS, Windows, macOS, Linux, and Web. Platform differences belong behind explicit boundaries rather than scattered `Platform.*`, `dart:io`, or plugin assumptions throughout features.

## Daily workflow

```bash
python tool/check_version_sync.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```

For browser-boundary work also run:

```bash
python tool/bootstrap_platforms.py
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

Every tracked path is documented exactly once in [`repository-reference.md`](repository-reference.md). The current catalog contains **108 tracked files**. Update it in the same commit/workstream as tracked path changes.

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

Do not leak plugin/database implementation details throughout feature widgets.

## Cross-platform design rule

Before adding any platform-sensitive behavior ask:

1. Does this API compile on Web?
2. Does the plugin actually implement all six targets?
3. What should an unsupported platform do?
4. Does the feature require `dart:io` or another native-only library?
5. Can platform selection be isolated behind conditional imports/exports?
6. How is the behavior tested on native plus browser targets?
7. Does it affect permissions, privacy, security, hosting, or release artifacts?

Unsupported capability must be explicit and safe. Do not fake parity with a weaker custom security mechanism.

## Adding a note feature

Decide:

- persisted note data vs setting vs transient UI state;
- schema/migration impact;
- backup compatibility;
- FTS/filter impact;
- browser/native behavior;
- privacy/permission/security impact;
- compact/wide/keyboard/screen-reader behavior;
- smallest deterministic regression layer;
- documentation/release impact.

## Database development

Application 2.0.12 and Drift schema 1 are independent version domains.

A future schema migration must increment `schemaVersion`, add deterministic migration logic, and test representative previous-schema fictional data. FTS table/trigger changes need explicit migration/rebuild planning.

Every schema/query change must be reviewed on both:

- native Drift/SQLite;
- Drift Web SQLite WASM/worker.

Do not assume a successful `NativeDatabase.memory()` test proves browser runtime behavior.

## Web database runtime

`AppDatabase` supplies Web URIs for `sqlite3.wasm` and `drift_worker.js`.

`tool/bootstrap_platforms.py` currently ties those assets to direct dependency Drift **2.34.3**. When changing `drift`:

1. Review Drift release/migration notes.
2. Update `pubspec.yaml` deliberately.
3. Update/review the bootstrap Web version pairing.
4. Regenerate Web assets.
5. Run Chrome platform smoke + Web release build.
6. Deploy/test the real bundle on a representative origin.
7. Update lockfile, architecture/testing/release docs.

Do not quietly mix a worker/WASM pair from another Drift release.

## Repository boundaries

Repositories own persistence invariants. Prefer intention-specific operations (`archive`, `trash`, `restore`, `setPinned`) over arbitrary column mutation from UI code. Use a transaction when multiple storage changes form one logical operation.

`NoteRepository` owns note lifecycle, snapshots, search/filter metadata, and the no-pinned-trash invariant.

`BackupRepository` owns portable interchange validation/merge rules.

## Controllers

Controllers own feature/application state, not platform APIs.

Rules:

- Dispose listeners/timers.
- Guard async completions after disposal.
- Protect newer state from stale async requests.
- Debounce high-frequency work where appropriate.
- Keep unrelated settings/features out of a controller.

## Editor and autosave

The editor stores raw text plus note metadata rather than a rich-document graph.

`Debouncer` reduces high-frequency submissions; `AsyncSerialQueue` guarantees submitted writes execute in order. Every save captures an immutable draft. A completion may mark the UI saved only if the draft is still current.

Normal Back waits for the current-draft save. Export/history also requires a successful current-draft save. Do not remove the serial queue without replacing its ordering guarantee.

Current-line prefix actions must preserve the offset-zero empty-first-line regression.

## Settings/onboarding

Preferences stay behind `SettingsStore`/`SettingsRepository`/`AppSettingsController`.

- Never store credentials, biometric data, or note bodies there.
- Treat setter failure as persistence failure.
- Serialize order-sensitive writes.
- Roll back failed optimistic state when appropriate.
- Keep stale failures from overwriting newer visible state.
- Persist onboarding before leaving it.

## Lifecycle ownership

`AppDependencies` owns long-lived resources it creates. Startup failure and permanent app teardown must both release those resources exactly once.

Any new long-lived dependency needs:

- explicit owner;
- partial-bootstrap cleanup;
- final disposal/close path;
- regression/manual lifecycle verification.

## Cross-platform file transfer

All selected content is untrusted.

### Native

- Prefer picker cached paths over eager full picker bytes.
- Stream with `BoundedFileReader`.
- Validate reported and cumulative bytes.
- Translate filesystem failures to domain exceptions.

### Web

- Do not assume a native path exists.
- Request picker bytes/stream.
- Validate picker-reported size and actual received length.
- Decode only after bounds checks.
- Keep `dart:io` behind conditional implementation code so browser compilation remains valid.

Current ceilings:

- Markdown/text: 16 MiB.
- JSON backup: 64 MiB.

Export paths differ too: native uses platform save dialogs/paths while Web typically produces browser downloads through the picker implementation.

## Backup development

Backup schema is independent from app/DB version.

Preserve fail-before-write validation for app/schema/types/tags/IDs/relationships/UTC timestamps/timestamp order/ARGB/lifecycle state, then use transactional conflict-safe restore.

Use backup JSON—not raw internal native/browser database files—as the supported cross-platform interchange format.

## External links

Do not call launcher plugins directly from feature widgets. Use `ExternalLinkService`, handle `false`, and add platform smoke coverage for new URI schemes.

## App-lock development

`AppLockService` is a capability boundary.

Current behavior:

- supported `local_auth` native targets authenticate through OS APIs;
- Linux resolves unavailable with the current dependency;
- Web uses a conditional unavailable implementation and never imports native authentication code.

The root lock gate must remain usable when capability is unavailable, including when a stale `appLockEnabled=true` preference exists.

Never add plaintext/home-grown credentials solely to claim full feature parity. App lock is not database encryption.

## Adding dependencies

Before adding/updating a package:

- Verify active maintenance and Flutter/Dart compatibility.
- Check **all six target implementations**, not only package-level Dart compatibility.
- Review permissions/networking/privacy/license.
- Review Web compile/runtime implications.
- Prefer existing dependencies/standard APIs where sufficient.
- Rebuild every affected target.
- Update `pubspec.lock` using the pinned toolchain once the lockfile baseline exists.

Stable 2.0.12 currently has an explicit lockfile blocker in issue #8; the lock must be generated by Flutter 3.44.7, not handwritten.

## Version/toolchain metadata

Keep synchronized:

- `pubspec.yaml` semantic/build version.
- visible `AppStrings.version`.
- changelog section.
- matching version-specific release notes.
- `.flutter-version`.
- Flutter pins in CI/platform/release workflows.

Verify:

```bash
python tool/check_version_sync.py
```

## Generated platform runners

```bash
python tool/bootstrap_platforms.py
```

The script generates all six targets and is deliberately fail-fast for Android/iOS template drift and Drift Web asset/version drift.

Generated runner directories are not the source of truth; the pinned Flutter SDK + bootstrap script are.

## Tests

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

Fix diagnostics rather than weakening global analysis merely to silence one difficult line.

## Debugging database behavior

Use fictional data. Never ask users to post real SQLite databases, browser storage dumps, or backups.

For FTS, inspect expected rows/triggers and keep user input bound as variables. For Web, also inspect worker/WASM fetches, WASM MIME, browser console/storage backend, and persistence across reload.

## Error messages

User-facing failures should be actionable, concise, truthful about preserved data, and free of note/credential/path details. Raw platform exceptions belong only in safe redacted diagnostics when useful.

## Accessibility during development

For UI changes check:

- keyboard on desktop + Web;
- browser focus/zoom;
- touch targets;
- semantics/tooltips;
- increased text size;
- narrow/wide layouts;
- non-color status cues;
- reduced motion;
- readable failure/status messages.

See [`accessibility.md`](accessibility.md).

## Documentation discipline

Update coupled truth in the same workstream:

- setup/bootstrap → README + setup docs;
- architecture/platform boundary → architecture + ADR if material;
- data behavior → privacy;
- security capability → security;
- release/toolchain/platform matrix → changelog + release docs + workflows;
- tracked file set → repository reference;
- current checkpoint → `what_changed.md`.

## Commit discipline

Prefer small cohesive Conventional Commits. Project identity:

```bash
git config user.email "sanskarin@outlook.in"
```

## Finishing a change

```bash
python tool/check_version_sync.py
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Then run every platform build/runtime check affected by the change. Document blocked/unrun verification accurately; never convert “implemented” into “verified” without evidence.
