# NoteNest — 2.0.12 Final Engineering Handoff

Last updated: 2026-08-19
Target application version: **2.0.12**
Flutter package version: **2.0.12+2012**
Pinned Flutter SDK: **3.44.7**
Active development branch: `main`
Tracked-file documentation checkpoint: **103 tracked files cataloged**
Verification PR: **#5 — open, but it predates the latest `main` continuation commits**
Stable tag status: **not yet tagged**

## Current release status

NoteNest is prepared as a **2.0.12 release candidate**.

The implementation, repository tooling, regression suite, public documentation, security/privacy documentation, and release documentation have been deeply hardened. A stable `v2.0.12` tag is intentionally not created yet because completed green Flutter/native CI evidence and the documented manual platform/accessibility checks are still required.

Do not describe the current candidate as fully verified, bug-free, or stable until those checks pass on the exact release commit.

## 2026-08-19 continuation — exhaustive repository documentation and lifecycle hardening

This continuation performed another full tracked-tree audit rather than assuming the previous documentation checkpoint was exhaustive.

### Exhaustive tracked-file reference

Added `docs/repository-reference.md` as the authoritative file-by-file repository map. At this checkpoint it contains exactly one catalog entry for each of the repository's **103 tracked files**.

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
- The exact audit commands and limitations of what the reference checker proves.

Added `tool/check_repository_reference.py` so this completeness promise is enforceable rather than editorial. It compares `git ls-files` with catalog entries and fails for:

- A tracked path with no documentation entry.
- A stale catalog entry for a path no longer tracked.
- A duplicate catalog path.
- A missing repository-reference document.

`tool/check_repo.py` now requires both the exhaustive reference and its checker. CI now runs the checker after repository policy validation and before Markdown-link/security checks.

Contributor and pull-request documentation now requires updating the catalog whenever a tracked path is added, removed, or renamed.

### Lifecycle consistency bug found and fixed during documentation audit

The backup validator already rejected the impossible `pinned + trashed` lifecycle state, and `trash()` already cleared pin state. However, the live repository boundary previously allowed a caller to invoke `setPinned(id, value: true)` on a note that was already trashed.

`NoteRepository.setPinned` now:

1. Allows unpinning normally.
2. Performs the pin-enable check inside a database transaction.
3. Loads the current note state.
4. Throws `ValidationException('Trashed notes cannot be pinned.')` if the note is trashed.
5. Applies the pin only when the lifecycle state is valid.

This keeps live persistence rules consistent with backup validation instead of relying solely on current UI affordances to prevent an invalid state.

Regression coverage was added to `test/data/note_repository_test.dart`. The test trashes a note, verifies pinning throws `ValidationException`, then verifies the stored note remains trashed and unpinned.

### Continuation commits created before this handoff commit

The work was kept in focused commits:

- `88137c4f3544960d3bce9f5e78c7d08c300de80c` — `tooling: enforce exhaustive repository reference`
- `658c2d083f21e070c6d028032fde35f01835cf98` — `fix: prevent pinning trashed notes`
- `c7ba995e925fcdafde7a9a56800a6bd1da74a9bf` — `test: cover pinning invariant for trash`
- `72b16f97a3e58ee9422edbccda877a9760787c34` — `docs: add exhaustive tracked-file repository reference`
- `ed99f470492a35a3cf15a038352a69d2ab608b2d` — `tooling: require repository reference documentation`
- `60c6bea124035c6f84f42ce5a57c8b42af9c4cf0` — `ci: enforce exhaustive documentation coverage`
- `7f9f0e0d814410c18e8bf732c505de4105c43db5` — `docs: enforce file-reference updates for contributors`
- `758b0855889e292fdf2bedc024f25a3e97716bf9` — `docs: add repository-reference PR gate`
- `3ebecd0f9dc74c6d82c431f3cd42dd2fda54d4aa` — `docs: record exhaustive reference and lifecycle hardening`

The current handoff update is an additional documentation commit after those checkpoints.

## Version metadata

The 2.0.12 version surfaces agree:

- `pubspec.yaml`: `2.0.12+2012`
- `AppStrings.version`: `2.0.12`
- `CHANGELOG.md`: `## [2.0.12] - Release candidate`
- `docs/releases/2.0.12.md`: exact package and visible version values

`tool/check_version_sync.py` was added so future release bumps cannot silently update only one version surface. CI runs it before Flutter dependency/build work. The checker also requires a positive build number and matching version-specific release notes.

## Major 2.0.12 hardening

### Editor data integrity

- Every submitted editor save captures an immutable draft.
- `AsyncSerialQueue` executes submitted writes in order.
- The queue now supports typed task results.
- Stale save completions cannot mark newer visible content as already saved.
- Lifecycle/background saves use the same ordered queue.
- Normal Back navigation captures and saves the current draft before allowing the route to pop.
- A failed final save keeps the editor open with user-visible feedback.
- The pop guard waits for a rebuilt `canPop` frame before the programmatic pop.
- Version-history and Markdown-export actions require a successful current-draft save before they start.
- Initial note-load failure shows a retryable error instead of an endless spinner.
- Version-query, restore, and export errors are contained with user feedback.

Regression coverage:

- `test/core/async_serial_queue_test.dart`
- `test/widgets/note_editor_save_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`

### Notes browser reliability

The notes browser contains failures around create/open/pin/favorite/archive/trash/undo/restore/permanent-delete/empty-trash operations and reports concise SnackBar feedback instead of leaking async storage errors.

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

All Notes can create/import. Favorites, Archive, and Trash no longer offer creation/import actions whose result would be hidden by the current collection.

Regression coverage:

- `test/widgets/notes_page_empty_state_test.dart`

### Settings persistence ordering and rollback

A new injectable `SettingsStore` boundary separates settings state from the preference plugin.

`AppSettingsController` now:

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

### Bootstrap cleanup

The app already had a startup failure UI. `AppDependencies.create()` now also disposes the settings controller and closes the database if initial settings loading fails before dependencies are returned.

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

The live `NoteRepository` boundary now also rejects enabling pin state on an already-trashed note, so valid-state enforcement is not limited to backup import.

Regression coverage:

- `test/data/backup_repository_test.dart`
- `test/data/note_repository_test.dart`

### Cross-platform/Unicode-safe Markdown export names

`SafeFileName` now:

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

## Release/repository engineering

### Exact Flutter pin

Flutter `3.44.7` is pinned in:

- `.flutter-version`
- `.github/workflows/ci.yml`
- `.github/workflows/platform-builds.yml`
- `.github/workflows/release.yml`

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

### Repository tools

- `tool/bootstrap_platforms.py`
- `tool/check_version_sync.py`
- `tool/check_repo.py`
- `tool/check_repository_reference.py`
- `tool/check_markdown_links.py`
- `tool/security_scan.py`

## Documentation synchronized for 2.0.12

The deep documentation baseline includes:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `SECURITY.md`
- `PRIVACY.md`
- `CONTRIBUTING.md`
- `.github/pull_request_template.md`
- `docs/architecture.md`
- `docs/setup.md`
- `docs/development.md`
- `docs/testing.md`
- `docs/release.md`
- `docs/releases/2.0.12.md`
- `docs/repository-reference.md`
- `what_changed.md`

Existing accessibility, performance, troubleshooting, support, code-of-conduct, GitHub-operations, and ADR documentation remains part of the baseline and is individually cataloged in `docs/repository-reference.md`.

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
- `test/data/note_repository_test.dart` — now includes the trashed-note pinning regression
- `test/data/settings_repository_test.dart`

### Widgets

- `test/widgets/about_page_test.dart`
- `test/widgets/note_editor_accessibility_test.dart`
- `test/widgets/note_editor_save_test.dart`
- `test/widgets/notes_page_empty_state_test.dart`
- `test/widgets/onboarding_page_test.dart`

This inventory describes tests present in the repository. It does not claim a green Flutter run until CI or a Flutter-enabled host executes them.

## Static source-review signals

The earlier final GitHub code-search pass found no indexed matches for:

- `TODO:`
- `FIXME:`
- `HACK:`

Earlier final hardening removed the native import `withData: true` path and direct feature-level external launcher calls.

The repository policy checker continues to reject `TODO:`, `FIXME:`, and `HACK:` markers in tracked `lib/**/*.dart` source.

These are static signals, not formatter/analyzer/test substitutes.

## Local verification limitation

A clean clone was attempted in the execution container so the repository's Python tools could run directly. The container could not resolve `github.com` because outbound DNS/network access is unavailable there.

Therefore these local commands are not claimed as successfully executed in this environment:

```bash
python tool/check_version_sync.py
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

The exhaustive repository reference was independently constructed against the GitHub recursive tracked tree and contains one intended entry for each of the 103 tracked files. The authoritative automated proof remains the CI execution of `tool/check_repository_reference.py` on the checked-out commit.

The connected GitHub API remained available for repository inspection and edits.

The environment also does not provide the full Flutter/native build toolchain needed to claim formatter/analyzer/tests/native builds or real-device verification.

## PR-based 2.0.12 verification

A dedicated verification PR remains open:

- PR: **#5 — `ci: verify NoteNest 2.0.12 release candidate`**
- Head branch: `verify/2.0.12-ci`
- Previously inspected PR head commit: `7118196855fb8d9b60743bc3b35eac68702955fd`
- Previous runtime difference: one non-functional source comment plus a verification checkpoint document

At the earlier checkpoint, its PR-triggered workflows were queued:

- **Platform builds** — run 86 / ID `32255557942` — `queued`
- **CI** — run 169 / ID `32255558015` — `queued`
- **Security checks** — run 152 / ID `32255558014` — `queued`

Those exact PR results do **not** represent the current `main` after the lifecycle fix, exhaustive documentation, CI-policy updates, and subsequent handoff commits listed above. PR #5 must therefore not be treated as final evidence for the latest release candidate even if its older jobs later turn green.

Final automated verification must target the latest exact `main`/release-candidate commit after this continuation, or a new verification branch created from it.

## Commit-email limitation

Requested project commit email: `sanskarin@outlook.in`.

The connected GitHub contents API does not expose a per-file author/committer email override, so connector-created commits use the connected integration identity.

For local Git work:

```bash
git config user.email "sanskarin@outlook.in"
```

## Remaining stable 2.0.12 blockers

These are verification/distribution tasks rather than intentionally omitted core functionality:

1. Obtain completed green CI/security/platform-build results on the latest exact 2.0.12 candidate after this continuation.
2. Fix any formatter/analyzer/test/native failures those jobs reveal.
3. Run the clean-checkout Python and Flutter quality gates on a Flutter-enabled host, including `tool/check_repository_reference.py`.
4. Verify rapid-edit → immediate Back saves the newest draft before navigation.
5. Verify a real/simulated editor storage failure blocks Back/export/history safely.
6. Verify note-browser mutation failure feedback.
7. Verify settings persistence ordering/rollback and persistence-first onboarding on representative targets.
8. Verify collection-scoped filters, including Trash metadata and the no-pinned-trash lifecycle invariant.
9. Verify bounded oversized Markdown/backup rejection through real picker/provider behavior.
10. Verify backup export/restore and malformed timestamp/color/ID/lifecycle rejection using fictional data.
11. Verify repository/funding/mail/release links and no-handler behavior.
12. Verify app lock on supported and unsupported targets.
13. Complete keyboard, screen-reader, large-text, light/dark, reduced-motion, and custom-color accessibility review.
14. Replace illustrative layout artwork with verified runtime screenshots before making screenshot claims.
15. Prepare distribution signing status/artifacts and SHA-256 checksums.
16. Create `v2.0.12` only on the exact commit that passed the full release checklist.

## Release-readiness statement

NoteNest is now a deeply hardened **2.0.12 release candidate** with local-first persistence/search, collection-aware organization, deterministic editor/settings persistence, save-before-navigation protection, snapshots, strict conflict-safe backup/restore validation, bounded native imports, Unicode-safe exports, resilient external links, responsive Material 3 UI, accessibility/privacy controls, startup/error-state handling, extensive regression coverage, an exhaustive machine-enforced 103-file repository reference, and multi-platform CI/release automation.

The remaining blockers are explicit verification and distribution checks. Stable `v2.0.12` must not be published until those checks complete successfully on the exact release commit.
