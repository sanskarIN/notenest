# NoteNest Repository Reference

Current audited application target: **2.0.12** (`2.0.12+2012`).

This document is the exhaustive tracked-file map for NoteNest. It records the responsibility and change impact of every committed path so contributors do not need to infer ownership from directory names.

## Exhaustive-documentation contract

At this checkpoint the repository has **109 tracked files**. Every tracked path appears exactly once in the catalog below. The contract is enforced by:

```bash
python tool/check_repository_reference.py
```

The checker compares `git ls-files` with the catalog entries in this document and rejects missing, stale, or duplicate paths. Any tracked addition, deletion, or rename must update this reference in the same change.

Generated runners, Drift output, build artifacts, dependency caches, signing material, exported user data, and local databases are deliberately outside the tracked-file count. The application `pubspec.lock` is intentionally tracked because it is part of the reproducible release baseline.

## Architecture orientation

The main dependency flow is:

```text
Flutter widgets/features
        ↓
controllers/application state
        ↓
repositories and platform services
        ↓
Drift / SQLite / SharedPreferences / platform plugins
```

`lib/app/app_dependencies.dart` is the composition root. Note data is owned by `NoteRepository`, backup interchange by `BackupRepository`, settings by `SettingsStore`/`SettingsRepository`, file movement by `FileTransferService`, app-lock capability by `AppLockService`, and external URI handling by `ExternalLinkService`.

Version domains remain independent:

1. Application version: **2.0.12**.
2. Flutter package build: **2012**.
3. Drift database schema: **1**.
4. Backup schema version: maintained separately by the backup format.

## Tracked-file catalog

### Repository configuration and governance

- `.editorconfig` — Repository-wide UTF-8/LF, final-newline, whitespace, and indentation policy.
- `.env.example` — Documents the non-secret build-channel placeholder and confirms core NoteNest needs no runtime secrets.
- `.flutter-version` — Pins Flutter 3.44.7; the version-sync gate requires every Flutter workflow pin to match it.
- `.gitattributes` — Normalizes line endings and marks binary asset types to prevent cross-platform Git churn.
- `.gitignore` — Excludes build/generated output, local databases, IDE noise, environment secrets, signing files, coverage, caches, and logs.
- `analysis_options.yaml` — Strict Dart/Flutter static-analysis policy with generated Drift output excluded.
- `build.yaml` — Drift build-runner settings controlling generated persistence behavior.
- `pubspec.yaml` — Canonical package metadata, version `2.0.12+2012`, SDK constraints, pinned direct dependencies, and asset declarations.
- `pubspec.lock` — Resolver-generated application dependency graph with exact direct/transitive versions and hosted-package content hashes; CI/platform/release restoration enforces it.
- `README.md` — Public project overview, features, six-platform target matrix, setup, quality gates, architecture, and project links.
- `CHANGELOG.md` — Release-oriented history for user-facing, security, tooling, and platform changes.
- `ROADMAP.md` — Forward-looking product and engineering direction; roadmap entries are not shipped-feature claims.
- `PRIVACY.md` — Public local-first data-practice disclosure covering storage, imports/exports, app lock, links, and network boundaries.
- `SECURITY.md` — Threat model, supported security posture, trust boundaries, safe handling, and vulnerability reporting.
- `SUPPORT.md` — User/contributor support and troubleshooting routing separate from private security disclosure.
- `CONTRIBUTING.md` — Contributor setup, branch/commit, testing, documentation, and pull-request expectations.
- `CODE_OF_CONDUCT.md` — Community behavior and enforcement expectations.
- `LICENSE` — MIT license governing reuse and distribution.
- `what_changed.md` — Deep engineering handoff with exact changes, verification limitations, checkpoints, and release blockers.

### GitHub community and automation

- `.github/FUNDING.yml` — Configures the project funding surface.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — Structured bug report form including platform and reproducibility context.
- `.github/ISSUE_TEMPLATE/config.yml` — Controls issue-template chooser behavior and support/security routing.
- `.github/ISSUE_TEMPLATE/feature_request.yml` — Structured feature request form emphasizing value and privacy/offline impact.
- `.github/dependabot.yml` — Automated dependency-update configuration.
- `.github/pull_request_template.md` — Review checklist for code, tests, docs, security, accessibility, and release impact.
- `.github/workflows/ci.yml` — Primary quality workflow: version checks, enforced lockfile restore, Drift generation, formatting, analyzer, tests, repository policy, reference validation, links, and secret scan.
- `.github/workflows/platform-builds.yml` — Six-platform compile matrix using the enforced lockfile for Android, Linux, Windows, macOS, unsigned iOS, and Web; Web also runs the Chrome platform smoke regression.
- `.github/workflows/release.yml` — Tag/manual artifact workflow restoring the enforced lockfile before packaging Android, Linux, Windows, macOS, unsigned iOS, and a deployable Web bundle.
- `.github/workflows/security.yml` — Dedicated deterministic repository/dependency security workflow.

### Branding and documentation assets

- `assets/branding/notenest_logo.svg` — Canonical editable NoteNest logo source.
- `docs/assets/screenshots/layout-reference.svg` — Clearly labeled illustrative layout reference until verified runtime captures exist.

### Engineering and product documentation

- `docs/accessibility.md` — Accessibility requirements and manual verification matrix for keyboard, semantics, touch targets, scaling, contrast, motion, and screen readers.
- `docs/adr/0001-flutter-drift-modular-monolith.md` — Decision record for Flutter + Drift in a modular-monolith architecture.
- `docs/adr/0002-offline-first-data.md` — Decision record establishing local-first data ownership as a product constraint.
- `docs/adr/0003-generated-platform-runners.md` — Decision record for reproducibly generated platform runners rather than tracked templates.
- `docs/architecture.md` — Deep design for composition, data/storage/search, repositories, services, error handling, platform boundaries, accessibility, migrations, performance, and security.
- `docs/development.md` — Day-to-day engineering workflow and module/dependency rules.
- `docs/github.md` — GitHub-side issue, PR, branch, checks, release, and maintenance operations.
- `docs/performance.md` — Performance goals, measurement guidance, pressure points, and optimization rules.
- `docs/release.md` — Release engineering procedure covering versions, lock/toolchain discipline, builds, manual validation, signing, artifacts, checksums, and tags.
- `docs/releases/2.0.12.md` — Version-specific engineering and verification notes for the 2.0.12 candidate.
- `docs/repository-reference.md` — This exhaustive machine-enforced tracked-file catalog.
- `docs/setup.md` — Clean-clone prerequisites and setup across supported development/build targets.
- `docs/testing.md` — Test strategy and regression inventory across core, data, widgets, platform boundaries, accessibility, and builds.
- `docs/troubleshooting.md` — Symptom-oriented build/runtime recovery guidance designed not to risk user data.

### Application composition and core

- `lib/main.dart` — Process entry point, dependency bootstrap, app startup, and safe redacted bootstrap-failure fallback.
- `lib/app/app.dart` — Material app shell, localization/theme/accessibility wiring, onboarding, lifecycle app-lock gate, unsupported-platform lock bypass, and final dependency disposal.
- `lib/app/app_dependencies.dart` — Composition root constructing database, repositories, controllers, services, logger, and final resource cleanup.
- `lib/app/app_settings_controller.dart` — Atomic settings load plus serialized persistence, rollback, onboarding persistence-first behavior, and app-lock preference state.
- `lib/core/constants/app_strings.dart` — Central app identity/version/contact/navigation and collection-empty-state strings.
- `lib/core/errors/app_exception.dart` — Domain exception taxonomy for storage, validation, import/export, and authentication failures.
- `lib/core/logging/app_logger.dart` — Structured redacting logger with bounded fields and sensitive-key filtering.
- `lib/core/theme/app_theme.dart` — Material 3 light/dark theme construction, project typography, scaling, and shared component defaults.
- `lib/core/theme/app_tokens.dart` — Shared spacing, radii, touch-target, breakpoint, extent, and timing invariants.
- `lib/core/utils/async_serial_queue.dart` — Typed FIFO asynchronous task queue used for order-sensitive persistence.
- `lib/core/utils/bounded_file_reader.dart` — Conditional cross-platform facade selecting native filesystem streaming only where `dart:io` exists.
- `lib/core/utils/bounded_file_reader_io.dart` — Native `dart:io` bounded reader that validates reported and cumulative byte length while streaming selected files.
- `lib/core/utils/bounded_file_reader_stub.dart` — Browser/non-IO fallback that prevents filesystem-path access from entering unsupported environments.
- `lib/core/utils/debouncer.dart` — Timer-based coalescing helper used for search/autosave work.
- `lib/core/utils/import_limits.dart` — Central byte ceilings and validation helpers for Markdown/text and backup imports.
- `lib/core/utils/markdown_document_codec.dart` — NoteNest Markdown metadata/body import-export codec and validation.
- `lib/core/utils/markdown_lite.dart` — Deterministic Markdown-lite editor transformations and preview helpers.
- `lib/core/utils/safe_file_name.dart` — Cross-platform Unicode-safe export filename sanitizer including Windows reserved-name handling.

### Data and domain

- `lib/data/database/app_database.dart` — Drift schema root, FTS5 triggers/search, foreign keys, and cross-platform database factory; Web uses explicit Drift WASM/worker assets.
- `lib/data/database/tables.dart` — Drift Notes and NoteVersions table definitions and relationships.
- `lib/data/repositories/backup_repository.dart` — Validated JSON export/restore, lifecycle/type/timestamp/ID checks, conflict resolution, and transactional writes.
- `lib/data/repositories/note_repository.dart` — Authoritative note CRUD/search/filter/snapshot/lifecycle boundary, including no-pinned-trash enforcement.
- `lib/data/repositories/settings_repository.dart` — `SettingsStore` abstraction and SharedPreferences adapter with truthful setter failure handling.
- `lib/domain/models/note_filter.dart` — UI-independent collection/query/folder/tag filter contract.

### Features, services, and reusable widgets

- `lib/features/about/about_page.dart` — About/project information and safe external project/support actions.
- `lib/features/home/home_shell.dart` — Responsive compact/wide navigation shell and guarded new-note route.
- `lib/features/notes/note_editor_page.dart` — Editor loading, immutable drafts, ordered autosave, save-before-pop, lifecycle saves, Markdown actions, metadata/colors, history/export, and error recovery.
- `lib/features/notes/notes_controller.dart` — Notes-browser state, collection/search/filter metadata, async error state, and stale-completion protection.
- `lib/features/notes/notes_page.dart` — Search/filter/grid presentation, collection-specific empty states, import, and guarded lifecycle mutations.
- `lib/features/onboarding/onboarding_page.dart` — Privacy-first onboarding that only exits after persistence succeeds.
- `lib/features/settings/settings_page.dart` — Appearance/accessibility/data/privacy settings, backup actions, release links, persistence feedback, and visible app-lock capability state.
- `lib/services/app_lock_service.dart` — Conditional app-lock facade selecting native device authentication or an unavailable-platform fallback without importing unsupported Web plugin code.
- `lib/services/app_lock_service_io.dart` — Native `local_auth` implementation for supported operating systems; plugin absence/errors resolve safely to unavailable.
- `lib/services/app_lock_service_stub.dart` — Web/non-IO app-lock implementation that reports authentication unavailable and never traps the user behind an impossible unlock flow.
- `lib/services/external_link_service.dart` — Injectable HTTP(S)/mailto launcher boundary converting refusal/exceptions to safe results.
- `lib/services/file_transfer_service.dart` — Cross-platform file picker orchestration using file_picker 12 single-file selection, reported-length validation, native bounded-path reads, streamed non-path reads, UTF-8 decoding, Markdown import/export, and backup import/export.
- `lib/widgets/empty_state.dart` — Reusable collection-aware empty-state presentation.
- `lib/widgets/note_card.dart` — Responsive accessible note-summary card and action surface.
- `lib/widgets/note_color_swatch.dart` — Accessible 48-pixel color target with explicit selected semantics and non-color cue.

### Automated tests

- `test/app/app_settings_controller_test.dart` — Atomic load, serialized settings changes, rollback, onboarding, and app-lock preference regressions.
- `test/core/app_logger_test.dart` — Logger normalization/redaction regressions.
- `test/core/async_serial_queue_test.dart` — FIFO ordering, typed result, and post-failure continuation tests.
- `test/core/bounded_file_reader_test.dart` — Native bounded read, early/cumulative size rejection, and filesystem-error translation tests.
- `test/core/import_limits_test.dart` — Exact byte-ceiling acceptance and oversized rejection tests.
- `test/core/markdown_document_codec_test.dart` — Markdown round-trip and malformed/unsupported metadata tests.
- `test/core/markdown_lite_test.dart` — Pure Markdown-lite transformation tests.
- `test/core/safe_file_name_test.dart` — Invalid/reserved/trailing-name, fallback, length, and Unicode safety tests.
- `test/data/backup_repository_test.dart` — Backup round-trip, conflict, schema/type/ID/tag/timestamp/color/lifecycle, relationship, and transactional safety tests.
- `test/data/note_repository_test.dart` — Create/list/search, snapshot/restore/cascade, filters, FTS escaping, and lifecycle-invariant tests.
- `test/data/settings_repository_test.dart` — Settings defaults and persistence behavior tests.
- `test/features/notes/notes_controller_test.dart` — Collection-switch and collection-scoped metadata regressions.
- `test/services/external_link_service_test.dart` — Successful, refused, and throwing external-launch behavior tests.
- `test/web/web_platform_smoke_test.dart` — Chrome-targeted regression proving Web app-lock and native-path facilities degrade safely instead of importing/using unsupported platform facilities.
- `test/widgets/about_page_test.dart` — About-page external-action failure feedback test.
- `test/widgets/note_editor_accessibility_test.dart` — Note-color semantics, target size, labels, and selected-cue tests.
- `test/widgets/note_editor_save_test.dart` — Latest-draft back-save, load recovery, and offset-zero first-line formatting regressions.
- `test/widgets/notes_page_empty_state_test.dart` — Collection-specific empty-state action tests.
- `test/widgets/onboarding_page_test.dart` — Onboarding messaging, persistence, busy state, and retryable failure tests.

### Repository tooling

- `tool/bootstrap_platforms.py` — Generates Android/iOS/Linux/macOS/Windows/Web runners; applies/verifies Android authentication/AppCompat requirements, explicit iOS 14 deployment compatibility, and Windows/MSVC compatibility; pins Drift Web assets to the pubspec Drift version; downloads `sqlite3.wasm`/`drift_worker.js`; and fails on platform/dependency drift.
- `tool/check_markdown_links.py` — Deterministic tracked-Markdown local-link validator.
- `tool/check_repo.py` — Fast repository policy gate for required baseline (including tracked `pubspec.lock`), README identity text, unfinished Dart markers, generated-file policy, and ignore rules.
- `tool/check_repository_reference.py` — Exhaustive tracked-path coverage checker for this catalog.
- `tool/check_version_sync.py` — App/release metadata plus exact Flutter workflow-pin synchronization gate.
- `tool/security_scan.py` — Lightweight deterministic tracked-file credential/secret-pattern scan.

## Generated and intentionally untracked material

The exhaustive count above is committed source only.

- Drift/build-runner output such as `lib/data/database/app_database.g.dart` is generated and intentionally untracked.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, and `web/` runners are generated from Flutter 3.44.7 by the bootstrap script. Web generation also obtains the Drift 2.34.3 `sqlite3.wasm` and `drift_worker.js` runtime assets from the matching Drift release.
- `.dart_tool/`, `build/`, `coverage/`, platform ephemeral directories, logs, browser/native build products, and package caches are reproducible/local outputs.
- `.env`, signing keys/certificates, key properties, personal SQLite databases, exported personal backups, and other credentials/private data must never be committed.

Because these paths are not returned by `git ls-files`, they are not catalog entries unless repository policy changes.

## Source-of-truth and change-impact map

| Change | Primary source(s) | Coupled checks/docs |
|---|---|---|
| App semantic/build version | pubspec + visible app version | changelog, version release notes, version-sync gate |
| Flutter SDK pin | `.flutter-version` | CI/platform/release workflows + version-sync gate |
| Application dependency graph | `pubspec.yaml` + `pubspec.lock` | enforced restore, dependency review, affected target builds |
| Database fields/schema | Drift tables/database | generated output, migrations, backup compatibility, architecture/tests |
| Web database/runtime assets | database factory + platform bootstrap | Drift dependency pin, Web build/release verification, deployment docs |
| Note lifecycle rules | note repository | backup validation, controllers/widgets, repository tests |
| Backup interchange rules | backup repository | backup tests, architecture/security/privacy/release notes |
| Preference behavior | settings repository/controller | settings UI, tests, privacy/security when semantics change |
| Platform/plugin integration | services + platform bootstrap | setup/troubleshooting, build matrix, manual target checks |
| External links/contact surfaces | app strings + external-link service | About/Settings, support docs, service/widget tests |
| Accessibility/UI tokens | tokens + reusable widgets | accessibility docs and widget/manual checks |
| Repository quality policy | tools + analyzer configuration | workflows and engineering/release docs |
| Tracked file set | Git index | this document + repository-reference checker |

## Repository invariants worth preserving

- Core note workflows remain local-first and require no NoteNest account or project-operated backend.
- Search uses parameterized SQLite FTS5 input.
- Changed note content is snapshotted transactionally before the current row is updated.
- Submitted editor writes are ordered and normal navigation waits for the current draft to save.
- Offset-zero Markdown prefix formatting targets the real first line, including an empty leading line.
- Trashing clears incompatible state and a trashed note cannot be pinned.
- Collection filter metadata uses the same lifecycle predicate as listing.
- Settings mutations are serialized and failed optimistic writes roll back when appropriate.
- Onboarding is persisted before leaving the onboarding route.
- Root app teardown delegates settings/database cleanup to the composition root.
- Imports are byte-bounded before decoding: native targets validate length and use bounded paths when available; non-path/browser content is streamed with cumulative limit checks.
- Backup data is validated before restore writes and newer local notes win conflicts.
