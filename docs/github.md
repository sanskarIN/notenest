# GitHub Repository Operations

This guide covers repository settings that live in GitHub rather than in source files.

## Default branch

Use `main` as the default branch.

Recommended branch protection/ruleset:

- Require a pull request before merge for normal feature/fix work when practical.
- Require the `CI / Format, analyze, test` check.
- Require relevant platform build checks for changes affecting Flutter/native code.
- Require conversation resolution.
- Block force pushes to `main`.
- Block branch deletion.
- Keep administrator/bypass access limited to real recovery needs.
- Prefer linear history only if the team intentionally uses squash/rebase; otherwise merge commits are acceptable.

A solo maintainer may choose a lighter pull-request requirement, but force-push protection and green quality checks remain valuable.

## Suggested labels

Keep labels small and purposeful:

| Label | Purpose |
|---|---|
| `bug` | Reproducible defect |
| `enhancement` | Product improvement |
| `documentation` | Documentation-only work |
| `dependencies` | Dependency updates |
| `ci` | Automation/build infrastructure |
| `security` | Security hardening/report coordination (do not expose vulnerability detail) |
| `accessibility` | Accessibility improvements/defects |
| `performance` | Measured performance work |
| `database` | Schema/migration/persistence |
| `android` | Android-specific |
| `windows` | Windows-specific |
| `linux` | Linux-specific |
| `macos` | macOS-specific |
| `ios` | iOS-specific |
| `good first issue` | Small, well-defined newcomer task |
| `help wanted` | Maintainer welcomes implementation help |
| `blocked` | Waiting on an external prerequisite/decision |

Do not create dozens of overlapping labels that make triage harder.

## Milestones

Suggested milestones:

- `1.0.0 — First stable release`
- `1.1 — Organization & productivity`
- `1.2 — Resilience & scale`
- `1.3 — Platform integration`

Only assign an issue when the milestone has a credible scope. `ROADMAP.md` remains the broader direction document.

## Issues

The repository includes forms for bug reports and feature requests. Keep security vulnerabilities private according to `SECURITY.md`.

Triage flow:

1. Confirm issue contains enough reproduction/problem detail.
2. Redact/remove exposed secrets/private user data immediately if present.
3. Check duplication.
4. Label by type and affected subsystem/platform.
5. Add milestone only when scheduled.
6. Request a minimal fictional reproduction if personal notes/backups were used.
7. Close as not planned when out of product scope, with a clear explanation.

## Discussions

If GitHub Discussions is enabled, suggested categories are:

- Announcements — maintainer-only project/release updates.
- Q&A — development/setup questions that benefit from reusable public answers.
- Ideas — early product proposals before an implementation issue exists.
- Show and tell — screenshots/forks/integrations that respect user privacy.

Do not use Discussions for private vulnerability reports or anything requiring private note content.

## Pull requests

Use the repository PR template. Prefer atomic changes and Conventional Commits. Merge only when required checks are green or an explicitly documented emergency justifies a controlled exception.

For database changes, reviewers should inspect migration + backup compatibility + FTS impact, not only UI behavior.

For UI changes, reviewers should inspect responsive and accessibility impact.

## Dependabot

`.github/dependabot.yml` checks Dart/Flutter package and GitHub Actions updates weekly. Dependency PRs still require normal tests/review; an automated version bump is not proof of compatibility.

When a native plugin changes:

- Review permissions/native setup.
- Regenerate runners.
- Run affected platform builds.
- Re-test app-lock/file-picker behavior as relevant.

## Actions

Current workflows:

- `CI` — dependency resolution, Drift generation, format, analyze, tests, policy/secret checks.
- `Security checks` — tracked-file secret scan and PR dependency review.
- `Platform builds` — native compile validation for Android, Linux, Windows, macOS, and iOS no-codesign.
- `Release artifacts` — tagged/manual artifact packaging without embedding signing secrets.

If Actions are disabled at repository level, enable them before treating badges/checks as meaningful.

## Security features

For a public repository, enable available GitHub security features where supported by the account/repository:

- Secret scanning and push protection.
- Dependabot alerts.
- Dependency graph.
- Private vulnerability reporting/security advisories if desired.

CodeQL does not provide a Dart-specific analysis database in the current project workflow, so Flutter's strict analyzer plus dependency/secret checks are used instead of adding a non-functional CodeQL language job. Revisit this if GitHub adds appropriate Dart support.

## Funding

`.github/FUNDING.yml` points to the optional Buy Me a Coffee page. Funding should remain non-intrusive and must not gate core app functionality.

## Releases

Use annotated semantic version tags such as `v1.0.0`. Do not move an existing public tag. Follow `docs/release.md` and attach only artifacts whose build/signing status is accurately described.

## Repository description/topics

Suggested description:

> Private, offline-first cross-platform notes app built with Flutter, Dart, Drift and SQLite.

Suggested topics:

- `flutter`
- `dart`
- `notes-app`
- `sqlite`
- `drift`
- `offline-first`
- `android`
- `windows`
- `linux`
- `macos`
- `open-source`
- `productivity`

Keep topics relevant; do not add unrelated trending terms.

## Handoff discipline

After a meaningful development phase, update `what_changed.md` with exact verification and recent commits so the next working session does not need to reconstruct state from chat history.
