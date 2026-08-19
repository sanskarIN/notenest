#!/usr/bin/env python3
"""Validate local Markdown links without making network requests.

The release prompt requires documentation-link checks. This script verifies that
relative links in tracked Markdown files resolve to files/directories inside the
repository. External URLs, mail links, and fragment-only links are intentionally
left to maintainers/browser tooling because CI should not depend on network
availability or third-party uptime.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]

INLINE_LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
REFERENCE_LINK_RE = re.compile(r"^\s*\[[^\]]+\]:\s*(\S+)", re.MULTILINE)
IGNORED_SCHEMES = {"http", "https", "mailto", "tel", "sms", "data"}


def tracked_markdown_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "*.md"],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [ROOT / line for line in result.stdout.splitlines() if line.strip()]


def _strip_optional_title(raw_target: str) -> str:
    target = raw_target.strip()
    if target.startswith("<") and ">" in target:
        return target[1 : target.index(">")]
    # Markdown destinations may be followed by an optional quoted title.
    # Repository-local paths in this project do not intentionally contain spaces.
    return target.split(maxsplit=1)[0] if target else ""


def _is_external_or_fragment(target: str) -> bool:
    if not target or target.startswith("#"):
        return True
    parsed = urlsplit(target)
    if parsed.scheme.lower() in IGNORED_SCHEMES:
        return True
    return target.startswith("//")


def _resolve_local_target(source: Path, target: str) -> Path | None:
    cleaned = _strip_optional_title(target)
    if _is_external_or_fragment(cleaned):
        return None

    parsed = urlsplit(cleaned)
    path_part = unquote(parsed.path)
    if not path_part:
        return None

    if path_part.startswith("/"):
        candidate = ROOT / path_part.lstrip("/")
    else:
        candidate = source.parent / path_part

    try:
        resolved = candidate.resolve(strict=False)
        resolved.relative_to(ROOT.resolve())
    except ValueError:
        raise ValueError("link escapes repository root") from None
    return resolved


def links_in(text: str) -> list[str]:
    links = [match.group(1) for match in INLINE_LINK_RE.finditer(text)]
    links.extend(match.group(1) for match in REFERENCE_LINK_RE.finditer(text))
    return links


def main() -> int:
    errors: list[str] = []
    checked = 0

    for source in tracked_markdown_files():
        text = source.read_text(encoding="utf-8")
        for raw_target in links_in(text):
            try:
                target = _resolve_local_target(source, raw_target)
            except ValueError as error:
                errors.append(f"{source.relative_to(ROOT)}: {raw_target!r}: {error}")
                continue
            if target is None:
                continue
            checked += 1
            if not target.exists():
                errors.append(
                    f"{source.relative_to(ROOT)}: broken local link {raw_target!r}",
                )

    if errors:
        print("Documentation link checks failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Documentation local-link checks passed ({checked} links checked).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
