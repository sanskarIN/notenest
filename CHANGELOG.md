# Changelog

All notable NoteNest changes are documented here. The project follows the spirit of [Keep a Changelog](https://keepachangelog.com/) and intends to use semantic versioning for published releases.

Current release-candidate target: **2.0.12** (`2.0.12+2012` in `pubspec.yaml`).

## [Unreleased]

### Changed

- GitHub-hosted workflow first-party actions were modernized to maintained 2026 runtime lines: `actions/checkout@v7`, `actions/setup-java@v6`, `actions/upload-artifact@v7`, and `actions/dependency-review-action@v5`.
- `tool/check_repo.py` now enforces those maintained action-major baselines so future workflow edits cannot silently regress to obsolete runtime generations.
- `subosito/flutter-action@v2` remains on its current supported major while the project continues to pin Flutter **3.44.7** exactly.

No post-2.0.12 product feature change is included in this maintenance checkpoint; exact candidate automation must be rerun after these workflow changes.

## [2.0.12] - Release candidate

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
- Responsive phone/tablet/desktop/browser navigation.
- Material 3 light, dark, and system themes.
- User-adjustable text scale and reduced-motion preference.
- Privacy-first onboarding.
- Optional operating-system-backed app lock through `local_auth` where that plugin is supported.
- Settings and About screens with project/support/funding information.
- Editable NoteNest SVG logo source and labeled layout-reference artwork.
- In-memory repository/database tests, backup-validation tests, settings tests, application-controller tests, feature-controller tests, Markdown helper/metadata tests, logger-redaction tests, import-bound/bounded-reader tests, safe-filename tests, async-save-order tests, external-link tests, onboarding coverage, collection-empty-state coverage, About-link failure coverage, editor load/save-before-pop coverage, editor first-line formatting-boundary coverage, custom color-swatch accessibility coverage, and a Chrome-targeted Web platform smoke regression.
- Reproducible platform runner bootstrap for **Android, iOS, Linux, macOS, Windows, and Web**.
- First-class Flutter Web target with local Drift/SQLite persistence through the matching `sqlite3.wasm` and `drift_worker.js` assets.
- Browser-safe Markdown/text and backup import using picker data/streams with reported and actual byte-limit validation.
- Web release-mode build verification and Web release artifact packaging in GitHub Actions.
- Repository documentation, contribution policy, security policy, privacy disclosure, support guide, ADRs, CI configuration, templates, and dependency automation.
- Deterministic Markdown local-link checker integrated into the CI quality gate.
- Exact Flutter SDK pin (`3.44.7`) synchronized across project, quality, platform-build, and release workflows.
- Shared 48-logical-pixel minimum touch-target design token for custom controls.
- Bounded native-file reader used by local note/backup imports.
- `tool/check_version_sync.py` to keep package, visible app, changelog, release-note, and workflow Flutter SDK versions synchronized.
- A centralized `ExternalLinkService` boundary with injectable launcher behavior for deterministic tests.
- Injectable `SettingsStore` boundary for testing settings persistence and failures without a real platform preference plugin.
- `docs/repository-reference.md`, an exhaustive responsibility/maintenance map for every tracked repository file.
- `tool/check_repository_reference.py`, integrated into CI, to reject undocumented, stale, or duplicate tracked-file catalog entries.
- A genuine Flutter-3.44.7 resolver-generated `pubspec.lock` for the final file-picker-12 dependency graph, containing **129 resolved packages** and hosted-package content hashes.
- Enforced-lockfile dependency restoration in quality, all six platform-build lanes, and release packaging.

### Changed

- Project semantic version advanced to **2.0.12** with Flutter build number **2012**.
- About UI now reports version **2.0.12**.
- Supported project targets cover the complete Flutter platform set: Android, iOS/iPadOS, Linux, macOS, Windows, and Web.
- The Drift database factory supplies explicit Web SQLite WASM and worker locations while retaining normal Drift Flutter behavior on native targets.
- Platform bootstrap pins browser SQLite runtime assets to Drift **2.34.3**, matching `pubspec.yaml`, and fails if the dependency pin changes without an explicit asset review.
- Browser bootstrap validates downloaded WASM/worker payload signatures before writing generated Web runtime files.
- `file_picker` advanced to **12.0.0** after real Android verification exposed the obsolete 11.0.3 plugin-registration path.
- File transfer now uses file_picker 12 single-file selection plus `PlatformFile.length()` and `readAsByteStream()`; native cached paths still use bounded filesystem streaming where available.
- file_picker 12's required **iOS 14.0** minimum is explicitly enforced by generated iOS project/framework configuration.
- Windows bootstrap applies the MSVC compatibility definition required by the current VS2026 hosted runner for `local_auth_windows`' experimental-coroutine dependency instead of pinning an obsolete runner image.
- Platform runner generation uses `flutter create --no-pub`; generated runners and dependency resolution are now separate reproducibility stages.
- Windows bootstrap invokes Flutter `.bat`/`.cmd` launchers through `COMSPEC` so Python works correctly on Windows hosts.
- Android CI/release Java setup uses `actions/setup-java@v5`.
- Active build-runner invocations use the current `dart run build_runner build` command; the removed `--delete-conflicting-outputs` option is no longer passed by maintained workflows.
- App-lock implementation is selected conditionally so Web does not import an unsupported `local_auth` implementation.
- Unsupported app-lock targets remain usable even if an app-lock preference exists; Settings reports capability instead of allowing an impossible enable flow.
- CI verifies version synchronization before dependency restoration and Flutter compilation work.
- Version synchronization rejects a `.flutter-version`/workflow Flutter SDK mismatch.
- Platform-build verification runs when the committed lockfile, bundled assets, Web smoke tests, application source, or bootstrap/build inputs change.
- Native/platform bootstrap validates Android authentication/minimum-SDK/AppCompat, iOS Face ID/iOS-14 configuration, Windows MSVC compatibility, and Web database assets; upstream template/dependency drift fails loudly.
- Repository policy requires `pubspec.lock` to exist and be tracked by Git.
- External repository, funding, support-email, business-email, and release links share the same safe launcher behavior.
- Folder/tag filter metadata is collection-scoped rather than global.
- Switching between All Notes, Favorites, Archive, and Trash clears folder/tag selections that belong to the previous collection.
- Onboarding completion is persisted before the UI leaves onboarding.
- Settings mutations are serialized through the same ordered async primitive used for other ordering-sensitive work.
- Normal editor back navigation waits for the current draft save to finish successfully before the route is allowed to pop.
- Version-history and Markdown-export actions require the current draft to save successfully before the action starts.
- Dart source/test files are canonicalized with the pinned Dart **3.12.2** formatter.
- The exhaustive repository reference now catalogs **109 tracked files**, including the committed application lockfile.

### Fixed

- Flutter 3.44.7 dependency resolution no longer conflicts with `flutter_localizations`; `intl` is aligned to the SDK-pinned **0.20.2**.
- Browser compilation is no longer blocked by a direct `dart:io` import in the shared bounded-file reader.
- Web import no longer requires a native filesystem path from `file_picker`; browser/non-path streams are accepted with the same configured size ceilings.
- Android no longer relies on file_picker 11's failing legacy plugin registration path; file_picker 12's federated Android implementation is used.
- Windows release compilation on current GitHub-hosted VS2026 no longer fails at the experimental-coroutine compatibility assertion.
- Cupertino page transitions import explicitly on the targets that use them.
- Drift repository query callbacks use the generated `$NotesTable` / `$NoteVersionsTable` types exposed by the generated database library.
- A persisted app-lock preference can no longer strand Web or another unsupported target on an unlock screen that can never succeed.
- Root application teardown disposes the settings controller and closes the Drift database through `AppDependencies.dispose()` when the `NoteNestApp` state is permanently removed.
- Markdown-lite heading/list/checklist formatting at caret offset zero targets the actual empty first line even when the note begins with a newline.
- Serialized editor saves prevent overlapping autosave, lifecycle, export/history, and final navigation submissions from overtaking one another.
- Prevented stale save completions from reporting a newer unsaved draft as saved.
- Replaced an endless editor loading spinner after note-load failure with a retryable local-storage error state.
- Prevented normal editor back navigation from silently leaving before the current draft save finishes; a failed save keeps the editor open with feedback.
- Prevented Markdown export/version-history actions from continuing against stale persisted content when the pre-action save fails.
- Contained version-query/restore/export failures with user-visible feedback.
- Contained Notes browser create/open/pin/favorite/archive/trash/restore/delete/undo failures instead of leaking async errors through UI callbacks.
- Contained the HomeShell new-note action when note creation/opening fails.
- Cleaned up the settings controller/database if application dependency bootstrap fails while loading settings.
- Corrected Favorites, Archive, and Trash empty states so they no longer offer create/import actions whose result would not appear in the active collection.
- Restricted Markdown import affordance to All Notes, where newly imported notes are immediately visible.
- Fixed Trash folder/tag filtering by including trashed note metadata in the Trash collection's filter choices.
- Prevented Favorites/Archive filter menus from advertising folders/tags that do not exist in the active collection.
- Prevented a trashed note from being pinned through the repository boundary, keeping live lifecycle state consistent with backup validation rules.
- Hardened Markdown export filenames against cross-platform invalid characters, trailing dots/spaces, excessive length, and Windows reserved device names.
- Prevented filename truncation from splitting a UTF-16 surrogate pair/Unicode code point at the configured boundary.
- Replaced color-only editor swatch selection with explicit selected semantics and a visible checkmark while keeping a comfortable interaction target.
- Replaced moving-stable Flutter workflow setup with the exact project SDK version for reproducible automated builds.
- Removed eager picker byte loading from native Markdown/backup imports; selected cached files are length-checked and consumed incrementally through the configured byte ceiling.
- External-link launcher failures and exceptions no longer escape from About/Settings actions; users receive concise failure feedback instead.
- Settings preference failures no longer leave the UI pretending an unpersisted value was saved; applicable settings roll back to the last persisted value.
- Preference writes are ordered so rapid changes cannot persist out of submission order.
- Failed onboarding persistence no longer causes a transition away from onboarding before the failure can be shown/retried.
- Preference-store setter results are checked instead of silently ignoring a reported persistence failure.
- Analyzer-only style diagnostics found during final hardening were corrected instead of weakening analysis rules.

### Security

- Backup restore rejects malformed/non-NoteNest/unsupported-schema data before applying writes.
- Restore validation requires a valid explicit-UTC root `exportedAt` timestamp.
- Restore validation rejects malformed serialized tags, duplicate note IDs, IDs containing surrounding whitespace, and version entries that reference unknown notes.
- Imported serialized tags are normalized back to NoteNest trim/deduplicate/sort invariants before storage.
- Restore validation rejects impossible lifecycle states such as archived+trashed and pinned+trashed note/version records.
- Restore validation requires explicit UTC timestamps ending in `Z` and rejects a note whose `updatedAt` precedes `createdAt`.
- Restore validation accepts `colorValue` only when null or within the 32-bit ARGB integer range.
- Restore operations preserve newer local note revisions.
- Imported text is decoded as UTF-8 and never executed.
- Markdown/text imports are rejected above 16 MiB before decoding; NoteNest JSON backups are rejected above 64 MiB before UTF-8/JSON processing.
- Native import reads are disk-backed/incremental when a picker path exists; non-path/Web import validates picker-reported size and cumulative streamed byte length before processing.
- SQL search inputs are transformed into parameterized FTS variables instead of interpolated into SQL.
- Common secret, signing, database, and local-environment files are excluded from source control.
- App lock delegates authentication to maintained platform APIs where supported and degrades to unavailable on unsupported targets rather than introducing custom browser credentials.
- Generated Markdown export names are normalized before reaching platform save dialogs.
- External launcher exceptions are contained at a service boundary instead of becoming uncaught UI failures.
- Preference-persistence failures are propagated to controller/UI boundaries instead of being treated as successful writes.
- Dependency restoration for automated build/release evidence fails instead of silently changing locked versions or hosted content hashes.
- Dedicated security and dependency-review jobs passed on the file_picker-12 release candidate before the final post-lock verification cycle.

### Automated verification reached during hardening

On the file_picker-12 candidate before the final documentation/lint-only post-lock rerun:

- Windows release compile on the current hosted VS2026 image: **passed**.
- macOS release compile: **passed**.
- unsigned iOS release compile with explicit iOS 14 floor: **passed**.
- Chrome Web platform smoke: **passed**.
- Web release compile: **passed**.
- Repository secret scan: **passed**.
- Dependency review: **passed**.
- Android and Linux lanes were still running/queued when this changelog checkpoint was written; they are not claimed green here.

Final release evidence must come from the exact post-lock/post-documentation candidate, not from an earlier diagnostic run.

### Known release-preparation constraints

- Platform runner templates, Web database runtime assets, and Drift-generated Dart files are intentionally generated during setup/CI instead of committed as stale generated output.
- The Web bundle requires `sqlite3.wasm` to be served with the correct WebAssembly MIME type. Cross-origin isolation headers improve the optimal Drift/OPFS path where a chosen host supports them; Drift retains fallback storage paths when those headers are unavailable.
- Web app lock is intentionally unavailable because `local_auth 3.0.2` has no Web implementation. Linux likewise treats device authentication as unavailable unless a supported implementation is introduced later.
- Store/distribution signing credentials are intentionally not part of the repository.
- Completed green GitHub Actions verification is still required against the exact final post-lock/post-documentation 2.0.12 candidate before a stable tag is created.
- Real-device/browser/platform checks remain required for editor save-before-pop, file pickers/providers, settings persistence, external links, keyboard navigation, screen readers, large text, reduced motion, Web persistence/reload/import/export, supported-device authentication, and runtime screenshots.
- Intended Web deployment-origin MIME/worker/WASM reachability and browser-restart persistence still require real-host verification.
- Signing/notarization/store readiness and distributed-artifact checksums remain distribution-time work.

The `v2.0.12` tag must only be created after all configured CI jobs pass from a clean checkout, all six platform build targets complete on the exact final candidate, verified runtime screenshots replace the illustrative reference, Web deployment/runtime checks are recorded, and final manual accessibility/release checks are recorded in `what_changed.md`.

[Unreleased]: https://github.com/sanskarIN/notenest/compare/v2.0.12...HEAD
[2.0.12]: https://github.com/sanskarIN/notenest/releases/tag/v2.0.12
