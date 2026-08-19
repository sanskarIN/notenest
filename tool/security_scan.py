#!/usr/bin/env python3
"""Fail CI when common credential material appears in tracked source-like files.

This is deliberately small and transparent. It complements GitHub's repository
security features; it is not a replacement for provider-side secret revocation.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

RULES: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("private-key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----")),
    ("github-token", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}\b")),
    ("github-fine-grained-token", re.compile(r"\bgithub_pat_[A-Za-z0-9_]{40,}\b")),
    ("aws-access-key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("google-api-key", re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b")),
    ("slack-token", re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{20,}\b")),
)

TEXT_SUFFIXES = {
    ".dart",
    ".yaml",
    ".yml",
    ".json",
    ".md",
    ".txt",
    ".py",
    ".xml",
    ".gradle",
    ".kts",
    ".properties",
    ".plist",
    ".sh",
    ".ps1",
}

SKIP_PATHS = {"pubspec.lock"}


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    paths: list[Path] = []
    for raw in result.stdout.split(b"\0"):
        if not raw:
            continue
        relative = raw.decode("utf-8", errors="strict")
        path = ROOT / relative
        if relative in SKIP_PATHS:
            continue
        if path.suffix.lower() in TEXT_SUFFIXES or path.name in {
            ".env.example",
            ".gitignore",
            ".gitattributes",
            ".editorconfig",
        }:
            paths.append(path)
    return paths


def main() -> int:
    findings: list[tuple[str, int, str]] = []
    for path in tracked_files():
        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for line_number, line in enumerate(content.splitlines(), start=1):
            for rule_name, pattern in RULES:
                if pattern.search(line):
                    findings.append(
                        (str(path.relative_to(ROOT)), line_number, rule_name),
                    )

    if findings:
        print("Potential credential material found:", file=sys.stderr)
        for relative, line_number, rule in findings:
            print(f"- {relative}:{line_number} ({rule})", file=sys.stderr)
        print(
            "Remove/revoke real credentials before committing. Scanner values are intentionally not echoed.",
            file=sys.stderr,
        )
        return 1

    print(f"Secret scan passed across {len(tracked_files())} tracked text files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
