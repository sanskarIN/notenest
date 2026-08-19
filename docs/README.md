# NoteNest Documentation Index

This directory contains the implementation, development, verification, accessibility, security-adjacent, and release documentation for NoteNest.

Start with the root [`README.md`](../README.md) for the project overview. Use this index when working on the repository or reviewing a release candidate.

## Architecture and design

- [`architecture.md`](architecture.md) — module boundaries, application composition, Drift/SQLite/FTS architecture, editor and controller design, backup boundaries, app lock, logging, accessibility, and native-runner strategy.
- [`adr/0001-flutter-drift-modular-monolith.md`](adr/0001-flutter-drift-modular-monolith.md) — decision to use Flutter + Drift in a modular monolith.
- [`adr/0002-offline-first-data.md`](adr/0002-offline-first-data.md) — offline-first data ownership and storage decision.
- [`adr/0003-generated-platform-runners.md`](adr/0003-generated-platform-runners.md) — reproducible generated native runner strategy.

## Data and reliability

- [`data-portability.md`](data-portability.md) — JSON backup format, Markdown metadata, restore conflicts, import limits, UTF-8 behavior, safe filenames, and compatibility rules.
- [`reliability.md`](reliability.md) — stale-load protection, autosave serialization, lifecycle behavior, load recovery, app-lock recovery, Unicode-safe bounds, and async review invariants.
- [`performance.md`](performance.md) — performance assumptions, measurement approach, fixture sizes, and optimization guidance.

## Development

- [`setup.md`](setup.md) — Flutter/toolchain installation, platform runner generation, package/code generation, Android/Windows/Linux/macOS/iOS setup, and quality-gate commands.
- [`development.md`](development.md) — branching, commits, architecture boundaries, persistence/search/autosave rules, dependency changes, generated code, logging, testing, and handoff discipline.
- [`testing.md`](testing.md) — unit/repository/widget/integration/native testing strategy and manual verification matrix.
- [`troubleshooting.md`](troubleshooting.md) — common Flutter, codegen, native, auth, import/export, backup, CI, formatting, and database problems.

## Accessibility and UI quality

- [`accessibility.md`](accessibility.md) — semantics, touch targets, text scaling, reduced motion, keyboard/screen-reader checks, responsive review, and release accessibility checklist.

## GitHub and release operations

- [`github.md`](github.md) — GitHub repository operations, branch protection guidance, labels/milestones, automation, Discussions, and maintenance workflow.
- [`release.md`](release.md) — release prerequisites, automated checks, platform builds, packaging/signing boundaries, screenshots, checksums, tag/release procedure, and rollback considerations.

## Root governance and user-facing policy files

The following live at repository root because GitHub/open-source tooling expects or benefits from those conventional locations:

- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — contribution workflow and engineering expectations.
- [`../CODE_OF_CONDUCT.md`](../CODE_OF_CONDUCT.md) — community conduct policy.
- [`../SECURITY.md`](../SECURITY.md) — vulnerability reporting and security boundaries.
- [`../PRIVACY.md`](../PRIVACY.md) — privacy/data handling description.
- [`../SUPPORT.md`](../SUPPORT.md) — support channels and issue-reporting guidance.
- [`../CHANGELOG.md`](../CHANGELOG.md) — notable implementation/release changes.
- [`../ROADMAP.md`](../ROADMAP.md) — planned direction and non-goals.
- [`../what_changed.md`](../what_changed.md) — current engineering handoff and exact verification state.

## Automation and executable repository checks

These are code rather than prose, but they are part of the project documentation/verification contract:

- `tool/check_repo.py` — required-file, reproducibility, source-marker, generated-file, toolchain-pin, and ignore-policy checks.
- `tool/check_markdown_links.py` — local Markdown link validation.
- `tool/security_scan.py` — lightweight tracked-text secret pattern scan that does not echo matched secret values.
- `tool/bootstrap_platforms.py` — reproducible native runner generation and NoteNest-specific native patching.
- `tool/test_bootstrap_platforms.py` — native bootstrap patch invariants.

GitHub Actions:

- `.github/workflows/ci.yml` — formatting, analysis, Flutter tests/coverage, Python tool tests, repository policy, link check, secret scan, and resolved lock artifact.
- `.github/workflows/platform-builds.yml` — Android, Linux, Windows, macOS, and iOS-no-codesign compile matrix.
- `.github/workflows/security.yml` — repository secret baseline and pull-request dependency review.
- `.github/workflows/release.yml` — packaged multi-platform release artifacts and SHA-256 checksum manifests.

## Documentation maintenance rule

When a code change alters a public behavior, persistence rule, native requirement, verification command, dependency/toolchain baseline, privacy/security boundary, or release procedure, update the relevant documentation in the same branch.

Do not claim a test/build/manual check passed merely because its command or workflow exists. The actual result belongs in `what_changed.md` or the corresponding release record.
