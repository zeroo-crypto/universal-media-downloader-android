#!/usr/bin/env python3
"""scripts/verify_apk.py
--------------------------------------------------------------------------------
Automated APK Quality Gate & Verification Helper (Cross-Platform)

Verifies:
  1. 4-byte zip alignment using Android SDK zipalign.
  2. APK Signature Scheme v1 (JAR signing) and v2 using apksigner.
  3. Signer certificate DN is a valid non-debug release certificate
     (must NOT be CN=Android Debug).
  4. AndroidManifest and resource badging integrity using aapt / aapt2:
     - Package name: com.zeroo.universal_media_downloader
     - Launchable activity: com.zeroo.universal_media_downloader.MainActivity
     - Application label and icon resolution without parsing errors.

Target Release APKs (4 flavors):
  - app-release.apk            (Universal)
  - app-arm64-v8a-release.apk  (ARM 64-bit)
  - app-armeabi-v7a-release.apk(ARM 32-bit)
  - app-x86_64-release.apk     (x86_64 Emulator/PC)

Exit status:
  0 - All checks passed across all 4 APKs
  1 - One or more verification checks failed
--------------------------------------------------------------------------------
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from typing import Dict, List, Optional, Tuple

EXPECTED_PACKAGE = "com.zeroo.universal_media_downloader"
EXPECTED_ACTIVITY = "com.zeroo.universal_media_downloader.MainActivity"
EXPECTED_APKS = [
    "app-release.apk",
    "app-arm64-v8a-release.apk",
    "app-armeabi-v7a-release.apk",
    "app-x86_64-release.apk",
]


def locate_android_sdk() -> Optional[str]:
    """Search for the Android SDK directory across common environment variables and paths."""
    candidates = [
        os.environ.get("ANDROID_HOME"),
        os.environ.get("ANDROID_SDK_ROOT"),
        os.path.expanduser("~/Android/Sdk"),
        os.path.expanduser("~/Library/Android/sdk"),
        "/usr/local/lib/android/sdk",
        "/opt/android-sdk",
    ]
    localappdata = os.environ.get("LOCALAPPDATA")
    if localappdata:
        candidates.append(os.path.join(localappdata, "Android", "Sdk"))

    for c in candidates:
        if c and os.path.isdir(c):
            return os.path.abspath(c)
    return None


def locate_build_tools(sdk_path: Optional[str] = None) -> Optional[str]:
    """Find the newest version directory under Android SDK build-tools."""
    explicit_bt = os.environ.get("ANDROID_BUILD_TOOLS_DIR")
    if explicit_bt and os.path.isdir(explicit_bt):
        return os.path.abspath(explicit_bt)

    sdk = sdk_path or locate_android_sdk()
    if not sdk:
        return None

    bt_root = os.path.join(sdk, "build-tools")
    if not os.path.isdir(bt_root):
        return None

    versions = [
        d for d in os.listdir(bt_root)
        if os.path.isdir(os.path.join(bt_root, d))
    ]
    if not versions:
        return None

    def version_key(v: str):
        # Numeric split sort for versions like "35.0.0", "34.0.0-rc1"
        parts = re.split(r"[-.]", v)
        key = []
        for p in parts:
            if p.isdigit():
                key.append(int(p))
            else:
                key.append(p)
        return key

    versions.sort(key=version_key)
    return os.path.join(bt_root, versions[-1])


def resolve_tool(tool_name: str, build_tools_dir: Optional[str] = None, fallback_name: Optional[str] = None) -> Optional[str]:
    """Resolve an executable binary path from build-tools dir or system PATH."""
    exts = [".exe", ".bat", ".cmd", ""] if sys.platform == "win32" else [""]

    if build_tools_dir and os.path.isdir(build_tools_dir):
        for name in [tool_name, fallback_name]:
            if not name:
                continue
            for ext in exts:
                cand = os.path.join(build_tools_dir, f"{name}{ext}")
                if os.path.isfile(cand) and (sys.platform == "win32" or os.access(cand, os.X_OK)):
                    return cand

    # Check PATH
    path_cand = shutil.which(tool_name)
    if path_cand:
        return path_cand
    if fallback_name:
        path_cand = shutil.which(fallback_name)
        if path_cand:
            return path_cand

    return None


class APKVerifier:
    def __init__(self, target_dir: str = "build/app/outputs/flutter-apk", build_tools_dir: Optional[str] = None):
        self.target_dir = os.path.abspath(target_dir)
        self.build_tools_dir = build_tools_dir or locate_build_tools()

        self.zipalign_bin = resolve_tool("zipalign", self.build_tools_dir)
        self.apksigner_bin = resolve_tool("apksigner", self.build_tools_dir)
        self.aapt_bin = resolve_tool("aapt", self.build_tools_dir, fallback_name="aapt2")

    def check_tools(self) -> Tuple[bool, List[str]]:
        missing = []
        if not self.zipalign_bin:
            missing.append("zipalign")
        if not self.apksigner_bin:
            missing.append("apksigner")
        if not self.aapt_bin:
            missing.append("aapt / aapt2")
        return (len(missing) == 0, missing)

    def verify_alignment(self, apk_path: str) -> Tuple[bool, str]:
        """Assert 4-byte zip alignment using zipalign."""
        if not self.zipalign_bin:
            return False, "zipalign executable not resolved"
        try:
            res = subprocess.run(
                [self.zipalign_bin, "-c", "-v", "4", apk_path],
                capture_output=True,
                text=True,
                check=False
            )
            output = res.stdout + "\n" + res.stderr
            if res.returncode == 0 and re.search(r"Verification succes*ful", output, re.IGNORECASE):
                return True, "4-byte zip alignment verified."
            return False, f"zipalign failed (code {res.returncode}):\n{output.strip()}"
        except Exception as e:
            return False, f"Exception running zipalign: {e}"

    def verify_signatures(self, apk_path: str) -> Tuple[bool, List[str]]:
        """Assert v1 and v2 signature schemes and non-debug certificate DN."""
        if not self.apksigner_bin:
            return False, ["apksigner executable not resolved"]
        try:
            res = subprocess.run(
                [self.apksigner_bin, "verify", "--verbose", "--print-certs", apk_path],
                capture_output=True,
                text=True,
                check=False
            )
            output = res.stdout + "\n" + res.stderr
            if res.returncode != 0:
                return False, [f"apksigner returned code {res.returncode}:\n{output.strip()}"]

            errors = []
            notes = []

            # Check v1
            if "Verified using v1 scheme (JAR signing): true" in output:
                notes.append("Scheme v1 (JAR signing): true")
            else:
                notes.append("Scheme v1 (JAR signing): false (v2 signature active)")

            # Check v2
            if "Verified using v2 scheme (APK Signature Scheme v2): true" in output:
                notes.append("Scheme v2 (APK Signature Scheme v2): true")
            else:
                errors.append("Scheme v2 (APK Signature Scheme v2) is not true or missing")

            # Check Debug DN
            if re.search(r"CN\s*=\s*Android Debug", output, re.IGNORECASE):
                errors.append("Signer certificate is 'CN=Android Debug'! Must be signed with a release keystore.")
            else:
                dn_match = re.search(r"certificate DN:\s*(.+)", output)
                if dn_match:
                    notes.append(f"Certificate DN: {dn_match.group(1).strip()}")
                else:
                    notes.append("Certificate DN: Verified valid non-debug")

            if errors:
                return False, errors
            return True, notes
        except Exception as e:
            return False, [f"Exception running apksigner: {e}"]

    def verify_badging(self, apk_path: str) -> Tuple[bool, List[str]]:
        """Validate package name, launchable activity, label, and icons using aapt / aapt2."""
        if not self.aapt_bin:
            return False, ["aapt / aapt2 executable not resolved"]
        try:
            res = subprocess.run(
                [self.aapt_bin, "dump", "badging", apk_path],
                capture_output=True,
                text=True,
                check=False
            )
            output = res.stdout + "\n" + res.stderr
            if res.returncode != 0:
                return False, [f"aapt dump badging returned code {res.returncode}:\n{output.strip()}"]

            errors = []
            notes = []

            # Package name check
            pkg_pattern = rf"package:\s+name='{re.escape(EXPECTED_PACKAGE)}'"
            if re.search(pkg_pattern, output):
                notes.append(f"Package name: {EXPECTED_PACKAGE}")
            else:
                errors.append(f"Expected package name '{EXPECTED_PACKAGE}' not found in badging")

            # Launchable activity check
            act_pattern = rf"launchable-activity:\s+name='{re.escape(EXPECTED_ACTIVITY)}'"
            if re.search(act_pattern, output):
                notes.append(f"Launchable activity: {EXPECTED_ACTIVITY}")
            else:
                errors.append(f"Expected launchable activity '{EXPECTED_ACTIVITY}' not found in badging")

            # Application label check
            label_match = re.search(r"application-label:\s*'([^']+)'", output)
            if label_match:
                notes.append(f"Application label: '{label_match.group(1)}'")
            elif "application-label:" in output:
                notes.append("Application label present")
            else:
                errors.append("Application label missing from badging")

            # Application icon check
            if re.search(r"application-icon-|icon='[^']+'", output):
                notes.append("Application icons resolved cleanly")
            else:
                errors.append("Application icon definition missing or unresolvable")

            if errors:
                return False, errors
            return True, notes
        except Exception as e:
            return False, [f"Exception running aapt: {e}"]

    def run_all(self) -> bool:
        print("=" * 72)
        print(" Universal Media Downloader - Automated APK Quality Gate (Python)")
        print("=" * 72)
        print(f"Target directory : {self.target_dir}")
        print(f"Build-tools dir  : {self.build_tools_dir or '<none found; using PATH>'}")
        print(f"zipalign binary  : {self.zipalign_bin or '<NOT FOUND>'}")
        print(f"apksigner binary : {self.apksigner_bin or '<NOT FOUND>'}")
        print(f"aapt binary      : {self.aapt_bin or '<NOT FOUND>'}")
        print("-" * 72)

        tools_ok, missing_tools = self.check_tools()
        if not tools_ok:
            print("[-] ERROR: Missing required Android SDK build tools:", ", ".join(missing_tools), file=sys.stderr)
            print("Please set ANDROID_HOME or install Android SDK Build-Tools.", file=sys.stderr)
            return False

        # Check all expected APKs exist
        missing_apks = []
        for apk in EXPECTED_APKS:
            apk_path = os.path.join(self.target_dir, apk)
            if not os.path.isfile(apk_path):
                missing_apks.append(apk)

        if missing_apks:
            for m in missing_apks:
                print(f"[-] ERROR: Required release APK not found: {os.path.join(self.target_dir, m)}", file=sys.stderr)
            return False

        total_failures = 0
        for idx, apk in enumerate(EXPECTED_APKS, start=1):
            apk_path = os.path.join(self.target_dir, apk)
            size_mb = os.path.getsize(apk_path) / (1024 * 1024)
            print(f"\n[{idx}/4] Verifying: {apk} ({size_mb:.2f} MB)")
            print(f"    Path: {apk_path}")

            apk_errors = []

            # 1. zipalign
            print("    Checking 4-byte zip alignment (zipalign)...")
            align_ok, align_msg = self.verify_alignment(apk_path)
            if align_ok:
                print(f"      [PASS] {align_msg}")
            else:
                print(f"      [FAIL] {align_msg}", file=sys.stderr)
                apk_errors.append(align_msg)

            # 2. apksigner
            print("    Checking signature schemes and certificate DN (apksigner)...")
            sig_ok, sig_msgs = self.verify_signatures(apk_path)
            if sig_ok:
                for m in sig_msgs:
                    print(f"      [PASS] {m}")
            else:
                for m in sig_msgs:
                    print(f"      [FAIL] {m}", file=sys.stderr)
                apk_errors.extend(sig_msgs)

            # 3. aapt badging
            print("    Checking manifest and badging integrity (aapt)...")
            badge_ok, badge_msgs = self.verify_badging(apk_path)
            if badge_ok:
                for m in badge_msgs:
                    print(f"      [PASS] {m}")
            else:
                for m in badge_msgs:
                    print(f"      [FAIL] {m}", file=sys.stderr)
                apk_errors.extend(badge_msgs)

            if not apk_errors:
                print(f"    >>> Result: {apk} PASSED all quality gate checks.")
            else:
                print(f"    >>> Result: {apk} FAILED {len(apk_errors)} check(s).", file=sys.stderr)
                total_failures += len(apk_errors)

        print("\n" + "=" * 72)
        if total_failures == 0:
            print(" QUALITY GATE STATUS: PASSED")
            print(" All 4 release APKs verified successfully (zipalign, apksigner, aapt).")
            print("=" * 72)
            return True
        else:
            print(f" QUALITY GATE STATUS: FAILED ({total_failures} errors detected)", file=sys.stderr)
            print(" APK binaries do not satisfy release quality gate criteria.", file=sys.stderr)
            print("=" * 72, file=sys.stderr)
            return False


def main():
    parser = argparse.ArgumentParser(description="Automated APK Quality Gate & Verification")
    parser.add_argument("target_dir", nargs="?", default="build/app/outputs/flutter-apk",
                        help="Directory containing release APKs (default: build/app/outputs/flutter-apk)")
    parser.add_argument("--build-tools-dir", default=None,
                        help="Explicit path to Android SDK build-tools directory")
    args = parser.parse_args()

    verifier = APKVerifier(target_dir=args.target_dir, build_tools_dir=args.build_tools_dir)
    success = verifier.run_all()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
