# GitHub Repository Operations

This guide covers repository settings and maintenance practices that live primarily in GitHub rather than application source.

## Default branch

Use `main` as the default branch.

Recommended ruleset/protection where the repository/account plan permits:

- Require pull requests for normal feature/fix work when practical.
- Require the primary CI quality check.
- Require relevant six-platform build checks for application/platform changes.
- Require conversation resolution.
- Block force pushes and branch deletion on `main`.
- Limit administrator/bypass permissions to real recovery needs.
- Use linear history only if the maintainers intentionally choose squash/rebase.

A solo maintainer may use a lighter PR requirement, but accidental history rewrite and unverified release changes should still be prevented.

## Suggested labels

| Label | Purpose |
|---|---|
| `bug` | Reproducible defect |
| `enhancement` | Product improvement |
| `documentation` | Documentation-only work |
| `dependencies` | Package/toolchain updates |
| `ci` | Automation/build infrastructure |
| `security` | Security hardening/report coordination without vulnerability detail |
| `accessibility` | Accessibility improvements/defects |
| `performance` | Measured performance work |
| `database` | Schema/migration/persistence |
| `android` | Android-specific |
| `ios` | iOS/iPadOS-specific |
| `windows` | Windows-specific |
| `macos` | macOS-specific |
| `linux` | Linux-specific |
| `web` | Browser/Web-specific |
| `cross-platform` | Affects several/all supported targets |
| `good first issue` | Small, well-defined newcomer task |
| `help wanted` | Maintainer welcomes implementation help |
| `blocked` | Waiting on an external prerequisite/decision |

Keep labels purposeful rather than creating overlapping variants.

## Milestones

Use release-oriented milestones matching the current project line, for example:

- `2.0.12 — Stable verification`
- `2.1 — Organization & productivity`
- `2.2 — Resilience & scale`
- `2.3 — Platform integration`

Only schedule issues into a milestone when scope is credible. [`../ROADMAP.md`](../ROADMAP.md) remains the broader direction source.

## Issues

The bug form supports Android, iOS/iPadOS, Windows, macOS, Linux, and Web. Web reports should include browser/version and deployment-origin context when relevant.

Triage:

1. Confirm enough reproduction/problem detail exists.
2. Remove/redact exposed secrets or private user data immediately.
3. Check duplicates.
4. Label by type/subsystem/platform.
5. Request a minimal fictional reproduction if personal data was used.
6. Add a milestone only when scheduled.
7. Route vulnerabilities privately according to `SECURITY.md`.

## Pull requests

Use the repository PR template. Prefer focused Conventional Commits and merge only when required checks are green, unless a documented emergency explicitly justifies an exception.

Reviewers should inspect:

- database changes: migration, FTS, native/Web database behavior, backup compatibility;
- dependency/plugin changes: actual implementation/capability on all six targets;
- Web changes: native-only imports, browser storage, worker/WASM serving, file picker/download semantics;
- UI changes: compact/wide/browser layouts, keyboard/focus, screen readers, text/zoom, motion;
- release changes: exact version/toolchain/lockfile/artifact/check status.

## Dependabot and dependencies

`.github/dependabot.yml` proposes supported dependency/workflow updates. Automated version bumps are not compatibility evidence.

When a package/plugin changes:

- review maintenance/license/security notes;
- review all six Flutter target implementations;
- review permissions/network/privacy behavior;
- regenerate platform runners;
- update/review the resolver lockfile once the application lockfile baseline is committed;
- if `drift` changes, review/update the pinned Web worker/WASM pairing;
- run all affected native/Web tests/builds.

## Actions

Current workflows:

- **CI** — release/toolchain synchronization, locked dependency restore, Drift generation, formatting, analyzer, tests, repository/reference/link/secret checks, and coverage artifact upload.
- **Security checks** — repository security baseline and pull-request dependency review.
- **Platform builds** — Android, Linux, Windows, macOS, unsigned iOS, plus Chrome Web fallback smoke and Web release compilation.
- **Release artifacts** — tag/manual packaging for Android, Linux, Windows, macOS, unsigned iOS validation, and Web bundle output without embedding signing secrets.

Maintained action-major baseline for GitHub-hosted runners:

- `actions/checkout@v7`;
- `actions/setup-java@v5` where Java setup is required;
- `actions/upload-artifact@v7` for coverage/release artifacts;
- `actions/dependency-review-action@v5` for pull-request dependency review;
- `subosito/flutter-action@v2`, the current supported major for the Flutter setup action used by this project.

`actions/setup-java@v6` is not used for production verification because that tag is not currently published as a stable release. The project stays on the latest published stable major until a later migration is both available and verified.

The maintained first-party action majors above use current supported action runtimes and therefore assume up-to-date GitHub-hosted runners. If self-hosted runners are introduced later, their runner version must be reviewed before adopting or retaining those majors.

`tool/check_repo.py` enforces this maintained action-major baseline so a later workflow edit cannot silently regress to an obsolete or unpublished runtime line.

All Flutter jobs use the exact project SDK pin. If GitHub Actions are disabled, badges/queued workflows are not proof of verification.

## Security features

Where available for this public repository/account, enable:

- secret scanning/push protection;
- Dependabot alerts;
- dependency graph;
- private vulnerability reporting/security advisories.

The current workflow uses Flutter's strict analyzer plus dependency/repository/secret checks rather than pretending unsupported CodeQL language analysis covers Dart.

## Funding

`.github/FUNDING.yml` points to the optional Buy Me a Coffee page. Funding must not gate core functionality.

## Releases

Use annotated semantic tags such as `v2.0.12`. Never move a published tag.

For the current candidate:

- the resolver-generated `pubspec.lock` is committed, cataloged, and enforced across quality/platform/release workflows;
- generated platform runners must preserve the committed `pubspec.yaml` and `pubspec.lock` exactly before locked restoration;
- issue #8 remains open until the exact final post-fix automated verification is complete;
- the exact final candidate must pass CI/security plus Android/iOS/Windows/macOS/Linux/Web build verification;
- real runtime/accessibility/browser deployment checks must be recorded;
- signing/checksum status must be explicit.

Follow [`release.md`](release.md).

## Repository description/topics

Suggested description:

> Private, local-first cross-platform notes app for Android, iOS, Windows, macOS, Linux and Web, built with Flutter, Drift and SQLite.

Suggested topics:

- `flutter`
- `dart`
- `notes-app`
- `sqlite`
- `drift`
- `offline-first`
- `local-first`
- `android`
- `ios`
- `windows`
- `linux`
- `macos`
- `web`
- `open-source`
- `productivity`

Keep topics accurate rather than adding unrelated trending terms.

## Verification PR discipline

A verification-only PR may be used to trigger path-filtered build matrices without merging a functional change. Such a PR must:

- identify the exact `main` candidate SHA;
- contain only a clearly non-functional trigger marker beyond that candidate;
- never be merged into `main`;
- be realigned whenever `main` changes;
- treat only completed checks on its **current head** as evidence;
- explicitly mark older queued/green runs as superseded after realignment.

For 2.0.12, the previous PR #7 run is diagnostic only because `main` advanced after it exposed test, action-tag, and runner-bootstrap blockers. A new exact verification head must be created from the final post-fix `main` candidate.

## Handoff discipline

After a meaningful phase, update `what_changed.md` with implementation changes, exact verification limitations, release blockers, and current GitHub checkpoints so another session can continue without reconstructing project history from chat.
