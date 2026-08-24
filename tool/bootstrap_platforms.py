#!/usr/bin/env python3
"""Generate Flutter platform runners and apply NoteNest platform requirements.

This script is intentionally idempotent so a clean clone can generate runner files
with the locally installed Flutter version instead of committing stale templates.
It also validates required patches and browser database assets so upstream Flutter
or dependency drift fails loudly instead of producing an incomplete target.
"""

from __future__ import annotations

import os
import plistlib
import re
import shutil
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DRIFT_WEB_VERSION = "2.34.3"
IOS_MIN_VERSION = "14.0"
WINDOWS_COROUTINE_COMPAT_DEFINE = (
    "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"
)
DRIFT_RELEASE_BASE = (
    "https://github.com/simolus3/drift/releases/download/"
    f"drift-{DRIFT_WEB_VERSION}"
)


def run(*args: str) -> None:
    if not args:
        raise ValueError("run() requires at least one command argument")

    executable = shutil.which(args[0]) or args[0]
    command = (executable, *args[1:])
    if Path(executable).suffix.lower() in {".bat", ".cmd"}:
        comspec = os.environ.get("COMSPEC", "cmd.exe")
        subprocess.run(
            [comspec, "/d", "/s", "/c", subprocess.list2cmdline(command)],
            cwd=ROOT,
            check=True,
        )
        return

    subprocess.run(command, cwd=ROOT, check=True)


def generate_platform_runners() -> None:
    manifest_paths = (ROOT / "pubspec.yaml", ROOT / "pubspec.lock")
    snapshots = {
        path: path.read_bytes() if path.exists() else None for path in manifest_paths
    }
    try:
        run(
            "flutter",
            "create",
            "--no-pub",
            "--platforms=android,ios,linux,macos,windows,web",
            "--org=com.sanskarin",
            "--project-name=notenest",
            ".",
        )
    finally:
        for path, data in snapshots.items():
            if data is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(data)


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
    required_import = "import io.flutter.embedding.android.FlutterFragmentActivity"
    required_class = "class MainActivity : FlutterFragmentActivity()"
    if required_import not in text or required_class not in text:
        raise RuntimeError(
            "Android MainActivity template changed; could not enforce "
            "FlutterFragmentActivity for local_auth.",
        )
    activity.write_text(text, encoding="utf-8")

    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not manifest.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {manifest}")
    manifest_text = manifest.read_text(encoding="utf-8")
    permission = (
        '<uses-permission android:name="android.permission.USE_BIOMETRIC" />'
    )
    if permission not in manifest_text:
        manifest_text = manifest_text.replace(
            ">",
            f">\n    {permission}",
            1,
        )
    if permission not in manifest_text:
        raise RuntimeError("Could not add Android USE_BIOMETRIC permission.")
    manifest.write_text(manifest_text, encoding="utf-8")

    gradle = ROOT / "android/app/build.gradle.kts"
    if not gradle.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {gradle}")
    gradle_text = gradle.read_text(encoding="utf-8")
    gradle_text = gradle_text.replace(
        "minSdk = flutter.minSdkVersion",
        "minSdk = 24",
    )
    if "minSdk = 24" not in gradle_text:
        raise RuntimeError(
            "Android Gradle template changed; could not enforce minSdk = 24.",
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
    if appcompat not in gradle_text:
        raise RuntimeError("Could not add Android AppCompat dependency.")
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
        style_text, replacements = pattern.subn(
            lambda match: f"{match.group(1)}{appcompat_theme}{match.group(3)}",
            style_text,
        )
        if replacements == 0 or appcompat_theme not in style_text:
            raise RuntimeError(
                f"Android style template changed; could not patch {style_path}.",
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
    if not data.get("NSFaceIDUsageDescription"):
        raise RuntimeError("Could not configure the iOS Face ID usage description.")
    with plist_path.open("wb") as target:
        plistlib.dump(data, target, sort_keys=False)

    framework_plist = ROOT / "ios/Flutter/AppFrameworkInfo.plist"
    if not framework_plist.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {framework_plist}")
    with framework_plist.open("rb") as source:
        framework_data = plistlib.load(source)
    framework_data["MinimumOSVersion"] = IOS_MIN_VERSION
    with framework_plist.open("wb") as target:
        plistlib.dump(framework_data, target, sort_keys=False)

    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if not project.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {project}")
    project_text = project.read_text(encoding="utf-8")
    project_text, replacements = re.subn(
        r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;",
        f"IPHONEOS_DEPLOYMENT_TARGET = {IOS_MIN_VERSION};",
        project_text,
    )
    if replacements == 0 or f"IPHONEOS_DEPLOYMENT_TARGET = {IOS_MIN_VERSION};" not in project_text:
        raise RuntimeError(
            "iOS project template changed; could not enforce the iOS 14 deployment target.",
        )
    project.write_text(project_text, encoding="utf-8")

    podfile = ROOT / "ios/Podfile"
    if podfile.exists():
        pod_text = podfile.read_text(encoding="utf-8")
        platform_line = f"platform :ios, '{IOS_MIN_VERSION}'"
        if re.search(r"(?m)^\s*#?\s*platform :ios, '[0-9.]+'\s*$", pod_text):
            pod_text = re.sub(
                r"(?m)^\s*#?\s*platform :ios, '[0-9.]+'\s*$",
                platform_line,
                pod_text,
                count=1,
            )
        else:
            pod_text = f"{platform_line}\n\n{pod_text}"
        podfile.write_text(pod_text, encoding="utf-8")


def patch_windows() -> None:
    cmake = ROOT / "windows/CMakeLists.txt"
    if not cmake.exists():
        raise RuntimeError(f"Flutter did not generate expected file: {cmake}")
    cmake_text = cmake.read_text(encoding="utf-8")
    compatibility_block = (
        "if(MSVC)\n"
        f"  add_compile_definitions({WINDOWS_COROUTINE_COMPAT_DEFINE})\n"
        "endif()\n"
    )
    if WINDOWS_COROUTINE_COMPAT_DEFINE not in cmake_text:
        project_match = re.search(r"(?m)^project\([^\n]+\)\s*$", cmake_text)
        if project_match is None:
            raise RuntimeError(
                "Windows CMake template changed; could not locate the project declaration.",
            )
        insert_at = project_match.end()
        cmake_text = (
            f"{cmake_text[:insert_at]}\n\n{compatibility_block}"
            f"{cmake_text[insert_at:].lstrip(chr(10))}"
        )
    if WINDOWS_COROUTINE_COMPAT_DEFINE not in cmake_text:
        raise RuntimeError(
            "Could not configure the Visual Studio coroutine compatibility definition.",
        )
    cmake.write_text(cmake_text, encoding="utf-8")


def _pinned_drift_version() -> str:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"(?m)^\s{2}drift:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$", pubspec)
    if match is None:
        raise RuntimeError("Could not determine the pinned drift version from pubspec.yaml.")
    return match.group(1)


def _download_web_asset(name: str) -> bytes:
    url = f"{DRIFT_RELEASE_BASE}/{name}"
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "NoteNest-platform-bootstrap/2.0.12"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()
    except (urllib.error.URLError, TimeoutError) as error:
        raise RuntimeError(f"Could not download required web asset: {name}") from error


def _write_verified_web_asset(name: str, data: bytes) -> None:
    if len(data) < 1024:
        raise RuntimeError(f"Downloaded web asset is unexpectedly small: {name}")
    if name == "sqlite3.wasm" and not data.startswith(b"\x00asm"):
        raise RuntimeError("Downloaded sqlite3.wasm does not have a WebAssembly header.")
    if name == "drift_worker.js" and data.lstrip().startswith(b"<"):
        raise RuntimeError("Downloaded drift_worker.js looks like an HTML error page.")

    target = ROOT / "web" / name
    temporary = target.with_suffix(f"{target.suffix}.tmp")
    temporary.write_bytes(data)
    temporary.replace(target)


def prepare_web() -> None:
    web = ROOT / "web"
    if not (web / "index.html").exists() or not (web / "manifest.json").exists():
        raise RuntimeError("Flutter did not generate the expected web runner files.")

    pinned = _pinned_drift_version()
    if pinned != DRIFT_WEB_VERSION:
        raise RuntimeError(
            "Pinned drift version changed. Update DRIFT_WEB_VERSION and review the "
            "matching drift_worker.js/sqlite3.wasm assets before building web."
        )

    for name in ("sqlite3.wasm", "drift_worker.js"):
        _write_verified_web_asset(name, _download_web_asset(name))


def main() -> None:
    if shutil.which("flutter") is None:
        raise SystemExit("Flutter is required but was not found on PATH.")
    generate_platform_runners()
    patch_android()
    patch_ios()
    patch_windows()
    prepare_web()
    print(
        "NoteNest Android, iOS, Linux, macOS, Windows, and Web runners are ready "
        "and platform requirements were verified."
    )


if __name__ == "__main__":
    main()
