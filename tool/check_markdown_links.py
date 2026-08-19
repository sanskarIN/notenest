#!/usr/bin/env python3
"""Validate local links in tracked Markdown documentation."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]

INLINE_LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
REFERENCE_LINK_RE = re.compile(r"^\s*\[[^\]]+\]:\s*(\S+)")
HTML_LINK_RE = re.compile(r"""\b(?:href|src)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
FENCE_RE = re.compile(r"^\s*(```|~~~)")


def tracked_markdown_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "*.md"],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [ROOT / line for line in result.stdout.splitlines() if line.strip()]


def destination(raw: str) -> str:
    value = raw.strip()
    if value.startswith("<") and ">" in value:
        return value[1 : value.index(">")].strip()
    return value.split(maxsplit=1)[0] if value else ""


def is_external(value: str) -> bool:
    lowered = value.lower()
    if lowered.startswith(("#", "mailto:", "tel:", "data:")):
        return True
    parsed = urlsplit(value)
    return parsed.scheme in {"http", "https"} or bool(parsed.netloc)


def local_target(source: Path, value: str) -> Path | None:
    if not value or is_external(value):
        return None

    parsed = urlsplit(value)
    path_text = unquote(parsed.path)
    if not path_text:
        return None

    candidate = (
        ROOT / path_text.lstrip("/")
        if path_text.startswith("/")
        else source.parent / path_text
    )
    return candidate.resolve(strict=False)


def destinations(text: str) -> list[str]:
    found: list[str] = []
    in_fence = False

    for line in text.splitlines():
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue

        found.extend(match.group(1) for match in INLINE_LINK_RE.finditer(line))
        reference = REFERENCE_LINK_RE.match(line)
        if reference:
            found.append(reference.group(1))
        found.extend(match.group(1) for match in HTML_LINK_RE.finditer(line))

    return found


def main() -> int:
    errors: list[str] = []

    for source in tracked_markdown_files():
        text = source.read_text(encoding="utf-8")
        for raw in destinations(text):
            value = destination(raw)
            target = local_target(source, value)
            if target is None:
                continue

            try:
                target.relative_to(ROOT.resolve())
            except ValueError:
                errors.append(
                    f"{source.relative_to(ROOT)}: local link leaves repository: {value}"
                )
                continue

            if not target.exists():
                errors.append(
                    f"{source.relative_to(ROOT)}: missing local link target: {value}"
                )

    if errors:
        print("Markdown link checks failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Markdown local-link checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
