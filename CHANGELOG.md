# Changelog

All notable NoteNest changes are documented here. The project follows the spirit of [Keep a Changelog](https://keepachangelog.com/) and intends to use semantic versioning for published releases.

## [Unreleased]

### Added

- Initial production-oriented Flutter application architecture.
- Drift/SQLite note database with version snapshots and foreign-key cleanup.
- SQLite FTS5 full-text search across note title, body, folder, and tags.
- Create/edit, pin, favorite, archive, trash, restore, permanent-delete, and empty-trash workflows.
- Folders, tags, note colors, collection filters, folder filters, and tag filters.
- Autosaving editor with Markdown-lite formatting helpers and checklist prefix support.
- Distraction-free editor mode.
- Version-history browser and restore action.
- Markdown/text import and Markdown export.
- Validated JSON backup/export and conflict-safe restore.
- Responsive phone/tablet/desktop navigation.
- Material 3 light, dark, and system themes.
- User-adjustable text scale and reduced-motion preference.
- Privacy-first onboarding.
- Optional operating-system-backed app lock through `local_auth`.
- Settings and About screens with project/support/funding information.
- Editable NoteNest SVG logo source and labeled layout-reference artwork.
- In-memory repository/database tests, backup-validation tests, settings tests, Markdown helper/metadata tests, logger-redaction tests, import-bound/bounded-reader tests, safe-filename tests, async-save-order tests, onboarding coverage, collection-empty-state coverage, and custom color-swatch accessibility coverage.
- Reproducible native runner bootstrap script for Android, iOS, Linux, macOS, and Windows.
- Repository documentation, contribution policy, security policy, privacy disclosure, support guide, ADRs, CI configuration, templates, and dependency automation.
- Deterministic Markdown local-link checker integrated into the CI quality gate.
- Exact Flutter SDK pin (`3.44.7`) synchronized across project, quality, platform-build, and release workflows.
- Shared 48-logical-pixel minimum touch-target design token for custom controls.
- Bounded native-file reader used by local note/backup imports.

### Fixed

- Serialized editor saves so overlapping autosave, lifecycle, export/history, and final navigation submissions cannot overtake one another and write an older submitted draft after a newer one.
- Prevented stale save completions from reporting a newer unsaved draft as saved.
- Corrected Favorites, Archive, and Trash empty states so they no longer offer create/import actions whose result would not appear in the active collection.
- Restricted Markdown import affordance to All Notes, where newly imported notes are immediately visible.
- Hardened Markdown export filenames against cross-platform invalid characters, trailing dots/spaces, excessive length, and Windows reserved device names.
- Replaced color-only editor swatch selection with explicit selected semantics and a visible checkmark while keeping a comfortable interaction target.
- Replaced moving-stable Flutter workflow setup with the exact project SDK version for reproducible automated builds.
- Removed eager `file_picker` byte loading from native Markdown/backup imports; selected cached files are now length-checked and consumed incrementally through the configured byte ceiling before NoteNest constructs the final in-memory buffer.

### Security

- Backup restore rejects malformed/non-NoteNest/unsupported-schema data before applying writes.
- Restore validation rejects malformed serialized tags, duplicate note IDs, and version entries that reference unknown notes.
- Restore operations preserve newer local note revisions.
- Imported text is decoded as UTF-8 and never executed.
- Markdown/text imports are rejected above 16 MiB before NoteNest constructs a complete import buffer.
- NoteNest JSON backups are rejected above 64 MiB before NoteNest constructs a complete import buffer or performs UTF-8/JSON processing.
- Native import reads are disk-backed/incremental after the picker returns a cached local path instead of requesting `withData: true` eager memory loading.
- SQL search inputs are transformed into parameterized FTS variables instead of interpolated into SQL.
- Common secret, signing, database, and local-environment files are excluded from source control.
- App lock delegates authentication to maintained platform APIs rather than custom authentication/cryptography.
- Generated Markdown export names are normalized before reaching platform save dialogs.

### Known release-preparation constraints

- Native runner templates and Drift-generated Dart files are intentionally generated during setup/CI instead of committed as stale generated output.
- A Flutter-enabled environment is required to produce runtime screenshots and final native artifacts.
- Store/distribution signing credentials are intentionally not part of the repository.
- The latest recorded GitHub Actions verification runs have not yet produced completed green results; stable release claims remain blocked until those checks and the documented manual platform/accessibility checks are recorded.

## [1.0.0] - Planned

The first stable release is planned after all configured CI jobs pass from a clean checkout, primary platform build checks complete, verified runtime screenshots replace the illustrative reference, and final manual accessibility/release checks are recorded in `what_changed.md`.

[Unreleased]: https://github.com/sanskarIN/notenest/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sanskarIN/notenest/releases/tag/v1.0.0
