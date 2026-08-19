# NoteNest — 2.0.12 Final Engineering Handoff

Last updated: 2026-08-19
Target application version: **2.0.12**
Flutter package version: **2.0.12+2012**
Pinned Flutter SDK: **3.44.7**
Active development branch: `main`
Stable tag status: **not yet tagged**

## Current release status

NoteNest is now prepared as a **2.0.12 release candidate**.

The implementation, repository tooling, regression suite, public documentation, security/privacy documentation, and release documentation have been deeply hardened. A stable `v2.0.12` tag is intentionally not created yet because completed green Flutter/native CI evidence and the documented manual platform/accessibility checks are still required.

Do not describe the current candidate as fully verified, bug-free, or stable until those checks pass on the exact release commit.

## Version 2.0.12 metadata

The release-candidate version surfaces now agree:

- `pubspec.yaml`: `2.0.12+2012`
- `AppStrings.version`: `2.0.12`
- `CHANGELOG.md`: `## [2.0.12] - Release candidate`
- `docs/releases/2.0.12.md`: exact package and visible version values

`tool/check_version_sync.py` was added so future release bumps cannot silently update only one of these surfaces. CI runs the version synchronization check before Flutter dependency/build work.

The checker also requires a positive build number and matching version-specific release notes.

## Major 2.0.12 engineering hardening

### Editor save ordering and final-draft protection

The editor now protects against overlapping asynchronous saves:

- Every submitted save captures an immutable draft.
- `AsyncSerialQueue` executes submitted writes in order.
- A stale save completion cannot mark newer visible content as already saved.
- Lifecycle/background saves use the same queue.
- The serial queue now supports typed task results so callers can require a successful save.

Normal back navigation is guarded:

- The editor captures/saves the current draft before permitting the route to pop.
- If the save fails, the editor stays open.
- The user receives `Could not save this note. Resolve the save problem before leaving.`
- The pop guard is rebuilt before the programmatic pop to avoid a stale `canPop` frame.

Version-history and Markdown-export actions now require the current draft to save successfully before starting. This prevents those actions from proceeding against stale persisted content after a save failure.

Initial note-load failures no longer leave an endless progress indicator. The editor shows a retryable `Could not open this note` state.

Version-query, restore, and export failures are contained with user-visible feedback.

Regression coverage includes:

- `test/core/async_serial_queue_test.dart`
- `test/widgets/note_editor_save_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`

### Notes browser mutation reliability

The notes browser now contains failures around:

- Create note.
- Open note.
- Pin/unpin.
- Favorite/unfavorite.
- Archive/unarchive.
- Move to trash.
- Undo trash.
- Restore.
- Permanent delete.
- Empty trash.

Failures produce concise SnackBar feedback instead of leaking asynchronous storage errors through UI callbacks.

The HomeShell floating-action new-note path received the same protection.

### Collection-aware folder/tag filtering

A concrete filtering defect was fixed: folder/tag metadata was previously effectively global and Trash metadata was excluded, which could make trashed folders/tags impossible to select while other collections advertised irrelevant choices.

Final behavior:

- All Notes metadata contains active/non-archived notes only.
- Favorites metadata contains active favorites only.
- Archive metadata contains archived/non-trashed notes only.
- Trash metadata contains trashed notes.
- Switching collection clears stale folder/tag selections from the previous collection.
- The same `_matchesCollection` predicate is reused for note listing and filter metadata.

Regression coverage:

- `test/data/note_repository_test.dart`
- `test/features/notes/notes_controller_test.dart`

### Collection-specific empty states

All Notes can create/import. Favorites, Archive, and Trash no longer offer creation/import actions whose results would be hidden by the current collection.

Regression coverage:

- `test/widgets/notes_page_empty_state_test.dart`

### Settings persistence ordering and rollback

A new injectable `SettingsStore` boundary separates settings state from the `shared_preferences` plugin.

`AppSettingsController` now:

- Loads settings atomically.
- Serializes preference mutations.
- Tracks the last successfully persisted value.
- Rolls back a failed optimistic theme/text-size/reduced-motion/app-lock value when that failed value is still current.
- Does not let an older failed write overwrite a newer requested value.

`SettingsRepository` now treats a reported failed preference setter result as a real `StorageException` instead of silently assuming persistence succeeded.

Settings UI catches persistence failures and reports that the previous saved value was restored.

Regression coverage:

- `test/app/app_settings_controller_test.dart`
- `test/data/settings_repository_test.dart`

### Persistence-first onboarding

Onboarding no longer marks completion optimistically before storage succeeds.

Final behavior:

- Completion is persisted first.
- Only then is `onboardingComplete` changed and the app allowed to leave onboarding.
- A failed write leaves onboarding visible and retryable.
- The button enters a busy state while completion is being saved.
- Failure produces `Could not save onboarding progress. Please try again.`

Regression coverage:

- `test/app/app_settings_controller_test.dart`
- `test/widgets/onboarding_page_test.dart`

### Application bootstrap cleanup

The app already had a startup fallback UI for dependency-initialization failures. The dependency factory now also cleans up the partially created settings controller and database if initial settings loading fails before dependencies are returned.

This avoids leaving locally created resources open during a failed bootstrap path.

### Bounded native file imports

Native Markdown/text and backup imports no longer request eager `file_picker` byte loading.

Current import pipeline:

1. Picker returns a cached native path with `withData: false`.
2. `BoundedFileReader` checks the reported file length.
3. The file is read incrementally from disk.
4. Accumulated byte length is validated after each chunk before it is added to the final buffer.
5. Strict UTF-8 decoding happens only after the bounded read.
6. Markdown/backup structured parsing happens after decoding.

Current ceilings:

- Markdown/text: **16 MiB**
- NoteNest JSON backup: **64 MiB**

Filesystem read failures become `ImportExportException`.

The platform picker/provider can still perform its own caching before NoteNest receives a path, so real-device/provider testing remains required.

Regression coverage:

- `test/core/import_limits_test.dart`
- `test/core/bounded_file_reader_test.dart`

### Backup/restore validation

The backup parser now rejects malformed data before restore writes for all of these invariants:

- Root is a JSON object.
- `app == "NoteNest"`.
- Supported backup schema version.
- Valid explicit-UTC root `exportedAt` timestamp.
- `notes` and `versions` have expected list shape.
- Required text/bool/integer/timestamp fields have expected types.
- Serialized tags decode to text lists.
- Imported tags are canonicalized by trimming, dropping empty values, deduplicating, sorting, and re-encoding.
- Incoming note IDs are non-empty, unique, and free of surrounding whitespace.
- Version note IDs are non-empty/free of surrounding whitespace and reference an incoming/existing note.
- `colorValue` is null or a valid 32-bit ARGB integer from `0x00000000` through `0xFFFFFFFF`.
- Note/version timestamps are explicit UTC values ending in `Z`.
- Note `updatedAt` is not earlier than `createdAt`.
- A note/version cannot be both archived and trashed.
- A trashed note/version cannot be pinned.

Only after validation does the restore transaction begin.

Conflict behavior still preserves a newer local note over an older imported copy, and duplicate snapshots are not added again.

Regression coverage is concentrated in `test/data/backup_repository_test.dart`.

### Cross-platform/Unicode-safe Markdown export names

`SafeFileName` now:

- Replaces invalid/control filename characters.
- Normalizes whitespace.
- Removes trailing dots/spaces.
- Protects Windows reserved names such as `CON`, `NUL`, `COM1`, and `LPT9`.
- Preserves Unicode.
- Enforces the configured basename limit.
- Falls back to `untitled-note` when needed.
- Truncates by Unicode code points instead of splitting a UTF-16 surrogate pair at the boundary.

Regression coverage:

- `test/core/safe_file_name_test.dart`

### Safe external-link boundary

`ExternalLinkService` centralizes external URI launching for:

- Repository link.
- Buy Me a Coffee.
- Business emails.
- Support email.
- GitHub Releases.

The service:

- Accepts an injectable launcher for tests.
- Uses external-application launch mode by default.
- Converts launcher refusal/exception into `false`.

About and Settings show user-visible failure feedback instead of leaking launcher/plugin errors.

Regression coverage:

- `test/services/external_link_service_test.dart`
- `test/widgets/about_page_test.dart`

### Note-color accessibility

The editor color selector uses:

- Shared 48 logical-pixel minimum custom interaction target.
- Explicit semantic selected state.
- Visible checkmark for the selected color.
- Reset icon for the default/no-color choice.
- Descriptive tooltip/semantic labels.

Regression coverage:

- `test/widgets/note_editor_accessibility_test.dart`

## Release/repository engineering

### Exact Flutter pin

Flutter `3.44.7` is pinned consistently in:

- `.flutter-version`
- `.github/workflows/ci.yml`
- `.github/workflows/platform-builds.yml`
- `.github/workflows/release.yml`

This avoids silently building the same source against a newly moved stable Flutter version.

### CI quality gate

The configured quality sequence includes:

```bash
python3 tool/check_version_sync.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python3 tool/check_repo.py
python3 tool/check_markdown_links.py
python3 tool/security_scan.py
```

### Repository tools

- `tool/bootstrap_platforms.py` — deterministic native-runner generation plus NoteNest local-auth platform patches.
- `tool/check_version_sync.py` — package/UI/changelog/release-note version consistency.
- `tool/check_repo.py` — required repository baseline, generated-file policy, unfinished source markers, important ignore rules.
- `tool/check_markdown_links.py` — deterministic repository-local Markdown link validation.
- `tool/security_scan.py` — lightweight tracked credential-pattern scan without echoing matched values.

## 2.0.12 documentation synchronized

Release/user documentation updated for this candidate includes:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `SECURITY.md`
- `PRIVACY.md`
- `docs/architecture.md`
- `docs/setup.md`
- `docs/development.md`
- `docs/testing.md`
- `docs/release.md`
- `docs/releases/2.0.12.md`
- `what_changed.md`

Existing accessibility, performance, troubleshooting, support, contribution, code-of-conduct, GitHub-operations, and ADR documentation remains part of the repository baseline.

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
- `test/data/note_repository_test.dart`
- `test/data/settings_repository_test.dart`

### Widgets

- `test/widgets/about_page_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`
- `test/widgets/note_editor_save_test.dart`
- `test/widgets/notes_page_empty_state_test.dart`
- `test/widgets/onboarding_page_test.dart`

This inventory describes tests present in the repository. It does not claim a green Flutter test run until CI/a Flutter-enabled host actually executes them.

## Static source-review results

The final GitHub code-search pass found no indexed matches for:

- `TODO:`
- `FIXME:`
- `HACK:`

Earlier final hardening also removed the native import `withData: true` path and direct feature-level external launcher calls.

Code-search results are a static signal only and are not a formatter/analyzer/test substitute.

## Verification performed/blocked in this environment

### Local clean-clone attempt

A clean clone was attempted in the execution container to run the Python repository quality tools directly. The container could not resolve `github.com` because outbound DNS/network access is unavailable there.

Therefore the following local commands are **not claimed as executed successfully** in this environment:

```bash
python tool/check_version_sync.py
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

The connected GitHub API remained available for source inspection and repository edits.

### Flutter/native verification

The execution environment does not provide a usable Flutter/Dart native build toolchain for this repository, so it cannot honestly claim:

- `dart format` pass.
- `flutter analyze` pass.
- `flutter test` pass.
- Android build pass.
- Windows build pass.
- Linux build pass.
- macOS build pass.
- iOS no-codesign build pass.
- Real-device app-lock/file-picker/external-link checks.
- Runtime screenshots.
- Manual screen-reader/desktop-keyboard matrix.

A PR-based verification branch is created after this handoff specifically so the configured GitHub Actions checks can be inspected through PR-triggered workflow status.

## Commit-email limitation

Requested project commit email: `sanskarin@outlook.in`.

The connected GitHub file-write API does not expose a per-file author/committer email override. Connector-created commits use the connected integration identity.

For local Git work use:

```bash
git config user.email "sanskarin@outlook.in"
```

## Stable 2.0.12 release blockers

The remaining work is verification/release-environment work rather than intentionally omitted core functionality:

1. Obtain completed green CI quality checks on the current candidate.
2. Obtain completed Android/Windows/Linux/macOS/iOS compile/build checks where configured.
3. Fix any actual formatter/analyzer/test/native failures those jobs reveal.
4. Run the clean-checkout Python quality tools and Flutter quality gate on a Flutter-enabled host.
5. Verify rapid-edit → immediate Back saves the newest draft before navigation.
6. Verify a real/simulated editor storage failure blocks Back/export/history safely.
7. Verify note-browser mutation failure feedback.
8. Verify settings persistence ordering/rollback and persistence-first onboarding on representative targets.
9. Verify collection-scoped filters, including Trash folder/tag metadata.
10. Verify bounded oversized Markdown/backup rejection through real picker/provider behavior.
11. Verify backup export/restore and malformed UTC/color/ID/lifecycle rejection with fictional data.
12. Verify repository/funding/mail/release links and no-handler behavior.
13. Verify app lock on supported and unsupported targets.
14. Complete keyboard, screen-reader, large-text, light/dark, reduced-motion, and custom-color accessibility review.
15. Replace illustrative layout artwork with verified runtime screenshots before making screenshot claims.
16. Prepare signed/distribution artifacts where applicable and publish SHA-256 checksums.
17. Create `v2.0.12` only on the exact commit that passed the release checklist.

## Release-readiness statement

NoteNest is now a deeply hardened **2.0.12 release candidate** with local-first persistence/search, collection-aware organization, deterministic editor/settings persistence, save-before-navigation protection, snapshots, strict conflict-safe backup/restore validation, bounded native imports, Unicode-safe exports, resilient external links, responsive Material 3 UI, accessibility/privacy controls, startup/error-state handling, extensive regression coverage, documentation, and multi-platform CI/release automation.

The remaining blockers are explicit verification and distribution checks. Stable `v2.0.12` must not be published until those checks complete successfully on the exact release commit.
