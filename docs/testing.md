# NoteNest Testing Strategy

Testing protects local user data first, then interaction quality. A passing test suite does not replace manual accessibility/platform checks, but every deterministic invariant that can be tested cheaply should be automated.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Quality layers

### Core/service unit tests

Use for deterministic logic without real platform services or user databases.

Current coverage includes:

- `test/core/markdown_lite_test.dart` — Markdown-lite transformations and preview behavior.
- `test/core/markdown_document_codec_test.dart` — NoteNest Markdown metadata round trips and malformed metadata rejection.
- `test/core/import_limits_test.dart` — accepted/rejected Markdown and backup byte-size boundaries.
- `test/core/bounded_file_reader_test.dart` — bounded native-file reads, early oversize rejection, and filesystem-error wrapping.
- `test/core/safe_file_name_test.dart` — invalid characters, Windows reserved names, trailing-dot/space handling, Unicode preservation, maximum filename length, and surrogate-safe truncation.
- `test/core/async_serial_queue_test.dart` — FIFO async task ordering and continuation after an earlier task fails.
- `test/core/app_logger_test.dart` — structured logger redaction behavior.
- `test/services/external_link_service_test.dart` — launcher success, refusal, and exception containment.

These tests protect the primitives used by autosave, imports, exports, logging, and external links independently of UI timing.

### Application-controller tests

Current application-state coverage includes:

- `test/app/app_settings_controller_test.dart` — atomic settings load, serialized writes, rollback after failed writes, persistence-first onboarding, and app-lock preference rollback.
- `test/features/notes/notes_controller_test.dart` — collection-switch filter reset and collection-scoped folder/tag metadata loading.

Controller tests are useful for async ordering/state behavior that should not depend on widget rendering.

### Repository/database tests

Use an in-memory SQLite database through Drift `NativeDatabase.memory()`.

Current files:

- `test/data/note_repository_test.dart`
- `test/data/backup_repository_test.dart`
- `test/data/settings_repository_test.dart`

Current note-repository coverage includes:

- Create/read/update behavior.
- Full-text search and quote punctuation.
- Pin/favorite/archive/trash collection invariants.
- Snapshot creation/restore/cascade deletion.
- Collection-scoped folder metadata.
- Collection-scoped tag metadata, including Trash.

Current backup coverage includes:

- Valid round trip.
- Conflict-safe restore.
- Wrong app identity.
- Unsupported backup schema.
- Malformed JSON.
- Missing/invalid root export timestamp.
- Invalid note timestamps.
- Timestamps missing explicit UTC `Z`.
- `updatedAt` before `createdAt`.
- Malformed serialized tags.
- Tag canonicalization on import.
- Out-of-range ARGB colors.
- Duplicate note IDs.
- IDs with surrounding whitespace.
- Impossible archived+trashed and pinned+trashed lifecycle states.
- Versions that reference missing notes.

Settings repository tests use mocked `SharedPreferences` values for safe defaults and successful persistence behavior. Failure/rollback semantics are covered at the injectable `SettingsStore`/controller boundary.

### Widget tests

Current deterministic widget coverage includes:

- `test/widgets/onboarding_page_test.dart` — privacy/offline messaging, successful completion, and persistence-failure feedback.
- `test/widgets/notes_page_empty_state_test.dart` — collection-specific empty states and prevention of mismatched create/import actions in Favorites, Archive, and Trash.
- `test/widgets/note_editor_accessibility_test.dart` — reusable note-color swatch selected/reset cues, tap behavior, and minimum interaction target.
- `test/widgets/note_editor_save_test.dart` — latest-draft persistence before normal back navigation and retryable missing-note load failure instead of an endless progress state.
- `test/widgets/about_page_test.dart` — user-visible feedback when an external About link cannot be opened.

Remaining useful widget coverage includes editor formatting actions, destructive confirmation behavior, Settings failure messages with injected stores/services, note-browser mutation failure UI with a future injectable note store, broader large-text layout checks, and explicit keyboard focus traversal.

### Integration/end-to-end tests

Important journeys that should receive platform integration coverage as CI/device capacity allows:

1. First run → persist onboarding → create note → autosave → close/reopen.
2. Failed onboarding preference write → remain on onboarding → retry.
3. Rapid edit → immediate Back → route remains until the latest draft is saved → reopen and verify newest content.
4. Simulated save failure → Back remains blocked → failure message appears → content remains editable/retryable.
5. Edit note → snapshot → restore prior version.
6. Save failure before Version history/Export → requested action does not continue against stale persisted content.
7. Search → result → editor.
8. Change folder/tag filter → switch collection → verify stale filters clear.
9. Archive → archive collection → collection-specific folder/tag filters → unarchive.
10. Trash → trash collection → trashed folder/tag filters → restore/permanent-delete.
11. Browser mutation/storage failure → concise feedback rather than uncaught asynchronous error.
12. Export backup → modify fictional library → restore backup.
13. App-lock enable → background/resume → authenticate.
14. Preference write failure → previous saved setting restored.
15. Markdown import/export through platform picker adapters.
16. Oversized file selection → safe rejection on supported picker/provider platforms.
17. Repository/funding/mail/release external links → success and no-handler/failure feedback.
18. Bootstrap settings failure → startup fallback is shown and partially created local dependencies are cleaned up.

Plugin-heavy behavior requires a real/emulated platform or a wrapper/fake boundary rather than relying only on widget tests.

## Commands

Verify release metadata first:

```bash
python tool/check_version_sync.py
```

Generate Drift code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run all Flutter tests:

```bash
flutter test
```

Run one test file:

```bash
flutter test test/data/note_repository_test.dart
```

Run by test name:

```bash
flutter test --plain-name "full-text search finds note content"
```

Coverage:

```bash
flutter test --coverage
```

Complete local quality gate:

```bash
python tool/check_version_sync.py
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

Use `python3` or Windows `py` if that is the executable provided by the host.

### Repository-maintenance tools

`tool/check_version_sync.py` verifies:

- `pubspec.yaml` declares `MAJOR.MINOR.PATCH+BUILD`.
- Build number is positive.
- `AppStrings.version` matches the package semantic version.
- `CHANGELOG.md` has a matching release section.
- `docs/releases/<version>.md` exists and contains the exact package/visible version values.

`tool/check_repo.py` verifies required project/documentation files, forbidden unfinished markers in tracked Dart source, generated-file policy, and important ignore rules.

`tool/check_markdown_links.py` checks tracked Markdown documents for repository-local inline links, reference-link definitions, and HTML `href`/`src` targets that point to missing files or escape the repository. External URLs are intentionally not fetched so the quality gate remains deterministic.

`tool/security_scan.py` performs the project's lightweight tracked-file credential-pattern scan.

## Test data rules

- Use fictional note text.
- Keep fixtures deterministic.
- Do not depend on current network services.
- Do not depend on real credentials.
- Do not commit a personal SQLite file or exported personal backup.
- Prefer explicit UTC timestamps when date ordering is the subject of a test.
- Avoid tests whose success depends on locale/timezone unless the locale/timezone is set by the test.
- Test malformed data without including real sensitive content.

## Backup tests

Backup/restore is data-sensitive. Every validation change should preserve the invariant that malformed input is rejected **before** restore writes begin.

Required coverage for the current backup schema includes:

- Valid round trip.
- Malformed JSON.
- Wrong `app` identifier.
- Unsupported backup schema version.
- Valid explicit-UTC `exportedAt`.
- Missing/wrong field types.
- Explicit UTC note/version timestamp validation.
- `updatedAt >= createdAt` for notes.
- Malformed serialized tags.
- Canonicalized imported tags (trim, remove empty, deduplicate, sort).
- Valid/null and invalid/out-of-range ARGB values.
- Duplicate note IDs.
- Whitespace-polluted note/version identifiers.
- Impossible lifecycle states rejected.
- Snapshot references to missing notes.
- Newer-local-note conflict preservation.
- Duplicate snapshot behavior.
- Transaction rollback if a parsed/restored operation fails.
- Unicode note content.
- Empty library.
- Large but reasonable fixture.

Whenever a backup bug is fixed, add the smallest regression fixture before or with the fix.

## Import/export tests

File transfer has pure validation/normalization plus platform picker integration.

Pure coverage keeps these invariants stable:

- Markdown/text import limit is 16 MiB.
- JSON backup import limit is 64 MiB.
- Files exactly at a configured limit are accepted by the limit validator.
- Native picked files are not requested with eager `withData` loading.
- The cached native file is length-checked and read incrementally through `BoundedFileReader` before a final byte buffer is produced.
- Files exceeding the active validator fail before NoteNest constructs a full oversized buffer.
- Filesystem read failures become `ImportExportException`.
- Strict UTF-8 is required.
- Cross-platform invalid filename characters are normalized.
- Windows reserved device names cannot become raw export basenames.
- Trailing dots/spaces are removed.
- Empty/invalid titles fall back to `untitled-note`.
- Unicode titles remain usable.
- Truncation does not split UTF-16 surrogate pairs; output is constructed from complete Unicode code points.

Platform picker behavior must still be smoke-tested on real supported targets because native/cloud providers may perform their own caching before NoteNest receives a local path.

## External-link tests

The service layer must cover:

- Successful launch.
- Platform launcher returning `false`.
- Platform/plugin launcher throwing.

The widget layer should verify failure feedback without invoking a real external application. Real platform smoke tests still need to exercise HTTP(S) and `mailto:` handlers.

## Settings persistence tests

Preference state has two responsibilities: persist correctly and avoid misleading visible state when persistence fails.

Coverage should verify:

- Loaded values appear atomically.
- Rapid writes preserve submission order.
- Failed theme/text/motion/app-lock writes restore the last persisted value when the failed value is still current.
- A stale failed write must not overwrite a newer visible value.
- Plugin setter failure results are converted into storage failures.
- Onboarding does not transition away until completion persistence succeeds.
- Failed onboarding persistence remains retryable.

Do not use preferences for credentials or note content.

## Search and collection-filter tests

FTS behavior should cover:

- Title match.
- Body match.
- Folder/tag match.
- Multiple terms.
- Search punctuation/quotes that must not break SQL syntax.
- Unicode text supported by the configured tokenizer.
- Exclusion rules for archive/trash/favorites after search.
- Ranking behavior only where exact ordering is stable enough to assert.

Collection-filter metadata should cover:

- All Notes metadata excludes Archive/Trash.
- Favorites metadata includes only active favorites.
- Archive metadata includes only archive rows.
- Trash metadata includes trashed folders/tags.
- Switching collection clears stale folder/tag selections.

Search input must never be concatenated into executable SQL syntax.

## Snapshot, editor and autosave tests

Version/editor behavior should cover:

- Changed content creates one pre-change snapshot.
- Unchanged save creates no snapshot.
- Restore makes the snapshot content current.
- Permanent note deletion removes related snapshots.
- Snapshot timestamps are UTC values.
- Missing-note initial load becomes a retryable error state.
- Editor save submissions remain ordered.
- A stale save completion cannot mark a newer draft as saved.
- Normal back navigation does not pop until the current draft save succeeds.
- A failed save blocks normal back navigation and export/history actions.

`AsyncSerialQueue` has deterministic ordering/failure-continuation tests. `note_editor_save_test.dart` protects save-before-pop at widget level. Real platform/editor smoke testing should still cover system back gestures/buttons, desktop back navigation, lifecycle backgrounding, process termination behavior, and real storage/plugin failures.

If snapshot retention/pruning is introduced, add boundary tests around the retention policy.

## Migration tests

Drift schema version 1 remains the initial schema even though application release candidate is version 2.0.12. These are independent version domains.

Starting with database schema version 2, every migration requires fixture-driven tests:

1. Create/open a database at the previous released schema.
2. Populate representative fictional data.
3. Run the upgrade.
4. Verify values, constraints, indexes/FTS, and foreign keys.
5. Run repository operations on upgraded data.

Do not test migrations only from an empty database.

## Accessibility testing

Automated checks should be complemented by manual review. Useful automated assertions include:

- Semantics label exists for icon-only/custom controls.
- Selected state is not communicated only by color.
- Custom interaction targets meet the shared minimum size.
- Controls can be found/tapped without relying on pixel coordinates.
- Failure messages are user-visible and readable.
- Large text does not overflow representative layouts.

Current deterministic coverage verifies the custom note-color swatch's selected/reset cues and 48-logical-pixel target plus About failure feedback and editor load/save-before-pop states. Manual matrix is documented in [`accessibility.md`](accessibility.md).

## Performance testing

Do not turn unit tests into flaky timing benchmarks. Use dedicated benchmark/profile runs for search/list/editor/import hot paths. Document device/host, build mode, fixture size, and repeated measurements.

See [`performance.md`](performance.md).

## Platform build checks

Unit/widget tests run on Linux CI. Native build workflows validate platform integration separately because plugin compilation and generated runners vary by host OS.

A platform build passing means the project compiled under that runner; it does not prove every plugin runtime behavior on a physical device.

All automated Flutter workflows use the exact project SDK rather than an unpinned moving stable release. A Flutter-version upgrade must update `.flutter-version` and all Flutter workflows together.

## CI expectations

Pull requests/pushes to `main` should fail when:

- Release metadata is out of sync.
- Dependency resolution fails.
- Drift generation fails.
- Formatting differs.
- Analyzer reports an error/warning under configured policy.
- Tests fail.
- Required repository/documentation files are absent.
- Tracked Markdown contains a broken repository-local link.
- Lightweight secret scan finds a known credential pattern.

Build workflows add native compile confidence.

## Flaky tests

A flaky test is a defect in the test suite. Do not repeatedly rerun it until green without investigating. Remove timing assumptions, external dependencies, uncontrolled random values, or shared mutable state.

If a test must be temporarily quarantined to unblock an urgent fix, document why and create a concrete follow-up; do not silently skip data-integrity coverage.

## Regression rule

Every confirmed bug should result in a regression test at the lowest layer that reliably reproduces the bug, unless automation is genuinely infeasible. When automation is unavailable, document the exact manual regression procedure in the related issue/PR/release handoff and consider adding a testable abstraction.
