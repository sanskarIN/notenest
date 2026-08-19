from __future__ import annotations

import plistlib
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

import bootstrap_platforms


class BootstrapPlatformsTest(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self._temporary.cleanup)
        self.root = Path(self._temporary.name)
        self.previous_root = bootstrap_platforms.ROOT
        bootstrap_platforms.ROOT = self.root
        self.addCleanup(self._restore_root)

    def _restore_root(self) -> None:
        bootstrap_platforms.ROOT = self.previous_root

    def _write_android_fixture(self) -> None:
        activity = (
            self.root
            / "android/app/src/main/kotlin/com/sanskarin/notenest/MainActivity.kt"
        )
        activity.parent.mkdir(parents=True, exist_ok=True)
        activity.write_text(
            "package com.sanskarin.notenest\n\n"
            "import io.flutter.embedding.android.FlutterActivity\n\n"
            "class MainActivity : FlutterActivity()\n",
            encoding="utf-8",
        )

        manifest = self.root / "android/app/src/main/AndroidManifest.xml"
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
            "    <application />\n"
            "</manifest>\n",
            encoding="utf-8",
        )

        gradle = self.root / "android/app/build.gradle.kts"
        gradle.parent.mkdir(parents=True, exist_ok=True)
        gradle.write_text(
            "android {\n    defaultConfig {\n        minSdk = flutter.minSdkVersion\n    }\n}\n",
            encoding="utf-8",
        )

        for values_dir, parent in (
            ("values", "@android:style/Theme.Light.NoTitleBar"),
            ("values-night", "@android:style/Theme.Black.NoTitleBar"),
        ):
            styles = self.root / f"android/app/src/main/res/{values_dir}/styles.xml"
            styles.parent.mkdir(parents=True, exist_ok=True)
            styles.write_text(
                "<resources>\n"
                f'  <style name="LaunchTheme" parent="{parent}" />\n'
                f'  <style name="NormalTheme" parent="{parent}" />\n'
                "</resources>\n",
                encoding="utf-8",
            )

    def test_android_patch_is_valid_and_idempotent(self) -> None:
        self._write_android_fixture()

        bootstrap_platforms.patch_android()
        bootstrap_platforms.patch_android()

        manifest = self.root / "android/app/src/main/AndroidManifest.xml"
        root = ET.parse(manifest).getroot()
        permissions = [
            element.attrib.get("{http://schemas.android.com/apk/res/android}name")
            for element in root.findall("uses-permission")
        ]
        self.assertEqual(permissions, ["android.permission.USE_BIOMETRIC"])

        activity = (
            self.root
            / "android/app/src/main/kotlin/com/sanskarin/notenest/MainActivity.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("FlutterFragmentActivity", activity)
        self.assertNotIn("class MainActivity : FlutterActivity()", activity)

        gradle = (self.root / "android/app/build.gradle.kts").read_text(
            encoding="utf-8"
        )
        self.assertIn("minSdk = 24", gradle)
        self.assertEqual(
            gradle.count('implementation("androidx.appcompat:appcompat:1.7.1")'),
            1,
        )

        light_styles = (
            self.root / "android/app/src/main/res/values/styles.xml"
        ).read_text(encoding="utf-8")
        dark_styles = (
            self.root / "android/app/src/main/res/values-night/styles.xml"
        ).read_text(encoding="utf-8")
        self.assertIn("Theme.AppCompat.Light.NoActionBar", light_styles)
        self.assertIn("Theme.AppCompat.DayNight.NoActionBar", dark_styles)

    def test_ios_patch_adds_face_id_usage_description_idempotently(self) -> None:
        plist_path = self.root / "ios/Runner/Info.plist"
        plist_path.parent.mkdir(parents=True, exist_ok=True)
        with plist_path.open("wb") as target:
            plistlib.dump({"CFBundleName": "NoteNest"}, target)

        bootstrap_platforms.patch_ios()
        bootstrap_platforms.patch_ios()

        with plist_path.open("rb") as source:
            data = plistlib.load(source)
        self.assertEqual(
            data["NSFaceIDUsageDescription"],
            "Use Face ID to unlock your private NoteNest notes when app lock is enabled.",
        )


if __name__ == "__main__":
    unittest.main()
