#!/usr/bin/env python3
"""Fast repository-level policy checks used by CI.

These checks catch missing handoff/documentation/platform-baseline files and
accidental placeholder markers before a release. Flutter/Dart correctness is
checked separately.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "README.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "SECURITY.md",
    "SUPPORT.md",
    "PRIVACY.md",
    "CHANGELOG.md",
    "ROADMAP.md",
    "what_changed.md",
    ".gitignore",
    ".editorconfig",
    ".gitattributes",
    ".env.example",
    ".flutter-version",
    "pubspec.yaml",
    "analysis_options.yaml",
    "build.yaml",
    "assets/branding/notenest_logo.svg",
    "docs/assets/screenshots/layout-reference.svg",
    "docs/architecture.md",
    "docs/setup.md",
    "docs/development.md",
    "docs/testing.md",
    "docs/release.md",
    "docs/github.md",
    "docs/troubleshooting.md",
    "docs/accessibility.md",
    "docs/performance.md",
    "docs/repository-reference.md",
    "docs/adr/0001-flutter-drift-modular-monolith.md",
    "docs/adr/0002-offline-first-data.md",
    "docs/adr/0003-generated-platform-runners.md",
    ".github/workflows/ci.yml",
    ".github/workflows/platform-builds.yml",
    ".github/workflows/release.yml",
    ".github/workflows/security.yml",
    ".github/dependabot.yml",
    ".github/pull_request_template.md",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml",
    ".github/FUNDING.yml",
    "lib/core/utils/bounded_file_reader.dart",
    "lib/core/utils/bounded_file_reader_io.dart",
    "lib/core/utils/bounded_file_reader_stub.dart",
    "lib/services/app_lock_service.dart",
    "lib/services/app_lock_service_io.dart",
    "lib/services/app_lock_service_stub.dart",
    "test/web/web_platform_smoke_test.dart",
    "tool/bootstrap_platforms.py",
    "tool/check_markdown_links.py",
    "tool/check_repo.py",
    "tool/check_repository_reference.py",
    "tool/check_version_sync.py",
    "tool/security_scan.py",
)

REQUIRED_README_TEXT = (
    "Made by the Sanskar",
    "https://buymeacoffee.com/sanskarIN",
    "sanskarin@outlook.in",
    "supportramsandesh@gmail.com",
    "MIT License",
    "Android, iOS, Windows, macOS, Linux, and Web",
)

FORBIDDEN_SOURCE_MARKERS = (
    "TODO:",
    "FIXME:",
    "HACK:",
)


def tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> int:
    errors: list[str] = []

    for relative in REQUIRED_FILES:
        if not (ROOT / relative).is_file():
            errors.append(f"missing required file: {relative}")

    readme_path = ROOT / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for value in REQUIRED_README_TEXT:
            if value not in readme:
                errors.append(f"README is missing required text: {value}")

    for relative in tracked_files():
        path = ROOT / relative
        if relative.startswith("lib/") and path.suffix == ".dart":
            text = path.read_text(encoding="utf-8")
            for marker in FORBIDDEN_SOURCE_MARKERS:
                if marker in text:
                    errors.append(f"unfinished marker {marker!r} in {relative}")

        if relative.endswith(".g.dart"):
            errors.append(
                f"generated Drift/build_runner file should not be tracked: {relative}",
            )

    gitignore_path = ROOT / ".gitignore"
    if gitignore_path.is_file():
        gitignore = gitignore_path.read_text(encoding="utf-8")
        for required_rule in (".env", "*.jks", "*.keystore", "lib/**/*.g.dart"):
            if required_rule not in gitignore:
                errors.append(f".gitignore missing rule: {required_rule}")

    if errors:
        print("Repository policy checks failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Repository completeness and policy checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
