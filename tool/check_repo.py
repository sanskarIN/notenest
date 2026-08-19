#!/usr/bin/env python3
"""Fast repository-level policy checks used by CI.

These checks catch missing handoff/documentation/automation files, unfinished
source markers, generated files accidentally committed, and toolchain drift.
Flutter/Dart correctness is checked separately by the normal quality gate.
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
    "lib/core/logging/app_logger.dart",
    "lib/core/theme/app_tokens.dart",
    "lib/core/utils/markdown_document_codec.dart",
    "test/core/app_logger_test.dart",
    "test/core/markdown_document_codec_test.dart",
    "test/data/note_repository_test.dart",
    "test/data/backup_repository_test.dart",
    "test/widgets/onboarding_page_test.dart",
    "test/integration/note_lifecycle_integration_test.dart",
    "tool/bootstrap_platforms.py",
    "tool/check_docs_links.py",
    "tool/security_scan.py",
    "docs/architecture.md",
    "docs/setup.md",
    "docs/development.md",
    "docs/testing.md",
    "docs/release.md",
    "docs/troubleshooting.md",
    "docs/accessibility.md",
    "docs/performance.md",
    "docs/github.md",
    "docs/adr/0001-flutter-drift-modular-monolith.md",
    "docs/adr/0002-offline-first-data.md",
    "docs/adr/0003-generated-platform-runners.md",
    ".github/workflows/ci.yml",
    ".github/workflows/platform-builds.yml",
    ".github/workflows/security.yml",
    ".github/workflows/release.yml",
    ".github/dependabot.yml",
    ".github/pull_request_template.md",
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/FUNDING.yml",
)

REQUIRED_README_TEXT = (
    "Made by the Sanskar",
    "https://buymeacoffee.com/sanskarIN",
    "sanskarin@outlook.in",
    "sanskarin.business@gmail.com",
    "supportramsandesh@gmail.com",
    "MIT License",
)

FORBIDDEN_SOURCE_MARKERS = (
    "TODO:",
    "FIXME:",
    "HACK:",
)

PINNED_FLUTTER_WORKFLOWS = (
    ".github/workflows/ci.yml",
    ".github/workflows/platform-builds.yml",
    ".github/workflows/release.yml",
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

    flutter_version_path = ROOT / ".flutter-version"
    flutter_version = ""
    if flutter_version_path.is_file():
        flutter_version = flutter_version_path.read_text(encoding="utf-8").strip()
        if not flutter_version:
            errors.append(".flutter-version must contain a pinned Flutter version")

    if flutter_version:
        required_pin = f'flutter-version: "{flutter_version}"'
        for relative in PINNED_FLUTTER_WORKFLOWS:
            path = ROOT / relative
            if path.is_file() and required_pin not in path.read_text(encoding="utf-8"):
                errors.append(
                    f"{relative} does not pin Flutter {flutter_version} from .flutter-version",
                )

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
