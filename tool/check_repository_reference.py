#!/usr/bin/env python3
"""Verify that the exhaustive repository reference covers every tracked file.

The reference is intentionally strict: every path returned by ``git ls-files`` must
have exactly one catalog entry in ``docs/repository-reference.md`` and the catalog
must not retain entries for files that no longer exist in version control.
"""

from __future__ import annotations

import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "docs/repository-reference.md"
ENTRY_RE = re.compile(r"^\s*-\s+`([^`]+)`\s+—\s+", re.MULTILINE)


def tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return sorted(line.strip() for line in result.stdout.splitlines() if line.strip())


def documented_files() -> list[str]:
    if not REFERENCE.is_file():
        return []
    return ENTRY_RE.findall(REFERENCE.read_text(encoding="utf-8"))


def main() -> int:
    if not REFERENCE.is_file():
        print(
            "Repository reference check failed:\n"
            "- missing docs/repository-reference.md",
            file=sys.stderr,
        )
        return 1

    tracked = tracked_files()
    documented = documented_files()
    documented_counts = Counter(documented)

    tracked_set = set(tracked)
    documented_set = set(documented)

    errors: list[str] = []

    for path in sorted(tracked_set - documented_set):
        errors.append(f"tracked file is undocumented: {path}")

    for path in sorted(documented_set - tracked_set):
        errors.append(f"reference contains stale/untracked path: {path}")

    for path, count in sorted(documented_counts.items()):
        if count != 1:
            errors.append(f"reference path must appear exactly once: {path} ({count})")

    if errors:
        print("Repository reference check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        "Repository reference coverage passed "
        f"({len(tracked)} tracked files documented)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
