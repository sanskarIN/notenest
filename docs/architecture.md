# NoteNest Architecture

## Goals

NoteNest is a local-first notes application whose architecture should remain understandable by one contributor while being strong enough for production-quality maintenance. The project therefore uses a **modular monolith** rather than introducing a backend or microservices that the product does not need.

Primary architecture goals:

- Keep Flutter UI separate from storage and platform integration.
- Keep core note workflows usable offline.
- Make dependencies explicit and replaceable in tests.
- Protect data integrity during edits, snapshots, trash operations, and restores.
- Keep schema evolution controlled through migrations.
- Keep platform-specific behavior behind small services.
- Preserve accessibility/responsive behavior as first-class UI requirements.
- Keep import/export formats validated and versioned.

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
│ FileTransferService / AppLockService                        │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Local infrastructure                                        │
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

Widgets receive these dependencies through constructors rather than reaching into a global service locator. This keeps ownership visible and makes later test doubles/adapters easier to introduce.

`AppDependencies.dispose()` closes resources owned by the composition root.

## Application shell

`lib/app/app.dart` owns application-wide concerns:

- Theme and text-scale settings.
- Flutter localization delegates.
- Reduced-motion media preference.
- First-run onboarding selection.
- Optional app-lock gate and lifecycle relocking.

It does not implement note persistence logic.

`HomeShell` chooses between compact bottom navigation and desktop/tablet `NavigationRail`, then routes the major app areas.

## Presentation layer

### Notes browser

`NotesPage` renders current `NotesController` state. It is responsible for interaction and visual state, including:

- Search bar.
- Folder/tag filters.
- Empty/loading/error states.
- Responsive note-card grid.
- Import action.
- Trash confirmations.

The page does not construct SQL statements.

### Editor

`NoteEditorPage` owns ephemeral text-controller state for one open note. It:

- Loads a note through `NoteRepository`.
- Debounces edits before repository persistence.
- Saves on lifecycle transitions.
- Offers Markdown-lite text transformations.
- Displays folder/tag/color controls.
- Opens snapshot history.
- Exports Markdown through `FileTransferService`.

The repository, not the widget, decides when a changed save creates a version snapshot.

### Settings

`SettingsPage` manipulates `AppSettingsController`, `FileTransferService`, and `AppLockService`. It distinguishes user preferences from note data.

### About

`AboutPage` contains project identity, version, privacy summary, license, contacts, GitHub, funding link, and required `Made by the Sanskar` credit.

## State management choice

The initial architecture uses small `ChangeNotifier` controllers instead of adopting an additional state-management framework. This keeps dependencies and learning surface small while providing reactive UI state.

Rules:

- Controllers should orchestrate UI state and call repositories/services.
- Repositories should own persistence/business invariants related to their storage model.
- Widgets should not mutate database tables directly.
- `ChangeNotifier` should not become a global mutable store for unrelated features.

If application complexity later justifies another state-management solution, it should be introduced through an ADR and migrated incrementally rather than mixing multiple patterns casually.

## Data model

### `notes`

Current note state includes:

- `id` — UUID string, primary key.
- `title` — text.
- `body` — text.
- `folder` — text, empty means no folder.
- `tags` — JSON-encoded list of strings.
- `color_value` — optional ARGB integer.
- `is_pinned`
- `is_favorite`
- `is_archived`
- `is_trashed`
- `created_at`
- `updated_at`

Times are created as UTC and converted to local time at display boundaries.

### `note_versions`

Snapshots contain the note's pre-change content/metadata plus `captured_at`. The relation references `notes.id` with cascade deletion so permanent deletion removes history.

Snapshots are created only when content/organizational fields passed to `saveContent` actually differ from current state. Flag-only actions such as favorite/pin currently do not create a snapshot.

### FTS5 index

`notes_fts` is an SQLite FTS5 external-content virtual table indexing:

- `title`
- `body`
- `folder`
- serialized `tags`

Insert/update/delete triggers keep the index synchronized with `notes`. Search terms are normalized into quoted prefix tokens and passed as a bound SQL variable.

Search results use `bm25(notes_fts)` ranking and then recent-update ordering.

## Data invariants

`NoteRepository` maintains important rules:

- IDs are generated by UUID v7.
- Tags are trimmed, deduplicated, sorted, and JSON encoded.
- An archived note is not trashed.
- Trashing a note unarchives and unpins it.
- Restore removes trash state without guessing a previous archive state.
- Active collection excludes archived/trashed rows.
- Favorites collection excludes archived/trashed rows.
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

The backup schema version is independent conceptually from Drift's database schema version even though both currently begin at `1`. They must be evolved deliberately because a database migration and an interchange-format change have different compatibility requirements.

Restore behavior:

1. Decode JSON.
2. Verify object root.
3. Verify application identity.
4. Verify supported backup schema version.
5. Verify note/version lists.
6. Parse every entry into typed companions; malformed required fields reject the operation.
7. Begin a database transaction.
8. Upsert incoming notes except where the current local note has a later `updatedAt`.
9. Add non-duplicate snapshots.
10. Commit and return a restore report.

A future format change must include backward-compatibility tests or a clear conversion tool.

## File transfer boundary

`FileTransferService` is the platform/file-picker boundary. It:

- Converts backup JSON to/from bytes.
- Ensures imported text is valid UTF-8.
- Produces filesystem-safe Markdown filenames.
- Generates minimal Markdown front matter.
- Delegates actual note creation/backup restore to repositories.

Imported Markdown is treated as text; it is never executed or rendered as trusted HTML.

## Settings boundary

Small non-sensitive preferences use `shared_preferences`. They are not stored in the notes database because they have different lifecycle and migration characteristics.

Current preferences:

- Theme mode.
- Text scale.
- Reduced motion.
- Onboarding completion.
- App-lock enabled state.

Sensitive credentials should not be added to `shared_preferences`.

## App lock boundary

`AppLockService` wraps `local_auth`. It answers whether device authentication is available and requests authentication.

Important security distinction:

- App lock gates UI access.
- It does not provide independent database encryption.
- NoteNest does not receive/store biometric templates.
- Authentication failure is handled as a safe locked state.

See `SECURITY.md` for the threat model.

## Error handling

`core/errors/app_exception.dart` centralizes domain-friendly exception categories such as:

- `StorageException`
- `ValidationException`
- `ImportExportException`
- `AuthenticationException`

Not every plugin exception is wrapped yet; UI boundaries catch user-triggered import/backup errors and display a safe message. Future logging should redact note content and sensitive paths.

## Responsive design

Main breakpoints are intentionally simple:

- `< 760 px`: bottom navigation.
- `>= 760 px`: navigation rail.
- `>= 1120 px`: extended navigation rail.

Notes grid:

- `< 560 px`: 1 column.
- `>= 560 px`: 2 columns.
- `>= 850 px`: 3 columns.
- `>= 1200 px`: 4 columns.

These are UI implementation thresholds, not claims about physical device categories. Changes should be driven by layout behavior rather than device-name detection.

## Accessibility architecture

Accessibility is enforced through reusable design choices:

- Standard Material controls with semantics/focus behavior.
- Tooltips on icon-only actions.
- Semantic labels on note cards and save indicator.
- Text-scale preference layered with Flutter's accessibility environment.
- Reduced-motion preference mapped to `MediaQuery.disableAnimations`.
- Non-color indicators for lifecycle actions.
- Destructive confirmation text.
- Wide tap targets through Material components.

Manual checks remain necessary; see `accessibility.md`.

## Generated native runners

Native runner files are generated using `tool/bootstrap_platforms.py` so templates match the contributor's Flutter SDK. The script applies small documented NoteNest-specific patches.

This decision avoids maintaining a large set of stale framework-generated templates while keeping native setup reproducible. See ADR 0003.

If native customization grows significantly (services, extensions, packaging metadata), the project may begin committing selected runner files or all runners after an ADR review.

## Schema migrations

Current schema version is `1`, so `onCreate` creates all tables and FTS infrastructure.

For version 2+:

- Increase `schemaVersion`.
- Add `onUpgrade` handling by old/new versions.
- Keep each migration deterministic.
- Rebuild/adjust FTS infrastructure if indexed columns change.
- Add migration fixtures/tests.
- Never rely on uninstall/reinstall as a migration strategy.

## Performance boundaries

Current local-first design intentionally keeps logic simple. Potential scale pressure points:

- `NoteRepository.list` currently loads a candidate list before applying collection/folder/tag filtering in Dart.
- `folders()` and `tags()` scan notes separately.
- Note grid is lazily built but does not use database pagination.
- Snapshot history can grow indefinitely.

These are acceptable for the initial simple-notes scope but explicitly documented for measurement before large-library optimization. See `performance.md`.

## Security boundaries

The architecture intentionally avoids backend-only controls that do not apply to a local app (CORS, server cookies, server CSRF, etc.). Relevant controls include:

- Parameterized database values.
- Import validation.
- Transactional restore.
- Least-privilege platform integration.
- Secret/signing exclusion.
- OS authentication delegation.
- No implicit note upload.
- No custom crypto.

## Architecture decisions

- [ADR 0001 — Flutter + Drift modular monolith](adr/0001-flutter-drift-modular-monolith.md)
- [ADR 0002 — Offline-first local data ownership](adr/0002-offline-first-data.md)
- [ADR 0003 — Reproducible generated native runners](adr/0003-generated-platform-runners.md)

Architecture changes that affect data ownership, schema compatibility, remote processing, authentication, or module boundaries should add a new ADR.
