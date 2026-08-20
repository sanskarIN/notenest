# NoteNest Roadmap

The roadmap keeps future work aligned with NoteNest's local-first, private, accessible notes experience. It is not a promise of release dates.

Current release-candidate target: **2.0.12** (`2.0.12+2012`).

## Product principles

Future features should:

1. Preserve useful offline/local functionality.
2. Avoid required accounts for core notes.
3. Keep data portable.
4. Prefer local processing where practical.
5. Be accessible by keyboard, touch, browser, and assistive technologies.
6. Work coherently across compact/wide layouts.
7. Treat Android, iOS/iPadOS, Windows, macOS, Linux, and Web as explicit platform-impact surfaces.
8. Have tests/documentation proportional to risk.
9. Avoid intrusive monetization/donation flows.
10. Keep security, migration, dependency, and release compatibility explicit.

## 2.0.12 hardening already implemented

Implementation is listed separately from pending verification because source completion is not release certification.

### Data integrity and persistence

- Ordered editor save submissions prevent old autosaves overtaking newer drafts.
- Stale save completions cannot mark a newer draft saved.
- Back/export/history waits for the appropriate current-draft save.
- Settings writes are serialized with rollback after applicable failures.
- Onboarding is persistence-first.
- Root composition cleanup owns settings/database disposal.
- Collection metadata/filter lifecycle rules are consistent.
- A trashed note cannot be pinned.

### Import/export and recovery

- 16 MiB Markdown/text and 64 MiB backup ceilings.
- Strict UTF-8 processing.
- Native imports use bounded cached-path streaming rather than eager picker bytes.
- Web imports use picker bytes/streams with reported and actual length validation.
- Backup app/schema/type/tag/ID/relationship/UTC/timestamp/color/lifecycle validation.
- Conflict-safe transactional restore.
- Cross-platform/Unicode-safe Markdown export names.

### Six-platform baseline

- Android target/bootstrap/build automation.
- iOS/iPadOS target/bootstrap/no-codesign compile automation.
- Windows target/build automation.
- macOS target/build automation.
- Linux target/build automation.
- **Web target with Drift SQLite WASM/worker storage, browser file import/export, Chrome fallback regression, and release bundle packaging.**
- Responsive compact/wide UI spans phones, tablets, desktop windows, and browser viewports.
- App-lock service degrades safely where `local_auth` is unavailable; Web/Linux remain usable.

### Accessibility/platform resilience

- Collection-specific empty states.
- Non-color color-selection cues and 48-pixel custom target baseline.
- Centralized external-link boundary and failure feedback.
- Browser/native platform capability differences are explicit instead of hidden behind false parity.

### Release/repository engineering

- Flutter **3.44.7** exact pin across project/CI/platform/release automation.
- Six-platform runner bootstrap with fail-fast Android/iOS configuration checks.
- Drift **2.34.3** Web runtime asset pin tied to the direct dependency.
- Version, repository, 108-file exhaustive-reference, Markdown-link, and secret policy gates.
- Six-platform build matrix including Chrome Web smoke + release compile.
- Six-platform release packaging including Web output.
- Complete setup/testing/release/security/privacy documentation for browser-local operation.

## Milestone: 2.0.12 — stable verification

### Required before stable tag

- [x] Version `2.0.12+2012` / visible 2.0.12 synchronized.
- [x] Flutter 3.44.7 workflow/toolchain pin synchronized.
- [x] All six Flutter targets implemented in bootstrap/build/release automation.
- [x] Web browser-safe file and app-lock boundaries implemented.
- [x] Drift Web runtime assets pinned to matching Drift 2.34.3 release.
- [x] Chrome Web platform smoke regression added.
- [x] Exhaustive repository reference expanded to 108 tracked files.
- [ ] Resolver-generated `pubspec.lock` committed/reviewed/cataloged/enforced (issue #8).
- [ ] Full deterministic quality/security gates green on the exact post-lock candidate.
- [ ] Android release compile green.
- [ ] Windows release compile green.
- [ ] Linux release compile green.
- [ ] macOS release compile green.
- [ ] iOS no-codesign compile green.
- [ ] Chrome Web smoke green.
- [ ] Web release compile green.
- [ ] Rapid-edit/Back latest-draft behavior manually verified.
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

## Milestone: 2.1 — organization and productivity polish

Candidate work after stable 2.0.12:

- Configurable sorting.
- Multi-select note actions.
- Dedicated folder/tag rename/merge management.
- Saved searches/local smart filters.
- Optional automatic trash retention.
- Additional Markdown-lite shortcuts, including desktop/browser keyboard shortcuts.
- Better checklist interaction without converting storage into rich text.
- Duplicate-note command.
- Local word/character count.
- Import preview.
- Batch Markdown export.

Every item should be reviewed on compact mobile, desktop, and Web viewports.

## Milestone: 2.2 — resilience and scale

Candidate work:

- Database-side collection/folder/tag filtering.
- Pagination/keyset loading for large libraries.
- 1k/10k/50k fictional benchmark fixtures.
- Search ranking/highlighting improvements.
- Snapshot pruning/retention policy.
- Backup corruption-detection metadata/checksum using maintained primitives (not an encryption/authenticity claim).
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
- Threat/encryption/key recovery model.
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
- A custom Web/Linux password system merely to claim app-lock feature parity.

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

See [`what_changed.md`](what_changed.md) for the exact current engineering checkpoint.
