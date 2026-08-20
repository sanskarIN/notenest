# NoteNest Testing Strategy

Testing protects local user data first, then interaction quality. Deterministic invariants belong in automation; build success never substitutes for real runtime/accessibility validation.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Platform scope

The test/release strategy covers all six Flutter project targets:

- Android
- iOS / iPadOS
- Windows
- macOS
- Linux
- Web

Web is a first-class target, not a documentation-only compatibility claim. The platform workflow includes a Chrome-targeted fallback regression and a release-mode Web compilation job.

## Quality layers

### Core/service unit tests

Current deterministic coverage includes:

- `test/core/markdown_lite_test.dart` — Markdown-lite transformations.
- `test/core/markdown_document_codec_test.dart` — metadata round trips/malformed input.
- `test/core/import_limits_test.dart` — Markdown and backup byte boundaries.
- `test/core/bounded_file_reader_test.dart` — native streaming, oversize rejection, filesystem error translation.
- `test/core/safe_file_name_test.dart` — cross-platform/Unicode filename safety.
- `test/core/async_serial_queue_test.dart` — FIFO persistence ordering and failure continuation.
- `test/core/app_logger_test.dart` — logger redaction.
- `test/services/external_link_service_test.dart` — successful/refused/throwing launcher behavior.

### Web platform smoke regression

`test/web/web_platform_smoke_test.dart` runs under Chrome and protects browser-specific boundaries:

- Web app lock reports device authentication unavailable.
- Web authentication requests fail closed rather than throwing or registering an unsupported native plugin.
- Native filesystem path reads are unavailable in the browser and produce a domain import/export failure instead of compiling `dart:io` into the browser target.

Run it explicitly:

```bash
flutter test --platform chrome test/web/web_platform_smoke_test.dart
```

This smoke test complements—rather than replaces—release-mode `flutter build web` and real deployed-origin persistence/import/export tests.

### Application-controller tests

- `test/app/app_settings_controller_test.dart` — atomic load, serialized writes, rollback, persistence-first onboarding, app-lock preference behavior.
- `test/features/notes/notes_controller_test.dart` — collection-switch filter reset and collection-scoped metadata.

### Repository/database tests

In-memory Drift coverage:

- `test/data/note_repository_test.dart`
- `test/data/backup_repository_test.dart`
- `test/data/settings_repository_test.dart`

Note repository coverage includes create/update/search, quote-safe FTS input, lifecycle collections, pin/favorite/archive/trash invariants, snapshots, restore/cascade behavior, folder/tag metadata, and the no-pinned-trash invariant.

Backup coverage includes valid round trips, conflict-safe restore, app/schema/type validation, UTC timestamps, timestamp order, tags, IDs/relationships, 32-bit colors, lifecycle validation, duplicate identifiers/snapshots, and transaction safety.

### Widget tests

- `test/widgets/onboarding_page_test.dart` — privacy/offline messaging and persistence success/failure.
- `test/widgets/notes_page_empty_state_test.dart` — collection-specific empty states/actions.
- `test/widgets/note_editor_accessibility_test.dart` — selected/reset semantics and touch target.
- `test/widgets/note_editor_save_test.dart` — save-before-pop, load recovery, and first-line formatting boundary.
- `test/widgets/about_page_test.dart` — external-link failure feedback.

Future useful coverage includes broader editor toolbar operations, destructive confirmations, injected Settings failures, note-browser mutation failure UI, large-text layout coverage, and keyboard focus traversal.

## Cross-platform file transfer tests

File transfer has three boundaries:

1. Pure format/size validation.
2. Platform-selected data acquisition.
3. Persistence/import/export behavior.

Required invariants:

- Markdown/text ceiling: **16 MiB**.
- JSON backup ceiling: **64 MiB**.
- Exactly-at-limit input is accepted by the validator.
- Oversized input fails before UTF-8/JSON/Markdown processing.
- Native targets avoid eager picker byte loading and use bounded path streaming when a cached path is available.
- Web requests picker data because browsers do not expose native filesystem paths in the same way.
- Web validates both picker-reported size and actual bytes/stream accumulation before decoding.
- Strict UTF-8 is required.
- Filesystem errors become `ImportExportException`.
- Export names remain cross-platform and Unicode safe.

Manual/platform picker testing must include native/cloud document providers and browser file selection/download behavior because the provider/browser owns part of that pipeline.

## Web database and deployment tests

Drift Web depends on the generated `sqlite3.wasm` + `drift_worker.js` pair from the same Drift **2.34.3** release as the direct project dependency.

Automated Web verification must cover:

```bash
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Real deployment verification must additionally use the intended host/origin and check:

1. App boots without WASM/worker fetch errors.
2. `sqlite3.wasm` is served as `application/wasm`.
3. Create/edit/search works.
4. Note data survives page reload.
5. Note data survives browser restart under normal storage settings.
6. Markdown import/export works.
7. JSON backup export/restore works.
8. Oversized picker input is rejected.
9. Browser/site-data clearing behavior is documented rather than mistaken for sync durability.
10. Actual Drift browser storage mode is recorded; use cross-origin isolation when supported/desired for the optimal OPFS path, while accepting tested fallback modes when isolation is unavailable.

Test Chrome/Edge and at least one additional browser family appropriate to the intended support statement before stable browser distribution.

## App-lock platform tests

`local_auth 3.0.2` is used only where implemented. The expected current behavior is:

- Android: device authentication when supported.
- iOS/iPadOS: device authentication when supported.
- macOS: device authentication when supported.
- Windows: device authentication when supported.
- Linux: app-lock capability unavailable with the current dependency.
- Web: app-lock capability unavailable.

Unsupported platforms must remain fully usable. Test both an unset lock preference and a previously persisted `appLockEnabled=true` condition to prove the app does not become permanently inaccessible.

## Integration/end-to-end journeys

Important release journeys include:

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
13. Platform-supported app lock → background/resume/authenticate.
14. Unsupported app lock → app remains accessible and Settings reports unavailable.
15. Preference failure → previous persisted value restored.
16. Markdown import/export through actual native/browser picker paths.
17. Oversized file rejection through actual provider/browser behavior.
18. Repository/funding/mail/releases links success/failure.
19. Bootstrap settings failure → safe startup fallback and dependency cleanup.
20. Controlled root teardown → settings/database disposed.
21. Web create/edit/search → reload → browser restart persistence.
22. Web backup/Markdown download then re-import.

Use only fictional data.

## Commands

### Full deterministic quality gate

```bash
python tool/check_version_sync.py
dart run build_runner build --delete-conflicting-outputs
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
flutter pub get
dart run build_runner build --delete-conflicting-outputs
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

- `tool/check_version_sync.py` — verifies package/UI/changelog/version-specific release notes, `.flutter-version`, and every Flutter workflow pin.
- `tool/check_repo.py` — verifies the required documentation/automation/cross-platform source baseline, unfinished-source markers, generated-file policy, and important ignore rules.
- `tool/check_repository_reference.py` — verifies all **108 tracked files** are cataloged exactly once.
- `tool/check_markdown_links.py` — validates repository-local Markdown links deterministically.
- `tool/security_scan.py` — lightweight tracked credential-pattern scan.

## Test data rules

- Use fictional note text and backups.
- Keep fixtures deterministic.
- Never require real credentials.
- Do not commit personal SQLite/browser storage dumps or real exported backups.
- Use explicit UTC timestamps for ordering tests.
- Avoid uncontrolled locale/timezone dependencies.
- External network services must not be needed for deterministic unit/widget tests; platform bootstrap's pinned Web asset download is a separate build input.

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

## Search and lifecycle tests

FTS tests should cover title/body/folder/tag matches, multiple terms, quote/punctuation safety, Unicode supported by the tokenizer, collection exclusion rules, and stable ordering only where deterministic.

Collection metadata must match the active lifecycle predicate. Search terms must never be concatenated as executable SQL.

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

Real platform testing still needs lifecycle/background/system-back/process-termination behavior.

## Migration tests

Drift schema version remains **1** for application 2.0.12. Starting with schema 2, every migration needs fixture-driven previous-schema → new-schema validation including data, constraints, FTS/index behavior, foreign keys, and repository operations.

## Accessibility testing

Automation should check semantics, non-color selected state, minimum target size, discoverable controls, visible failure messages, and representative large-text layouts where practical.

Manual verification must cover screen readers, keyboard traversal, browser focus, zoom/text scaling, dark/light themes, reduced motion, compact/wide viewports, and destructive action clarity. See [`accessibility.md`](accessibility.md).

## Platform build matrix

GitHub Actions separately verifies:

- Android release APK compile.
- Linux release compile.
- Windows release compile.
- macOS release compile.
- iOS release compile without signing.
- Web Chrome smoke test + release compile.

A compiled target is evidence of integration/compilation only, not proof of real-device/browser runtime behavior.

The path filter includes application source, assets, package/build metadata, bootstrap changes, the workflow itself, and Web smoke tests so browser-support regressions cannot bypass the matrix.

## CI expectations

PR/push verification should fail when:

- Release/toolchain versions drift.
- Dependency resolution or Drift generation fails.
- Formatting/analyzer/tests fail.
- Required cross-platform repository files disappear.
- The exhaustive tracked-file catalog is stale/duplicated.
- Markdown links or tracked-secret checks fail.
- Platform bootstrap cannot apply native patches or prepare compatible Web database assets.
- Any native compile lane fails.
- Chrome Web smoke or release Web compilation fails.

## Flaky tests and regression rule

A flaky test is a defect. Do not rerun until green without investigating timing, external dependency, randomness, or shared-state causes.

Every confirmed bug should get the smallest reliable regression test. If automation is genuinely infeasible, record the exact manual regression in the issue/PR/release handoff and look for a future injectable boundary.
