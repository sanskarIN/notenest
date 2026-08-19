# NoteNest Roadmap

The roadmap keeps future work aligned with NoteNest's local-first, private, accessible notes experience. It is not a promise of release dates. Priorities may change based on defects, platform changes, maintenance cost, and user feedback.

## Product principles

Future features should:

1. Preserve useful offline functionality.
2. Avoid requiring an account for core notes.
3. Keep user data portable.
4. Prefer local processing where practical.
5. Be accessible by keyboard, touch, and assistive technologies.
6. Work coherently on compact and desktop layouts.
7. Have tests and documentation proportional to risk.
8. Avoid intrusive monetization or donation prompts.
9. Avoid adding features merely to increase feature count.
10. Keep security and migration compatibility explicit.

## Milestone: 1.0.0 — first stable release

### Required before stable

- [ ] All configured CI jobs green from a clean checkout.
- [ ] Drift generation and strict analyzer checks pass.
- [ ] Unit, repository/database, backup, and widget tests pass.
- [ ] Android build smoke test passes.
- [ ] Windows, Linux, and macOS build jobs pass on their native runners.
- [ ] iOS no-codesign build validation passes on macOS.
- [ ] Verify backup export/restore manually using fictional data.
- [ ] Verify app-lock supported/unsupported flows on appropriate devices.
- [ ] Replace layout illustration with verified runtime screenshots while keeping the reference only if useful.
- [ ] Manual keyboard-navigation review on desktop.
- [ ] Manual screen-reader semantics review on at least one mobile platform.
- [ ] Manual large-text and reduced-motion review.
- [ ] Clean release notes and tagged version.
- [ ] Confirm privacy/security documentation exactly matches the built release.

## Milestone: 1.1 — organization and productivity polish

Candidate work after 1.0:

- Configurable sorting: updated, created, title, pinned-first behavior.
- Multi-select note actions.
- Better folder/tag management screens with rename/merge flows.
- Saved searches/local smart filters.
- Optional automatic trash retention period with clear local-only behavior.
- More Markdown-lite editor shortcuts on desktop.
- Better checklist interaction without converting the app into a full rich-text editor.
- Duplicate-note command.
- Local word/character count.
- Import preview before committing a large batch.
- Batch Markdown export.

## Milestone: 1.2 — resilience and scale

Candidate work:

- Pagination/keyset loading for very large local libraries.
- Benchmark fixture generator for 1k/10k/50k notes.
- Search ranking/highlight improvements.
- Snapshot pruning policy with user-visible retention controls.
- Backup integrity metadata/checksum using maintained primitives for corruption detection (not as a security/encryption claim).
- Backup dry-run report before restore.
- Migration-fixture tests for every released schema version.
- Crash-safe import staging for large backups if profiling demonstrates a need.

## Milestone: 1.3 — platform integration

Candidate work, only when platform behavior can be tested:

- Android share-to-NoteNest text import.
- iOS share extension feasibility review.
- Desktop open-with behavior for Markdown files.
- Platform shortcuts/quick actions for creating a note.
- Window-size/state persistence on desktop.
- OS-level recent-document integration only if it does not expose private note content unintentionally.

Every platform integration requires a privacy/permissions review.

## Internationalization milestone

The first shipping language is English. Future localization work should:

- Move remaining widget literals into localization resources.
- Add ARB-based generated localizations.
- Test long-string layouts.
- Test right-to-left layout before advertising RTL support.
- Verify date/time formatting by locale.
- Avoid embedding untranslated text in native configuration where user-visible.

No language should be listed as supported until the major user journeys have been reviewed in that locale.

## Accessibility milestone

Potential improvements after baseline manual validation:

- Automated semantics regression checks for key screens.
- Focus-order tests for desktop editor/navigation.
- High-contrast theme preference if user testing identifies a need beyond system contrast behavior.
- Adjustable editor line height/reading width.
- More explicit non-color indicators for optional note color metadata.
- Accessibility-focused golden checks only if stable across supported Flutter versions.

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

Every release cycle also includes:

- Dependency review.
- Flutter/Dart compatibility review.
- Native permission review.
- Database migration review.
- Accessibility regression review.
- Backup/restore compatibility check.
- Documentation link/command review.
- Security/privacy policy review.

See [`what_changed.md`](what_changed.md) for the exact current engineering checkpoint rather than treating this roadmap as a completion log.
