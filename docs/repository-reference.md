# NoteNest Repository Reference

Current audited application target: **2.0.12** (`2.0.12+2012`).

This document is the exhaustive map of files intentionally tracked in the NoteNest repository. It exists so a contributor can understand the responsibility, maintenance impact, and source-of-truth role of every committed file without guessing from directory names.

## Exhaustive-documentation contract

At this checkpoint the repository has **103 tracked files**. Every one appears exactly once in the catalog below. The contract is enforced by:

```bash
python tool/check_repository_reference.py
```

The checker compares `git ls-files` with catalog entries in this document. A tracked file addition, deletion, or rename must update this reference in the same change. Duplicate and stale catalog entries fail the check as well.

This reference describes committed source and project files. It does not claim that generated output, local caches, signing material, user data, or native build artifacts are repository source.

## Architecture orientation

The principal dependency flow remains:

```text
Flutter widgets/features
        ↓
controllers/application state
        ↓
repositories and platform services
        ↓
Drift / SQLite / SharedPreferences / platform plugins
```

`lib/app/app_dependencies.dart` is the composition root. Note data lives behind `NoteRepository`, backup interchange behind `BackupRepository`, settings behind `SettingsStore`/`SettingsRepository`, platform file operations behind `FileTransferService`, operating-system authentication behind `AppLockService`, and external URI handling behind `ExternalLinkService`.

The data model has three independent version domains that must not be confused:

1. Application version: 2.0.12.
2. Flutter package build: 2012.
3. Drift database schema: 1.

Backup schema versioning is another independent compatibility surface.

## Tracked-file catalog

Descriptions below explain both what each file does and why it matters when modifying the project.

### Repository configuration and top-level governance

- `.editorconfig` — Defines repository-wide UTF-8/LF, final-newline, whitespace, and two-space indentation behavior, while preserving meaningful Markdown trailing spaces and Makefile tabs. Change this only when editor-format policy changes for the whole repository.
- `.env.example` — Documents the only current build-channel placeholder (`NOTENEST_BUILD_CHANNEL=stable`) and explicitly states that core offline NoteNest requires no runtime secrets. Never turn this into a place for real credentials.
- `.flutter-version` — Pins the project Flutter SDK to 3.44.7 so local tooling and automation can use the same framework revision. `tool/check_version_sync.py` now rejects any CI/platform/release Flutter action pin that drifts from this file.
- `.gitattributes` — Normalizes repository text to LF, preserves CRLF for Windows shell scripts, and marks common image formats as binary. This prevents accidental cross-platform line-ending churn.
- `.gitignore` — Excludes Flutter/Dart outputs, generated Drift files, local SQLite files, IDE noise, `.env` secrets, signing material, native transient directories, coverage/test artifacts, and logs while retaining `.env.example`. Security-sensitive ignore rules are also enforced by `tool/check_repo.py`.
- `analysis_options.yaml` — Dart/Flutter static-analysis policy: Flutter lints plus strict casts/inference/raw types and async/context/formatting-oriented project rules; generated `.g.dart` files are excluded. Prefer fixing code over weakening these rules globally.
- `build.yaml` — Drift build-runner configuration; currently keeps `store_date_time_values_as_text` disabled so generated persistence code uses the selected native DateTime storage representation. Schema/storage changes must consider this setting.
- `pubspec.yaml` — Canonical Flutter package metadata for `notenest`, private publication status, version `2.0.12+2012`, SDK constraints, pinned runtime/dev dependencies, Material support, and branding assets. Dependency/version changes must be validated against workflows and release metadata.
- `README.md` — Primary project landing page: product purpose, release status, features, supported targets, setup, quality gates, architecture, privacy/security/accessibility, documentation links, and contribution/support entry points. It should summarize current truth and point to deeper sources rather than overclaim verification.
- `CHANGELOG.md` — Release-oriented change history following Keep-a-Changelog semantics; currently carries the 2.0.12 release-candidate record. User-visible behavior, fixes, security hardening, and repository/release engineering changes should be recorded here in the relevant version.
- `ROADMAP.md` — Forward-looking product and engineering direction after the current candidate. Roadmap items are intentions, not shipped features; keep local-first/privacy constraints explicit.
- `PRIVACY.md` — Public data-practice disclosure for the local-first app, including storage, imports/exports, app lock, external links, and absence of required project-operated cloud/analytics behavior. Any new networking, telemetry, accounts, AI processing, ads, or third-party data flow requires review here.
- `SECURITY.md` — Threat model, supported security posture, safe handling rules, vulnerability-reporting process, and security boundary clarifications such as app lock versus database encryption. Update whenever trust boundaries, dependencies, data flows, permissions, or disclosure procedures change.
- `SUPPORT.md` — User/contributor support channels and troubleshooting/reporting guidance. It separates ordinary support from private security reporting and should remain consistent with contact information elsewhere.
- `CONTRIBUTING.md` — Contributor workflow covering setup, branches/commits, testing, pull requests, documentation, and project standards. Keep it aligned with the actual CI commands and architecture rules.
- `CODE_OF_CONDUCT.md` — Community conduct expectations and enforcement/reporting guidance for project participation. This governs contributor interaction rather than application runtime behavior.
- `LICENSE` — MIT license text governing reuse and distribution of the open-source repository. Do not edit casually; license changes have project-wide legal implications.
- `what_changed.md` — Continuation and release-engineering handoff recording what was changed, what was inspected, exact verification limitations/status, commit checkpoints, and remaining stable-release blockers. Update it at every major continuation boundary.

### GitHub community and automation

- `.github/FUNDING.yml` — Configures the repository’s GitHub funding surface for the project’s support link. Keep it aligned with the funding URL shown in product/project documentation.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — Structured bug-report form that asks reporters for reproducible, actionable defect information. Update it when supported platforms, diagnostic expectations, or bug-triage requirements change.
- `.github/ISSUE_TEMPLATE/config.yml` — Controls the GitHub issue-template chooser and related issue-entry behavior. Keep external support/security routing consistent with `SUPPORT.md` and `SECURITY.md`.
- `.github/ISSUE_TEMPLATE/feature_request.yml` — Structured feature-request form for proposed NoteNest improvements. It should continue to prompt for user value, privacy/offline implications, and enough context for maintainers to assess scope.
- `.github/dependabot.yml` — Configures automated dependency update proposals for the repository. Review its ecosystem/schedule whenever dependency-management or workflow policy changes.
- `.github/pull_request_template.md` — Default pull-request checklist and reviewer context for code, tests, documentation, security, accessibility, and release-impact review. Keep it synchronized with the enforced quality gate.
- `.github/workflows/ci.yml` — Primary Linux quality workflow for pushes/PRs: pins Flutter 3.44.7, verifies application/release/toolchain versions, resolves packages, generates Drift code, checks formatting/analyzer/tests, then runs repository/reference/documentation/security policy tools and uploads coverage. Any new deterministic repository gate should be wired here.
- `.github/workflows/platform-builds.yml` — Cross-platform compile workflow triggered by bundled assets plus relevant source/build/bootstrap changes; generates runners and compiles Android, Linux, Windows, macOS, and unsigned iOS using Flutter 3.44.7. It catches native/plugin integration failures that Linux-only unit tests cannot prove away and prevents asset-only changes from bypassing native compile verification.
- `.github/workflows/release.yml` — Tag/manual artifact workflow that packages Android, Linux, Windows, macOS, and unsigned iOS outputs with the pinned toolchain. It is packaging automation, not permission to publish an unverified tag or unsigned store build.
- `.github/workflows/security.yml` — Dedicated security-oriented GitHub Actions workflow for repository security checks. Keep it deterministic, least-privilege, and consistent with `SECURITY.md` and the tracked-file secret policy.

### Branding and documentation assets

- `assets/branding/notenest_logo.svg` — Editable vector source for the NoteNest logo used by project documentation/assets. Treat it as canonical project artwork and preserve accessible alt text wherever embedded.
- `docs/assets/screenshots/layout-reference.svg` — Illustrative layout reference used until verified runtime captures exist. It must not be presented as evidence that a particular platform/runtime build was visually verified.

### Engineering and product documentation

- `docs/accessibility.md` — Detailed accessibility requirements and manual verification matrix for keyboard use, semantics, touch targets, text scaling, contrast/non-color cues, reduced motion, screen readers, and responsive layouts. It deliberately describes goals/checks rather than claiming formal certification.
- `docs/adr/0001-flutter-drift-modular-monolith.md` — Architecture Decision Record choosing Flutter + Drift in a modular-monolith structure. It preserves the rationale/tradeoffs behind the core technology and module-boundary choice.
- `docs/adr/0002-offline-first-data.md` — Architecture Decision Record establishing offline-first/local data ownership as a product constraint. New sync/cloud features must reconcile with this decision rather than silently bypassing it.
- `docs/adr/0003-generated-platform-runners.md` — Architecture Decision Record explaining why native runner templates are generated reproducibly instead of being tracked. It is the source of truth for the `tool/bootstrap_platforms.py` strategy and its tradeoffs.
- `docs/architecture.md` — Deep system design: composition root, presentation/controllers, repositories/services, Drift schema/FTS, backup/settings/import/external-link/app-lock boundaries, error handling, accessibility, migrations, performance, and security. Material structural changes should update this and, when warranted, add an ADR.
- `docs/development.md` — Day-to-day engineering guide covering module dependency direction, database/schema work, repositories/controllers, autosave, settings, imports/backups, links, app lock, dependencies, versioning, testing, accessibility, docs, and commit discipline. Keep commands synchronized with CI.
- `docs/github.md` — Repository-hosting operations guide for issues, pull requests, branches, checks, releases, and GitHub-side maintenance. Update when automation, review, or repository-management practices change.
- `docs/performance.md` — Performance goals, pressure points, measurement guidance, and optimization rules for note listing/search/editor/import/snapshot behavior. Use profiling evidence before adding complexity.
- `docs/release.md` — Release engineering procedure and checklist: application/toolchain version synchronization, generated code, repository/reference checks, native builds, manual verification, signing/artifacts/checksums, and tag discipline. A tag is not considered ready merely because packaging automation exists.
- `docs/releases/2.0.12.md` — Version-specific engineering/release notes for the 2.0.12 candidate (`2.0.12+2012`), including hardening and verification requirements. `tool/check_version_sync.py` treats this version-specific document as a required release surface.
- `docs/repository-reference.md` — This exhaustive tracked-file catalog and maintenance map. `tool/check_repository_reference.py` requires every tracked path—including this file—to appear exactly once here, so additions/deletions/renames must update the catalog in the same change.
- `docs/setup.md` — Clean-clone prerequisite and setup instructions across supported development hosts, including pinned Flutter, native toolchains, runner generation, package resolution, code generation, and first run. Update whenever bootstrap prerequisites or commands change.
- `docs/testing.md` — Testing strategy and regression inventory spanning core/service, controller, repository/database, widget, integration, accessibility, performance, migration, import/backup, repository/toolchain policy, and platform-build verification. It distinguishes tests present from checks actually executed successfully.
- `docs/troubleshooting.md` — Symptom-oriented setup/build/runtime troubleshooting with recovery steps that avoid risking real user data. Extend it when recurring installation, code-generation, platform, database, or plugin failures are diagnosed.

### Application composition and core

- `lib/main.dart` — Process entry point: initializes Flutter bindings, creates `AppDependencies`, launches `NoteNestApp`, and falls back to a minimal safe bootstrap-failure UI with redacted logging if initialization throws.
- `lib/app/app.dart` — Application shell: MaterialApp configuration, theme/text scale/localization, reduced-motion media setting, onboarding routing, lifecycle-aware app-lock gate, settings-listener ownership, and final delegation to `AppDependencies.dispose()` when the root state is permanently removed.
- `lib/app/app_dependencies.dart` — Explicit composition root that creates the database, repositories, settings controller, backup/file/app-lock/link services, and logger; it cleans partially created resources if initial settings loading fails and owns the final settings/database disposal operation invoked by the root app.
- `lib/app/app_settings_controller.dart` — App-wide settings state with atomic loading and serialized persistence through `AsyncSerialQueue`; optimistic theme/font/motion/app-lock changes roll back to the last persisted value on applicable failures, while onboarding is persistence-first.
- `lib/core/constants/app_strings.dart` — Central project/product strings including app identity, 2.0.12 visible version, contacts, repository/funding URLs, navigation labels, and collection-specific empty-state text. Version/contact changes should update the corresponding documentation and synchronization checks.
- `lib/core/errors/app_exception.dart` — Small sealed exception taxonomy (`StorageException`, `ValidationException`, `ImportExportException`, `AuthenticationException`) used to translate lower-level failures into domain-meaningful boundaries without leaking raw implementation detail.
- `lib/core/logging/app_logger.dart` — Structured `dart:developer` logger that normalizes event names, maps severity, bounds arbitrary string fields, and redacts keys likely to contain note/user/credential/file data. Tests protect redaction behavior.
- `lib/core/theme/app_theme.dart` — Material 3 light/dark theme construction, seeded color scheme, project text scaling, input/card/snackbar defaults, and platform-appropriate page transitions. Shared sizing/breakpoints belong in tokens rather than being duplicated here.
- `lib/core/theme/app_tokens.dart` — Reusable design/behavior tokens: spacing/radii, 48 logical-pixel minimum custom touch target, navigation/grid breakpoints, content extents, and search/autosave/motion durations. UI changes should reuse these where the value is a project-wide invariant.
- `lib/core/utils/async_serial_queue.dart` — Minimal async FIFO primitive that serializes submitted tasks and returns typed task results while allowing later work to continue after an earlier failure. It underpins ordering-sensitive editor and settings persistence.
- `lib/core/utils/bounded_file_reader.dart` — Filesystem boundary that checks reported length, incrementally reads a cached native file, rechecks accumulated bytes, and translates file errors while enforcing an upper byte limit before producing the final buffer.
- `lib/core/utils/debouncer.dart` — Timer-based helper that coalesces high-frequency UI work such as note autosave/search submissions. Dispose/cancel behavior matters whenever it is owned by a widget/controller lifecycle.
- `lib/core/utils/import_limits.dart` — Central byte ceilings and validation helpers for untrusted native imports: Markdown/text and NoteNest backup limits. New import formats should define similarly explicit, tested bounds.
- `lib/core/utils/markdown_document_codec.dart` — Codec for NoteNest Markdown import/export metadata and text representation, including validation of supported front-matter-like fields. Changes can affect interchange compatibility and require round-trip/malformed-input tests.
- `lib/core/utils/markdown_lite.dart` — Pure Markdown-lite editing/preview transformations used by the editor toolbar without introducing a rich-document storage model. Keep transformations deterministic and storage-compatible.
- `lib/core/utils/safe_file_name.dart` — Cross-platform export basename sanitizer handling invalid/control characters, whitespace, trailing dots/spaces, Windows reserved names, fallback names, Unicode preservation, and code-point-safe truncation.

### Data and domain

- `lib/data/database/app_database.dart` — Drift database root at schema version 1; enables foreign keys, creates Notes/NoteVersions, builds/maintains an external-content SQLite FTS5 index with triggers, and executes parameterized ranked prefix search. Future schema versions require deterministic migrations.
- `lib/data/database/tables.dart` — Declarative Drift table definitions for current notes and pre-change note-version snapshots, including lifecycle flags, timestamps, optional ARGB color, and cascading version cleanup on permanent note deletion.
- `lib/data/repositories/backup_repository.dart` — Backup export/restore boundary that serializes the NoteNest interchange payload, validates app/schema/types/UTC timestamps/IDs/tags/colors/lifecycle relationships before writes, then performs conflict-safe transactional restore and snapshot de-duplication.
- `lib/data/repositories/note_repository.dart` — Authoritative note persistence/invariant boundary: UUID-v7 creation, canonical tags, FTS-backed listing/filtering, transactional content snapshots, version restore, lifecycle/favorite/pin operations, deletion, and collection-scoped metadata. It now rejects attempts to pin a trashed note so live state matches backup lifecycle invariants.
- `lib/data/repositories/settings_repository.dart` — `SettingsStore` abstraction plus SharedPreferences adapter for theme, font scale, reduced motion, onboarding, and app-lock flags. Setter failures are converted to storage failures so the controller can roll back truthful visible state.
- `lib/domain/models/note_filter.dart` — UI-independent note-query value model describing collection, text query, folder, and tag filters. It is the contract between browser/controller behavior and repository list semantics.

### Features, services, and reusable widgets

- `lib/features/about/about_page.dart` — About/project-information UI showing identity/version/privacy/license/contact/repository/funding details. User-triggered external actions go through `ExternalLinkService` and surface launch failure safely.
- `lib/features/home/home_shell.dart` — Responsive top-level feature shell selecting compact bottom navigation or wider navigation rail, routing major areas, and protecting the floating new-note path from uncaught repository/navigation failures.
- `lib/features/notes/note_editor_page.dart` — Primary note-editing UI: note loading, immutable draft capture, debounced/serialized autosave, save-before-pop, lifecycle saves, Markdown-lite actions including correct first-line targeting at caret offset zero, metadata/color editing, version history, export, and retryable error feedback. Data integrity here depends on `NoteRepository` and `AsyncSerialQueue` contracts.
- `lib/features/notes/notes_controller.dart` — Feature controller for note browser state, collection/query/folder/tag filters, async loads/errors, generation protection against stale completions, and collection-scoped filter metadata. Collection switches clear incompatible folder/tag selections.
- `lib/features/notes/notes_page.dart` — Notes-browser presentation for search/filter controls, responsive card grid, collection-specific empty/loading/error states, import where visible, and guarded note mutations including archive/trash/restore/delete/undo flows.
- `lib/features/onboarding/onboarding_page.dart` — Privacy-first first-run UI whose completion callback is awaited; it remains visible/retryable while persistence fails and presents a busy/failure state instead of pretending onboarding was saved.
- `lib/features/settings/settings_page.dart` — Settings UI for appearance, text scale, reduced motion, app lock, backup/import/export-related actions, release/support links, and persistence feedback. It relies on injected controller/services rather than direct plugin access.
- `lib/services/app_lock_service.dart` — Platform authentication wrapper around `local_auth`; it delegates device authentication and treats app lock as UI access control, not database encryption or custom credential storage.
- `lib/services/external_link_service.dart` — Central injectable URL-launch boundary for HTTP(S)/mailto project actions; external launch refusal or exceptions are converted into a safe false result for context-specific UI feedback.
- `lib/services/file_transfer_service.dart` — File-picker/import/export orchestration: avoids eager native picker bytes, uses bounded cached-file reads, performs strict UTF-8/Markdown/backup handling, produces safe Markdown filenames, and delegates backup/note persistence to repositories.
- `lib/widgets/empty_state.dart` — Reusable empty-state presentation component used to keep collection-specific no-content UI consistent while allowing callers to decide which actions are valid in the current context.
- `lib/widgets/note_card.dart` — Reusable note summary/card interaction surface for browser grids, exposing note metadata/actions with responsive Material presentation and accessible interaction semantics.
- `lib/widgets/note_color_swatch.dart` — Reusable custom color-choice control with the shared 48-pixel target, explicit selected semantics, visible checkmark/reset cue, and tooltip/label behavior so selection is not color-only.

### Automated tests

- `test/app/app_settings_controller_test.dart` — Deterministic controller tests for atomic settings load, serialized mutations, rollback after persistence failures/stale writes, persistence-first onboarding, and app-lock preference behavior.
- `test/core/app_logger_test.dart` — Unit tests for structured logging sanitization/redaction so sensitive key categories are not accidentally emitted as raw values.
- `test/core/async_serial_queue_test.dart` — Unit tests proving FIFO task ordering, typed result behavior, and queue continuation after failure—critical to autosave/settings ordering guarantees.
- `test/core/bounded_file_reader_test.dart` — Unit tests for accepted bounded reads, early oversize rejection, incremental enforcement, and filesystem-error translation at the native import boundary.
- `test/core/import_limits_test.dart` — Boundary tests for configured Markdown/text and backup byte ceilings, including exactly-at-limit acceptance and oversized rejection.
- `test/core/markdown_document_codec_test.dart` — Codec regression tests for Markdown metadata/text round trips plus malformed/unsupported metadata handling.
- `test/core/markdown_lite_test.dart` — Pure editor-helper tests for supported Markdown-lite transformations/preview behavior without widget/platform dependencies.
- `test/core/safe_file_name_test.dart` — Filename-safety tests for invalid characters, reserved Windows names, trailing dots/spaces, fallback/length rules, Unicode preservation, and surrogate/code-point-safe truncation.
- `test/data/backup_repository_test.dart` — In-memory Drift regression suite for backup round trips, conflict resolution, schema/app/type/ID/tag/timestamp/color/lifecycle validation, relationship checks, and restore safety before/inside transactions.
- `test/data/note_repository_test.dart` — In-memory Drift tests for create/list/search, snapshot/restore/cascade behavior, collection lifecycle/filter metadata, quote-safe FTS input, and live lifecycle invariants. It explicitly verifies that a trashed note cannot be pinned.
- `test/data/settings_repository_test.dart` — Settings repository tests covering safe defaults and successful preference persistence; failure ordering/rollback is exercised through the injectable store/controller tests.
- `test/features/notes/notes_controller_test.dart` — Controller regression coverage for collection changes clearing stale filters and loading folder/tag metadata from the active collection rather than globally.
- `test/services/external_link_service_test.dart` — Service tests for successful URL launch, launcher refusal, and thrown launcher exceptions, proving feature UI can handle a simple safe result.
- `test/widgets/about_page_test.dart` — Widget regression verifying About surfaces user-visible feedback when an external project action cannot be opened.
- `test/widgets/note_editor_accessibility_test.dart` — Widget/semantics tests for the custom note-color swatch’s selection/reset cues, tap behavior, labels, and minimum interaction target.
- `test/widgets/note_editor_save_test.dart` — Widget regression coverage for latest-draft save before normal back navigation, retryable initial note-load failure instead of an endless spinner, and first-line Markdown formatting when the caret is at offset zero.
- `test/widgets/notes_page_empty_state_test.dart` — Widget tests for All Notes/Favorites/Archive/Trash empty states, ensuring only actions whose results are visible in the current collection are offered.
- `test/widgets/onboarding_page_test.dart` — Widget tests for offline/privacy onboarding messaging, successful persisted completion, busy behavior, and visible/retryable persistence failure.

### Repository tooling

- `tool/bootstrap_platforms.py` — Idempotent native-runner bootstrap: runs `flutter create` for Android/iOS/Linux/macOS/Windows, applies Android FragmentActivity/biometric permission/minSdk/AppCompat configuration plus the iOS Face ID usage description, then verifies those required patches and fails loudly if upstream Flutter template drift prevents them. Flutter must be on PATH.
- `tool/check_markdown_links.py` — Deterministic tracked-Markdown local-link validator covering inline/reference/HTML links while ignoring external-network validation and fenced examples. It rejects missing local targets and links escaping the repository.
- `tool/check_repo.py` — Fast repository policy gate checking the complete required release/documentation/automation baseline, required README text, forbidden unfinished Dart markers, generated `.g.dart` tracking, and security-relevant ignore rules.
- `tool/check_repository_reference.py` — Exhaustive documentation-coverage gate: compares `git ls-files` with path entries in this document, rejecting missing, stale, or duplicate catalog entries. Run it whenever any tracked path is added, removed, or renamed.
- `tool/check_version_sync.py` — Release/toolchain consistency gate that validates semantic/build version shape, keeps `pubspec.yaml`, visible `AppStrings.version`, `CHANGELOG.md`, and `docs/releases/<version>.md` synchronized, validates `.flutter-version`, and rejects mismatched Flutter action pins in CI/platform/release workflows.
- `tool/security_scan.py` — Lightweight deterministic scan of tracked repository files for credential/secret-like patterns. It complements—not replaces—dependency, platform, and human security review.

## Generated and intentionally untracked material

The exhaustive count above is for committed files only. Several important runtime/build files are deliberately generated or local:

- Drift/build-runner output such as `lib/data/database/app_database.g.dart` is generated from tracked Drift source. The project forbids committing generated `.g.dart` files and regenerates them with `dart run build_runner build --delete-conflicting-outputs`.
- `android/`, `ios/`, `linux/`, `macos/`, and `windows/` runners are generated by `tool/bootstrap_platforms.py` from the pinned Flutter SDK and then patched/verified for NoteNest native requirements. ADR 0003 explains this policy.
- `.dart_tool/`, `build/`, `coverage/`, native ephemeral directories, logs, and package caches are reproducible/local outputs and are ignored.
- `.env`, signing keys/certificates, key properties, personal SQLite databases, exported personal backups, and other secrets/private data must never be committed.

Because those paths are not returned by `git ls-files`, they must not be added as tracked-file catalog entries unless the repository policy itself changes.

## Source-of-truth and change-impact map

Use the closest source of truth and update all coupled surfaces in one workstream:

| Change | Primary source(s) | Coupled checks/docs |
|---|---|---|
| App semantic/build version | `pubspec.yaml`, `AppStrings.version` | `CHANGELOG.md`, matching `docs/releases/<version>.md`, `tool/check_version_sync.py` |
| Flutter SDK pin | `.flutter-version` | CI, platform-build, and release workflows + `tool/check_version_sync.py` |
| Database fields/schema | `tables.dart`, `app_database.dart` | repository code, generated Drift output, migration tests, architecture/backup compatibility |
| Note lifecycle rules | `note_repository.dart` | backup validation, controller/widget behavior, repository tests, architecture/testing docs |
| Backup interchange rules | `backup_repository.dart` | backup tests, architecture/security/privacy/release notes |
| Preference behavior | settings repository/controller | settings UI, controller/repository tests, privacy/security if data semantics change |
| Native/plugin integration | services + `bootstrap_platforms.py` | setup/troubleshooting docs, platform-build workflow, manual platform smoke tests |
| External links/contact surfaces | `AppStrings`, `ExternalLinkService` | About/Settings, README/support docs, service/widget tests |
| Accessibility/UI tokens | `app_tokens.dart`, reusable widgets | accessibility docs and widget/manual accessibility checks |
| Repository quality policy | `tool/*.py`, `analysis_options.yaml` | CI workflow, contributing/development/testing/release docs |
| Tracked file set | Git index | this document + `tool/check_repository_reference.py` |

## Repository invariants worth preserving

The file map should be read together with the deeper architecture/testing documents. High-value invariants currently include:

- Core note workflows are local-first and require no NoteNest account or project-operated backend.
- Search uses parameterized SQLite FTS5 input rather than executable string concatenation.
- Changed note content is snapshotted transactionally before the current row is updated.
- Submitted editor writes are ordered; normal navigation waits for the current draft to save successfully.
- Markdown prefix formatting at caret offset zero targets the actual first line, including an empty first line before a leading newline.
- Trashing a note clears pin/archive state, and the repository rejects attempts to pin a trashed note.
- Folder/tag filter metadata uses the same collection lifecycle predicate as note listing.
- Settings mutations are serialized, and failed optimistic writes roll back when the failed value is still current.
- Onboarding completion is persisted before leaving onboarding.
- Root application teardown delegates owned settings/database cleanup to `AppDependencies.dispose()`.
- Imported native files are size-bounded before NoteNest creates the final buffer.
- Backup input is validated before restore writes begin; newer local notes win timestamp conflicts.
- App lock delegates to the operating system and is not represented as database encryption.
- External URI/plugin failures are contained behind `ExternalLinkService`.
- Logging redacts fields likely to contain note, user, credential, or file data.
- Generated runners and Drift output are reproducible rather than treated as hand-maintained source; runner bootstrap verifies required native patches rather than silently accepting template drift.
- The exact Flutter action pins in quality/platform/release automation must match `.flutter-version`.
- Platform-build path filtering includes bundled assets so asset-only changes receive compile verification.

## How to audit this reference

After any repository structure or release-toolchain change:

```bash
python tool/check_version_sync.py
python tool/check_repository_reference.py
python tool/check_repo.py
python tool/check_markdown_links.py
```

Before submitting/releasing, run the full Flutter quality gate documented in `README.md`, `docs/development.md`, and `docs/testing.md`, then perform platform/manual checks relevant to the change.

A passing repository-reference check proves only **catalog coverage of tracked paths**. It does not prove that Dart formatting, analysis, Flutter tests, native builds, accessibility checks, or runtime behavior passed.
