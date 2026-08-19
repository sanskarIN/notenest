#!/usr/bin/env python3
"""Generate Flutter platform runners and apply NoteNest native requirements.

This script is intentionally idempotent so a clean clone can generate runner files
with the locally installed Flutter version instead of committing stale templates.
"""

from __future__ import annotations

import plistlib
import re
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

    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not manifest.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {manifest}")
    manifest_text = manifest.read_text(encoding="utf-8")
    permission = '<uses-permission android:name="android.permission.USE_BIOMETRIC" />'
    if permission not in manifest_text:
        manifest_start = manifest_text.find("<manifest")
        if manifest_start == -1:
            raise RuntimeError("AndroidManifest.xml does not contain a manifest root")
        manifest_open_end = manifest_text.find(">", manifest_start)
        if manifest_open_end == -1:
            raise RuntimeError("AndroidManifest.xml manifest root is malformed")
        manifest_text = (
            manifest_text[: manifest_open_end + 1]
            + f"\n    {permission}"
            + manifest_text[manifest_open_end + 1 :]
        )
    manifest.write_text(manifest_text, encoding="utf-8")

    gradle = ROOT / "android/app/build.gradle.kts"
    if not gradle.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {gradle}")
    gradle_text = gradle.read_text(encoding="utf-8")
    gradle_text = gradle_text.replace(
        "minSdk = flutter.minSdkVersion",
        "minSdk = 24",
    )
    appcompat = 'implementation("androidx.appcompat:appcompat:1.7.1")'
    if appcompat not in gradle_text:
        if "dependencies {" in gradle_text:
            gradle_text = gradle_text.replace(
                "dependencies {",
                f"dependencies {{\n    {appcompat}",
                1,
            )
        else:
            gradle_text = f"{gradle_text.rstrip()}\n\ndependencies {{\n    {appcompat}\n}}\n"
    gradle.write_text(gradle_text, encoding="utf-8")

    style_paths = sorted(
        (ROOT / "android/app/src/main/res").glob("values*/styles.xml"),
    )
    if not style_paths:
        raise RuntimeError("Flutter did not generate Android styles.xml files")
    pattern = re.compile(
        r'(<style\s+name="(?:LaunchTheme|NormalTheme)"\s+parent=")([^"]+)(")',
    )
    for style_path in style_paths:
        style_text = style_path.read_text(encoding="utf-8")
        appcompat_theme = (
            "Theme.AppCompat.DayNight.NoActionBar"
            if "values-night" in style_path.parent.name
            else "Theme.AppCompat.Light.NoActionBar"
        )
        style_text = pattern.sub(
            lambda match: f"{match.group(1)}{appcompat_theme}{match.group(3)}",
            style_text,
        )
        style_path.write_text(style_text, encoding="utf-8")


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
