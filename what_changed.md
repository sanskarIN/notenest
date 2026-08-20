# NoteNest — 2.0.12 Six-Platform Engineering Handoff

Last updated: **2026-08-20**

Target application version: **2.0.12**

Flutter package version: **2.0.12+2012**

Pinned Flutter SDK: **3.44.7**

Pinned direct Drift version: **2.34.3**

Drift database schema: **1**

Active development branch: `main`

Implemented Flutter project targets: **Android, iOS/iPadOS, Windows, macOS, Linux, Web**

Tracked-file documentation checkpoint: **108 tracked files cataloged**

Stable tag: **not yet created**

Active stable-release dependency blocker: **GitHub issue #8 — resolver-generated `pubspec.lock`**

Final verification path: **PR #7**, which must be realigned to the commit containing this handoff before its new checks are considered evidence.

## Current release status

NoteNest remains a **2.0.12 release candidate**. This continuation expands the project from five native-oriented targets to the complete Flutter platform set without changing the semantic version.

The source architecture, platform bootstrap, database factory, import/export boundary, optional app-lock capability model, GitHub Actions platform matrix, release packaging, tests, issue/PR templates, public documentation, privacy/security model, accessibility matrix, and release checklist now explicitly cover:

- Android
- iOS / iPadOS
- Windows
- macOS
- Linux
- Web

This is an **implementation/support target statement**, not a claim that every target has already passed final runtime certification. Stable `v2.0.12` remains blocked until the real dependency lock is committed and the exact resulting candidate passes automated, platform, browser, accessibility, runtime, screenshot, signing, and distribution checks.

## Why Web required architectural work

A browser target cannot safely be added by only changing README text or running `flutter create --platforms=web`.

The pre-continuation source contained two material browser blockers:

1. Shared import code directly depended on `dart:io` filesystem access.
2. App lock assumed a `local_auth` implementation even though the current plugin does not provide Web or Linux authentication implementations.

The database also needed an explicit browser SQLite runtime configuration and generated worker/WASM assets.

The completed cross-platform work addresses those boundaries directly.

## Cross-platform source changes

### Native filesystem code isolated from browser builds

`lib/core/utils/bounded_file_reader.dart` is now a conditional facade.

Native implementation:

- `lib/core/utils/bounded_file_reader_io.dart`
- imports `dart:io` only on IO targets;
- checks the selected file's reported length;
- streams chunks rather than requesting one eager native picker buffer;
- re-checks cumulative bytes before adding each chunk;
- maps filesystem errors to `ImportExportException`.

Browser/non-IO implementation:

- `lib/core/utils/bounded_file_reader_stub.dart`
- never attempts a fake browser filesystem path;
- reports filesystem-path reading unavailable through the same asynchronous domain-error contract.

The browser fallback was corrected after final review so the declared `Future` fails asynchronously rather than throwing synchronously before a caller can await/expect the operation.

Relevant commits:

- `b7aec1ba44bbf7652f13a51a8da417acee671bb4` — `refactor: isolate native file reader for web builds`
- `805f8e2012a213b18679215acbad1877d6e79c0f` — `refactor: move bounded file streaming to native implementation`
- `d4334cfcb957e6b41ecfdad832e3c2b12c7915eb` — `feat: add browser-safe file reader fallback`
- `643b2cf04951ef8a0d7100774415958ab3c20726` — `fix: surface web path errors asynchronously`

### File import now has native and browser acquisition paths

`lib/services/file_transfer_service.dart` no longer assumes every `PlatformFile` supplies a native filesystem path.

Native behavior:

- picker does not request eager data;
- cached path is passed to the bounded native reader.

Web behavior:

- picker requests bytes (`withData: kIsWeb`);
- picker-reported `file.size` is validated first;
- actual in-memory byte length is validated again;
- a supplied stream is accumulated only while cumulative validation succeeds;
- UTF-8/Markdown/JSON processing occurs only after bounds checks.

Limits remain:

- Markdown/text: **16 MiB**
- NoteNest JSON backup: **64 MiB**

Commit:

- `3600b0db672c2742a324d9c7c38d17da793f4c3d` — `feat: support bounded browser file imports`

### Web-compatible Drift database configured

`lib/data/database/app_database.dart` now configures the normal `driftDatabase(...)` factory with explicit browser options:

```dart
web: DriftWebOptions(
  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
  driftWorker: Uri.parse('drift_worker.js'),
),
```

The logical NoteNest schema remains **schema version 1**. Native and browser targets use the same Notes/NoteVersions/FTS behavior through the appropriate SQLite runtime.

Commit:

- `50b1c74575da6a70950a5292410cb53e3fc7135d` — `feat: configure persistent Drift storage for web`

### App lock is now a platform capability instead of a universal assumption

The current `local_auth` dependency supports the relevant Android/iOS/macOS/Windows environments but has no Web or Linux implementation.

NoteNest now uses:

- `lib/services/app_lock_service.dart` — conditional facade;
- `lib/services/app_lock_service_io.dart` — native `local_auth` wrapper with safe missing-plugin/platform/authentication error handling;
- `lib/services/app_lock_service_stub.dart` — Web/non-IO unavailable implementation.

Commits:

- `0453ae3eb0a74e1b24a832be9a5a075114b481c5` — `refactor: select app lock implementation per platform`
- `4c83701a7c1fa6eb00d18556c31b00f240714fbb` — `refactor: keep device authentication on supported native targets`
- `1bf39d99fe7b2917b33bd4e80bb49a886e7ff657` — `feat: disable unsupported app lock safely on web`

### Unsupported app-lock target cannot trap the user

A stale persisted `appLockEnabled=true` setting could otherwise create an impossible unlock screen on Web/Linux.

`lib/app/app.dart` now checks `canAuthenticate()` before authentication. If the runtime does not support device authentication, the root lock gate remains usable instead of permanently blocking access.

`lib/features/settings/settings_page.dart` now:

- loads authentication capability;
- shows checking/supported/unavailable state;
- prevents enabling app lock when unsupported;
- still allows an already-enabled stale preference to be disabled;
- keeps unrelated NoteNest functionality usable.

Commits:

- `f654bd9527ea396aa456c719e3faa39d52a8aadf` — `fix: bypass app lock on unsupported platforms`
- `3372d9be45e84967f892ef44f0a51b658bf042e9` — `fix: expose app lock availability across platforms`

No home-grown browser/Linux password or biometric scheme was added merely to claim feature parity. App lock remains UI access control and is not database encryption.

## Generated platform/bootstrap changes

`tool/bootstrap_platforms.py` now generates:

```text
android,ios,linux,macos,windows,web
```

in one reproducible bootstrap path using the pinned Flutter SDK.

Existing fail-fast Android/iOS checks remain:

- Android `FlutterFragmentActivity`.
- `USE_BIOMETRIC`.
- Android `minSdk = 24`.
- AppCompat dependency.
- expected AppCompat themes.
- iOS `NSFaceIDUsageDescription`.

### Drift Web runtime pairing

The bootstrap now also:

1. Parses the direct `drift:` version from `pubspec.yaml`.
2. Requires it to match reviewed `DRIFT_WEB_VERSION = "2.34.3"`.
3. Downloads `sqlite3.wasm` and `drift_worker.js` from the matching Drift GitHub release.
4. Rejects unexpectedly tiny payloads.
5. Requires the WASM binary header.
6. Rejects a worker response that looks like an HTML error page.
7. Writes the generated assets into the Web runner.
8. Fails if the direct Drift version changes without an explicit Web runtime review.

The assets remain generated/untracked. This policy provides package-version/runtime pairing and basic transport/content sanity; it is not documented as cryptographic provenance.

Commit:

- `256ea5d0386b3a7ebfc842e3e9441650e65ca584` — `feat: bootstrap verified Flutter web database assets`

## Web regression coverage

Added:

- `test/web/web_platform_smoke_test.dart`

The Chrome-targeted regression protects:

- unavailable Web app-lock capability;
- authentication failure without unsupported native plugin behavior;
- browser rejection of native filesystem-path reads through the domain exception boundary.

Commit:

- `439f090f75b00dbff76aebeb6c699778c2bc0c8a` — `test: cover browser platform fallbacks`

The later async-stub fix above protects the test contract itself.

## Six-platform GitHub Actions

### Platform builds

`.github/workflows/platform-builds.yml` now includes a Web job in addition to Android/Linux/Windows/macOS/iOS.

The Web lane performs:

```bash
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

`test/web/**` is included in platform-build path filters.

Commit:

- `3ea96658bcfc2890f6bd934e4a843e2e7a78d1cc` — `ci: add first-class Flutter web verification`

### Release artifacts

`.github/workflows/release.yml` now has a Web packaging job that runs the browser smoke check, creates the release Web bundle, and uploads `build/web/**` as a release workflow artifact.

Commit:

- `9e1e33fbdf962a10e67d060624b9d36c15b98553` — `ci: package Flutter web release artifact`

No CI success is claimed here until GitHub actually completes checks on the final verification head.

## Repository policy and documentation completeness

Five tracked files were added by the browser/native platform abstractions and Web test:

- `lib/core/utils/bounded_file_reader_io.dart`
- `lib/core/utils/bounded_file_reader_stub.dart`
- `lib/services/app_lock_service_io.dart`
- `lib/services/app_lock_service_stub.dart`
- `test/web/web_platform_smoke_test.dart`

The exhaustive repository catalog therefore moved from **103 to 108 tracked files**.

`docs/repository-reference.md` now documents all 108 paths and updates the source-of-truth matrix, generated boundaries, platform invariants, and audit guidance.

`tool/check_repo.py` now explicitly requires the browser/native abstraction files, the Web smoke regression, and a README six-platform support statement.

Commit:

- `72846b670f8af0bab9094e831420549ea558b9ba` — `tooling: require cross-platform support boundaries`

The authoritative automated proof of the 108-file catalog still requires `python tool/check_repository_reference.py` on a checked-out final candidate.

## GitHub community workflow changes

The bug report form now includes Web and asks for browser/platform details without requiring a locally installed Flutter SDK for a published-browser runtime report.

The pull-request template now requires explicit Android/iOS/Windows/macOS/Linux/Web impact review and includes the Chrome/Web build commands.

Relevant commits:

- `49c544c8ba216d8b5a31110f0a438dcdb37c15d1` — `docs: accept Web platform bug reports`
- `f382925182174374f3ae2615699b322d54aa0dcd` — `docs: add six-platform pull request review gate`

## Public and engineering documentation synchronized

The cross-platform work was propagated through the repository rather than leaving stale five-platform language.

Updated surfaces include:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `PRIVACY.md`
- `SECURITY.md`
- `SUPPORT.md`
- `CONTRIBUTING.md`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/pull_request_template.md`
- `docs/accessibility.md`
- `docs/adr/0003-generated-platform-runners.md`
- `docs/architecture.md`
- `docs/development.md`
- `docs/github.md`
- `docs/performance.md`
- `docs/release.md`
- `docs/releases/2.0.12.md`
- `docs/repository-reference.md`
- `docs/setup.md`
- `docs/testing.md`
- `docs/troubleshooting.md`
- this `what_changed.md`

Notable documentation commits:

- `4abc07c82f1b7484543c697d90cf17e3b20687a2` — `docs: record six-platform 2.0.12 support`
- `c0569ede6f3123625d3bfcf97fe98c9be2d63a36` — `docs: publish six-platform support matrix`
- `7f0363edd2dd8f5981f5618908539a868b835f97` — `docs: add complete Web setup and deployment`
- `d9f73380669aad4206b2c30dfe92f75017cf8dac` — `docs: make Web a required testing target`
- `debdf6458c038670b7d5012e23505d9b8c18dc7d` — `docs: require six-platform release verification`
- `fb77f553691c802edffac535f3b667973d8614a7` — `docs: finalize six-platform 2.0.12 candidate notes`
- `fc9d85db629458d15fa6d7097f2fc3795e0dfb48` — `docs: document browser-local privacy boundary`
- `486c939245f933918f256f46fd86587898854a26` — `docs: extend security model across Web`
- `c42850706b10162c014521266adbf718b3b760bc` — `docs: move Web support into 2.0.12 baseline`
- `937ca221f7af17a38be29c2fb1193f9ab97b904b` — `docs: document six-platform architecture boundaries`
- `587a1ae85efecf14694059d4994c02b7ff615b8d` — `docs: align development workflow to six targets`
- `1f6ff939e7fbc796f32e3ba3cb0a10ad9c4f1f99` — `docs: add Web cross-platform troubleshooting`
- `293bb415d7678ed8a37e8c6c2474bea10aed5c2c` — `docs: extend runner ADR to Flutter Web`
- `9ca936a211cd56a26df7699354f26c0feecccb4e` — `docs: include Web in accessibility matrix`
- `80de96a5a90a00b6974477ec275eea99ab17b378` — `docs: require six-platform contribution review`
- `aa21ded24141e76a81d59ad799263bfe1d04036a` — `docs: align GitHub operations with six platforms`
- `775e382b0372f62a338cc16950f6387c78baeec6` — `docs: add Web performance baseline`
- `27102b486f413444618e0c676f41332048418e19` — `docs: add Web support diagnostics`

## Current supported-target behavior

### Android

- Flutter target/bootstrap/build/release path.
- Local Drift SQLite/FTS.
- Native file import/export.
- Device authentication where supported/configured.

### iOS / iPadOS

- Flutter target/bootstrap/no-codesign compile/release-validation path.
- Local Drift SQLite/FTS.
- Native file import/export.
- Device authentication where supported; Face ID description configured.
- Distribution signing remains external.

### Windows

- Flutter desktop target/build/release path.
- Local Drift SQLite/FTS.
- Desktop file import/export.
- Device authentication where supported.

### macOS

- Flutter desktop target/build/release path.
- Local Drift SQLite/FTS.
- Desktop file import/export.
- Device authentication where supported.
- Signing/notarization remains distribution work.

### Linux

- Flutter desktop target/build/release path.
- Local Drift SQLite/FTS.
- Desktop file import/export.
- Current device app lock is unavailable because the dependency has no Linux implementation; NoteNest remains usable.

### Web

- Flutter Web target/bootstrap/build/release path.
- Drift SQLite through `sqlite3.wasm` + `drift_worker.js`.
- Browser picker import/download export behavior.
- Responsive compact/wide UI.
- App lock intentionally unavailable; app remains usable.
- Browser data remains local to the browser/profile/origin and is subject to site-data clearing/storage policy.

## Web deployment requirements

A successful `flutter build web` is not enough to certify a deployed host.

The intended Web release must verify:

- `sqlite3.wasm` is present and served as `application/wasm`;
- `drift_worker.js` is reachable at the configured path;
- the app boots without worker/WASM fetch errors;
- create/edit/search persists across page reload;
- persistence survives browser restart under normal storage policy;
- Markdown import/export works;
- JSON backup export/restore works;
- oversized browser selections are rejected;
- browser/site-data clearing behavior is understood/documented;
- keyboard/focus/zoom/screen reader behavior is reviewed;
- actual Drift browser storage mode is recorded where relevant.

Cross-origin isolation can provide the optimal OPFS-backed path on compatible deployments, but NoteNest does not require an unverified claim that every host/browser uses OPFS. Tested fallback storage is acceptable when documented.

## Package/platform audit

The current direct plugin/platform review found:

- Drift / drift_flutter: all-six-target database support with explicit Web runtime configuration.
- file_picker: all-six-target file selection/export support used through platform-appropriate data/path behavior.
- shared_preferences: Android/iOS/Linux/macOS/Web/Windows support.
- url_launcher: Android/iOS/Linux/macOS/Web/Windows support.
- local_auth: Android/iOS/macOS/Windows support, but no current Web/Linux implementation; NoteNest now treats that feature as unavailable there.

This package-capability review is still not equivalent to running the final builds/runtime flows.

## Static source-review signals

The final indexed source sweep in this continuation found no matches for:

- `TODO:`
- `FIXME:`
- `HACK:`
- `UnimplementedError`

An indexed search also found no unexpected shared `dart:io` usage after the conditional refactor. Search indexing is only a static signal and may lag; the final analyzer/Web compile remains authoritative.

## Verification limitation in this working environment

The execution container available during earlier finalization could not resolve `github.com` for a normal clone and does not provide the complete pinned Flutter/native toolchain needed to run the repository locally.

Therefore this handoff **does not claim** that any of the following completed successfully in the local container:

```bash
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Nor are Android/iOS/Windows/macOS/Linux/Web runtime/build results claimed green until GitHub Actions/real platform hosts complete them against the exact final candidate.

Repository inspection and edits were performed through the connected GitHub API.

## Stable-release blocker: `pubspec.lock`

GitHub issue **#8** remains open.

NoteNest is an application project and the stable dependency graph must be captured by a resolver-generated lockfile. The lock must be produced by pinned Flutter **3.44.7** from a clean exact candidate, reviewed, committed, added to `docs/repository-reference.md`, and enforced in final CI/release dependency installation.

Current catalog count before the lockfile is **108**. Adding only the lockfile makes the expected tracked-file count **109**.

The lockfile must not be manually invented or reconstructed from package constraints.

After the lockfile is committed, all final automated/six-platform verification must be repeated on the new exact candidate.

## Verification PR policy

PR **#7** is retained as a verification-only path.

Because this continuation changes `main` substantially, every older PR #7 run attached to the pre-cross-platform head is superseded.

After this handoff commit:

1. Move `verify/2.0.12-final` to the exact current `main` commit.
2. Add only a non-functional comment in `lib/main.dart` on the verification branch to exercise the `lib/**` path filters.
3. Reopen/update PR #7 if GitHub auto-closes it while branch and base are temporarily identical.
4. Treat only completed checks attached to that new head as evidence.
5. Do not merge the verification marker into `main`.
6. Because issue #8 still changes the final product candidate later, even green pre-lock checks remain pre-lock evidence rather than permission to tag stable 2.0.12.

## Remaining 2.0.12 stable blockers

1. Generate/review/commit/catalog/enforce the real Flutter-3.44.7 `pubspec.lock` (issue #8).
2. Re-run final exact-candidate CI after the lock commit.
3. Complete release/toolchain/repository/reference/link/secret gates.
4. Complete Drift generation, formatting, analyzer, and Flutter tests.
5. Complete Chrome Web fallback regression.
6. Complete Android release compile.
7. Complete Linux release compile.
8. Complete Windows release compile.
9. Complete macOS release compile.
10. Complete iOS no-codesign release compile.
11. Complete Web release compile.
12. Verify native file picker/import/export and size limits.
13. Verify browser picker/import/download and size limits.
14. Verify Web worker/WASM MIME/reachability and local persistence across reload/browser restart.
15. Verify note editor rapid-edit/back, save failure, first-line formatting, history/export guards.
16. Verify note lifecycle/filter/error-feedback behavior.
17. Verify settings ordering/rollback and persistence-first onboarding.
18. Verify backup export/restore/malformed-data behavior with fictional data.
19. Verify supported app-lock paths on representative supported targets.
20. Verify Web/Linux unavailable app-lock paths remain usable.
21. Verify external link success/failure.
22. Complete keyboard/browser focus, screen reader, large text/zoom, theme, reduced-motion, touch-target accessibility checks.
23. Capture verified runtime screenshots rather than treating illustrative artwork as runtime evidence.
24. Prepare native signing/notarization/store status as applicable.
25. Produce/review final artifacts and SHA-256 checksums.
26. Create `v2.0.12` only on the exact commit that passed the full final checklist.

## Release-readiness statement

NoteNest 2.0.12 is now implemented as a **six-platform Flutter release candidate** with local-first notes/search/history, deterministic editor/settings persistence, strict backup/restore validation, bounded native/browser imports, cross-platform exports, responsive Material 3 presentation, browser-local Drift SQLite support, safe platform authentication capability handling, all-six-target bootstrap/build/release automation, Chrome Web regression coverage, privacy/security/accessibility documentation for browser operation, and a machine-enforced exhaustive 108-file source catalog.

The project must still be described as a **release candidate**, not a fully verified stable release. The real application lockfile, final exact-candidate automated builds/tests, representative runtime/browser/accessibility checks, screenshots, signing, artifacts, and checksums remain mandatory before `v2.0.12`.
