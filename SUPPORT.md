# NoteNest Support

This document explains where to ask for help and what information makes a support request useful without exposing private notes, browser storage, or credentials.

## Support contacts

- Support: `supportramsandesh@gmail.com`
- Business: `sanskarin@outlook.in`
- Business: `sanskarin.business@gmail.com`
- GitHub: <https://github.com/sanskarIN>
- Repository: <https://github.com/sanskarIN/notenest>
- Buy Me a Coffee: <https://buymeacoffee.com/sanskarIN>

Donations are optional and do not affect feature access or whether a valid bug report is accepted.

## Before asking for help

1. Read the [README](README.md).
2. Follow [docs/setup.md](docs/setup.md).
3. Check [docs/troubleshooting.md](docs/troubleshooting.md).
4. Search existing issues.
5. Re-run the failing command/action and capture only the smallest useful error context.

## Development/build requests

Include:

- NoteNest version/commit.
- Operating system.
- Flutter version from `flutter --version`.
- Relevant `flutter doctor -v` output with personal paths redacted.
- Exact failing command.
- Smallest useful error section.
- Whether platform bootstrap, dependency resolution, and Drift code generation completed.
- Target platform: Android, iOS/iPadOS, Windows, macOS, Linux, or Web.

For Web build problems also include browser used for tests and whether bootstrap could obtain `sqlite3.wasm` / `drift_worker.js`.

## Runtime behavior requests

Include:

- Platform/device or browser/version.
- NoteNest version/commit.
- Short fictional-data reproduction steps.
- Expected vs actual behavior.
- Whether a new fictional note reproduces it.

For Web, add when relevant:

- deployment origin/host type without private credentials;
- whether the issue occurs after page reload/browser restart;
- browser normal vs private/incognito mode;
- any worker/WASM network error status and MIME message;
- browser zoom/assistive technology if accessibility-related.

Do **not** paste raw browser IndexedDB/OPFS/database contents.

## Protect private data

Do not publish:

- real note databases;
- browser storage dumps;
- real backup JSON containing personal notes;
- unredacted private screenshots;
- tokens, passwords, signing keys, keystores, certificates, recovery codes;
- sensitive authentication logs;
- private file paths/origins when unnecessary.

For import/restore defects, build the smallest fictional file that reproduces the behavior.

## Bugs vs support questions

Use GitHub bug reports for reproducible NoteNest defects. Use support email when setup assistance depends on private context you do not want in a public issue.

Feature requests should use the feature form so six-platform, privacy, accessibility, data, and security impact can be reviewed.

## Security issues

Never disclose an unpatched vulnerability in a public issue. Follow [SECURITY.md](SECURITY.md).

## Platform support boundaries

NoteNest targets all six Flutter platforms:

- **Android** — Flutter Android toolchain; supported device authentication where available.
- **iOS/iPadOS** — macOS/Xcode required to build; Apple signing required for distribution.
- **Windows** — Windows + Visual Studio C++ desktop tooling.
- **macOS** — macOS/Xcode; signing/notarization may be required for distribution.
- **Linux** — Linux desktop native prerequisites; current app-lock device authentication is unavailable.
- **Web** — Flutter Web browser target with Drift SQLite WASM/worker and browser file import/export; app-lock device authentication is unavailable.

Platform vendor/toolchain requirements cannot be bypassed by NoteNest source.

## Web-specific support

If the Web app fails to start or persist data, review:

- correct deployment of the generated `build/web` bundle;
- successful `drift_worker.js` and `sqlite3.wasm` requests;
- `application/wasm` MIME type;
- browser/site-data policies;
- same scheme/host/port origin between sessions;
- private/incognito behavior;
- actual browser console errors.

Do not clear browser site data before exporting a backup if valuable data exists.

## App-lock support

`local_auth` is used where the current dependency has an implementation. Web and Linux intentionally report app lock unavailable rather than falling back to a custom NoteNest password system.

If an unsupported platform becomes stuck behind an unlock screen, report it as a bug; the intended behavior is for the rest of NoteNest to remain usable.

## No guaranteed SLA

NoteNest is open source and support is best effort. No fixed response/resolution time is promised. Minimal fictional reproductions and exact environment details make diagnosis substantially easier.

---

**Made by the Sanskar**
