# NoteNest Data Portability and Recovery

This document is the implementation-facing reference for moving NoteNest data between files and local databases. It complements `PRIVACY.md`, `SECURITY.md`, `docs/architecture.md`, `docs/testing.md`, and `docs/release.md`.

NoteNest is offline-first. Export files can contain private note content and must be treated as sensitive user data even though the formats are intentionally readable and interoperable.

## Portability surfaces

NoteNest currently supports two local portability formats:

1. **JSON backup** — complete application backup containing notes and version-history snapshots.
2. **Markdown export/import** — one note at a time, with optional versioned NoteNest metadata that preserves title, folder, tags, and update timestamp.

Neither format requires a NoteNest account, backend, cloud service, or API key.

## JSON backup format

`BackupRepository` owns JSON serialization and restore rules.

Top-level structure:

```json
{
  "app": "NoteNest",
  "schemaVersion": 1,
  "exportedAt": "2026-08-19T00:00:00.000Z",
  "notes": [],
  "versions": []
}
```

`exportedAt` describes the export event. Conflict resolution is based on each note's `updatedAt`, not the backup's export timestamp.

### Note records

Each exported note contains:

- `id`
- `title`
- `body`
- `folder`
- `tags`
- `colorValue`
- `isPinned`
- `isFavorite`
- `isArchived`
- `isTrashed`
- `createdAt`
- `updatedAt`

Tags are stored in the database as serialized JSON text and validated as a text-list representation during restore.

### Version records

Each exported version snapshot contains:

- `noteId`
- title/body/folder/tags/color state
- pin/favorite/archive/trash state
- `capturedAt`

Version identifiers are database-local implementation details and are not required for semantic restore identity. A snapshot is treated as already present when its owning note ID and capture timestamp match an existing snapshot.

## Backup validation order

Restore treats every selected backup as untrusted input. Validation occurs before transactional mutation.

The restore path rejects, among other malformed states:

- invalid JSON
- non-object JSON root
- wrong application marker
- unsupported backup schema version
- malformed `notes` or `versions` lists
- missing/wrong primitive field types
- invalid timestamps
- malformed serialized tag JSON
- tag JSON that is not a list of strings
- empty note IDs
- duplicate incoming note IDs
- version rows with an empty owner ID
- version rows whose owner note is not included in the same backup

The relationship rule is deliberately strict: an existing local note with a matching ID does **not** make an otherwise dangling incoming history row valid. This prevents a malformed or hostile backup from injecting arbitrary snapshot history into unrelated local records.

## Transactionality

After parsing and validation, mutations execute inside a Drift/SQLite transaction. A failure during the mutation phase must not intentionally leave a partially restored logical backup.

The repository tests include malformed-input preservation checks. When adding a new backup field or schema version, add tests that verify both successful migration/restore and failed-restore atomicity.

## Conflict semantics

For an incoming note whose ID does not exist locally, the incoming record is inserted.

For an incoming note whose ID already exists locally:

- **Local `updatedAt` is later:** local note wins; incoming note is skipped.
- **Incoming `updatedAt` is later:** incoming note may replace the older local record.
- **Timestamps are equal and restorable state is identical:** no-op; the record is not rewritten or reported as a conflict.
- **Timestamps are equal but restorable state differs:** local note wins. Equal timestamp is not treated as evidence that the incoming copy is newer.

The equal-timestamp local-wins rule avoids destructive tie-breaking when timestamps cannot establish ordering.

`RestoreReport` records imported notes, imported versions, and skipped local-wins conflicts.

## Version restore behavior

Restoring a historical version makes the selected snapshot's note content/organization state current. The repository keeps normal note persistence boundaries and does not bypass the database layer.

Version-history deletion follows note deletion through the database foreign-key cascade. Empty-trash and permanent-delete regressions verify that removed notes do not leave orphaned snapshot history.

## Markdown format

`MarkdownDocumentCodec` owns the NoteNest Markdown metadata format.

A NoteNest export starts with a small versioned front-matter-like block:

```text
---
notenest: 1
title: "Example"
folder: "School"
tags: ["physics", "revision"]
updatedAt: "2026-08-19T00:00:00.000Z"
---

Body starts here.
```

Metadata values are JSON-encoded instead of parsed with an unrestricted YAML parser. This keeps quoting and Unicode handling deterministic and limits the grammar the importer needs to trust.

### Recognition rule

Only a front-matter block that explicitly declares a recognized `notenest` metadata version is interpreted as NoteNest metadata.

Therefore:

- ordinary Markdown remains ordinary Markdown
- unrelated YAML-style front matter remains note body text
- unsupported NoteNest metadata versions fail explicitly
- malformed recognized NoteNest fields fail explicitly instead of being guessed

### Body preservation

The encoder owns exactly one separator newline after the metadata block. The decoder removes exactly that codec-owned separator and preserves the actual note body after it.

Regression tests cover:

- ordinary body text
- Unicode text
- quotes
- an intentionally leading body newline
- an empty body
- Markdown separator text inside the body

This prevents export/import cycles from silently adding a leading blank line.

## Import byte limits

File import is bounded before decode/parse work.

The current limits are centralized in `ImportLimits`:

- JSON backup: 64 MiB maximum
- Markdown/text note: 8 MiB maximum

When the file picker provides bytes directly, the byte count is validated immediately. When only a filesystem path is available, `BoundedFileReader` checks file length before loading the file into memory and validates the returned byte count again.

These limits are safety/resource bounds, not storage quotas for the local database.

## UTF-8 handling

Selected backup and Markdown files are decoded as strict UTF-8. Malformed UTF-8 is rejected rather than silently replacing invalid byte sequences.

This makes import failure explicit and avoids converting corrupt input into different note text without user intent.

## Export filenames

`SafeFileName` derives Markdown export filenames from note titles.

Normalization:

- replaces cross-platform-invalid filename characters
- collapses whitespace
- removes trailing dots/spaces
- protects Windows reserved device names
- falls back to `untitled-note` when normalization leaves no usable name
- limits the name to 80 Unicode scalar values

Truncation operates on Unicode scalar values instead of UTF-16 code units, so a filename is not cut between surrogate halves of an emoji or another supplementary Unicode character.

Backup filenames use a UTC date stamp and a fixed NoteNest prefix.

## File picker boundary

`FileTransferService` is the platform-facing boundary for:

- backup save
- backup selection/restore
- Markdown save
- Markdown/text selection/import

Pure payload correctness belongs in codecs/repositories/utilities and is covered without requiring the native file picker. The picker itself still requires representative runtime checks on supported platforms before a stable release.

## Privacy handling

Exports can contain:

- full titles and bodies
- folder/tag organization
- note lifecycle flags
- history snapshots
- timestamps

Do not:

- commit real exports as fixtures
- attach personal backups to public issues
- paste private note bodies into CI logs
- upload user backups to third-party services automatically

Use fictional data for tests, screenshots, examples, and bug reproductions.

## Compatibility rules for future changes

When changing JSON backup semantics:

1. Decide whether the existing schema can represent the change safely.
2. Increase `backupSchemaVersion` for incompatible interpretation changes.
3. Preserve validation-before-mutation.
4. Define conflict behavior explicitly.
5. Add old/new compatibility tests.
6. Update this document, `CHANGELOG.md`, and release notes.

When changing NoteNest Markdown metadata:

1. Preserve ordinary Markdown behavior.
2. Do not reinterpret unrelated front matter.
3. Increase metadata schema version for incompatible changes.
4. Add exact body-preservation tests.
5. Keep values safely encoded rather than adding ambiguous ad-hoc parsing.

## Verification commands

Core portability regressions are exercised by the normal Flutter suite:

```bash
flutter test test/core/markdown_document_codec_test.dart
flutter test test/core/safe_file_name_test.dart
flutter test test/core/bounded_file_reader_test.dart
flutter test test/data/backup_repository_test.dart
flutter test test/integration/note_lifecycle_integration_test.dart
```

The complete release-quality gate remains documented in `docs/testing.md` and `docs/release.md`.
