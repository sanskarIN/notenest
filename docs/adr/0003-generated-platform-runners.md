# ADR 0003: Reproducible generated native runners

- Status: Accepted
- Date: 2026-08-19

## Context

Flutter native runner templates are largely framework-generated and change over time. NoteNest targets Android, Windows, Linux, macOS, and is iOS-ready, but the initial repository development environment did not include a Flutter SDK capable of generating/validating those runner trees locally.

Committing hand-written approximations of Flutter-generated native projects would create a high risk of stale or invalid templates. At the same time, NoteNest needs a reproducible way to generate required platform projects and apply the small native changes needed by `local_auth`.

## Decision

Do not commit guessed/stale framework-generated runner trees during the initial bootstrap. Instead:

- Keep `tool/bootstrap_platforms.py` in source control.
- Run Flutter's own `flutter create` for Android, iOS, Linux, macOS, and Windows.
- Patch Android's activity to use `FlutterFragmentActivity`.
- Patch the Android minimum SDK baseline required by the selected dependencies/project support policy.
- Add the iOS Face ID usage description needed for optional app lock.
- Generate runners in clean setup and native-build CI jobs.
- Keep platform-specific developer instructions in `docs/setup.md`.

## Why

This makes Flutter itself the source of truth for boilerplate runner templates instead of copying a template from an unknown SDK version. NoteNest-specific native deltas remain small, reviewable, and scripted.

## Consequences

### Positive

- Clean clones can reproduce runner files using their supported Flutter SDK.
- Less stale generated boilerplate in repository history.
- Flutter upgrades naturally expose template changes during regeneration.
- Required local-auth native patches are documented in code.
- CI can validate generated runners independently on native hosts.

### Tradeoffs

- `flutter create` is an explicit setup step.
- Native customization must be represented in the script or intentionally committed later.
- Upstream template path/text changes can break the patch script and require maintenance.
- The repository tree alone does not contain every generated native boilerplate file before bootstrap.
- Native release signing still requires platform-owner credentials outside the repository.

## When to reconsider

Begin committing full/selected runner trees if:

- Native code becomes substantial.
- Store metadata/entitlements require many persistent custom files.
- Platform-specific integrations are difficult to express safely as idempotent patches.
- Generated-template reproducibility becomes less reliable than reviewing committed native changes.

Any change in approach should explain migration/ownership in a new ADR or supersede this one.

## Verification

A runner-generation change should be checked by:

1. Starting from a clean checkout without runner directories.
2. Running `python tool/bootstrap_platforms.py`.
3. Running `flutter pub get` and Drift generation.
4. Building each target on a supported native host.
5. Testing optional app lock on supported Android/iOS devices when release verification is performed.

## Alternatives considered

### Commit manually reconstructed runner files

Rejected because manually approximating framework templates without the target Flutter toolchain can produce subtle compile/plugin registration issues.

### Commit runners from an arbitrary older Flutter SDK

Rejected because the repository's declared current toolchain baseline should not silently depend on stale generated templates.

### Support only one platform initially

Rejected because the project requirement explicitly includes multiple primary targets, and a reproducible generator allows those targets to remain first-class without inventing boilerplate.
