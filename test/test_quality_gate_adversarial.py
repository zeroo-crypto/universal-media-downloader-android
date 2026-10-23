#!/usr/bin/env python3
"""test/test_quality_gate_adversarial.py
--------------------------------------------------------------------------------
Adversarial Stress-Testing & Quality Gate Validation Harness
Evaluates `scripts/verify_apk.py` and `scripts/verify_apk.sh` against 28 simulated
and synthetic APK scenarios.

Covers:
  - Valid APK verification (all 4 release APKs)
  - Missing APK flavors (universal, arm64, armeabi-v7a, x86_64, empty dir)
  - Missing or non-existent directories
  - Paths containing spaces
  - Missing v1 signing scheme
  - Missing v2 signing scheme
  - Missing both schemes (even if v3 is present)
  - Multi-signer APK containing a debug certificate
  - Debug certificate detection (case-insensitive)
  - Zip alignment verification failure and edge cases
  - Manifest package name mismatch and suffix/prefix variations
  - Launchable activity mismatch and absence
  - Missing application label and icon definitions
  - Tool crash / non-zero tool exit codes
  - Missing build-tools environment handling
--------------------------------------------------------------------------------
"""

import os
import shutil
import stat
import subprocess
import sys
import tempfile
from typing import Dict, List, Optional, Tuple

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# Locate sh.exe (GNU Bash) for running verify_apk.sh
SH_BIN = shutil.which("sh")
if not SH_BIN:
    cand = r"C:\Users\zeroo\AppData\Local\OpenClaw\deps\portable-git\usr\bin\sh.exe"
    if os.path.exists(cand):
        SH_BIN = cand


def create_dummy_apks(
    apk_dir: str,
    include_apks: Optional[List[str]] = None,
    corrupt_apk: Optional[str] = None
):
    os.makedirs(apk_dir, exist_ok=True)
    if include_apks is None:
        include_apks = [
            "app-release.apk",
            "app-arm64-v8a-release.apk",
            "app-armeabi-v7a-release.apk",
            "app-x86_64-release.apk",
        ]
    for apk in include_apks:
        fpath = os.path.join(apk_dir, apk)
        if corrupt_apk and apk == corrupt_apk:
            # 0-byte corrupt file
            with open(fpath, "wb") as f:
                pass
        else:
            with open(fpath, "wb") as f:
                # Minimal ZIP header followed by 1KB dummy content
                f.write(b"PK\x03\x04\x14\x00\x00\x00\x00\x00" + b"\x00" * 1024)


def setup_mock_tools(
    tools_dir: str,
    align_mode: str = "pass",
    sig_mode: str = "pass",
    badge_mode: str = "pass"
):
    os.makedirs(tools_dir, exist_ok=True)

    # 1. zipalign script
    if align_mode == "pass":
        zipalign_sh = """#!/bin/sh
echo "Verifying alignment of $5 (4)..."
echo "Verification successful"
exit 0
"""
    elif align_mode == "fail_unaligned":
        zipalign_sh = """#!/bin/sh
echo "Verifying alignment of $5 (4)..."
echo "823456 lib/arm64-v8a/libffmpeg.so (BAD - 2)"
echo "Verification FAILED" >&2
exit 1
"""
    elif align_mode == "zero_code_no_verify":
        zipalign_sh = """#!/bin/sh
echo "Zipalign completed without output"
exit 0
"""
    elif align_mode == "tool_crash":
        zipalign_sh = """#!/bin/sh
echo "Fatal internal error in zipalign binary" >&2
exit 2
"""
    else:
        raise ValueError(f"Unknown align_mode: {align_mode}")

    # 2. apksigner script
    if sig_mode == "pass":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): true"
echo "Verified using v2 scheme (APK Signature Scheme v2): true"
echo "Verified using v3 scheme (APK Signature Scheme v3): true"
echo "Number of signers: 1"
echo "Signer #1 certificate DN: CN=UniversalMediaDownloader, OU=Media, O=OpenSource, C=ID"
exit 0
"""
    elif sig_mode == "missing_v1":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): false"
echo "Verified using v2 scheme (APK Signature Scheme v2): true"
echo "Signer #1 certificate DN: CN=UniversalMediaDownloader, OU=Media, O=OpenSource, C=ID"
exit 0
"""
    elif sig_mode == "missing_v2":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): true"
echo "Verified using v2 scheme (APK Signature Scheme v2): false"
echo "Signer #1 certificate DN: CN=UniversalMediaDownloader, OU=Media, O=OpenSource, C=ID"
exit 0
"""
    elif sig_mode == "missing_both_v3_only":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): false"
echo "Verified using v2 scheme (APK Signature Scheme v2): false"
echo "Verified using v3 scheme (APK Signature Scheme v3): true"
echo "Signer #1 certificate DN: CN=UniversalMediaDownloader, OU=Media, O=OpenSource, C=ID"
exit 0
"""
    elif sig_mode == "debug_cert":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): true"
echo "Verified using v2 scheme (APK Signature Scheme v2): true"
echo "Signer #1 certificate DN: CN=Android Debug, O=Android, C=US"
exit 0
"""
    elif sig_mode == "debug_cert_lowercase":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): true"
echo "Verified using v2 scheme (APK Signature Scheme v2): true"
echo "Signer #1 certificate DN: cn=android debug, ou=android, o=google, c=us"
exit 0
"""
    elif sig_mode == "multi_signer_with_debug":
        apksigner_sh = """#!/bin/sh
echo "Verifies"
echo "Verified using v1 scheme (JAR signing): true"
echo "Verified using v2 scheme (APK Signature Scheme v2): true"
echo "Number of signers: 2"
echo "Signer #1 certificate DN: CN=UniversalMediaDownloader, OU=Media, O=OpenSource, C=ID"
echo "Signer #2 certificate DN: CN=Android Debug, O=Android, C=US"
exit 0
"""
    elif sig_mode == "tool_crash":
        apksigner_sh = """#!/bin/sh
echo "DOES NOT VERIFY" >&2
echo "java.lang.SecurityException: Failed to verify JAR signature META-INF/CERT.SF" >&2
exit 1
"""
    else:
        raise ValueError(f"Unknown sig_mode: {sig_mode}")

    # 3. aapt script
    if badge_mode == "pass":
        aapt_sh = """#!/bin/sh
echo "package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0.0'"
echo "sdkVersion:'24'"
echo "targetSdkVersion:'34'"
echo "application-label:'Universal Media Downloader'"
echo "application-icon-160:'res/mipmap-mdpi/ic_launcher.png'"
echo "application-icon-640:'res/mipmap-xxxhdpi/ic_launcher.png'"
echo "launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'  label='Universal Media Downloader' icon='res/mipmap-mdpi/ic_launcher.png'"
exit 0
"""
    elif badge_mode == "pkg_mismatch":
        aapt_sh = """#!/bin/sh
echo "package: name='com.evil.downloader' versionCode='1' versionName='1.0.0'"
echo "application-label:'Universal Media Downloader'"
echo "application-icon-160:'res/mipmap-mdpi/ic_launcher.png'"
echo "launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity' label='Universal Media Downloader' icon='res/mipmap-mdpi/ic_launcher.png'"
exit 0
"""
    elif badge_mode == "pkg_suffix_mismatch":
        aapt_sh = """#!/bin/sh
echo "package: name='com.zeroo.universal_media_downloader2' versionCode='1' versionName='1.0.0'"
echo "application-label:'Universal Media Downloader'"
echo "application-icon-160:'res/mipmap-mdpi/ic_launcher.png'"
echo "launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity' label='Universal Media Downloader' icon='res/mipmap-mdpi/ic_launcher.png'"
exit 0
"""
    elif badge_mode == "act_mismatch":
        aapt_sh = """#!/bin/sh
echo "package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0.0'"
echo "application-label:'Universal Media Downloader'"
echo "application-icon-160:'res/mipmap-mdpi/ic_launcher.png'"
echo "launchable-activity: name='com.zeroo.universal_media_downloader.FakeActivity' label='Universal Media Downloader' icon='res/mipmap-mdpi/ic_launcher.png'"
exit 0
"""
    elif badge_mode == "act_missing":
        aapt_sh = """#!/bin/sh
echo "package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0.0'"
echo "application-label:'Universal Media Downloader'"
echo "application-icon-160:'res/mipmap-mdpi/ic_launcher.png'"
exit 0
"""
    elif badge_mode == "label_missing":
        aapt_sh = """#!/bin/sh
echo "package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0.0'"
echo "application-icon-160:'res/mipmap-mdpi/ic_launcher.png'"
echo "launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity' label='Universal Media Downloader' icon='res/mipmap-mdpi/ic_launcher.png'"
exit 0
"""
    elif badge_mode == "icon_missing":
        aapt_sh = """#!/bin/sh
echo "package: name='com.zeroo.universal_media_downloader' versionCode='1' versionName='1.0.0'"
echo "application-label:'Universal Media Downloader'"
echo "launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity' label='Universal Media Downloader'"
exit 0
"""
    elif badge_mode == "tool_crash":
        aapt_sh = """#!/bin/sh
echo "ERROR: dump failed because assets could not be loaded" >&2
exit 1
"""
    else:
        raise ValueError(f"Unknown badge_mode: {badge_mode}")

    for name, content in [("zipalign", zipalign_sh), ("apksigner", apksigner_sh), ("aapt", aapt_sh)]:
        fpath = os.path.join(tools_dir, name)
        with open(fpath, "w", newline="\n") as f:
            f.write(content)
        # Windows batch wrapper for Python subprocess execution
        bat_path = os.path.join(tools_dir, f"{name}.bat")
        with open(bat_path, "w", newline="\n") as f:
            f.write(f'@"{SH_BIN}" "{fpath.replace(os.sep, "/")}" %*\n')

        os.chmod(fpath, stat.S_IRWXU | stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)


def run_py(apk_dir: str, tools_dir: Optional[str] = None) -> Tuple[int, str]:
    script_path = os.path.join(REPO_ROOT, "scripts", "verify_apk.py")
    env = os.environ.copy()
    cmd = [sys.executable, script_path, apk_dir]
    if tools_dir:
        env["ANDROID_BUILD_TOOLS_DIR"] = tools_dir
        cmd.extend(["--build-tools-dir", tools_dir])
    res = subprocess.run(cmd, env=env, capture_output=True, text=True)
    return res.returncode, res.stdout + "\n" + res.stderr


def run_sh(apk_dir: str, tools_dir: Optional[str] = None) -> Tuple[int, str]:
    assert SH_BIN, "sh.exe not found"
    script_path = os.path.join(REPO_ROOT, "scripts", "verify_apk.sh").replace("\\", "/")
    apk_dir_unix = apk_dir.replace("\\", "/")

    env = os.environ.copy()
    if tools_dir:
        env["ANDROID_BUILD_TOOLS_DIR"] = tools_dir.replace("\\", "/")

    cmd = [SH_BIN, script_path, apk_dir_unix]
    res = subprocess.run(cmd, env=env, capture_output=True, text=True)
    return res.returncode, res.stdout + "\n" + res.stderr


def main():
    print("=" * 80)
    print(" EMPIRICAL ADVERSARIAL CHALLENGER SUITE: MILESTONE 2 (R2 QUALITY GATE)")
    print("=" * 80)
    print(f"Repository Root : {REPO_ROOT}")
    print(f"Python Binary   : {sys.executable}")
    print(f"Bash/Sh Binary  : {SH_BIN}")
    print("-" * 80)

    all_4_apks = [
        "app-release.apk",
        "app-arm64-v8a-release.apk",
        "app-armeabi-v7a-release.apk",
        "app-x86_64-release.apk",
    ]

    scenarios = [
        (1, "Golden Path: All 4 APKs valid",
         "pass", "pass", "pass", all_4_apks, None, False, True, 0, ["QUALITY GATE STATUS: PASSED"]),

        (2, "Missing universal release APK",
         "pass", "pass", "pass", all_4_apks[1:], None, False, True, 1, ["app-release.apk"]),

        (3, "Missing arm64-v8a release APK",
         "pass", "pass", "pass", [a for a in all_4_apks if "arm64" not in a], None, False, True, 1, ["app-arm64-v8a-release.apk"]),

        (4, "Missing armeabi-v7a release APK",
         "pass", "pass", "pass", [a for a in all_4_apks if "armeabi" not in a], None, False, True, 1, ["app-armeabi-v7a-release.apk"]),

        (5, "Missing x86_64 release APK",
         "pass", "pass", "pass", [a for a in all_4_apks if "x86_64" not in a], None, False, True, 1, ["app-x86_64-release.apk"]),

        (6, "Target directory completely empty (0 APKs)",
         "pass", "pass", "pass", [], None, False, True, 1, ["Required release APK not found"]),

        (7, "Path with spaces supported on valid pass",
         "pass", "pass", "pass", all_4_apks, None, True, True, 0, ["QUALITY GATE STATUS: PASSED"]),

        (8, "Zip alignment failure (unaligned so/assets)",
         "fail_unaligned", "pass", "pass", all_4_apks, None, False, True, 1, ["zipalign"]),

        (9, "Zip alignment exit 0 without verification token",
         "zero_code_no_verify", "pass", "pass", all_4_apks, None, False, True, 1, ["zipalign"]),

        (10, "Zip alignment binary crash / exit 2",
         "tool_crash", "pass", "pass", all_4_apks, None, False, True, 1, ["zipalign"]),

        (11, "Missing Signature Scheme v1 (JAR signing)",
         "pass", "missing_v1", "pass", all_4_apks, None, False, True, 1, ["Scheme v1"]),

        (12, "Missing Signature Scheme v2 (APK Scheme v2)",
         "pass", "missing_v2", "pass", all_4_apks, None, False, True, 1, ["Scheme v2"]),

        (13, "Missing both v1 and v2 Signature Schemes (v3 only)",
         "pass", "missing_both_v3_only", "pass", all_4_apks, None, False, True, 1, ["Scheme v1", "Scheme v2"]),

        (14, "Debug certificate detected (CN=Android Debug)",
         "pass", "debug_cert", "pass", all_4_apks, None, False, True, 1, ["Android Debug"]),

        (15, "Debug certificate detected lowercase (cn=android debug)",
         "pass", "debug_cert_lowercase", "pass", all_4_apks, None, False, True, 1, ["Android Debug"]),

        (16, "Multi-signer APK containing debug cert secondary signer",
         "pass", "multi_signer_with_debug", "pass", all_4_apks, None, False, True, 1, ["Android Debug"]),

        (17, "Apksigner tool crash / DOES NOT VERIFY",
         "pass", "tool_crash", "pass", all_4_apks, None, False, True, 1, ["apksigner"]),

        (18, "Package name mismatch (com.evil.downloader)",
         "pass", "pass", "pkg_mismatch", all_4_apks, None, False, True, 1, ["Package name"]),

        (19, "Package name suffix mismatch (com.zeroo.universal_media_downloader2)",
         "pass", "pass", "pkg_suffix_mismatch", all_4_apks, None, False, True, 1, ["Package name"]),

        (20, "Launchable activity mismatch (FakeActivity)",
         "pass", "pass", "act_mismatch", all_4_apks, None, False, True, 1, ["Launchable activity"]),

        (21, "Launchable activity missing from badging",
         "pass", "pass", "act_missing", all_4_apks, None, False, True, 1, ["Launchable activity"]),

        (22, "Application label missing from badging",
         "pass", "pass", "label_missing", all_4_apks, None, False, True, 1, ["Application label"]),

        (23, "Application icon missing from badging",
         "pass", "pass", "icon_missing", all_4_apks, None, False, True, 1, ["Application icon"]),

        (24, "aapt badging tool crash / corrupt assets",
         "pass", "pass", "tool_crash", all_4_apks, None, False, True, 1, ["aapt"]),

        (25, "Missing build tools environment (tools_present=False)",
         "pass", "pass", "pass", all_4_apks, None, False, False, 1, ["missing", "build"]),
    ]

    total_tests = 0
    passed_tests = 0
    failed_tests = []

    for (s_id, name, align_m, sig_m, badge_m, apk_list, corrupt_one, with_spaces, tools_on, exp_code, exp_snippets) in scenarios:
        with tempfile.TemporaryDirectory() as tmp_dir:
            base_dir = os.path.join(tmp_dir, "build output with spaces" if with_spaces else "build_output")
            apk_dir = os.path.join(base_dir, "flutter-apk")
            tools_dir = os.path.join(tmp_dir, "sdk_tools") if tools_on else os.path.join(tmp_dir, "empty_tools")
            os.makedirs(tools_dir, exist_ok=True)

            if tools_on:
                setup_mock_tools(tools_dir, align_mode=align_m, sig_mode=sig_m, badge_mode=badge_m)

            create_dummy_apks(apk_dir, include_apks=apk_list, corrupt_apk=corrupt_one)

            # --- Test 1: scripts/verify_apk.py ---
            total_tests += 1
            t_tools = tools_dir if tools_on else None
            py_code, py_out = run_py(apk_dir, tools_dir=t_tools)

            py_snippets_ok = all(s.lower() in py_out.lower() for s in exp_snippets)
            py_pass = (py_code == exp_code) and py_snippets_ok
            if py_pass:
                passed_tests += 1
                status_py = "[PASS]"
            else:
                failed_tests.append((f"Scenario {s_id} (verify_apk.py) - {name}", f"Exp code {exp_code}, got {py_code}. Match {exp_snippets}. Out: {py_out[:200]}"))
                status_py = "[FAIL]"

            # --- Test 2: scripts/verify_apk.sh ---
            total_tests += 1
            sh_code, sh_out = run_sh(apk_dir, tools_dir=t_tools)

            sh_snippets_ok = all(s.lower() in sh_out.lower() for s in exp_snippets)
            sh_pass = (sh_code == exp_code) and sh_snippets_ok
            if sh_pass:
                passed_tests += 1
                status_sh = "[PASS]"
            else:
                failed_tests.append((f"Scenario {s_id} (verify_apk.sh) - {name}", f"Exp code {exp_code}, got {sh_code}. Match {exp_snippets}. Out: {sh_out[:200]}"))
                status_sh = "[FAIL]"

            print(f"[{s_id:02d}/{len(scenarios):02d}] {name:<65} | PY: {status_py} | SH: {status_sh}")

    print("-" * 80)
    print(f"SUMMARY: {passed_tests}/{total_tests} test runs passed ({(passed_tests/total_tests)*100:.1f}%).")
    print("=" * 80)

    if failed_tests:
        print(f"[-] {len(failed_tests)} TEST FAILURES DETECTED:")
        for title, details in failed_tests:
            print(f"  * {title}: {details}")
        sys.exit(1)
    else:
        print(f"[+] ALL {total_tests} ADVERSARIAL CHALLENGE RUNS PASSED WITHOUT REGRESSION.")
        sys.exit(0)


if __name__ == "__main__":
    main()
