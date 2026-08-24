# NoteNest Roadmap

The roadmap keeps future work aligned with NoteNest's local-first, private, accessible notes experience. It is not a promise of release dates.

Current stable-candidate line: **2.0.12** (`2.0.12+2012`). Active next-version development: **2.1.0** on `feature/2.1.0-productivity`.

## Product principles

Future features should:

1. Preserve useful offline/local functionality.
2. Avoid required accounts for core notes.
3. Keep data portable.
4. Prefer local processing where practical.
5. Be accessible by keyboard, touch, browser, and assistive technologies.
6. Work coherently across compact and wide layouts.
7. Treat Android, iOS/iPadOS, Windows, macOS, Linux, and Web as explicit platform-impact surfaces.
8. Have tests/documentation proportional to risk.
9. Avoid intrusive monetization/donation flows.
10. Keep security, migration, dependency, and release compatibility explicit.

## 2.0.12 hardening already implemented

Implementation is listed separately from pending stable verification because source/build completion is not the same as runtime certification.

### Data integrity and persistence

- Ordered editor save submissions prevent old autosaves overtaking newer drafts.
- Stale save completions cannot mark a newer visible draft saved.
- Normal Back, export, and history paths wait for the appropriate current-draft save.
- Settings writes are serialized with rollback after applicable failures.
- Onboarding is persistence-first.
- Root composition owns settings/database cleanup.
- Collection metadata/filter lifecycle rules are consistent.
- A trashed note cannot be pinned.
- Note update timestamps advance monotonically even when several changes occur inside the same stored second.

### Import/export and recovery

- 16 MiB Markdown/text and 64 MiB backup ceilings.
- Strict UTF-8 processing.
- `file_picker 12.0.0` single-file selection with reported-length validation.
- Native cached paths use bounded filesystem streaming when available.
- Browser/non-path data uses cumulative `readAsByteStream()` bounds before decoding.
- Backup app/schema/type/tag/ID/relationship/UTC/timestamp/color/lifecycle validation.
- Conflict-safe transactional restore.
- Cross-platform/Unicode-safe Markdown export names.
- NoteNest Markdown metadata round trips remove only the format separator newline and preserve a real leading newline in note content.

### Six-platform baseline

- Android target/bootstrap/build automation with min SDK 24, FragmentActivity, biometric permission, and AppCompat requirements.
- iOS/iPadOS target/bootstrap/no-codesign compile automation with explicit **iOS 14.0+** floor.
- Windows target/build automation with current-MSVC compatibility for the `local_auth_windows` coroutine dependency.
- macOS target/build automation.
- Linux target/build automation.
- Web target with Drift SQLite WASM/worker storage, browser file behavior, Chrome fallback regression, and release bundle packaging.
- Responsive compact/wide UI spans phones, tablets, desktop windows, and browser viewports.
- App-lock service degrades safely where `local_auth` is unavailable; Web/Linux remain usable.

### Accessibility/platform resilience

- Collection-specific empty states.
- Non-color color-selection cues and 48-pixel custom target baseline.
- Centralized external-link boundary and failure feedback.
- Browser/native platform capability differences are explicit instead of hidden behind false parity.
- Onboarding scrolls vertically when compact-height or large-text layouts exceed the available viewport.

### Release/repository engineering

- Flutter **3.44.7** exact pin across project/CI/platform/release automation.
- Genuine resolver-generated application `pubspec.lock` committed for the current **129-package** graph.
- Lock-enforced dependency restoration across quality, all platform-build lanes, and release packaging.
- `tool/check_repo.py` requires the application lockfile to be tracked.
- Six-platform runner bootstrap uses `flutter create --no-pub`, keeping runner generation separate from dependency resolution.
- Runner bootstrap restores the committed `pubspec.yaml` and `pubspec.lock` byte-for-byte after Flutter template generation, preventing generated template dependency changes from invalidating the application lock.
- Drift **2.34.3** Web runtime assets are tied to the direct dependency.
- Version, repository, **109-file** exhaustive-reference, Markdown-link, and secret policy gates.
- Six-platform build matrix including Chrome Web smoke + release compile.
- Six-platform release packaging including Web output.
- Complete setup/development/release/security/privacy documentation for native/browser behavior.
- GitHub Actions runtime majors use published maintained lines: checkout v7, setup-java v5, upload-artifact v7, dependency-review v5, while Flutter setup remains on its maintained v2 line.
- Repository policy now enforces the maintained workflow-action baseline to prevent runtime-major regressions or use of an unpublished action tag.

## Milestone: 2.0.12 — stable verification

### Release engineering completed

- [x] Version `2.0.12+2012` / visible 2.0.12 synchronized.
- [x] Flutter 3.44.7 workflow/toolchain pin synchronized.
- [x] All six Flutter targets implemented in bootstrap/build/release automation.
- [x] Web browser-safe file and app-lock boundaries implemented.
- [x] Drift Web runtime assets pinned to matching Drift 2.34.3 release.
- [x] Chrome Web platform smoke regression implemented.
- [x] Resolver-generated `pubspec.lock` committed and reviewed from the pinned toolchain.
- [x] Dependency restore enforced with `--enforce-lockfile` in CI/platform/release workflows.
- [x] Exhaustive repository reference expanded to **109 tracked files**.
- [x] Canonical Dart 3.12.2 formatter baseline committed.
- [x] Android file-picker 11 registration blocker replaced with file_picker 12 federated implementation.
- [x] Windows VS2026 coroutine compatibility blocker fixed without pinning an obsolete runner.
- [x] Explicit iOS 14 deployment floor applied for file_picker 12.
- [x] GitHub Actions first-party runtime majors use published stable tags and are enforced by repository policy.
- [x] Generated platform runners preserve the application manifest and resolver lock before enforced restore.
- [x] Compact-height onboarding overflow has a scrollable regression fix.
- [x] Note timestamp ordering is monotonic and covered by repository tests.
- [x] Editor save/formatting widget tests target stable field keys rather than positional `TextField` ordering.
- [x] NoteNest Markdown metadata round-trip separator handling is fixed and covered for leading-newline content.

### Exact final automated verification completed

Frozen `main` candidate: `8b2b40f9af03c91be5818ea6b94987aecdb131dc`.

Verification-only PR #19 head: `e6f8cf444fba8ba7e3938e33fc3231f964195393`. PR #19 was closed without merge after completing its purpose; its only change was a non-functional path-filter trigger marker.

- [x] Version/toolchain synchronization green — CI `32682167823`.
- [x] Enforced locked dependency restore green.
- [x] Drift generation green.
- [x] Formatter green.
- [x] Analyzer green.
- [x] **86 Flutter tests** with coverage green.
- [x] Repository policy green.
- [x] 109-file repository-reference check green.
- [x] Markdown-link scan green.
- [x] Secret scan green.
- [x] Dependency review green — Security `32682167760`.
- [x] Android release compile green — Platform builds `32682167769`.
- [x] Windows release compile green.
- [x] Linux release compile green.
- [x] macOS release compile green.
- [x] iOS no-codesign compile green.
- [x] Chrome Web smoke green.
- [x] Web release compile green.
- [x] Every platform lane verified `pubspec.yaml` and `pubspec.lock` remained unchanged after generated-runner bootstrap.

Issues #8 (resolver-lock reproducibility) and #15 (GitHub Actions runtime modernization) are closed as completed based on this exact evidence.

### Required manual/runtime/accessibility verification

- [ ] Rapid-edit/Back latest-draft behavior manually verified.
- [ ] Save-failure blocking/retry behavior verified.
- [ ] Settings rollback/onboarding persistence verified.
- [ ] Collection/lifecycle behavior verified.
- [ ] Native file picker/import/export and oversize rejection verified.
- [ ] Browser import/download and oversize rejection verified.
- [ ] Backup export/restore/malformed-data handling verified with fictional data.
- [ ] Web persistence survives reload/browser restart on the intended origin.
- [ ] Web worker/WASM MIME/reachability verified on the intended host.
- [ ] Supported app-lock authentication verified on representative supported devices.
- [ ] Web/Linux unavailable app-lock behavior verified usable.
- [ ] External-link success/failure verified.
- [ ] Keyboard/browser focus, screen reader, large-text/zoom, themes, and reduced-motion checks recorded.
- [ ] Verified runtime screenshots replace unsupported screenshot claims.
- [ ] Final signing/artifact/checksum status recorded.
- [ ] `v2.0.12` created only on the exact fully verified commit.

## Milestone: 2.1.0 — organization and productivity polish

Active branch: `feature/2.1.0-productivity`, based directly on the fully automated-verified 2.0.12 `main` candidate. The package version remains `2.0.12+2012` until the 2.1.0 feature set and validation boundary are ready to freeze.

Implemented on the clean 2.1.0 branch:

- [x] Configurable sorting: newest, oldest, title A–Z, and title Z–A.
- [x] Pinned-first behavior retained under every selected sort mode.
- [x] Sort changes preserve collection/query/folder/tag filters.
- [x] Duplicate-note command with fresh identity and active lifecycle defaults.
- [x] Editor saves the current draft before duplication, then opens the independent copy.
- [x] Live local word and Unicode-code-point character counts.
- [x] Focused repository/controller/widget regressions for the new behavior.
- [x] No schema, backup-format, dependency, permission, account, server, or network requirement introduced by this checkpoint.

Remaining candidate work, ordered for later 2.1.x checkpoints rather than being silently bundled into the first validated slice:

- [ ] Multi-select note actions.
- [ ] Dedicated folder/tag rename/merge management.
- [ ] Saved searches/local smart filters.
- [ ] Optional automatic trash retention.
- [ ] Additional Markdown-lite shortcuts, including desktop/browser keyboard shortcuts.
- [ ] Better checklist interaction without converting storage into rich text.
- [ ] Import preview.
- [ ] Batch Markdown export.

Before 2.1.0 integration, its own CI/security/six-platform matrix must be green. Every implemented item should also be reviewed on compact mobile, desktop, and Web viewports before release.

## Milestone: 2.2 — resilience and scale

Candidate work:

- Database-side collection/folder/tag filtering.
- Pagination/keyset loading for large libraries.
- 1k/10k/50k fictional benchmark fixtures.
- Search ranking/highlighting improvements.
- Snapshot pruning/retention policy.
- Backup corruption-detection metadata/checksum using maintained primitives, without treating it as encryption/authenticity.
- Backup dry-run report.
- Migration fixtures for every released database schema.
- Streaming/staged structured backup parsing only if profiling demonstrates need.
- Explicit backup entry count/size limits if abuse/scale testing warrants them.
- Browser-storage stress profiling and backend-specific behavior documentation.

## Milestone: 2.3 — deeper platform integration

Candidate work only when each platform path can be tested:

- Android share-to-NoteNest text import.
- iOS share extension feasibility.
- Desktop open-with behavior for Markdown.
- Platform shortcuts/quick actions.
- Window size/state persistence.
- Web install/PWA/offline-shell feasibility review without overstating storage durability.
- Web drag/drop import feasibility with the same size-validation guarantees.
- OS/browser recent-document integration only when it does not expose note content unintentionally.

Each integration needs privacy/permissions/security review and a safe unavailable/failure path.

## Internationalization milestone

English is the first shipping language. Future localization should:

- Move remaining literals to localization resources.
- Add generated ARB localizations.
- Test long strings and compact Web/mobile widths.
- Validate RTL before advertising it.
- Verify locale date/time formatting.
- Review browser/native platform-specific user-visible text.

No language is supported until major journeys are reviewed in that locale.

## Accessibility milestone

Potential improvements:

- More semantics regression coverage.
- Focus-order tests for desktop/Web editor/navigation.
- High-contrast preference if user testing identifies a need.
- Adjustable editor line height/reading width.
- Stable accessibility golden checks if feasible with the pinned Flutter toolchain.
- Browser-specific keyboard/focus/zoom regression harnesses.

## Privacy-preserving optional sync — research only

Remote synchronization is **not** part of the current core architecture. Any proposal must first define:

- Optionality and full local/offline core use.
- Threat/encryption/key-recovery model.
- Device/browser transfer and conflict semantics.
- Metadata leakage.
- Account/deletion/export obligations.
- Backend operational security.
- Migration from local-only data.
- Clear opt-in and privacy disclosures.

Until these questions have robust answers, validated local backup/export is preferred over required cloud complexity.

## Explicit non-goals for now

- Advertising SDKs.
- Forced sign-in.
- Mandatory cloud storage.
- Social feed/community features.
- Unrelated cryptocurrency/blockchain features.
- Custom cryptography.
- Plugin marketplace before core stability.
- AI processing that silently uploads private notes.
- A backend merely to make the architecture appear larger.
- A custom Web/Linux password system merely to claim app-lock parity.

## Maintenance track

Every release cycle includes:

- Semantic/build/toolchain/lockfile review.
- Dependency and Drift Web runtime-pair review.
- Native/browser permission/capability review.
- Database migration/backup compatibility review.
- Android/iOS/Windows/macOS/Linux/Web build review.
- Web deployment MIME/worker/storage behavior review.
- Accessibility regression review including browser focus/zoom.
- Settings/lifecycle/import/export/link failure-path review.
- Exhaustive tracked-file documentation review.
- Security/privacy documentation review.
- GitHub Actions runtime-major review, with maintained published majors enforced by repository policy.

See [`what_changed.md`](what_changed.md) for the exact current engineering checkpoint.
