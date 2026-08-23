# NoteNest Testing Strategy

Testing protects local user data first, then interaction quality. Deterministic invariants belong in automation; successful compilation never substitutes for real runtime/accessibility validation.

Current release candidate: **2.0.12** (`2.0.12+2012`).

## Platform scope

The test/release strategy covers all six Flutter targets:

- Android
- iOS / iPadOS
- Windows
- macOS
- Linux
- Web

Web is a first-class target. The platform workflow runs both a Chrome-targeted platform-boundary regression and a release-mode Web build.

## Reproducible test environment

Use Flutter **3.44.7** and restore the committed dependency graph:

```bash
flutter pub get --enforce-lockfile
```

The current lock contains **129 resolved packages** and is part of the **109-file** tracked repository contract. Ordinary test runs must not silently change the graph.

Generate Drift code with:

```bash
dart run build_runner build
```

## Quality layers

### Core/service unit tests

Current deterministic coverage includes:

- `test/core/markdown_lite_test.dart` — Markdown-lite transformations.
- `test/core/markdown_document_codec_test.dart` — metadata round trips/malformed input.
- `test/core/import_limits_test.dart` — Markdown and backup byte boundaries.
- `test/core/bounded_file_reader_test.dart` — native bounded streaming, oversize rejection, filesystem error translation.
- `test/core/safe_file_name_test.dart` — cross-platform/Unicode filename safety.
- `test/core/async_serial_queue_test.dart` — FIFO persistence ordering and failure continuation.
- `test/core/app_logger_test.dart` — logger redaction.
- `test/services/external_link_service_test.dart` — successful/refused/throwing launcher behavior.

### Web platform smoke

`test/web/web_platform_smoke_test.dart` protects browser-specific boundaries:

- Web app lock reports device authentication unavailable.
- Authentication requests fail safely instead of registering an unsupported native plugin.
- Native filesystem-path access is unavailable in the browser and reaches the domain failure boundary rather than importing `dart:io` into shared Web code.

Run:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

This complements, but does not replace, `flutter build web --release` and real deployed-origin persistence/import/export testing.

### Application/controller tests

- `test/app/app_settings_controller_test.dart` — atomic load, serialized writes, rollback, persistence-first onboarding, app-lock preference behavior.
- `test/features/notes/notes_controller_test.dart` — collection-switch filter reset, collection-scoped metadata, and configurable note-sort behavior.

### Repository/database tests

- `test/data/note_repository_test.dart`
- `test/data/backup_repository_test.dart`
- `test/data/settings_repository_test.dart`

Coverage includes create/update/search, safe FTS input, lifecycle collections, pin/favorite/archive/trash invariants, duplicate-note content/lifecycle semantics, configurable sort ordering with pinned-first behavior, snapshots, restore/cascade behavior, folder/tag metadata, no-pinned-trash, backup schema/type/UTC/tag/ID/relationship/color/lifecycle validation, conflict-safe restore, and settings persistence.

### Widget tests

- `test/widgets/onboarding_page_test.dart` — privacy/offline messaging and persistence success/failure.
- `test/widgets/notes_page_empty_state_test.dart` — collection-specific empty states/actions plus visible sort-control interaction.
- `test/widgets/note_editor_accessibility_test.dart` — selected/reset semantics and touch target.
- `test/widgets/note_editor_save_test.dart` — save-before-pop, load recovery, first-line formatting boundary, live word/character metrics, and duplicate-note editor flow.
- `test/widgets/about_page_test.dart` — external-link failure feedback.

## 2.1 productivity regression boundaries

The isolated `feature/2.1-productivity` branch adds no schema, dependency, permission, account, or network requirement. Its deterministic tests should preserve the following contracts before integration:

### Text metrics

- empty body reports zero words and zero characters;
- whitespace-separated words are counted independently of repeated spaces/newlines;
- singular/plural labels remain correct;
- character count uses Unicode code points (`runes`) rather than UTF-16 code units;
- metrics update from the in-memory editor draft and do not trigger extra persistence or network work.

### Duplicate note

- duplication always receives a fresh note ID;
- current editor draft is saved before duplicate creation starts;
- body, folder, tags, and color copy exactly through repository normalization rules;
- titled sources receive a clear `(copy)` suffix;
- untitled sources receive `Untitled copy`;
- duplicate lifecycle starts active/unpinned/non-favorite/non-archived/non-trashed even when the source has lifecycle flags;
- editor navigation opens the new copy rather than mutating the source note.

### Configurable sorting

- newest-first remains the default;
- oldest-first reverses update ordering;
- title A–Z and Z–A are case-insensitive;
- deterministic update-time tie-breaking is retained for equal titles;
- pinned notes remain ahead of unpinned notes under every sort mode;
- sort changes preserve collection/query/folder/tag filters;
- sorting changes no stored note content and requires no migration.

## Cross-platform file-transfer tests

Current implementation uses `file_picker 12.0.0`.

Required invariants:

- Markdown/text ceiling: **16 MiB**.
- JSON backup ceiling: **64 MiB**.
- Exactly-at-limit input is accepted.
- Oversized input fails before UTF-8/Markdown/JSON processing.
- `PlatformFile.length()` is validated before processing.
- Native cached paths use `BoundedFileReader` where available.
- Browser/non-path data is consumed through `readAsByteStream()` with cumulative validation.
- Strict UTF-8 is required.
- Filesystem/platform failures become `ImportExportException`.
- Export names remain cross-platform and Unicode safe.

Manual picker testing must include representative native/cloud document providers and browser file selection/download behavior because provider/browser behavior lies outside deterministic unit tests.

## Web database/deployment tests

Drift Web uses `sqlite3.wasm` + `drift_worker.js` from the same Drift **2.34.3** release as the direct dependency.

Automated Web verification:

```bash
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Real deployment verification on the intended origin must additionally check:

1. App boots without worker/WASM fetch errors.
2. `sqlite3.wasm` is served as `application/wasm`.
3. Create/edit/search works.
4. Data survives page reload.
5. Data survives browser restart under normal storage settings.
6. Markdown import/export works.
7. JSON backup export/restore works.
8. Oversized picker input is rejected.
9. Browser/site-data clearing behavior is documented.
10. Actual Drift browser storage mode is recorded instead of assuming OPFS.

Test Chrome/Edge and at least one additional browser family appropriate to the eventual Web support statement before stable browser distribution.

## App-lock platform tests

Expected current behavior:

- Android: device authentication where supported.
- iOS/iPadOS: device authentication where supported.
- macOS: device authentication where supported.
- Windows: device authentication where supported.
- Linux: app-lock capability unavailable with the current dependency.
- Web: app-lock capability unavailable.

Unsupported platforms must remain fully usable. Test both an unset lock preference and a stale persisted `appLockEnabled=true` condition.

## Integration/end-to-end journeys

Important release journeys:

1. First run → persist onboarding → create note → autosave → close/reopen.
2. Failed onboarding persistence → remain/retry.
3. Rapid edit → immediate Back → latest draft persists before navigation.
4. Offset-zero first-line Markdown formatting.
5. Failed editor save → Back/export/history blocked with feedback.
6. Snapshot creation → history → restore.
7. Search → result → editor.
8. Collection switch clears incompatible filters.
9. Archive/unarchive and collection-scoped metadata.
10. Trash/restore/permanent-delete/no-pinned-trash behavior.
11. Mutation/storage failure feedback.
12. JSON export → modify fictional library → restore.
13. Supported app lock → background/resume/authenticate.
14. Unsupported app lock → app remains accessible and Settings reports unavailable.
15. Preference failure → previous persisted value restored.
16. Markdown import/export through actual native/browser picker paths.
17. Oversized file rejection through actual provider/browser behavior.
18. Repository/funding/mail/releases links success/failure.
19. Bootstrap settings failure → safe startup fallback and cleanup.
20. Controlled root teardown → settings/database disposed.
21. Web create/edit/search → reload → browser restart persistence.
22. Web backup/Markdown download then re-import.
23. Change note sort in an active filtered collection → order changes without losing filters.
24. Duplicate a recently edited note → newest draft is saved and the new active copy opens with independent identity/lifecycle.
25. Edit ASCII and non-BMP Unicode body text → live metrics update without changing stored-format semantics.

Use fictional data only.

## Commands

### Full deterministic quality gate

```bash
python tool/check_version_sync.py
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
python tool/check_repo.py
python tool/check_repository_reference.py
python tool/check_markdown_links.py
python tool/security_scan.py
```

### Web-specific verification

```bash
python tool/bootstrap_platforms.py
flutter pub get --enforce-lockfile
dart run build_runner build
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

### Individual tests

```bash
flutter test test/data/note_repository_test.dart
flutter test --plain-name "full-text search finds note content"
```

Use `python3` or Windows `py` where appropriate.

## Repository-maintenance tools

- `tool/check_version_sync.py` — verifies package/UI/changelog/version-specific notes, `.flutter-version`, and workflow Flutter pins.
- `tool/check_repo.py` — verifies required documentation/automation/cross-platform source baseline, tracked lockfile, unfinished markers, generated-file policy, and ignore rules.
- `tool/check_repository_reference.py` — verifies all **109 tracked files** are cataloged exactly once.
- `tool/check_markdown_links.py` — validates repository-local Markdown links.
- `tool/security_scan.py` — lightweight tracked credential-pattern scan.

## Test-data rules

- Use fictional note text and backups.
- Keep fixtures deterministic.
- Never require real credentials.
- Do not commit personal SQLite/browser storage dumps or real exported backups.
- Use explicit UTC timestamps for ordering tests.
- Avoid uncontrolled locale/timezone dependencies.
- Deterministic unit/widget tests must not require external services; platform bootstrap's reviewed Web asset download is a separate build input.

## Backup regression requirements

Every backup change should retain coverage for:

- Valid round trip.
- Malformed JSON/app/schema/type failures.
- Explicit UTC root/note/version timestamps.
- `updatedAt >= createdAt`.
- Tag parsing/canonicalization.
- Valid/null and invalid ARGB colors.
- Duplicate/whitespace-polluted identifiers.
- Invalid lifecycle combinations.
- Version-to-note relationships.
- Newer-local conflict preservation.
- Duplicate snapshots.
- Transaction rollback.
- Unicode content, empty library, and a large reasonable fixture.

Malformed input must be rejected before restore writes begin.

## Search/lifecycle/sort tests

FTS tests should cover title/body/folder/tag matches, multiple terms, quote/punctuation safety, appropriate Unicode, collection exclusion rules, and deterministic ordering where promised.

Collection metadata must match the active lifecycle predicate. Search terms must never be concatenated as executable SQL. Pinned-first behavior must remain explicit when configurable sort modes change secondary ordering.

## Editor/autosave tests

Protect:

- Snapshot-before-change.
- No snapshot on unchanged content.
- Restore makes snapshot content current.
- Cascade cleanup on permanent delete.
- Ordered saves.
- Stale completion cannot mark a newer draft saved.
- Back waits for successful current-draft save.
- Failed final save blocks Back/export/history.
- Retryable missing-note load state.
- Offset-zero first-line formatting.
- Live local word/character metrics.
- Save-before-duplicate semantics and duplicate editor replacement.

Real platform testing still needs lifecycle/background/system-back/process-termination behavior.

## Migration tests

Drift schema remains **1** for application 2.0.12. Starting with schema 2, every migration needs fixture-driven previous-schema → new-schema validation including data, constraints, FTS/index behavior, foreign keys, and repository operations.

The current 2.1 sorting, duplication, and text-metric work intentionally does not require a schema migration.

## Accessibility testing

Automation should check semantics, non-color selected state, minimum target size, discoverable controls, visible failure messages, and representative large-text layouts where practical.

Manual verification must cover screen readers, keyboard traversal, browser focus, zoom/text scaling, dark/light themes, reduced motion, compact/wide viewports, destructive-action clarity, and discoverability/readability of the 2.1 sort/text-metric controls. See [`accessibility.md`](accessibility.md).

## Platform build matrix

GitHub Actions verifies:

- Android release APK compile.
- Linux release compile.
- Windows release compile.
- macOS release compile.
- iOS release compile without signing.
- Chrome Web smoke + Web release compile.

The current file-picker-12 hardening generation has already completed all seven build/smoke steps successfully. The exact final post-documentation candidate must repeat them before release tagging.

The 2.1 branch must run its own matrix independently; a green 2.1 branch does not retroactively certify 2.0.12, and a green 2.0.12 verification run does not certify later 2.1 product changes.

Compilation is integration evidence, not proof of real-device/browser runtime behavior.

## CI expectations

PR/push verification should fail when:

- Release/toolchain versions drift.
- The committed lock cannot be enforced.
- Drift generation fails.
- Formatting/analyzer/tests fail.
- Required cross-platform repository files disappear.
- The 109-file catalog is stale or duplicated.
- Markdown links or tracked-secret checks fail.
- Platform bootstrap cannot apply required native patches or prepare compatible Web database assets.
- Any native compile lane fails.
- Chrome Web smoke or release Web compilation fails.

## Flaky-test/regression rule

A flaky test is a defect. Do not rerun until green without investigating timing, external dependency, randomness, or shared-state causes.

Every confirmed bug should get the smallest reliable regression test. If automation is genuinely infeasible, record the exact manual regression in the issue/PR/release handoff and look for a future injectable boundary.
