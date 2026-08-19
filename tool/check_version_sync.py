#!/usr/bin/env python3
"""Verify NoteNest's package and visible application versions stay in sync."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = ROOT / "pubspec.yaml"
APP_STRINGS = ROOT / "lib/core/constants/app_strings.dart"

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
