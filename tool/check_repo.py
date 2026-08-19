#!/usr/bin/env python3
"""Fast repository-level policy checks used by CI.

These checks catch missing handoff/documentation/automation files, unfinished
source markers, generated files accidentally committed, dependency-lock drift,
and Flutter toolchain drift. Flutter/Dart correctness is checked separately.
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
    "pubspec.lock",
    "analysis_options.yaml",
    "build.yaml",
    "lib/core/logging/app_logger.dart",
    "lib/core/theme/app_tokens.dart",
    "lib/core/utils/async_serial_queue.dart",
    "lib/core/utils/bounded_file_reader.dart",
    "lib/core/utils/import_limits.dart",
    "lib/core/utils/markdown_document_codec.dart",
    "lib/core/utils/safe_file_name.dart",
    "lib/widgets/note_color_swatch.dart",
    "test/core/app_logger_test.dart",
    "test/core/async_serial_queue_test.dart",
    "test/core/bounded_file_reader_test.dart",
    "test/core/import_limits_test.dart",
    "test/core/markdown_document_codec_test.dart",
    "test/core/safe_file_name_test.dart",
    "test/data/note_repository_test.dart",
    "test/data/backup_repository_test.dart",
    "test/data/settings_repository_test.dart",
    "test/widgets/note_editor_accessibility_test.dart",
    "test/widgets/notes_page_empty_state_test.dart",
    "test/widgets/note_color_swatch_test.dart",
    "test/widgets/onboarding_page_test.dart",
    "test/widgets/note_editor_page_test.dart",
    "test/integration/note_lifecycle_integration_test.dart",
    "tool/bootstrap_platforms.py",
    "tool/test_bootstrap_platforms.py",
    "tool/check_markdown_links.py",
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

REQUIRED_TRACKED_FILES = (
    "pubspec.lock",
    ".flutter-version",
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


def _workflow_has_flutter_pin(text: str, version: str) -> bool:
    accepted = (
        f"flutter-version: {version}",
        f'flutter-version: "{version}"',
        f"flutter-version: '{version}'",
    )
    return any(value in text for value in accepted)


def main() -> int:
    errors: list[str] = []
    tracked = set(tracked_files())

    for relative in REQUIRED_FILES:
        if not (ROOT / relative).is_file():
            errors.append(f"missing required file: {relative}")

    for relative in REQUIRED_TRACKED_FILES:
        if relative not in tracked:
            errors.append(f"required reproducibility file is not tracked: {relative}")

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
        for relative in PINNED_FLUTTER_WORKFLOWS:
            path = ROOT / relative
            if path.is_file():
                workflow = path.read_text(encoding="utf-8")
                if not _workflow_has_flutter_pin(workflow, flutter_version):
                    errors.append(
                        f"{relative} does not pin Flutter {flutter_version} from .flutter-version",
                    )

    pubspec_path = ROOT / "pubspec.yaml"
    if pubspec_path.is_file():
        pubspec = pubspec_path.read_text(encoding="utf-8")
        if ": any" in pubspec or ": 'any'" in pubspec or ': "any"' in pubspec:
            errors.append("pubspec.yaml contains an unpinned 'any' dependency")

    for relative in tracked:
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
