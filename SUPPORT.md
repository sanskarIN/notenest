# NoteNest Support

This document explains where to ask for help and what information makes a support request useful without exposing private notes or credentials.

## Support contacts

- Support: `supportramsandesh@gmail.com`
- Business: `sanskarin@outlook.in`
- Business: `sanskarin.business@gmail.com`
- GitHub: <https://github.com/sanskarIN>
- Repository: <https://github.com/sanskarIN/notenest>
- Buy Me a Coffee: <https://buymeacoffee.com/sanskarIN>

Donations are optional and do not change access to app features or determine whether a valid bug report is accepted.

## Before asking for help

1. Read the [README](README.md).
2. Follow [docs/setup.md](docs/setup.md) for installation/setup issues.
3. Check [docs/troubleshooting.md](docs/troubleshooting.md).
4. Search existing GitHub issues for the same error.
5. Re-run the failing command and capture only the relevant error text.

## What to include

For build/development problems, provide:

- Operating system and version.
- Flutter version from `flutter --version`.
- Output of `flutter doctor -v` with personally identifying paths redacted if desired.
- NoteNest version or commit SHA.
- Exact command that failed.
- The smallest relevant error section.
- Whether `python tool/bootstrap_platforms.py`, `flutter pub get`, and Drift code generation completed.

For app behavior problems, provide:

- Platform/device type.
- NoteNest version.
- Short reproduction steps.
- Expected behavior.
- Actual behavior.
- Whether the issue is reproducible with a newly created fictional note.

## Protect your private data

Do **not** publish:

- Real note databases.
- Real backup JSON files containing personal notes.
- Screenshots containing private information unless you intentionally redact them.
- API tokens, passwords, signing credentials, keystores, certificates, recovery codes, or private keys.
- Authentication logs containing sensitive platform/account information.

When a data file is needed to reproduce an import/restore bug, create the smallest fictional sample that demonstrates the problem.

## Bugs vs support questions

Use a GitHub bug report for reproducible defects in NoteNest. Use support email for setup assistance that depends on private context or information you do not want in a public issue.

Feature ideas should use the feature-request template so scope, privacy impact, and accessibility impact can be reviewed clearly.

## Security issues

Do not report an unpatched security vulnerability in a public issue. Follow [SECURITY.md](SECURITY.md).

## Platform build support

Flutter targets have host-specific requirements:

- Android builds can be produced on supported Flutter development hosts with Android tooling installed.
- Windows desktop builds require Windows.
- Linux desktop builds require Linux and native desktop development libraries.
- macOS and iOS builds require macOS/Xcode; distributable Apple builds require signing credentials.

The project cannot bypass operating-system vendor requirements.

## No guaranteed SLA

NoteNest is an open-source project. Support is best effort; no fixed response or resolution time is promised. Clear reproduction steps and small test cases make assistance much easier.

---

**Made by the Sanskar**
