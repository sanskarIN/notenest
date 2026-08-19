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
- In-memory repository/database tests, backup-validation tests, settings tests, Markdown helper tests, and onboarding widget coverage.
- Reproducible native runner bootstrap script for Android, iOS, Linux, macOS, and Windows.
- Repository documentation, contribution policy, security policy, privacy disclosure, support guide, ADRs, CI configuration, templates, and dependency automation.

### Security

- Backup restore rejects malformed/non-NoteNest/unsupported-schema data before applying writes.
- Restore operations preserve newer local note revisions.
- Imported text is decoded as UTF-8 and never executed.
- SQL search inputs are transformed into parameterized FTS variables instead of interpolated into SQL.
- Common secret, signing, database, and local-environment files are excluded from source control.
- App lock delegates authentication to maintained platform APIs rather than custom authentication/cryptography.

### Known release-preparation constraints

- Native runner templates and Drift-generated Dart files are intentionally generated during setup/CI instead of committed as stale generated output.
- A Flutter-enabled environment is required to produce runtime screenshots and final native artifacts.
- Store/distribution signing credentials are intentionally not part of the repository.

## [1.0.0] - Planned

The first stable release is planned after all configured CI jobs pass from a clean checkout, primary platform build checks complete, verified runtime screenshots replace the illustrative reference, and final manual accessibility/release checks are recorded in `what_changed.md`.

[Unreleased]: https://github.com/sanskarIN/notenest/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sanskarIN/notenest/releases/tag/v1.0.0
