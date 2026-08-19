# NoteNest Testing Strategy

Testing protects local user data first, then interaction quality. A passing test suite does not replace manual accessibility/platform checks, but every deterministic invariant that can be tested cheaply should be automated.

## Quality layers

### Pure unit tests

Use for logic without Flutter platform services or databases:

- Markdown-lite transformations.
- Filename/format helpers when extracted.
- Search-token normalization when exposed for testing.
- Backup field validation helpers when useful.

Current coverage includes `test/core/markdown_lite_test.dart`.

### Repository/database tests

Use an in-memory SQLite database through Drift `NativeDatabase.memory()` for:

- Create/read/update behavior.
- Search results.
- Pin/favorite/archive/trash lifecycle invariants.
- Snapshot creation/restore.
- Backup conflict resolution.
- Transactions.
- Future migrations.

These tests avoid touching a contributor's real app database.

Current files:

- `test/data/note_repository_test.dart`
- `test/data/backup_repository_test.dart`

### Settings tests

Use mocked `SharedPreferences` values to test safe defaults and persistence without depending on host preferences.

Current file:

- `test/data/settings_repository_test.dart`

### Widget tests

Use for deterministic UI behavior that does not require real plugins. Current onboarding test verifies privacy/offline messaging and completion callback behavior.

Future widget coverage should prioritize:

- Notes browser empty/error/list states.
- Navigation collection changes.
- Editor formatting actions.
- Destructive confirmation behavior.
- Settings values with injected fakes.
- Semantics labels for icon-only controls.

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
python tool/security_scan.py
```

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
- Newer-local-note conflict preservation.
- Duplicate snapshot behavior.
- Transaction rollback if a parsed/restored operation fails.
- Unicode note content.
- Empty library.
- Large but reasonable fixture.

Whenever a backup bug is fixed, add the smallest regression fixture before or with the fix.

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

## Snapshot tests

Version behavior should cover:

- Changed content creates one pre-change snapshot.
- Unchanged save creates no snapshot.
- Restore makes the snapshot content current.
- Permanent note deletion removes related snapshots.
- Snapshot timestamps are UTC values.

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
- Controls can be found/tapped without relying on pixel coordinates.
- Large text does not overflow in representative widget sizes.

Manual matrix is documented in `accessibility.md`.

## Performance testing

Do not turn unit tests into flaky timing benchmarks. Use dedicated benchmark/profile runs for search/list/editor hot paths. Document device/host, build mode, fixture size, and repeated measurements.

See `performance.md`.

## Platform build checks

Unit/widget tests run on Linux CI. Native build workflows validate platform integration separately because plugin compilation and generated runners vary by host OS.

A platform build passing means the project compiled under that runner; it does not prove every plugin runtime behavior on a physical device.

## CI expectations

Pull requests to `main` should fail when:

- Dependency resolution fails.
- Drift generation fails.
- Formatting differs.
- Analyzer reports an error/warning under configured policy.
- Tests fail.
- Required repository/documentation files are absent.
- Lightweight secret scan finds a known credential pattern.

Build workflows add native compile confidence.

## Flaky tests

A flaky test is a defect in the test suite. Do not repeatedly rerun it until green without investigating. Remove timing assumptions, external dependencies, uncontrolled random values, or shared mutable state.

If a test must be temporarily quarantined to unblock an urgent fix, document why and create a concrete follow-up; do not silently skip core data-integrity coverage.

## Regression rule

Every confirmed bug should result in a regression test at the lowest layer that reliably reproduces the bug, unless automation is genuinely infeasible. In that case document the manual regression procedure in the related issue/PR and consider adding a testable abstraction.
