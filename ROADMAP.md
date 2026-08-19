# NoteNest Roadmap

The roadmap keeps future work aligned with NoteNest's local-first, private, accessible notes experience. It is not a promise of release dates. Priorities may change based on defects, platform changes, maintenance cost, and user feedback.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Product principles

Future features should:

1. Preserve useful offline functionality.
2. Avoid requiring an account for core notes.
3. Keep user data portable.
4. Prefer local processing where practical.
5. Be accessible by keyboard, touch, and assistive technologies.
6. Work coherently on compact and desktop layouts.
7. Have tests/documentation proportional to risk.
8. Avoid intrusive monetization or donation prompts.
9. Avoid adding features merely to increase feature count.
10. Keep security, migration, and release metadata compatibility explicit.

## 2.0.12 release-candidate hardening already implemented

The following engineering work is already present on `main`; implementation is listed separately from the unchecked verification tasks because source completion does not equal release verification.

### Data integrity and persistence

- Serialized editor save submissions to prevent older autosaves overtaking newer drafts.
- Stale editor save completions cannot report a newer visible draft as already saved.
- Serialized settings writes with rollback to the last persisted value on failure.
- Persistence-first onboarding so the app does not leave onboarding until completion is saved.
- Shared-preference setter failures are treated as storage failures rather than silently accepted.
- Collection switching clears stale folder/tag filters.
- Folder/tag metadata is scoped to All Notes, Favorites, Archive, or Trash using the same collection predicate as note listing.

### Import/export and recovery

- Native Markdown/backup imports avoid eager NoteNest byte loading.
- Bounded disk-backed read checks before/through streaming.
- 16 MiB Markdown/text import ceiling.
- 64 MiB JSON backup import ceiling.
- Strict UTF-8 handling.
- Backup tag and note/version relationship validation.
- Explicit UTC timestamp validation for imported note/version timestamps.
- `updatedAt >= createdAt` validation for imported notes.
- 32-bit ARGB validation for imported note/version color values.
- Whitespace-polluted imported note/version IDs are rejected.
- Cross-platform-safe Markdown export filename normalization.
- Unicode-safe filename truncation that does not split surrogate pairs/code points.

### UI/accessibility/platform resilience

- Collection-specific empty states with context-appropriate actions.
- Explicit non-color note-color selection cues and shared 48 logical-pixel custom touch target.
- Centralized external-link service for repository/funding/email/release links.
- External launcher failures/exceptions are contained and produce user-visible feedback.

### Release/repository engineering

- Exact Flutter SDK pin (`3.44.7`) synchronized across `.flutter-version`, CI, native platform builds, and release packaging.
- Repository completeness, Markdown local-link, version synchronization, and lightweight secret checks in the quality pipeline.
- `tool/check_version_sync.py` keeps `pubspec.yaml`, `AppStrings.version`, changelog, and version-specific release notes synchronized.
- Dedicated `docs/releases/2.0.12.md` release-candidate notes.
- Regression coverage for the deterministic hardening above.
- Setup/development/testing/security/architecture/release documentation synchronized with the 2.0.12 behavior.

## Milestone: 2.0.12 — stable verification

### Required before stable tag

- [x] Package version set to `2.0.12+2012`.
- [x] Visible app version set to `2.0.12`.
- [x] Matching changelog section prepared.
- [x] Matching version-specific release notes prepared.
- [x] Version synchronization check added to CI.
- [ ] All configured CI jobs green from a clean checkout.
- [ ] `python tool/check_version_sync.py` passes on the exact candidate.
- [ ] Drift generation and strict analyzer checks pass.
- [ ] Unit/controller/repository/widget tests pass.
- [ ] Repository, Markdown-link, and lightweight secret checks pass.
- [ ] Android release build smoke test passes.
- [ ] Windows, Linux, and macOS release build jobs pass on native runners.
- [ ] iOS no-codesign build validation passes on macOS.
- [ ] Verify serialized final-draft autosave behavior manually after rapid edits/background/navigation.
- [ ] Verify settings persistence/rollback and persistence-first onboarding on representative platforms.
- [ ] Verify collection-specific folder/tag filters, including Trash.
- [ ] Verify backup export/restore using fictional data.
- [ ] Verify strict backup UTC/color/identifier rejection with malformed fictional files.
- [ ] Verify oversized Markdown/backup rejection through real platform file pickers/providers.
- [ ] Verify external HTTP(S)/mailto/release links and safe failure behavior.
- [ ] Verify app-lock supported/unsupported flows on appropriate devices.
- [ ] Replace layout illustration with verified runtime screenshots while keeping the reference only if useful.
- [ ] Manual keyboard-navigation review on desktop.
- [ ] Manual screen-reader semantics review on at least one mobile platform.
- [ ] Manual large-text, note-color selection, and reduced-motion review.
- [ ] Final release notes/checksums/signing status prepared.
- [ ] Confirm privacy/security documentation exactly matches the built release.
- [ ] Create `v2.0.12` only on the exact verified commit.

## Milestone: 2.1 — organization and productivity polish

Candidate work after stable 2.0.12:

- Configurable sorting: updated, created, title, pinned-first behavior.
- Multi-select note actions.
- Dedicated folder/tag management with rename/merge flows.
- Saved searches/local smart filters.
- Optional automatic trash retention period with clear local-only behavior.
- More Markdown-lite editor shortcuts on desktop.
- Better checklist interaction without converting the app into a full rich-text editor.
- Duplicate-note command.
- Local word/character count.
- Import preview before committing a batch.
- Batch Markdown export.

## Milestone: 2.2 — resilience and scale

Candidate work:

- Database-side collection/folder/tag filtering to reduce large-library Dart filtering.
- Pagination/keyset loading for large local libraries.
- Benchmark fixture generator for 1k/10k/50k notes.
- Search ranking/highlight improvements.
- Snapshot pruning policy with user-visible retention controls.
- Backup corruption-detection metadata/checksum using maintained primitives (not as an encryption/security-authenticity claim).
- Backup dry-run report before restore.
- Migration-fixture tests for every released database schema.
- Streaming/staged structured backup parsing if profiling demonstrates a need beyond the current bounded final buffer.
- Explicit size/count limits for backup entries if real-world abuse/scale testing warrants them.

## Milestone: 2.3 — platform integration

Candidate work, only when platform behavior can be tested:

- Android share-to-NoteNest text import.
- iOS share extension feasibility review.
- Desktop open-with behavior for Markdown files.
- Platform shortcuts/quick actions for creating a note.
- Window-size/state persistence on desktop.
- OS-level recent-document integration only if it does not expose private note content unintentionally.

Every platform integration requires a privacy/permissions review and safe failure path.

## Internationalization milestone

The first shipping language is English. Future localization work should:

- Move remaining widget literals into localization resources.
- Add ARB-based generated localizations.
- Test long-string layouts.
- Test right-to-left layout before advertising RTL support.
- Verify date/time formatting by locale.
- Avoid embedding untranslated text in native configuration where user-visible.

No language should be listed as supported until major user journeys are reviewed in that locale.

## Accessibility milestone

Potential improvements after baseline manual validation:

- Automated semantics regression checks for more key screens.
- Focus-order tests for desktop editor/navigation.
- High-contrast theme preference if user testing identifies a need beyond system contrast behavior.
- Adjustable editor line height/reading width.
- Accessibility-focused golden checks only if stable across supported Flutter versions.

The current custom note-color control already has a non-color selected cue, selected semantics, and a 48 logical-pixel target; future custom controls should preserve that baseline.

## Privacy-preserving optional sync — research only

Remote synchronization is **not** part of the current core architecture. It should not be implemented casually. Any future sync proposal must first define:

- Whether it is optional and core offline use remains complete.
- Threat model and encryption model.
- Key creation, backup, recovery, and device-transfer behavior.
- Conflict-resolution semantics.
- Metadata leakage.
- Account/deletion/export obligations.
- Backend operational security and abuse controls.
- Migration from local-only libraries.
- Clear privacy disclosures and opt-in.

Until those questions have robust answers, local backup/export is preferred over adding cloud complexity.

## Explicit non-goals for now

- Advertising SDKs.
- Forced sign-in.
- Mandatory cloud storage.
- Social feed/community features.
- Cryptocurrency/blockchain features unrelated to note-taking.
- Custom cryptography.
- A plugin marketplace before the core app is stable.
- AI processing that silently uploads private notes.
- A backend merely to make the architecture look larger.

## Maintenance track

Every release cycle includes:

- Version metadata synchronization review.
- Dependency review.
- Flutter/Dart exact-toolchain-pin review.
- Native permission review.
- Database migration review.
- Accessibility regression review.
- Backup/restore compatibility and validation review.
- Settings persistence/rollback review.
- Collection metadata/filter review.
- Import-bound/export-filename regression review.
- External-link failure-path review.
- Documentation link/command review.
- Security/privacy policy review.

See [`what_changed.md`](what_changed.md) for the exact current engineering checkpoint rather than treating this roadmap as a completion log.
