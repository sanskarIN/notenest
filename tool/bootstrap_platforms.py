#!/usr/bin/env python3
"""Generate Flutter platform runners and apply NoteNest native requirements.

This script is intentionally idempotent so a clean clone can generate runner files
with the locally installed Flutter version instead of committing stale templates.
"""

from __future__ import annotations

import plistlib
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def patch_android() -> None:
    activity = ROOT / "android/app/src/main/kotlin/com/sanskarin/notenest/MainActivity.kt"
    if not activity.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {activity}")
    text = activity.read_text(encoding="utf-8")
    text = text.replace(
        "import io.flutter.embedding.android.FlutterActivity",
        "import io.flutter.embedding.android.FlutterFragmentActivity",
    ).replace(
        "class MainActivity : FlutterActivity()",
        "class MainActivity : FlutterFragmentActivity()",
    )
    activity.write_text(text, encoding="utf-8")

    gradle = ROOT / "android/app/build.gradle.kts"
    if gradle.exists():
        gradle_text = gradle.read_text(encoding="utf-8")
        gradle_text = gradle_text.replace(
            "minSdk = flutter.minSdkVersion",
            "minSdk = 24",
        )
        gradle.write_text(gradle_text, encoding="utf-8")


def patch_ios() -> None:
    plist_path = ROOT / "ios/Runner/Info.plist"
    if not plist_path.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {plist_path}")
    with plist_path.open("rb") as source:
        data = plistlib.load(source)
    data.setdefault(
        "NSFaceIDUsageDescription",
        "Use Face ID to unlock your private NoteNest notes when app lock is enabled.",
    )
    with plist_path.open("wb") as target:
        plistlib.dump(data, target, sort_keys=False)


def main() -> None:
    if shutil.which("flutter") is None:
        raise SystemExit("Flutter is required but was not found on PATH.")
    run(
        "flutter",
        "create",
        "--platforms=android,ios,linux,macos,windows",
        "--org=com.sanskarin",
        "--project-name=notenest",
        ".",
    )
    patch_android()
    patch_ios()
    print("NoteNest platform runners are ready.")


if __name__ == "__main__":
    main()
