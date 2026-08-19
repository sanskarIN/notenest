# NoteNest — 2.0.12 Final Engineering Handoff

Last updated: 2026-08-19
Target application version: **2.0.12**
Flutter package version: **2.0.12+2012**
Pinned Flutter SDK: **3.44.7**
Active development branch: `main`
Tracked-file documentation checkpoint: **103 tracked files cataloged**
Final verification PR: **#7 — `ci: verify final NoteNest 2.0.12 candidate`**
Superseded verification PRs: **#5 and #6 — closed without merge**
Stable tag status: **not yet tagged**

## Current release status

NoteNest is prepared as a **2.0.12 release candidate**.

The implementation, storage invariants, editor persistence, settings/onboarding persistence, file-import bounds, backup validation, external-link handling, lifecycle ownership, repository tooling, regression suite, public documentation, security/privacy documentation, release documentation, and CI/native-build configuration have received repeated final hardening passes.

A stable `v2.0.12` tag is intentionally **not** created yet. Completed green quality/security/native CI evidence plus the documented real-platform, accessibility, screenshot, signing, and release checks are still required on the exact final candidate.

Do not describe the current candidate as fully verified, bug-free, perfectly secure, or stable until those checks pass on the exact release commit.

## 2026-08-19 final continuation — lifecycle, editor boundary, automation, and documentation hardening

This continuation audited the exact current tracked tree and release tooling again rather than assuming the prior release-candidate checkpoint had no remaining defects.

No late feature churn was introduced merely to increase the feature count. The final changes concentrate on correctness, resource ownership, regression protection, reproducible platform generation, CI coverage, and documentation truthfulness.

### Root dependency teardown fixed

`AppDependencies` already defined the final cleanup boundary for the settings controller and Drift database, and the architecture documentation described it as the composition root that owns those resources. The root `NoteNestApp`, however, previously removed its settings listener without invoking `AppDependencies.dispose()` when the root state was permanently removed.

`lib/app/app.dart` now:

1. Removes the settings listener.
2. Delegates final owned-resource cleanup to `AppDependencies.dispose()`.
3. Uses `unawaited(...)` because Flutter widget `dispose()` is synchronous while the database close path is asynchronous.
4. Calls `super.dispose()` after scheduling the owned cleanup.

This closes the ownership gap between the documented architecture and the actual root lifecycle.

Commit:

- `f961c096abed299cf97067e7bc997c68de5327fb` — `fix: dispose root app dependencies`

### Editor first-line formatting boundary fixed

A caret-position boundary bug remained in `_prefixCurrentLine`.

When the note body began with a newline and the caret was exactly at offset `0`, the previous `lastIndexOf` calculation searched from offset `0`. That could identify the leading newline and derive line start `1`, causing Heading/Bullet/Checklist formatting to target the second line rather than the actual empty first line.

The current implementation handles offset zero explicitly:

```dart
final int lineStart =
    caret == 0 ? 0 : _body.text.lastIndexOf('\n', caret - 1) + 1;
```

A widget regression now creates a note whose body is `\nSecond line`, positions the editor body caret at offset zero, invokes the Heading action, and requires the body to become:

```text
## 
Second line
```

Commits:

- `e7a3ac280055116b127429a589407b9d3a0d555a` — `fix: format the actual first editor line`
- `9d9757eaf4862be7359a5b8988bbdefee93cea9a` — `test: cover formatting at editor start`

### Asset-only native-build verification gap closed

The platform-build workflow previously watched application/build/bootstrap paths but not bundled assets. A branding or other bundled asset change could therefore reach `main` without automatically exercising the native compile matrix.

`.github/workflows/platform-builds.yml` now includes:

```yaml
- "assets/**"
```

for both pull-request and push path filters.

Commit:

- `0d74e68f3d9520af143f131412eba8a425c6cd69` — `ci: verify platform builds for asset changes`

### Flutter SDK workflow-pin drift is now machine-rejected

The repository already pinned Flutter `3.44.7` in `.flutter-version` and the CI/platform/release workflows, but `tool/check_version_sync.py` previously protected application/release metadata rather than proving that all workflow Flutter pins matched the project pin.

The checker now validates:

- `.flutter-version` exists.
- The file contains exactly `MAJOR.MINOR.PATCH`.
- CI, platform-build, and release workflow files exist.
- Each workflow declares at least one `flutter-version` value.
- Every discovered Flutter action pin exactly matches `.flutter-version`.
- Existing package/UI/changelog/release-note synchronization remains enforced.

Commit:

- `2ddf3f0179a502740d1e7f22d70363a62a836162` — `tooling: verify Flutter workflow pin synchronization`

### Native runner bootstrap now fails on template drift

`tool/bootstrap_platforms.py` intentionally generates native runners from the pinned Flutter SDK rather than committing stale runner templates. The previous patching logic could become fragile if upstream Flutter templates changed in a way that made a string replacement stop matching.

The bootstrap now validates the required generated/patch state and raises an error rather than printing success when a required platform patch was not applied.

Android checks now protect:

- Expected generated `MainActivity.kt` path.
- `FlutterFragmentActivity` import and class inheritance for local authentication.
- `USE_BIOMETRIC` permission.
- `minSdk = 24`.
- AppCompat dependency.
- AppCompat Launch/Normal themes across generated styles files.

The iOS check protects:

- Expected generated `Info.plist` path.
- Non-empty `NSFaceIDUsageDescription`.

This does not remove the need for native compile/runtime tests; it prevents a changed Flutter template from being silently accepted as correctly patched.

Commit:

- `dd0f407d1cfa4aad2956178b61f3c5d5409aec60` — `tooling: fail fast on native runner template drift`

### Repository policy baseline expanded

`tool/check_repo.py` now requires the full current release/documentation/automation baseline rather than a narrower subset.

The required set now explicitly protects items including:

- `.flutter-version`
- `build.yaml`
- canonical logo/layout-reference assets
- `docs/github.md`
- platform-build, release, and security workflows
- issue-template configuration
- native runner bootstrap
- repository/reference/version/link/security maintenance tools

Existing checks for required README identity/contact/license text, unfinished Dart markers, generated `.g.dart` policy, and security-relevant ignore rules remain.

Commit:

- `7e7d8a63003acc4c8eaf83768ea80ff7b852b574` — `tooling: enforce the full repository baseline`

### Final documentation synchronized

The release documentation was updated to describe the actual final code/tooling rather than the pre-fix state.

Synchronized surfaces include:

- `CHANGELOG.md`
- `README.md`
- `docs/development.md`
- `docs/testing.md`
- `docs/release.md`
- `docs/releases/2.0.12.md`
- `docs/repository-reference.md`
- this `what_changed.md`

The documentation now records, where relevant:

- root dependency teardown ownership
- offset-zero editor formatting regression
- exact Flutter workflow-pin checking
- asset-triggered native builds
- fail-fast native bootstrap verification
- complete repository baseline enforcement
- exhaustive tracked-file reference gate
- the exact quality-gate command list
- remaining manual/native verification boundaries

Documentation commits before this final handoff commit:

- `0b915e68f0d1f1cc14313fb119935acdeaadb425` — `docs: record final lifecycle and verification hardening`
- `15d4f61f7e113e73ec1159a05d6750936f5aaae6` — `docs: synchronize 2.0.12 final hardening notes`
- `2f2efd03b1dd397575ac9eb7f200a2ea8cb90bf9` — `docs: synchronize final regression and CI coverage`
- `27b64fb924ae3e6551b24a20ca881e176486cb67` — `docs: align release gate with final automation`
- `f8fb959f7c2ea4c08d5ad6081620820f6970f151` — `docs: refresh exhaustive repository reference`
- `b0fd86c5feb2de7ea59a0d360dab888f323b16ea` — `docs: align public quality gate with final checks`
- `4caa3597e3844eb299c4a9cb5493ec3021e69b39` — `docs: align development guide with final gates`

## Previous 2026-08-19 continuation — exhaustive repository documentation and lifecycle invariants

The immediately preceding continuation performed a full tracked-tree documentation audit and tightened the live note lifecycle boundary.

### Exhaustive tracked-file reference

`docs/repository-reference.md` is the authoritative file-by-file repository map. The repository currently has **103 tracked files**, and every tracked path is intended to appear exactly once in that catalog.

The reference covers:

- Root configuration and governance files.
- GitHub funding, issue templates, pull-request template, Dependabot, and workflows.
- Branding/documentation assets.
- Every engineering/product/release document and ADR.
- Every `lib/` application, core, data, domain, feature, service, and reusable-widget source file.
- Every tracked automated test file.
- Every repository-maintenance tool.
- `what_changed.md` itself.
- Generated/untracked boundaries and why native runners/generated Drift output are excluded from the tracked-file catalog.
- Architecture orientation and version-domain separation.
- A source-of-truth/change-impact matrix.
- High-value repository invariants.
- Exact audit commands and the limitations of what the reference checker proves.

`tool/check_repository_reference.py` makes this contract executable. It compares `git ls-files` with catalog entries and fails for:

- A tracked path with no documentation entry.
- A stale catalog entry for a path no longer tracked.
- A duplicate catalog path.
- A missing repository-reference document.

The CI quality workflow runs this checker after repository policy validation and before Markdown-link/security checks.

### Trashed-note pin invariant fixed

The backup validator already rejected the impossible `pinned + trashed` lifecycle state, and `trash()` already cleared pin state. The live repository boundary previously still allowed a caller to invoke `setPinned(id, value: true)` on a note that was already trashed.

`NoteRepository.setPinned` now:

1. Allows unpinning normally.
2. Performs the pin-enable check inside a database transaction.
3. Loads the current note state.
4. Throws `ValidationException('Trashed notes cannot be pinned.')` when applicable.
5. Applies the pin only when the lifecycle state is valid.

Regression coverage in `test/data/note_repository_test.dart` trashes a note, verifies pinning throws `ValidationException`, and verifies the stored note remains trashed and unpinned.

Focused commits from that continuation:

- `88137c4f3544960d3bce9f5e78c7d08c300de80c` — `tooling: enforce exhaustive repository reference`
- `658c2d083f21e070c6d028032fde35f01835cf98` — `fix: prevent pinning trashed notes`
- `c7ba995e925fcdafde7a9a56800a6bd1da74a9bf` — `test: cover pinning invariant for trash`
- `72b16f97a3e58ee9422edbccda877a9760787c34` — `docs: add exhaustive tracked-file repository reference`
- `ed99f470492a35a3cf15a038352a69d2ab608b2d` — `tooling: require repository reference documentation`
- `60c6bea124035c6f84f42ce5a57c8b42af9c4cf0` — `ci: enforce exhaustive documentation coverage`
- `7f9f0e0d814410c18e8bf732c505de4105c43db5` — `docs: enforce file-reference updates for contributors`
- `758b0855889e292fdf2bedc024f25a3e97716bf9` — `docs: add repository-reference PR gate`
- `3ebecd0f9dc74c6d82c431f3cd42dd2fda54d4aa` — `docs: record exhaustive reference and lifecycle hardening`
- `4f8d0f584c193c3d10cead525e6b453b6de9d09f` — `docs: update 2.0.12 exhaustive handoff`

Historical verification-only checkpoint from that phase:

- `a989a304d85aa8ae2ce7eae34fc424337ab83320` — `ci: trigger latest 2.0.12 platform verification`

That older checkpoint is superseded and is not final release evidence.

## Version and toolchain metadata

The current application version surfaces agree by design:

- `pubspec.yaml`: `2.0.12+2012`
- `AppStrings.version`: `2.0.12`
- `CHANGELOG.md`: `## [2.0.12] - Release candidate`
- `docs/releases/2.0.12.md`: exact package and visible version values

The toolchain pin is:

- `.flutter-version`: `3.44.7`
- `.github/workflows/ci.yml`: Flutter `3.44.7`
- `.github/workflows/platform-builds.yml`: Flutter `3.44.7`
- `.github/workflows/release.yml`: Flutter `3.44.7`

`tool/check_version_sync.py` now enforces both groups: application/release metadata and exact Flutter workflow-pin synchronization.

## Major 2.0.12 hardening inventory

### Editor data integrity

- Every submitted editor save captures an immutable draft.
- `AsyncSerialQueue` executes submitted writes in order.
- The queue supports typed task results.
- Stale save completions cannot mark newer visible content as already saved.
- Lifecycle/background saves use the same ordered queue.
- Normal Back navigation captures and saves the current draft before allowing the route to pop.
- A failed final save keeps the editor open with user-visible feedback.
- The pop guard waits for a rebuilt `canPop` frame before the programmatic pop.
- Version-history and Markdown-export actions require a successful current-draft save before they start.
- Initial note-load failure shows a retryable error instead of an endless spinner.
- Version-query, restore, and export errors are contained with user feedback.
- Current-line prefix formatting correctly handles caret offset zero when the document begins with an empty first line.

Regression coverage:

- `test/core/async_serial_queue_test.dart`
- `test/widgets/note_editor_save_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`

### Notes browser reliability

The notes browser contains failures around create/open/pin/favorite/archive/trash/undo/restore/permanent-delete/empty-trash operations and reports concise SnackBar feedback instead of leaking asynchronous storage errors.

The HomeShell floating-action new-note path has the same protection.

### Collection-aware filter metadata

Folder/tag choices use the same collection predicate as note listing:

- All Notes: active/non-archived metadata.
- Favorites: active favorites only.
- Archive: archived/non-trashed metadata.
- Trash: trashed metadata.

Switching collection clears stale folder/tag selections from the previous collection.

Regression coverage:

- `test/data/note_repository_test.dart`
- `test/features/notes/notes_controller_test.dart`

### Collection-specific empty states

All Notes can create/import. Favorites, Archive, and Trash do not offer creation/import actions whose result would be hidden by the current collection.

Regression coverage:

- `test/widgets/notes_page_empty_state_test.dart`

### Settings persistence ordering and rollback

The injectable `SettingsStore` boundary separates settings state from the preference plugin.

`AppSettingsController`:

- Loads settings atomically.
- Serializes preference mutations.
- Tracks the last successfully persisted value.
- Rolls back a failed optimistic theme/text-size/reduced-motion/app-lock value when appropriate.
- Does not let an older failed write overwrite a newer requested value.

`SettingsRepository` treats a reported failed preference setter result as `StorageException` rather than silently assuming persistence succeeded.

Settings UI reports persistence failure and explains that the previous saved value was restored.

Regression coverage:

- `test/app/app_settings_controller_test.dart`
- `test/data/settings_repository_test.dart`

### Persistence-first onboarding

- Completion is persisted before the app leaves onboarding.
- A failed write keeps onboarding visible and retryable.
- The completion button enters a busy state while saving.
- Failure produces user-visible feedback.

Regression coverage:

- `test/app/app_settings_controller_test.dart`
- `test/widgets/onboarding_page_test.dart`

### Dependency bootstrap and final lifecycle cleanup

`AppDependencies.create()` disposes the settings controller and closes the database if initial settings loading fails before dependencies are returned.

`NoteNestApp.dispose()` now delegates final cleanup to `AppDependencies.dispose()` so normal permanent root teardown also releases the owned settings/database resources.

### Bounded native imports

Native Markdown/text and backup imports use `withData: false` and a cached path.

`BoundedFileReader`:

1. Checks reported file length.
2. Reads incrementally from disk.
3. Re-checks accumulated bytes after each chunk before adding them to the final buffer.
4. Converts filesystem failures to `ImportExportException`.

Limits:

- Markdown/text: **16 MiB**
- NoteNest JSON backup: **64 MiB**

Strict UTF-8 decoding and structured parsing occur only after the bounded read.

Regression coverage:

- `test/core/import_limits_test.dart`
- `test/core/bounded_file_reader_test.dart`

### Backup/restore validation

Before restore writes, the parser validates:

- Root JSON object.
- `app == "NoteNest"`.
- Supported backup schema.
- Valid explicit-UTC root `exportedAt`.
- Notes/version list shape.
- Required field types.
- Serialized tag lists.
- Canonical imported tags: trim, remove empty, deduplicate, sort, re-encode.
- Non-empty unique note IDs without surrounding whitespace.
- Version IDs without surrounding whitespace and valid note relationships.
- `colorValue` null or within 32-bit ARGB range.
- Explicit UTC note/version timestamps ending in `Z`.
- Note `updatedAt >= createdAt`.
- No archived+trashed state.
- No pinned+trashed state.

Only after validation does the restore transaction begin. Newer local notes continue to win conflicts and duplicate snapshots are not added again.

The live `NoteRepository` boundary also rejects enabling pin state on an already-trashed note, so valid-state enforcement is not limited to backup import.

Regression coverage:

- `test/data/backup_repository_test.dart`
- `test/data/note_repository_test.dart`

### Cross-platform/Unicode-safe Markdown export names

`SafeFileName`:

- Replaces invalid/control characters.
- Normalizes whitespace.
- Removes trailing dots/spaces.
- Protects Windows reserved names such as `CON`, `NUL`, `COM1`, and `LPT9`.
- Preserves Unicode.
- Enforces the basename limit.
- Falls back to `untitled-note` when needed.
- Truncates by Unicode code points rather than splitting a surrogate pair at the boundary.

Regression coverage:

- `test/core/safe_file_name_test.dart`

### Safe external-link boundary

`ExternalLinkService` centralizes user-triggered repository, funding, business-email, support-email, and Releases links.

It accepts an injectable launcher, uses external-application launch mode by default, and converts launcher refusal/exception into a safe `false` result. About and Settings show failure feedback.

Regression coverage:

- `test/services/external_link_service_test.dart`
- `test/widgets/about_page_test.dart`

### Note-color accessibility

The custom editor palette uses:

- 48 logical-pixel minimum custom target.
- Explicit selected semantics.
- Visible checkmark for selection.
- Reset cue for the default/no-color choice.
- Descriptive tooltips/semantic labels.

Regression coverage:

- `test/widgets/note_editor_accessibility_test.dart`

## Release and repository engineering

### Exact Flutter pin

Flutter `3.44.7` is pinned in:

- `.flutter-version`
- `.github/workflows/ci.yml`
- `.github/workflows/platform-builds.yml`
- `.github/workflows/release.yml`

`tool/check_version_sync.py` rejects drift between those workflow pins and `.flutter-version`.

### CI quality gate

Configured sequence includes:

```bash
python3 tool/check_version_sync.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python3 tool/check_repo.py
python3 tool/check_repository_reference.py
python3 tool/check_markdown_links.py
python3 tool/security_scan.py
```

### Native platform-build gate

The platform workflow generates runners through the fail-fast bootstrap and compiles:

- Android release APK
- Linux release build
- Windows release build
- macOS release build
- iOS release compile with `--no-codesign`

Relevant source/build/bootstrap/**asset** changes trigger this matrix.

### Repository tools

- `tool/bootstrap_platforms.py` — reproducible runner generation plus required native-patch verification.
- `tool/check_version_sync.py` — application/release metadata plus Flutter workflow-pin synchronization.
- `tool/check_repo.py` — required repository/documentation/automation baseline and source/generated/ignore policy.
- `tool/check_repository_reference.py` — exhaustive tracked-file catalog coverage.
- `tool/check_markdown_links.py` — deterministic repository-local Markdown link validation.
- `tool/security_scan.py` — lightweight tracked credential-pattern scan.

## Documentation baseline

The deep documentation baseline includes:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `SECURITY.md`
- `PRIVACY.md`
- `SUPPORT.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `.github/pull_request_template.md`
- `docs/accessibility.md`
- `docs/architecture.md`
- `docs/setup.md`
- `docs/development.md`
- `docs/testing.md`
- `docs/release.md`
- `docs/releases/2.0.12.md`
- `docs/repository-reference.md`
- `docs/github.md`
- `docs/performance.md`
- `docs/troubleshooting.md`
- all tracked ADRs
- `what_changed.md`

Every tracked file—not only the documents above—is individually cataloged in `docs/repository-reference.md`.

## Current regression inventory

### Core

- `test/core/app_logger_test.dart`
- `test/core/async_serial_queue_test.dart`
- `test/core/bounded_file_reader_test.dart`
- `test/core/import_limits_test.dart`
- `test/core/markdown_document_codec_test.dart`
- `test/core/markdown_lite_test.dart`
- `test/core/safe_file_name_test.dart`

### Services

- `test/services/external_link_service_test.dart`

### Application/controllers

- `test/app/app_settings_controller_test.dart`
- `test/features/notes/notes_controller_test.dart`

### Data

- `test/data/backup_repository_test.dart`
- `test/data/note_repository_test.dart` — includes the trashed-note pinning regression
- `test/data/settings_repository_test.dart`

### Widgets

- `test/widgets/about_page_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`
- `test/widgets/note_editor_save_test.dart` — includes save-before-pop, missing-note load recovery, and first-line formatting boundary coverage
- `test/widgets/notes_page_empty_state_test.dart`
- `test/widgets/onboarding_page_test.dart`

This inventory describes tests present in the repository. It does **not** claim a green Flutter run until CI or a Flutter-enabled host executes them successfully against the exact final candidate.

## Static source-review signals

The final GitHub code-search pass found no indexed matches for:

- `TODO:`
- `FIXME:`
- `HACK:`
- `UnimplementedError`

Earlier hardening removed the native import `withData: true` path and direct feature-level external launcher calls.

The repository policy checker rejects `TODO:`, `FIXME:`, and `HACK:` markers in tracked `lib/**/*.dart` source.

These are static review signals, not formatter/analyzer/test/native-runtime substitutes.

## Local verification limitation

A clean clone was attempted in the execution container so the repository's Python tools could run directly. The container could not resolve `github.com` because outbound DNS/network access was unavailable there.

Therefore the following local commands are **not** claimed as successfully executed in that container:

```bash
python tool/check_version_sync.py
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

The exhaustive repository reference was independently constructed against the GitHub tracked tree and is intended to contain one entry for each of the 103 tracked files. The authoritative automated proof remains the CI execution of `tool/check_repository_reference.py` on the checked-out candidate.

The connected GitHub API remained available for repository inspection and edits.

The execution environment also does not provide the full Flutter/native build toolchain needed to claim local formatter/analyzer/tests/native builds or real-device verification.

## Final PR-based 2.0.12 verification

The verification history is intentionally explicit so an older green/queued run cannot be mistaken for final release evidence.

- PR **#5** — closed without merge; historical pre-continuation verification only.
- PR **#6** — closed without merge; superseded after the later lifecycle/editor/automation/documentation hardening.
- PR **#7 — `ci: verify final NoteNest 2.0.12 candidate`** — the active final verification path.
- PR #7 branch: `verify/2.0.12-final`.
- The verification branch is maintained as the exact latest `main` candidate plus only a non-functional comment in `lib/main.dart`.
- That comment deliberately matches the `lib/**` platform-build path filter so CI, security, and native platform workflows run without introducing a product change.
- The verification-only marker must not be merged back into `main`.
- If `main` changes, the branch must be realigned before any PR #7 result is considered final release evidence.

At initial PR #7 creation the quality, security, and platform-build workflows were queued. Because this handoff itself updates `main`, the verification branch is realigned after the handoff commit and a fresh head-specific run set becomes authoritative.

Run IDs are deliberately not hard-coded here as the definition of final success: the authoritative evidence is the completed check set attached to the **current PR #7 head commit** after realignment. No green result is claimed until those current-head jobs complete successfully.

## Commit identity

Requested project commit email: `sanskarin@outlook.in`.

GitHub branch metadata for the latest `main` checkpoint inspected during this continuation reported the commit author and committer as:

```text
Sanskar <sanskarin@outlook.in>
```

This matches the requested project email. For local Git work, continue to use:

```bash
git config user.email "sanskarin@outlook.in"
```

## Remaining stable 2.0.12 blockers

These are verification/distribution tasks rather than intentionally omitted core functionality:

1. Obtain completed green CI/security/platform-build results on the **current head of PR #7** after it is aligned to the final `main` handoff commit.
2. Fix any formatter/analyzer/test/native failure those current-head jobs reveal before release.
3. Run the clean-checkout Python and Flutter quality gates on a Flutter-enabled host, including `tool/check_repository_reference.py`.
4. Verify rapid-edit → immediate Back saves the newest draft before navigation.
5. Verify first-line Heading/Bullet/Checklist formatting at caret offset zero when the note starts with an empty first line.
6. Verify a real/simulated editor storage failure blocks Back/export/history safely.
7. Verify root app teardown closes the owned settings/database resources without disposal/lifecycle errors where a controlled lifecycle test is practical.
8. Verify note-browser mutation failure feedback.
9. Verify settings persistence ordering/rollback and persistence-first onboarding on representative targets.
10. Verify collection-scoped filters, including Trash metadata and the no-pinned-trash lifecycle invariant.
11. Verify bounded oversized Markdown/backup rejection through real picker/provider behavior.
12. Verify backup export/restore and malformed timestamp/color/ID/lifecycle rejection using fictional data.
13. Verify repository/funding/mail/release links and no-handler behavior.
14. Verify app lock on supported and unsupported targets.
15. Complete keyboard, screen-reader, large-text, light/dark, reduced-motion, and custom-color accessibility review.
16. Replace illustrative layout artwork with verified runtime screenshots before making screenshot claims.
17. Prepare distribution signing status/artifacts and SHA-256 checksums.
18. Create `v2.0.12` only on the exact commit that passed the full release checklist.

## Release-readiness statement

NoteNest is now a deeply hardened **2.0.12 release candidate** with local-first persistence/search, collection-aware organization, deterministic editor/settings persistence, save-before-navigation protection, first-line editor boundary regression protection, snapshot history, strict conflict-safe backup/restore validation, bounded native imports, Unicode-safe exports, resilient external links, explicit root resource teardown, responsive Material 3 UI, accessibility/privacy controls, startup/error-state handling, extensive regression coverage, an exhaustive machine-enforced 103-file repository reference, exact Flutter workflow-pin synchronization, fail-fast generated native-runner patch verification, asset-aware multi-platform build CI, and synchronized release documentation.

The remaining blockers are explicit automated/native/manual verification and distribution checks. Stable `v2.0.12` must not be published until those checks complete successfully on the exact release commit.
