# NoteNest Architecture

## Goals

NoteNest is a local-first notes application whose architecture should remain understandable by one contributor while being strong enough for production-quality maintenance. The project therefore uses a **modular monolith** rather than introducing a backend or microservices that the product does not need.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

Primary architecture goals:

- Keep Flutter UI separate from storage and platform integration.
- Keep core note workflows usable offline.
- Make dependencies explicit and replaceable in tests.
- Protect data integrity during edits, settings changes, snapshots, trash operations, imports, and restores.
- Keep schema evolution controlled through migrations.
- Keep platform-specific behavior behind small services.
- Preserve accessibility/responsive behavior as first-class UI requirements.
- Keep import/export formats validated and versioned.
- Keep release metadata synchronized automatically.

## High-level structure

```text
┌──────────────────────────────────────────────────────────────┐
│ Flutter presentation                                        │
│ HomeShell / NotesPage / NoteEditor / Settings / About       │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Application state/controllers                               │
│ NotesController / AppSettingsController                     │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Repositories and services                                   │
│ NoteRepository / BackupRepository / SettingsRepository      │
│ FileTransferService / AppLockService / ExternalLinkService  │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Local/platform infrastructure                               │
│ Drift / SQLite / FTS5 / SharedPreferences / platform APIs   │
└──────────────────────────────────────────────────────────────┘
```

## Composition root

`lib/app/app_dependencies.dart` is the explicit composition root. It creates:

- `AppDatabase`
- `NoteRepository`
- `SettingsRepository`
- `AppSettingsController`
- `BackupRepository`
- `FileTransferService`
- `AppLockService`
- `ExternalLinkService`
- `AppLogger`

Widgets receive dependencies through constructors rather than reaching into a global service locator. This keeps ownership visible and allows deterministic test doubles at plugin/storage boundaries.

`AppDependencies.dispose()` disposes settings state and closes the database it owns.

## Application shell

`lib/app/app.dart` owns application-wide concerns:

- Theme and text-scale settings.
- Flutter localization delegates.
- Reduced-motion media preference.
- First-run onboarding selection.
- Optional app-lock gate and lifecycle relocking.

It does not implement note persistence logic.

`HomeShell` chooses between compact bottom navigation and desktop/tablet `NavigationRail`, routes the major app areas, and passes shared service dependencies down to Settings/About.

## Presentation layer

### Notes browser

`NotesPage` renders current `NotesController` state and owns user interaction/visual state:

- Search bar.
- Folder/tag filters.
- Collection-specific empty/loading/error states.
- Responsive note-card grid.
- Markdown import action in All Notes.
- Trash confirmations.

The page does not construct SQL statements.

`NotesController` keeps collection, query, folder, tag, loading, error, note-list, and filter-metadata state. Collection switches clear folder/tag filters so a filter chosen in one collection cannot silently hide another collection. Repository folder/tag metadata is scoped to the active collection.

### Editor

`NoteEditorPage` owns ephemeral text-controller state for one open note. It:

- Loads a note through `NoteRepository`.
- Debounces edits before persistence submission.
- Captures immutable editor drafts.
- Serializes saves through `AsyncSerialQueue` so older submissions cannot overtake newer ones.
- Saves on lifecycle transitions.
- Offers Markdown-lite text transformations.
- Displays folder/tag/color controls.
- Opens snapshot history.
- Exports Markdown through `FileTransferService`.

The repository, not the widget, decides when a changed save creates a version snapshot. A save completion is displayed as current only when the persisted draft still matches visible editor content.

### Settings

`SettingsPage` manipulates `AppSettingsController`, `FileTransferService`, `AppLockService`, and `ExternalLinkService`.

`AppSettingsController` serializes preference writes. Appearance/accessibility/app-lock settings may update optimistically, but a failed write restores the last successfully persisted value and rethrows to the UI boundary for safe feedback.

Onboarding is deliberately persistence-first: the app does not leave onboarding until completion state has been saved successfully.

### About

`AboutPage` contains project identity, version, privacy summary, license, contacts, GitHub, funding link, and required `Made by the Sanskar` credit. External actions use `ExternalLinkService` rather than calling a launcher plugin directly.

## State management choice

The architecture uses small `ChangeNotifier` controllers instead of adding another state-management framework.

Rules:

- Controllers orchestrate UI state and call repositories/services.
- Repositories own persistence/business invariants related to their storage model.
- Widgets do not mutate database tables directly.
- `ChangeNotifier` does not become a global mutable store for unrelated features.
- Async controller work must be ordered or generation-guarded when stale completion could corrupt visible state.

If application complexity later justifies another state-management solution, introduce it through an ADR and migrate incrementally rather than mixing patterns casually.

## Data model

### `notes`

Current note state includes:

- `id` — UUID string, primary key.
- `title` — text.
- `body` — text.
- `folder` — text; empty means no folder.
- `tags` — JSON-encoded list of strings.
- `color_value` — optional 32-bit ARGB integer.
- `is_pinned`
- `is_favorite`
- `is_archived`
- `is_trashed`
- `created_at`
- `updated_at`

Times created by NoteNest are UTC and converted to local time only at display boundaries.

### `note_versions`

Snapshots contain the note's pre-change content/metadata plus `captured_at`. The relation references `notes.id` with cascade deletion so permanent deletion removes history.

Snapshots are created only when content/organizational fields passed to `saveContent` differ from current state. Flag-only actions such as favorite/pin currently do not create snapshots.

### FTS5 index

`notes_fts` is an SQLite FTS5 external-content virtual table indexing:

- `title`
- `body`
- `folder`
- serialized `tags`

Insert/update/delete triggers keep the index synchronized with `notes`. Search terms are normalized into quoted prefix tokens and passed as bound SQL variables.

Search results use `bm25(notes_fts)` ranking and then recent-update ordering.

## Note repository invariants

`NoteRepository` maintains rules including:

- IDs are generated by UUID v7.
- Tags are trimmed, deduplicated, sorted, and JSON encoded.
- An archived note is not trashed.
- Trashing a note unarchives and unpins it.
- Restore removes trash state without guessing an earlier archive state.
- All Notes excludes archived/trashed rows.
- Favorites contains active/non-archived favorites only.
- Archive contains archived/non-trashed rows.
- Trash contains trashed rows.
- Folder/tag metadata uses the same collection predicate as note listing.
- Pinned notes sort before unpinned notes, then by most recent update.
- A content save does not write/snapshot when values are unchanged.

Permanent deletion is intentionally irreversible inside the live database and therefore requires UI confirmation.

## Backup format

The JSON backup root currently contains:

```json
{
  "app": "NoteNest",
  "schemaVersion": 1,
  "exportedAt": "<UTC ISO-8601>",
  "notes": [],
  "versions": []
}
```

The backup schema version is independent from Drift's database schema version even though both currently begin at `1`.

Restore validation includes:

1. Decode JSON.
2. Verify object root.
3. Verify application identity.
4. Verify supported backup schema version.
5. Verify note/version lists.
6. Parse every entry into typed companions.
7. Require note/version identifiers without surrounding whitespace.
8. Validate serialized tag arrays.
9. Require `colorValue` to be null or a 32-bit ARGB integer.
10. Require stored timestamps to be explicit UTC values ending in `Z`.
11. Require each note's `updatedAt` not to precede its `createdAt`.
12. Reject duplicate incoming note IDs.
13. Verify every imported version references an incoming or existing note.
14. Only after validation, begin a database transaction.
15. Upsert incoming notes except when the local note has a later `updatedAt`.
16. Add non-duplicate snapshots.
17. Commit and return a restore report.

A future format change must include backward-compatibility tests or a clear conversion tool.

## File-transfer boundary

`FileTransferService` is the platform/file-picker boundary.

For native import it:

- Requests a picker result without eager `withData` loading.
- Uses the cached native file path.
- Reads through `BoundedFileReader`.
- Checks reported length before reading and checks accumulated length after each chunk.
- Enforces 16 MiB for Markdown/text and 64 MiB for NoteNest JSON backups.
- Requires strict UTF-8.
- Delegates structured validation to the Markdown/backup codecs/repositories.

For export it:

- Generates Markdown front matter.
- Uses `SafeFileName` to normalize invalid/reserved names.
- Truncates on Unicode code-point boundaries rather than splitting UTF-16 surrogate pairs.
- Delegates final save-location choice to the platform picker.

Imported Markdown is treated as text; it is never executed or rendered as trusted HTML.

## Settings boundary

Small non-sensitive preferences use `shared_preferences`; credentials must not be placed there.

Current preferences:

- Theme mode.
- Text scale.
- Reduced motion.
- Onboarding completion.
- App-lock enabled state.

`SettingsStore` is the injectable interface. `SettingsRepository` adapts the plugin and treats a reported failed setter result as `StorageException`. `AppSettingsController` serializes writes and owns rollback semantics.

## External-link boundary

`ExternalLinkService` is the only intended boundary for user-triggered repository/funding/email/release links.

It:

- Accepts an injectable launcher delegate for tests.
- Uses external application launch mode by default.
- Converts launcher failures/exceptions into a `false` result.
- Lets the calling UI provide context-appropriate feedback.

This prevents plugin failures from escaping as uncaught user-action errors.

## App-lock boundary

`AppLockService` wraps `local_auth`.

Important security distinction:

- App lock gates UI access.
- It does not provide independent database encryption.
- NoteNest does not receive/store biometric templates.
- Authentication failure is handled as a safe locked state.

See [`../SECURITY.md`](../SECURITY.md) for the threat model.

## Error handling

`core/errors/app_exception.dart` centralizes domain-friendly exception categories:

- `StorageException`
- `ValidationException`
- `ImportExportException`
- `AuthenticationException`

Plugin/platform boundaries catch or translate failures before they reach presentation where practical. User-visible errors do not expose note bodies, credentials, raw stack traces, or sensitive file content.

## Responsive design

Main thresholds:

- `< 760 px`: bottom navigation.
- `>= 760 px`: navigation rail.
- `>= 1120 px`: extended navigation rail.

Notes grid:

- `< 560 px`: 1 column.
- `>= 560 px`: 2 columns.
- `>= 850 px`: 3 columns.
- `>= 1200 px`: 4 columns.

These are logical layout thresholds, not physical-device detection.

## Accessibility architecture

Accessibility is reinforced through reusable design choices:

- Standard Material controls with semantics/focus behavior.
- Tooltips on icon-only actions.
- Semantic labels on note cards and save indicator.
- Text-scale preference layered with Flutter's accessibility environment.
- Reduced-motion preference mapped to `MediaQuery.disableAnimations`.
- Non-color selected indicators for custom note-color choices.
- A shared 48 logical-pixel minimum custom interaction target.
- Destructive confirmation text.
- Safe failure messages for persistence/external actions.

Manual checks remain necessary; see [`accessibility.md`](accessibility.md).

## Release metadata boundary

Application version information exists in more than one place because Flutter packaging and the visible About UI have different consumers.

`tool/check_version_sync.py` prevents silent drift by requiring:

- `pubspec.yaml` semantic version/build number.
- Matching `AppStrings.version`.
- Matching `CHANGELOG.md` release section.
- Matching `docs/releases/<version>.md` with exact package and visible versions.

CI runs this check before Flutter dependency/build work.

## Generated native runners

Native runner files are generated using `tool/bootstrap_platforms.py` so templates match the pinned Flutter SDK. The script applies documented NoteNest-specific patches.

See ADR 0003. If native customization grows significantly, committing selected/all runners may become preferable after an ADR review.

## Schema migrations

Current Drift schema version is `1`.

For version 2+ of the **database schema** (independent from app version 2.0.12):

- Increase `schemaVersion`.
- Add `onUpgrade` handling by old/new versions.
- Keep each migration deterministic.
- Rebuild/adjust FTS infrastructure if indexed columns change.
- Add migration fixtures/tests.
- Never rely on uninstall/reinstall as a migration strategy.

## Performance boundaries

Current pressure points worth measuring before optimization:

- `NoteRepository.list` loads a candidate list before applying collection/folder/tag filtering in Dart.
- Folder/tag metadata scans notes for the active collection.
- Note grid is lazily built but database pagination is not yet implemented.
- Snapshot history can grow indefinitely.
- Bounded import still creates a final in-memory buffer after the streamed size check.

These are documented tradeoffs, not reasons to add complexity without profiling. See [`performance.md`](performance.md).

## Security boundaries

Relevant controls include:

- Parameterized database values.
- Strict import/backup validation.
- Bounded native-file reads.
- Transactional restore.
- Preference-write failure detection/rollback.
- Safe external-link boundary.
- Least-privilege platform integration.
- Secret/signing exclusion.
- OS authentication delegation.
- No implicit note upload.
- No custom cryptography.

Backend-only controls such as server cookies/CORS/CSRF are not applicable while NoteNest has no project-operated backend.

## Architecture decisions

- [ADR 0001 — Flutter + Drift modular monolith](adr/0001-flutter-drift-modular-monolith.md)
- [ADR 0002 — Offline-first local data ownership](adr/0002-offline-first-data.md)
- [ADR 0003 — Reproducible generated native runners](adr/0003-generated-platform-runners.md)

Architecture changes affecting data ownership, schema compatibility, remote processing, authentication, or major module boundaries should add a new ADR.
