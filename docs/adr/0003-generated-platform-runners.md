# ADR 0003: Reproducible generated platform runners

- Status: Accepted
- Date: 2026-08-19
- Updated: 2026-08-20

## Context

Flutter platform projects are largely framework-generated and evolve with the SDK. NoteNest targets the complete Flutter platform set: Android, iOS/iPadOS, Linux, macOS, Windows, and Web.

Committing hand-written approximations of Flutter-generated projects would risk stale templates and plugin-registration drift. NoteNest also has a small set of platform-specific requirements:

- Android configuration required by `local_auth` and the selected SDK baseline.
- iOS Face ID usage description.
- Web SQLite WASM/worker runtime assets required by Drift Web.

## Decision

Keep the generation/bootstrap recipe in source control rather than committing guessed framework boilerplate.

`tool/bootstrap_platforms.py` must:

1. Run Flutter's generator for Android, iOS, Linux, macOS, Windows, and Web using the project-pinned Flutter SDK.
2. Patch/verify Android `FlutterFragmentActivity`.
3. Patch/verify Android biometric permission, minimum SDK, AppCompat dependency, and launch/normal theme baseline.
4. Patch/verify the iOS Face ID usage description.
5. Verify the direct Drift dependency matches the reviewed Web runtime version.
6. Obtain `sqlite3.wasm` and `drift_worker.js` from that same Drift release.
7. Perform basic asset sanity checks and fail instead of accepting missing/mismatched Web runtime assets.
8. Generate platform state in clean setup and CI build jobs.

## Why

Flutter remains the source of truth for runner boilerplate while NoteNest-specific deltas remain small, scripted, reviewable, and reproducible.

For Web, the decision also avoids committing binary/runtime assets that are derived from a pinned upstream Drift release. The source of truth is the direct Drift version plus the bootstrap rule, not an unexplained checked-in WASM blob.

## Consequences

### Positive

- Clean clones can reproduce all six runner targets from Flutter 3.44.7.
- Less generated boilerplate/binary churn in repository history.
- Flutter upgrades expose template changes during regeneration.
- Android/iOS authentication requirements stay explicit.
- Drift Web worker/WASM pairing is tied to the reviewed package version.
- CI can compile native targets and Web from the same source policy.

### Tradeoffs

- Platform bootstrap is an explicit setup step.
- Network access is required during bootstrap to obtain the pinned Drift Web assets.
- Upstream Flutter template changes can require patch maintenance.
- Drift version changes require explicit Web runtime review.
- The Git tree alone does not contain generated runner projects or Web runtime assets before bootstrap.
- Native signing still requires distributor-owned credentials outside the repository.
- Web deployment still requires correct MIME/hosting behavior after the build succeeds.

## Web-specific security/reproducibility boundary

The bootstrap pins the Drift release version and performs basic payload sanity checks (including a WebAssembly header check) but does not claim cryptographic provenance beyond the configured HTTPS GitHub release source.

If stronger supply-chain pinning is introduced later, add reviewed cryptographic digests or another maintained verification mechanism rather than inventing undocumented hashes.

The generated Web bundle must retain `sqlite3.wasm` and `drift_worker.js` at the paths expected by `AppDatabase`.

## When to reconsider

Consider committing full/selected platform trees if:

- substantial platform-native code accumulates;
- store metadata/entitlements require many persistent generated-file edits;
- Web hosting/runtime assets need audited immutable vendoring rather than bootstrap retrieval;
- scripted patching becomes more fragile than reviewing committed platform files;
- Flutter changes its platform generation model significantly.

Any policy change should supersede/update this ADR explicitly.

## Verification

A platform-generation change should be checked from a clean checkout:

```bash
python tool/check_version_sync.py
python tool/bootstrap_platforms.py
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test --platform chrome test/web/web_platform_smoke_test.dart
flutter build web --release
```

Then compile Android/Linux/Windows/macOS/iOS on supported hosts through the platform matrix and perform representative runtime/plugin/browser checks.

For Web deployment additionally verify worker/WASM reachability, `application/wasm` MIME, local persistence, import/export, and actual browser storage behavior on the intended origin.

## Alternatives considered

### Commit manually reconstructed runner files

Rejected because manually approximating framework templates without the pinned toolchain creates subtle compile/plugin registration risk.

### Commit runner projects from an arbitrary older SDK

Rejected because the declared current toolchain should not silently depend on stale templates.

### Track generated Web WASM/worker binaries directly

Not selected for the current baseline because the assets are reproducibly tied to the direct Drift release and would add binary churn. This can be reconsidered if offline build/reproducibility requirements justify vendoring plus checksum maintenance.

### Support only native targets

Rejected because Flutter Web is part of the required cross-platform scope and can be supported with explicit browser storage/file/authentication boundaries rather than pretending the browser behaves like a native filesystem platform.
