# NoteNest — 2.0.12 Final Engineering Handoff

Last updated: **2026-08-24**

Application version: **2.0.12**  
Flutter package version: **2.0.12+2012**  
Pinned Flutter SDK: **3.44.7**  
Bundled Dart SDK used by CI: **3.12.2**  
Pinned direct Drift dependency: **2.34.3**  
Pinned file picker: **12.0.0**  
Drift database schema: **1**  
Implemented Flutter targets: **Android, iOS/iPadOS, Windows, macOS, Linux, Web**  
Tracked-file contract: **109 files**  
Stable tag: **not created**  
Current blocker-fix PR: **#18 — `fix/2.0.12-verification-blockers`**  
Previous verification PR: **#7 — diagnostic only; no longer final evidence**

## Current release status

NoteNest 2.0.12 remains a six-platform Flutter **release candidate**, not a stable release.

PR #7 produced valuable exact-run evidence but also exposed additional blockers that invalidated its use as final release certification:

- six Flutter tests failed;
- Android could not resolve unpublished `actions/setup-java@v6`;
- Linux, Windows, macOS/iOS, and Web runner jobs reached `flutter pub get --enforce-lockfile` after `flutter create --no-pub` had rewritten the root application manifest, so the committed lock no longer matched;
- later `main` commits fixed monotonic note timestamps, compact-height onboarding overflow, and added stable editor field keys, so the frozen PR #7 candidate was no longer the current source tree.

The blocker-fix branch now addresses those failures in focused commits and PR #18 is the current merge/verification path before a new exact verification-only 2.0.12 candidate is frozen.

Implemented on PR #18 so far:

- `e6097bb1c2a8cc24150e4da26ad25bae31e45c8a` — `test: target editor body by stable key`
- `9d62d7a3f60a8b06c0b8aa09e55f8d138b44249e` — `fix: preserve Markdown body across metadata round trips`
- `d35189fd78092d630c7b2f635c9a93ed3f77efb8` — `test: preserve leading Markdown body newline`
- `b71ffe81200d82890d142b5aff67f586d9653462` — `ci: use stable setup-java v5 for platform builds`
- `fca4d5a85431073f73a6a1df5e0a939d7b0a1d91` — `ci: use stable setup-java v5 for release packaging`
- `55ef641c99756ec06022de30a6ac622557bc886e` — `ci: enforce stable setup-java v5 baseline`
- `782bd4f5605fce0cdc38e4a923dcd3b7ffd47da8` — `fix: preserve locked manifests during runner bootstrap`
- `a78d895caba7b0721fb331572ea4c78575f47f66` — `docs: correct stable GitHub Actions baseline`
- `6a276fd1d69d401db523b46632f2b23eaee4c227` — `docs: refresh 2.0.12 blocker-fix roadmap`
- `c804d5a4de44f6f83ffebce7ee6319e94dcfcd4c` — `docs: record 2.0.12 verification blocker fixes`

The source/reproducibility/toolchain baseline before those final blocker fixes remains:

- Flutter 3.44.7 dependency resolution is compatible.
- A genuine resolver-generated application `pubspec.lock` is committed.
- CI/platform/release workflows enforce that lock.
- Canonical Dart 3.12.2 formatting is committed.
- The file-picker Android blocker is fixed through `file_picker 12.0.0` rather than suppressed.
- Windows builds succeeded on the current GitHub-hosted Visual Studio 2026 toolchain during diagnostic verification.
- iOS has an explicit 14.0 deployment floor matching the current file-picker dependency.
- Web browser boundaries, Drift worker/WASM generation, and Chrome platform smoke are implemented.
- The repository reference catalogs every one of the **109 tracked files**.
- GitHub-hosted first-party workflow actions now use published stable majors and repository policy enforces that baseline.

After PR #18 is fully green and merged, a fresh exact verification-only branch must be created from the resulting final `main` commit. Only checks from that frozen post-merge candidate may be treated as final automated 2.0.12 evidence.

Even after that exact automated run is green, stable `v2.0.12` remains blocked on representative runtime, accessibility, deployed-Web, signing/artifact, screenshot, and checksum work described below.

## Final dependency graph and lockfile

The original 2.0.12 dependency-resolution attempt failed because Flutter 3.44.7's `flutter_localizations` SDK package pins `intl 0.20.2` while the project requested 0.20.3.

The manifest was corrected to:

```yaml
intl: 0.20.2
```

Later Android verification exposed a separate real blocker inside `file_picker 11.0.3`. The candidate therefore moved to:

```yaml
file_picker: 12.0.0
```

The dependency graph was resolved by the pinned Flutter 3.44.7 / Dart 3.12.2 GitHub Actions environment.

Current lockfile facts:

- Resolver-generated, not hand-authored.
- **129 resolved packages**.
- File size: **30,063 bytes**.
- SHA-256 captured from the generated artifact: `2d76ab639e1846fc6c55bcc0b8b49502f55a70d782cf118b1738c0c4437d7744`.
- Includes `file_picker 12.0.0` and its federated platform packages.
- Includes `intl 0.20.2`.
- Includes Drift `2.34.3` / drift_dev `2.34.5`.
- SDK constraints in the generated lock are compatible with Dart 3.12.2 / Flutter 3.44.7.

The exact generated lockfile plus canonical Dart formatter output were materialized by CI to `materialize/2.0.12-baseline`, commit:

- `c24cefd3d3d25dcafda2cf0ccda6c4a96315c69a` — `build: materialize 2.0.12 dependency and format baseline`

That generated tree was promoted marker-free onto `main` as:

- `cf7e4f139b79dfa3d0d6ab36c69077fd61d23aec` — `build: lock and format 2.0.12 baseline`

No dependency versions or hosted-package hashes were manually reconstructed.

## Lock enforcement and runner bootstrap

The repository treats the lock as an application release invariant.

Normal automated restoration uses:

```bash
flutter pub get --enforce-lockfile
```

This applies to:

- `.github/workflows/ci.yml`
- `.github/workflows/platform-builds.yml`
- `.github/workflows/release.yml`

The temporary CI materialization/write path has been removed. CI permissions are back to:

```yaml
permissions:
  contents: read
```

`tool/check_repo.py` requires `pubspec.lock` to exist **and be tracked by Git**.

`docs/repository-reference.md` includes the lockfile and the repository contract remains **109 tracked files**.

PR #7 revealed an additional reproducibility issue in generated runner creation. `flutter create --no-pub` can update the root `pubspec.yaml` to match the current Flutter template even though NoteNest intentionally keeps its own reviewed application dependency graph. The subsequent `flutter pub get --enforce-lockfile` then rejected that rewritten manifest against the committed lock.

PR #18 changes `tool/bootstrap_platforms.py` so runner generation snapshots both `pubspec.yaml` and `pubspec.lock`, runs `flutter create --no-pub`, and restores the application files byte-for-byte in a `finally` path. This means:

- generated platform runner files can still move with the pinned Flutter template;
- the reviewed NoteNest dependency manifest remains authoritative;
- the resolver-generated lock remains authoritative;
- a failed `flutter create` cannot leave the application manifest or lock silently modified;
- `prepare_web()` reads the restored NoteNest Drift dependency instead of a generated template manifest;
- `--enforce-lockfile` now verifies the actual committed application pair.

## Canonical Dart formatting and analyzer cleanup

The first pinned formatter run found that 40 of 59 checked Dart files were not in canonical Dart 3.12.2 format. CI generated the exact formatter output and that tree is committed.

The analyzer on the materialized tree then reported only five information-level style diagnostics:

- one unnecessary multi-underscore parameter pattern in `AsyncSerialQueue`;
- one unnecessary interpolation brace in the Unicode filename regression;
- two ignored-parameter style diagnostics in `external_link_service_test.dart`;
- one ignored-parameter style diagnostic in `about_page_test.dart`.

Those five findings were fixed without weakening analysis policy:

- `73cedd9c24a9a2b6c155ccf08daba7b04d823f83` — `style: simplify ignored serial queue parameters`
- `630886e786e8fe27c3d94c136ab394631af79bb6` — `style: simplify filename test interpolation`
- `28498b8b2b441bd21547b87134f1d27e78443597` — `style: simplify ignored launcher parameters`
- `e8978fef17a42c54cde17a4c7ea22fc9fdc397a1` — `style: simplify ignored About launcher parameters`

The exact final analyzer/test run is still required because the blocker-fix branch changes source, tests, workflows, bootstrap tooling, and documentation.

## PR #7 test failures and source fixes

PR #7 CI run `32627339322` reached Flutter tests after version synchronization, enforced lock restore, Drift generation, formatting, and analyzer all passed. It reported **77 tests passed and 6 failed**.

The failures were:

1. backup restore preserving a newer local note;
2. onboarding completion layout overflow;
3. onboarding persistence-failure layout overflow;
4. editor Back-save widget regression;
5. editor offset-zero formatting widget regression;
6. Markdown metadata round-trip body mismatch.

Current source now addresses those failure classes:

- `6a91dfd6fea33c18ad36dc80009fa578715ad538` guarantees monotonically advancing note update timestamps;
- `c0db1c4fdd945271c228d523fd53f2fdd6044be9` covers monotonic note update timestamps;
- `e93476b25b73df5730bb9fd0101ed560c313eadd` makes onboarding vertically scrollable;
- `7567737cfd0850f80e72fdcd01d94c9d4bb691f3` covers compact onboarding layout;
- `20bc47d9fd072914b83ed02f0e7428e5c09c1a00` adds stable editor field keys;
- PR #18 changes the two editor tests to locate `note-body-field` directly instead of assuming the body is the last `TextField`;
- PR #18 fixes NoteNest Markdown metadata body extraction and adds a leading-newline regression.

Those fixes still require the new PR #18 CI run and later exact post-merge verification before they are accepted as release evidence.

## GitHub Actions runtime baseline

The earlier maintenance pass intentionally modernized first-party action pins, but PR #7 exposed that `actions/setup-java@v6` was not a published tag and therefore failed during Android job setup.

The current production baseline is now:

- `actions/checkout@v7` in maintained workflows;
- `actions/setup-java@v5` in Android platform/release jobs;
- `actions/upload-artifact@v7` for CI coverage and release artifacts;
- `actions/dependency-review-action@v5` for pull-request dependency review;
- `subosito/flutter-action@v2` retained on its maintained major.

PR #18 updates both workflows and `tool/check_repo.py` so the repository rejects accidental return to the unpublished `setup-java@v6` pin.

The earlier modernization commits remain historical context:

- `6b56010ab29ee739d6207564ee850e30763cac80` — `ci: modernize quality workflow actions`
- `bfdf60b5d22564c18bd9c63c091fe614f7eaac01` — `ci: modernize platform build actions`
- `2ec0d69df1df3a03c48ea2042dd22675fc16601c` — `ci: modernize release workflow actions`
- `0c06fc2c1e834d75765a47cdd9b344f2f92b7f8f` — `ci: modernize security workflow actions`
- `631302f3663ee49a7e52ad483a3cccff7e5ce715` — `ci: enforce maintained workflow action majors`

The stable-Java correction is tracked separately in PR #18 rather than rewriting that history.

## File picker 12 migration

Real Android release compilation on file_picker 11 reached Java/plugin registration and failed inside the plugin's obsolete Android path. NoteNest moved to `file_picker 12.0.0`, whose current platform architecture is federated and compatible with the modern Android tooling path used by the pinned Flutter candidate.

`FileTransferService` uses the v12 API:

- `FilePicker.pickFile()` for one file.
- `PlatformFile.length()` for reported length.
- Native cached path → `BoundedFileReader`.
- No usable native path → `PlatformFile.readAsByteStream()`.
- Cumulative byte validation while streaming.
- UTF-8 decoding only after byte validation.
- Explicit MIME types for Markdown and JSON save operations.

The former `withData` / `withReadStream` picker-request assumptions are no longer needed.

Current ceilings remain:

- Markdown/text: **16 MiB**.
- JSON backup: **64 MiB**.

## iOS/iPadOS minimum version

file_picker 12 requires a newer Apple mobile baseline than the old dependency graph. NoteNest makes that constraint explicit rather than allowing build-tool defaults to decide it silently.

`tool/bootstrap_platforms.py` enforces:

- `MinimumOSVersion = 14.0` in `ios/Flutter/AppFrameworkInfo.plist`.
- `IPHONEOS_DEPLOYMENT_TARGET = 14.0` in the generated Xcode project.
- `platform :ios, '14.0'` in the Podfile where applicable.

The unsigned iOS release compile passed on the file-picker-12 diagnostic generation.

## Windows current-toolchain compatibility

The earlier Windows bootstrap problem was two-part:

1. Python could not execute Flutter's `.bat` launcher as if it were a native executable.
2. After that was fixed, current `windows-latest`/Visual Studio 2026 reached native compilation and failed on `local_auth_windows`' experimental coroutine header compatibility assertion.

`tool/bootstrap_platforms.py` now:

- resolves `.bat`/`.cmd` launchers through `COMSPEC`;
- injects `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` into the generated Windows CMake configuration for MSVC builds.

This preserves compatibility with the current hosted Windows toolchain instead of pinning an obsolete runner image.

The subsequent Windows release build on current GitHub-hosted VS2026 completed successfully during diagnostic verification.

## Android generated-runner requirements

The generated Android runner remains reproducible and fail-fast for NoteNest requirements:

- `FlutterFragmentActivity`.
- `USE_BIOMETRIC` permission.
- minimum SDK **24**.
- AppCompat dependency.
- AppCompat launch/normal themes.

The Android workflow/release jobs now use published stable `actions/setup-java@v5` with Temurin Java 17.

The file-picker-12 Android release APK build completed successfully on the earlier diagnostic candidate. PR #18 must re-prove this lane with the corrected action pin and manifest-preserving bootstrap.

## Web database/runtime engineering

`AppDatabase` uses Drift Web options for:

```dart
sqlite3.wasm
drift_worker.js
```

`tool/bootstrap_platforms.py` now:

1. snapshots the committed `pubspec.yaml` and `pubspec.lock`;
2. generates all six runners with `flutter create --no-pub`;
3. restores the committed application manifest and lock byte-for-byte even if runner generation fails;
4. reads the direct Drift version from the restored `pubspec.yaml`;
5. requires it to match reviewed `DRIFT_WEB_VERSION = "2.34.3"`;
6. downloads `sqlite3.wasm` and `drift_worker.js` from the matching Drift release;
7. rejects unexpectedly small payloads;
8. verifies the WebAssembly header;
9. rejects worker content that looks like an HTML error page;
10. writes the assets into the generated Web runner;
11. fails if the direct dependency and reviewed runtime pair drift apart.

This is version/runtime pairing plus basic payload validation. It is not a cryptographic provenance claim.

## Browser-native file boundary

Shared source does not directly require `dart:io`.

The bounded reader is split into:

- `lib/core/utils/bounded_file_reader.dart` — conditional facade;
- `lib/core/utils/bounded_file_reader_io.dart` — native implementation;
- `lib/core/utils/bounded_file_reader_stub.dart` — unsupported-path/browser implementation.

Native selected paths are read incrementally with reported and cumulative length checks. Browser/non-path file-picker content is streamed through the file-picker platform abstraction with the same application byte ceilings.

## App-lock capability boundary

The current `local_auth` dependency does not implement every NoteNest target.

NoteNest uses:

- `lib/services/app_lock_service.dart` — conditional facade;
- `lib/services/app_lock_service_io.dart` — native wrapper;
- `lib/services/app_lock_service_stub.dart` — Web/non-IO unavailable implementation.

Current behavior:

- supported native implementations authenticate through OS APIs;
- Web reports unavailable;
- Linux reports unavailable with the current dependency;
- stale `appLockEnabled=true` preferences do not trap unsupported platforms;
- Settings prevents unsupported enablement while allowing stale enabled state to be turned off.

No custom browser/Linux password system was added merely to advertise parity. App lock remains UI access control, not database encryption.

## Data-integrity hardening retained in 2.0.12

### Editor

- Debounced submissions.
- FIFO asynchronous save ordering.
- Immutable draft capture per submitted save.
- Stale completion cannot mark a newer draft saved.
- Normal Back waits for current draft persistence.
- Export/history waits for current draft persistence.
- Save failure keeps the editor open with feedback.
- Missing-note load failure becomes retryable.
- Offset-zero empty-first-line Markdown prefix behavior is covered.
- Stable widget keys identify title/body/folder/tag fields for deterministic tests.

### Notes lifecycle

- Create/open/pin/favorite/archive/trash/restore/delete/undo failures are contained.
- Trash clears incompatible lifecycle state.
- A trashed note cannot be pinned.
- Collection filter metadata uses the same lifecycle semantics as collection listing.
- Stored update timestamps advance monotonically, preserving deterministic conflict ordering when rapid updates occur within the same wall-clock second.

### Settings and onboarding

- Preference writes are serialized.
- Reported setter failure is treated as failure.
- Applicable optimistic state rolls back.
- Stale failures do not overwrite newer state.
- Onboarding persists before the UI leaves onboarding.
- Onboarding content is vertically scrollable for compact-height/large-text layouts.

### Markdown metadata

- NoteNest metadata remains front matter rather than rich-text storage.
- Metadata decoding removes one generated blank separator after recognized NoteNest front matter.
- A real leading newline in the note body remains part of the body.
- Unrelated YAML-style front matter remains ordinary Markdown and is not consumed as NoteNest metadata.

### Backup

Restore validates before writes:

- application identity;
- backup schema;
- explicit UTC root export timestamp;
- field/list/value types;
- canonicalized tags;
- duplicate/whitespace-polluted IDs;
- version-note relationships;
- 32-bit ARGB color range;
- UTC note/version timestamps;
- timestamp order;
- lifecycle invariants.

Restore is transactional and keeps newer local note revisions during conflicts.

## Repository and documentation contract

The exhaustive tracked-file catalog contains **109 files**. `pubspec.lock` is included as release source.

The principal public/engineering surfaces are synchronized with the locked file-picker-12 and published-actions baseline:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/repository-reference.md`
- `docs/setup.md`
- `docs/development.md`
- `docs/testing.md`
- `docs/release.md`
- `docs/github.md`
- `docs/troubleshooting.md`
- `docs/releases/2.0.12.md`
- this handoff

## Diagnostic automated evidence

### Platform builds before PR #7

Diagnostic file-picker-12 platform run: **32360941439**.

Completed build steps:

- Android release APK: **passed**.
- Linux release: **passed**.
- Windows release: **passed**.
- macOS release: **passed**.
- unsigned iOS release: **passed**.
- Chrome Web platform smoke: **passed**.
- Web release: **passed**.

This run proves the Android file-picker-12 path, Windows current-MSVC fix, explicit iOS 14 floor, Linux desktop build, and Web runtime generation compiled together on that reviewed dependency generation.

It is not the final release run because later lock-enforcement, documentation, source fixes, and workflow changes followed.

### Security before PR #7

Diagnostic security run: **32360941512**.

- Repository secret scan: **passed**.
- Dependency review: **passed**.

### Quality/materialization before PR #7

Diagnostic CI run: **32360941601**.

Reached successfully:

- Flutter 3.44.7 setup.
- Version synchronization.
- Dependency resolution for file-picker-12 graph.
- Lock artifact generation.
- Drift code generation.
- Exact lock/formatter materialization.
- Canonical formatting verification.

Analyzer then stopped the run on five style-level infos. Those findings were corrected on `main` without weakening analysis policy.

### PR #7 exact run

Frozen PR #7 base candidate: `0c390135cfe5af2f65341a978c8380956e026687`.  
Verification head: `81b3e03329b4612b2ef95c9e64f22b1617616515`.

Runs:

- CI `32627339322`: **failed** at Flutter tests after version sync, lock restore, Drift generation, formatting, and analyzer succeeded; 77 tests passed, 6 failed.
- Platform builds `32627339327`: **failed**; Android failed resolving unpublished `actions/setup-java@v6`, while other lanes failed locked restoration after runner generation rewrote the application manifest.
- Security `32627339343`: **passed**.

These runs are diagnostic and superseded by the blocker-fix work on PR #18.

## PR #18 blocker-fix verification

PR #18 starts from `main` at:

`20bc47d9fd072914b83ed02f0e7428e5c09c1a00`

Its purpose is to prove the corrections found necessary by PR #7 without pretending that a blocker-fix PR is itself the final stable release certification.

PR #18 must pass:

- CI quality including all Flutter tests and repository gates;
- security/dependency review;
- Android release compile with stable `setup-java@v5`;
- Linux release compile after manifest-preserving runner bootstrap;
- Windows release compile after manifest-preserving runner bootstrap;
- macOS release compile after manifest-preserving runner bootstrap;
- unsigned iOS release compile after manifest-preserving runner bootstrap;
- Chrome Web smoke after manifest-preserving runner bootstrap;
- Web release compile after manifest-preserving runner bootstrap.

If PR #18 is green, merge the blocker fixes into `main`. Then create/re-align a separate verification-only branch from the exact resulting `main` SHA plus one non-functional path-filter trigger marker. Only that post-merge exact head may become final automated release evidence.

## Issue #8 status

Issue #8 originally tracked the missing application lockfile.

The technical lockfile work is implemented:

- genuine lock generated by pinned Flutter;
- file-picker-12 final graph represented;
- lock committed to `main`;
- lock cataloged in the 109-file reference;
- repository policy requires it;
- quality/platform/release workflows enforce it;
- temporary CI write/materialization path removed;
- PR #18 preserves the manifest/lock pair across generated runner creation before enforced restoration.

Issue #8 should remain open until the new exact post-merge automated verification confirms the locked candidate. Closing #8 does **not** mean the stable tag may be created; manual/runtime/distribution checks remain.

## Issue #15 status

Issue #15 tracked GitHub Actions runtime-major modernization.

The prior implementation incorrectly selected unpublished `actions/setup-java@v6`. PR #7 proved that tag could not be resolved. PR #18 corrects the production baseline to:

- checkout v7 across maintained workflows;
- setup-java v5 where Java is needed;
- upload-artifact v7 for coverage/release artifacts;
- dependency-review-action v5;
- Flutter setup v2;
- repository policy enforcement for the reviewed **published** action-major baseline;
- GitHub operations, roadmap, changelog, and handoff documentation synchronized.

Issue #15 should remain open until PR #18 and the later exact post-merge candidate prove CI/security/all six platform lanes green with the corrected published runtime baseline.

## Exact final automated verification still required

After PR #18 is merged, the new exact verification-only run must prove on one frozen candidate:

### CI quality

- version synchronization;
- `flutter pub get --enforce-lockfile`;
- Drift generation;
- canonical formatter;
- analyzer;
- Flutter tests with coverage;
- repository policy, including published maintained action-major checks;
- 109-file repository reference;
- Markdown links;
- secret scan;
- coverage artifact upload.

### Security

- repository security baseline;
- dependency review.

### Platform builds

- Android release APK;
- Linux release;
- Windows release;
- macOS release;
- unsigned iOS release;
- Chrome Web platform smoke;
- Web release.

Do not change `main` after that final run and then cite the old run as evidence for the new SHA.

## Manual/runtime/accessibility blockers after automation

Even with final GitHub Actions green, stable 2.0.12 still requires representative validation using fictional data:

1. First-run onboarding persistence.
2. Create/edit/autosave/rapid edit/newest-draft behavior.
3. Save failure blocking Back navigation.
4. Markdown first-line/offset-zero actions.
5. Folder/tag/color/pin/favorite lifecycle behavior.
6. Search, archive, trash, restore, delete, version history.
7. Native Markdown/text selection/import/export and >16 MiB rejection.
8. Native JSON backup export/restore and >64 MiB rejection.
9. Browser import/download and bounds behavior.
10. Web create/edit/search after reload and browser restart on the intended deployment origin.
11. Web `sqlite3.wasm` MIME and worker/WASM reachability.
12. Actual Web storage backend/retention behavior.
13. Supported app-lock behavior on representative Android/iOS/macOS/Windows devices.
14. Web/Linux unavailable app-lock behavior remains usable.
15. External repository/funding/release/mail actions and failure paths.
16. Keyboard/browser focus and resize behavior.
17. Screen-reader semantics where practical.
18. Large text/browser zoom.
19. Light/dark themes and reduced motion.
20. Verified runtime screenshots from the exact candidate.
21. Signing/notarization/store readiness status.
22. Final artifacts and SHA-256 checksums.

## Stable-tag rule

Do **not** create `v2.0.12` merely because source code or GitHub Actions are green.

The stable tag should point only to the exact commit for which:

- final automated verification is green;
- representative runtime/accessibility/Web deployment checks are recorded;
- signing/artifact/checksum status is recorded;
- release notes truthfully state the verified scope.

If a problem is found after a published stable tag, do not move the tag. Prepare a new patch release.

## Current engineering statement

NoteNest 2.0.12 is a reproducibly locked, six-platform Flutter release candidate with local-first notes/search/versioning, ordered editor/settings persistence, validated conflict-safe backup/restore, bounded native/browser file handling, safe cross-platform app-lock capability modeling, generated six-target runner policy, Drift Web SQLite support, current Windows/iOS/Android toolchain hardening, published maintained GitHub Actions majors, deterministic repository quality gates, and a complete 109-file tracked-source contract.

The remaining release work is **verification and distribution readiness**, not missing core architecture. Until PR #18, the later exact post-merge automated verification, and the manual/runtime/distribution checklist are complete, the truthful status remains:

**2.0.12 release candidate — not stable.**
