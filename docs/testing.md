# NoteNest Testing Strategy

Testing protects local user data first, then interaction quality. A passing test suite does not replace manual accessibility/platform checks, but every deterministic invariant that can be tested cheaply should be automated.

## Quality layers

### Pure/core unit tests

Use for logic without real platform services or user databases. Current core coverage includes:

- `test/core/markdown_lite_test.dart` — Markdown-lite transformations and preview behavior.
- `test/core/markdown_document_codec_test.dart` — NoteNest Markdown metadata round trips and malformed metadata rejection.
- `test/core/import_limits_test.dart` — accepted/rejected Markdown and backup byte-size boundaries.
- `test/core/bounded_file_reader_test.dart` — bounded native-file reads, early oversize rejection, and safe filesystem-error wrapping.
- `test/core/safe_file_name_test.dart` — invalid characters, Windows reserved names, trailing-dot/space handling, Unicode, and maximum filename length.
- `test/core/async_serial_queue_test.dart` — FIFO async task ordering and recovery after an earlier task fails.
- `test/core/app_logger_test.dart` — structured logger redaction behavior.

The serial-queue tests protect the editor autosave ordering primitive independently of the UI. Import-limit, bounded-reader, and safe-filename tests keep local file handling deterministic and cross-platform.

### Repository/database tests

Use an in-memory SQLite database through Drift `NativeDatabase.memory()` for:

- Create/read/update behavior.
- Search results.
- Pin/favorite/archive/trash lifecycle invariants.
- Snapshot creation/restore.
- Backup conflict resolution and relationship validation.
- Transactions.
- Future migrations.

Current files:

- `test/data/note_repository_test.dart`
- `test/data/backup_repository_test.dart`

These tests avoid touching a contributor's real app database.

### Settings tests

Use mocked `SharedPreferences` values to test safe defaults and persistence without depending on host preferences.

Current file:

- `test/data/settings_repository_test.dart`

### Widget tests

Use for deterministic UI behavior that does not require real plugins. Current coverage includes:

- `test/widgets/onboarding_page_test.dart` — privacy/offline messaging and onboarding completion.
- `test/widgets/notes_page_empty_state_test.dart` — collection-specific empty states and prevention of mismatched create/import actions in Favorites, Archive, and Trash.
- `test/widgets/note_editor_accessibility_test.dart` — reusable note-color swatch selected cue, reset cue, tap behavior, and minimum interaction target.

Remaining useful widget coverage includes navigation collection changes, editor formatting actions, destructive confirmation behavior, Settings values with injected fakes, and broader large-text/layout checks.

### Integration/end-to-end tests

Important journeys that should receive platform integration coverage as CI/device capacity allows:

1. First run → onboarding → create note → autosave → close/reopen.
2. Edit note → snapshot → restore prior version.
3. Search → result → editor.
4. Archive → archive collection → unarchive.
5. Trash → restore and permanent-delete paths.
6. Export backup → modify fictional library → restore backup.
7. App-lock enable → background/resume → authenticate.
8. Markdown import/export through platform picker adapters.
9. Rapid editor changes followed by background/navigation to confirm the final draft wins after serialized saves.
10. Oversized file selection to confirm the user receives a safe import failure on supported picker platforms.

Plugin-heavy behavior may require a real/emulated platform or a wrapper/fake boundary rather than a pure widget test.

## Commands

Generate Drift code first:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run all tests:

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
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

`tool/check_markdown_links.py` checks tracked Markdown documents for local inline links, reference-link definitions, and HTML `href`/`src` targets that point to missing files or escape the repository. External URLs are intentionally not fetched so the quality gate stays deterministic and does not fail because a third-party site is temporarily unavailable.

On systems where the Python command is `python3`, use that executable. On Windows the `py` launcher may be used.

## Test data rules

- Use fictional note text.
- Keep fixtures deterministic.
- Do not depend on current network services.
- Do not depend on real credentials.
- Do not commit a personal SQLite file or exported personal backup.
- Prefer explicit timestamps when date ordering is the subject of a test.
- Avoid tests whose success depends on locale/timezone unless the locale/timezone is set by the test.

## Backup tests

Backup/restore is data-sensitive and should cover at least:

- Valid round trip.
- Malformed JSON.
- Wrong `app` identifier.
- Unsupported backup schema version.
- Missing/wrong field types.
- Invalid timestamps.
- Malformed serialized tags.
- Duplicate note IDs.
- Snapshot references to missing notes.
- Newer-local-note conflict preservation.
- Duplicate snapshot behavior.
- Transaction rollback if a parsed/restored operation fails.
- Unicode note content.
- Empty library.
- Large but reasonable fixture.

Whenever a backup bug is fixed, add the smallest regression fixture before or with the fix.

## Import/export tests

File transfer has two layers: pure validation/normalization and platform picker integration.

Pure coverage keeps these invariants stable:

- Markdown/text import limit is 16 MiB.
- JSON backup import limit is 64 MiB.
- Files exactly at a configured limit are accepted by the limit validator.
- Native picked files are not requested with eager `withData` loading.
- The cached native file is length-checked and read incrementally through `BoundedFileReader` before a final byte buffer is produced.
- Files exceeding the active validator fail before a full oversized buffer is constructed by NoteNest.
- Filesystem read failures are surfaced as `ImportExportException` rather than leaking raw filesystem errors through the feature layer.
- Cross-platform invalid filename characters are normalized.
- Windows reserved device names cannot become raw export basenames.
- Trailing dots/spaces are removed.
- Empty/invalid titles fall back to `untitled-note`.
- Unicode titles remain usable.

Platform picker behavior must still be smoke-tested on real supported targets because `file_picker` is a native boundary and may cache cloud/provider files before handing NoteNest a local path.

## Search tests

FTS behavior should cover:

- Title match.
- Body match.
- Folder/tag match.
- Multiple terms.
- Search punctuation/quotes that must not break SQL syntax.
- Unicode text supported by the configured tokenizer.
- Exclusion rules for archive/trash/favorites after search.
- Ranking behavior only where exact ordering is stable enough to assert.

Search input must never be concatenated into executable SQL syntax.

## Snapshot and autosave tests

Version behavior should cover:

- Changed content creates one pre-change snapshot.
- Unchanged save creates no snapshot.
- Restore makes the snapshot content current.
- Permanent note deletion removes related snapshots.
- Snapshot timestamps are UTC values.

Editor save ordering uses a serial async queue so overlapping autosave/lifecycle/action saves cannot overtake each other. The queue primitive has deterministic ordering/failure-continuation tests; a platform/editor integration smoke test should still confirm that the final visible draft is persisted after rapid edits and navigation/backgrounding.

If snapshot retention/pruning is introduced, add boundary tests around the retention policy.

## Migration tests

Schema version 1 is the initial schema. Starting with version 2, every migration requires fixture-driven tests:

1. Create/open a database at the previous released schema.
2. Populate representative fictional data.
3. Run the upgrade.
4. Verify values, constraints, indexes/FTS, and foreign keys.
5. Run repository operations on the upgraded data.

Do not test migrations only from an empty database.

## Accessibility testing

Automated checks should be complemented by manual review. Useful automated assertions include:

- Semantics label exists for icon-only/custom controls.
- Selected state is not communicated only by color.
- Custom interaction targets meet the shared minimum size.
- Controls can be found/tapped without relying on pixel coordinates.
- Large text does not overflow in representative widget sizes.

Current deterministic coverage verifies the custom note-color swatch's visible selected/reset cues and 48-logical-pixel target. Manual matrix is documented in [accessibility.md](accessibility.md).

## Performance testing

Do not turn unit tests into flaky timing benchmarks. Use dedicated benchmark/profile runs for search/list/editor hot paths. Document device/host, build mode, fixture size, and repeated measurements.

See [performance.md](performance.md).

## Platform build checks

Unit/widget tests run on Linux CI. Native build workflows validate platform integration separately because plugin compilation and generated runners vary by host OS.

A platform build passing means the project compiled under that runner; it does not prove every plugin runtime behavior on a physical device.

All automated Flutter workflows use the exact SDK recorded by the project rather than an unpinned moving stable release. A Flutter-version upgrade must therefore update `.flutter-version` and all workflows together.

## CI expectations

Pull requests to `main` should fail when:

- Dependency resolution fails.
- Drift generation fails.
- Formatting differs.
- Analyzer reports an error/warning under configured policy.
- Tests fail.
- Required repository/documentation files are absent.
- Tracked Markdown contains a broken local link.
- Lightweight secret scan finds a known credential pattern.

Build workflows add native compile confidence.

## Flaky tests

A flaky test is a defect in the test suite. Do not repeatedly rerun it until green without investigating. Remove timing assumptions, external dependencies, uncontrolled random values, or shared mutable state.

If a test must be temporarily quarantined to unblock an urgent fix, document why and create a concrete follow-up; do not silently skip core data-integrity coverage.

## Regression rule

Every confirmed bug should result in a regression test at the lowest layer that reliably reproduces the bug, unless automation is genuinely infeasible. In that case document the manual regression procedure in the related issue/PR and consider adding a testable abstraction.
