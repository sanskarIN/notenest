#!/usr/bin/env python3
"""Verify NoteNest package, UI, changelog, and release-note versions stay in sync."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = ROOT / "pubspec.yaml"
APP_STRINGS = ROOT / "lib/core/constants/app_strings.dart"
CHANGELOG = ROOT / "CHANGELOG.md"
RELEASES_DIR = ROOT / "docs/releases"

PUBSPEC_VERSION_RE = re.compile(
    r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$",
    re.MULTILINE,
)
APP_VERSION_RE = re.compile(
    r"static const String version\s*=\s*['\"](\d+\.\d+\.\d+)['\"]\s*;",
)


def main() -> int:
    errors: list[str] = []

    pubspec_text = PUBSPEC.read_text(encoding="utf-8")
    app_strings_text = APP_STRINGS.read_text(encoding="utf-8")
    changelog_text = CHANGELOG.read_text(encoding="utf-8")

    pubspec_match = PUBSPEC_VERSION_RE.search(pubspec_text)
    if pubspec_match is None:
        errors.append("pubspec.yaml must declare version as MAJOR.MINOR.PATCH+BUILD")
        package_version = None
        build_number = None
    else:
        package_version = pubspec_match.group(1)
        build_number = int(pubspec_match.group(2))
        if build_number <= 0:
            errors.append("pubspec.yaml build number must be greater than zero")

    app_match = APP_VERSION_RE.search(app_strings_text)
    if app_match is None:
        errors.append("AppStrings.version must declare a MAJOR.MINOR.PATCH value")
        app_version = None
    else:
        app_version = app_match.group(1)

    if package_version is not None and app_version is not None:
        if package_version != app_version:
            errors.append(
                "version mismatch: "
                f"pubspec.yaml={package_version}, AppStrings.version={app_version}"
            )

    if package_version is not None and build_number is not None:
        changelog_heading = f"## [{package_version}]"
        if changelog_heading not in changelog_text:
            errors.append(
                f"CHANGELOG.md must contain a {changelog_heading!r} release section"
            )

        release_notes = RELEASES_DIR / f"{package_version}.md"
        if not release_notes.is_file():
            errors.append(
                f"missing release notes for {package_version}: "
                f"docs/releases/{package_version}.md"
            )
        else:
            release_text = release_notes.read_text(encoding="utf-8")
            expected_package = f"Package version: `{package_version}+{build_number}`"
            expected_visible = f"Visible application version: `{package_version}`"
            if expected_package not in release_text:
                errors.append(
                    f"release notes must contain exact package version {package_version}+{build_number}"
                )
            if expected_visible not in release_text:
                errors.append(
                    f"release notes must contain visible version {package_version}"
                )

    if errors:
        print("Version synchronization checks failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        "Version synchronization checks passed: "
        f"{package_version}+{build_number}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
