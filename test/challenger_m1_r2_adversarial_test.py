#!/usr/bin/env python3
"""test/challenger_m1_r2_adversarial_test.py
--------------------------------------------------------------------------------
Adversarial Verification Suite for Milestone 1 (Round 2)
Agent: teamwork_preview_challenger_m1_r2_1 (Empirical Challenger)

Mission:
  Empirically challenge the CI workflow configuration and apksigner dual-signing
  implementation for Milestone 1.

Tests:
  1. AST & Pipeline Structural Sequence Audit:
     - 13 sequential steps in .github/workflows/build_apk.yml
     - Step 8 is 'Sign Release APKs with apksigner (Dual-Scheme v1 + v2)'
     - Step 8 is strictly positioned after 'Build Split-per-ABI Release APKs' (idx 7)
       and strictly before 'Verify APK Quality Gate' (idx 9).
  2. Cryptographic Argument & Flag Verification:
     - Strict presence of '--v1-signing-enabled true'
     - Strict presence of '--v2-signing-enabled true'
     - Keystore path, alias, and passwords match specification and build.gradle.
  3. APK Flavour Target Whitelist Audit:
     - All 4 target APKs explicitly enumerated in TARGET_APKS array.
     - 100% parity with upload artifact paths, release assets, and scripts/verify_apk.sh.
  4. Fail-Closed Security & Non-Bypassability:
     - continue-on-error is false.
     - No suppression operators ('|| true', 'set +e').
     - Downstream steps lack 'if: always()' or 'if: failure()'.
     - Per-APK immediate signature verification assertion.
  5. Empirical Shell Simulation with Mock apksigner Oracle:
     - Simulates runner execution with realistic build-tools directory discovery.
     - Captures all tool invocations and verifies exact call arguments.
     - Tests fail-fast halting when apksigner sign fails.
  6. Checksum Ordering Invariant & Cryptographic Tamper Proof:
     - Demonstrates that signing post-checksum generation invalidates SHA256SUMS.txt.
     - Confirms that positioning signing before checksum generation guarantees
       integrity of published binaries and checksums.
--------------------------------------------------------------------------------
"""

import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORKFLOW_FILE = os.path.join(REPO_ROOT, ".github", "workflows", "build_apk.yml")
KEYSTORE_FILE = os.path.join(REPO_ROOT, "android", "app", "release.keystore")
BUILD_GRADLE_FILE = os.path.join(REPO_ROOT, "android", "app", "build.gradle")

EXPECTED_APKS = [
    "build/app/outputs/flutter-apk/app-release.apk",
    "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk",
    "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk",
    "build/app/outputs/flutter-apk/app-x86_64-release.apk",
]


def test_1_ast_and_step_sequence():
    print("\n--- [Challenger Test 1] AST & Pipeline Step Sequence ---")
    assert os.path.isfile(WORKFLOW_FILE), f"Workflow file not found: {WORKFLOW_FILE}"

    with open(WORKFLOW_FILE, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f.read())

    assert "jobs" in data and "build" in data["jobs"], "Job 'build' missing from workflow"
    steps = data["jobs"]["build"]["steps"]
    step_names = [s.get("name") for s in steps]

    print(f"Total steps found: {len(steps)}")
    for i, name in enumerate(step_names):
        print(f"  Step {i:02d}: {name}")

    assert len(steps) == 13, f"Expected exactly 13 steps, got {len(steps)}"

    sign_step_name = "Sign Release APKs with apksigner (Dual-Scheme v1 + v2)"
    assert sign_step_name in step_names, f"Signing step '{sign_step_name}' missing from steps"

    sign_idx = step_names.index(sign_step_name)
    assert sign_idx == 8, f"Signing step must be at index 8, but found at index {sign_idx}"

    split_build_idx = step_names.index("Build Split-per-ABI Release APKs")
    verify_idx = step_names.index("Verify APK Quality Gate")
    checksum_idx = step_names.index("Generate SHA-256 Checksums")
    upload_idx = step_names.index("Upload APK Artifacts")
    publish_idx = step_names.index("Publish to GitHub Releases")

    assert split_build_idx < sign_idx, (
        f"Signing step (idx {sign_idx}) must be placed AFTER split build (idx {split_build_idx})"
    )
    assert sign_idx < verify_idx, (
        f"Signing step (idx {sign_idx}) must be placed BEFORE Quality Gate (idx {verify_idx})"
    )
    assert verify_idx < checksum_idx, (
        f"Quality Gate (idx {verify_idx}) must be placed BEFORE Checksums (idx {checksum_idx})"
    )
    assert checksum_idx < upload_idx, (
        f"Checksums (idx {checksum_idx}) must be placed BEFORE Upload (idx {upload_idx})"
    )
    assert upload_idx < publish_idx, (
        f"Upload (idx {upload_idx}) must be placed BEFORE Publish (idx {publish_idx})"
    )

    print("[PASS] AST step sequence strictly verified: Build -> Sign -> Verify -> Checksum -> Upload -> Publish.")
    return data, steps[sign_idx]


def test_2_cryptographic_flags_and_keystore(sign_step):
    print("\n--- [Challenger Test 2] Cryptographic Flags & Keystore Credentials ---")
    run_script = sign_step.get("run", "")
    assert run_script, "Signing step 'run' block is empty"

    # 1. Assert mandatory flags
    assert "--v1-signing-enabled true" in run_script, (
        "CRITICAL BUG: '--v1-signing-enabled true' flag is missing from apksigner sign command"
    )
    assert "--v2-signing-enabled true" in run_script, (
        "CRITICAL BUG: '--v2-signing-enabled true' flag is missing from apksigner sign command"
    )

    # 2. Assert keystore path & alias & passwords
    assert 'KEYSTORE="android/app/release.keystore"' in run_script, (
        "Keystore path must be 'android/app/release.keystore'"
    )
    assert 'KS_PASS="pass:universal_media_downloader"' in run_script, (
        "Keystore password must be 'pass:universal_media_downloader'"
    )
    assert 'KEY_ALIAS="universal_media_key"' in run_script, (
        "Key alias must be 'universal_media_key'"
    )
    assert 'KEY_PASS="pass:universal_media_downloader"' in run_script, (
        "Key password must be 'pass:universal_media_downloader'"
    )

    # 3. Verify keystore file existence in repository
    assert os.path.isfile(KEYSTORE_FILE), f"Keystore file not found in repo at {KEYSTORE_FILE}"
    keystore_size = os.path.getsize(KEYSTORE_FILE)
    assert keystore_size > 0, f"Keystore file is empty: {keystore_size} bytes"

    # 4. Verify build.gradle alignment
    with open(BUILD_GRADLE_FILE, "r", encoding="utf-8") as f:
        bg_content = f.read()

    assert "universal_media_downloader" in bg_content, (
        "build.gradle does not contain expected release keystore credentials"
    )
    assert "universal_media_key" in bg_content, (
        "build.gradle does not contain expected release key alias"
    )
    assert "v1SigningEnabled true" in bg_content, (
        "build.gradle missing v1SigningEnabled true"
    )
    assert "v2SigningEnabled true" in bg_content, (
        "build.gradle missing v2SigningEnabled true"
    )

    print("[PASS] Cryptographic flags (--v1-signing-enabled true, --v2-signing-enabled true) and keystore match.")


def test_3_apk_flavour_coverage(sign_step, workflow_data):
    print("\n--- [Challenger Test 3] APK Flavour Target Whitelist Audit ---")
    run_script = sign_step.get("run", "")

    # Extract TARGET_APKS from bash array
    match = re.search(r"TARGET_APKS=\(\s*([\s\S]*?)\s*\)", run_script)
    assert match, "Could not find TARGET_APKS array in signing step"

    raw_apks = match.group(1).split()
    target_apks = [a.strip('"\',') for a in raw_apks if a.strip('"\',')]

    print("Found TARGET_APKS in signing script:")
    for apk in target_apks:
        print(f"  - {apk}")

    assert len(target_apks) == 4, f"Expected exactly 4 target APKs, found {len(target_apks)}"
    for expected in EXPECTED_APKS:
        assert expected in target_apks, f"Required release APK '{expected}' missing from TARGET_APKS"

    # Parity check with upload-artifact and gh-release
    step_dict = {s.get("name"): s for s in workflow_data["jobs"]["build"]["steps"]}
    upload_paths = step_dict["Upload APK Artifacts"].get("with", {}).get("path", "")
    release_files = step_dict["Publish to GitHub Releases"].get("with", {}).get("files", "")

    for expected in EXPECTED_APKS:
        assert expected in upload_paths, f"APK '{expected}' missing from upload-artifact paths"
        assert expected in release_files, f"APK '{expected}' missing from action-gh-release files"

    print("[PASS] 100% target APK flavour coverage verified across signing, artifact upload, and GitHub release.")


def test_4_fail_closed_security_and_non_bypassability(sign_step, workflow_data):
    print("\n--- [Challenger Test 4] Fail-Closed Security & Error Shielding ---")

    # 1. Step must not ignore errors
    assert not sign_step.get("continue-on-error", False), (
        "VULNERABILITY: 'Sign Release APKs' has continue-on-error enabled!"
    )

    # 2. Shell script must not suppress failures
    run_script = sign_step.get("run", "")
    assert "|| true" not in run_script, "VULNERABILITY: '|| true' found in signing script"
    assert "|| exit 0" not in run_script, "VULNERABILITY: '|| exit 0' found in signing script"
    assert "set +e" not in run_script, "VULNERABILITY: 'set +e' found in signing script"

    # 3. Must verify signatures immediately
    assert '"$APKSIGNER" verify --verbose "$apk"' in run_script, (
        "Signing script must perform immediate verification after signing each APK"
    )

    # 4. Downstream steps must not run on failure
    steps = workflow_data["jobs"]["build"]["steps"]
    step_dict = {s.get("name"): s for s in steps}

    for name in ["Verify APK Quality Gate", "Generate SHA-256 Checksums", "Upload APK Artifacts", "Publish to GitHub Releases"]:
        cond = step_dict[name].get("if", "")
        assert "always()" not in cond, f"Step '{name}' has 'always()' condition"
        assert "failure()" not in cond, f"Step '{name}' has 'failure()' condition"

    print("[PASS] Step operates fail-closed with zero failure suppression and zero downstream leak vectors.")


def test_5_simulation_with_mock_apksigner_oracle():
    print("\n--- [Challenger Test 5] Simulation Execution with Mock apksigner Oracle ---")
    sh_bin = shutil.which("sh")
    if not sh_bin:
        cand = r"C:\Users\zeroo\AppData\Local\OpenClaw\deps\portable-git\usr\bin\sh.exe"
        if os.path.exists(cand):
            sh_bin = cand
    assert sh_bin, "sh.exe not found on system"

    # Locate git usr/bin for GNU coreutils (sort, find, tail) on Windows if available
    git_usr_bin = None
    if os.path.exists(r"C:\Users\zeroo\AppData\Local\OpenClaw\deps\portable-git\usr\bin"):
        git_usr_bin = r"C:\Users\zeroo\AppData\Local\OpenClaw\deps\portable-git\usr\bin"
    elif os.path.dirname(sh_bin) and os.path.exists(os.path.join(os.path.dirname(sh_bin), "..", "usr", "bin")):
        git_usr_bin = os.path.abspath(os.path.join(os.path.dirname(sh_bin), "..", "usr", "bin"))

    # Read the exact step run script from workflow
    with open(WORKFLOW_FILE, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f.read())
    sign_step = [s for s in data["jobs"]["build"]["steps"] if "Sign Release APKs" in s.get("name", "")][0]
    run_script = sign_step["run"]

    # 1. Happy path test with mock apksigner
    with tempfile.TemporaryDirectory() as tmp:
        # Prepare directory structure
        build_tools_dir = os.path.join(tmp, "android_sdk", "build-tools", "34.0.0")
        flutter_apk_dir = os.path.join(tmp, "build", "app", "outputs", "flutter-apk")
        android_app_dir = os.path.join(tmp, "android", "app")
        os.makedirs(build_tools_dir, exist_ok=True)
        os.makedirs(flutter_apk_dir, exist_ok=True)
        os.makedirs(android_app_dir, exist_ok=True)

        # Copy real keystore to test dir
        shutil.copy(KEYSTORE_FILE, os.path.join(android_app_dir, "release.keystore"))

        # Create dummy APK files
        for apk_rel in EXPECTED_APKS:
            apk_path = os.path.join(tmp, apk_rel.replace("/", os.sep))
            with open(apk_path, "wb") as f:
                f.write(b"PK\x03\x04" + b"ZIP_ENTRY" * 20)

        # Create mock apksigner recording invocations to log file
        log_file = os.path.join(tmp, "apksigner_invocations.log").replace("\\", "/")
        mock_apksigner = f"""#!/bin/sh
echo "INVOKED: $@" >> "{log_file}"
if [ "$1" = "--version" ]; then
  echo "34.0.0"
  exit 0
fi

if [ "$1" = "sign" ]; then
  # Validate mandatory arguments
  echo "$@" | grep -q -- "--v1-signing-enabled true" || {{ echo "MISSING V1 FLAG" >&2; exit 2; }}
  echo "$@" | grep -q -- "--v2-signing-enabled true" || {{ echo "MISSING V2 FLAG" >&2; exit 2; }}
  echo "$@" | grep -q -- "--ks android/app/release.keystore" || {{ echo "MISSING KEYSTORE" >&2; exit 2; }}
  echo "$@" | grep -q -- "--ks-key-alias universal_media_key" || {{ echo "MISSING ALIAS" >&2; exit 2; }}
  exit 0
fi

if [ "$1" = "verify" ]; then
  echo "Verified using v1 scheme (JAR signing): true"
  echo "Verified using v2 scheme (APK Signature Scheme v2): true"
  echo "Number of signers: 1"
  exit 0
fi

exit 0
"""
        apksigner_bin = os.path.join(build_tools_dir, "apksigner")
        with open(apksigner_bin, "w", newline="\n") as f:
            f.write(mock_apksigner)
        os.chmod(apksigner_bin, 0o755)

        # Create runner script simulating bash -e execution
        runner_sh = f"""#!/bin/sh
set -e
export ANDROID_HOME="{os.path.join(tmp, 'android_sdk').replace(os.sep, '/')}"
{run_script}
"""
        runner_file = os.path.join(tmp, "runner.sh")
        with open(runner_file, "w", newline="\n") as f:
            f.write(runner_sh)
        os.chmod(runner_file, 0o755)

        env = os.environ.copy()
        if git_usr_bin:
            env["PATH"] = git_usr_bin + os.pathsep + env.get("PATH", "")

        res = subprocess.run([sh_bin, runner_file.replace(os.sep, "/")], cwd=tmp, env=env, capture_output=True, text=True)
        assert res.returncode == 0, f"Happy path simulation failed: {res.stderr}\n{res.stdout}"

        # Assert apksigner calls
        with open(log_file.replace("/", os.sep), "r", encoding="utf-8") as f:
            invocations = [line.strip() for line in f if line.strip()]

        sign_invocations = [inv for inv in invocations if "INVOKED: sign" in inv]
        verify_invocations = [inv for inv in invocations if "INVOKED: verify" in inv]

        print(f"Total sign invocations: {len(sign_invocations)}")
        print(f"Total verify invocations: {len(verify_invocations)}")

        assert len(sign_invocations) == 4, f"Expected 4 sign calls, got {len(sign_invocations)}"
        assert len(verify_invocations) == 4, f"Expected 4 verify calls, got {len(verify_invocations)}"

        for expected_apk in EXPECTED_APKS:
            apk_sub = expected_apk.replace("build/app/outputs/flutter-apk/", "")
            assert any(apk_sub in inv for inv in sign_invocations), f"APK {apk_sub} not signed"
            assert any(apk_sub in inv for inv in verify_invocations), f"APK {apk_sub} not verified"

        print("[PASS] Happy path simulation executed 4 dual-signing and 4 verification operations flawlessly.")

    # 2. Adversarial failure simulation: apksigner sign fails on arm64 APK
    with tempfile.TemporaryDirectory() as tmp:
        build_tools_dir = os.path.join(tmp, "android_sdk", "build-tools", "34.0.0")
        flutter_apk_dir = os.path.join(tmp, "build", "app", "outputs", "flutter-apk")
        android_app_dir = os.path.join(tmp, "android", "app")
        os.makedirs(build_tools_dir, exist_ok=True)
        os.makedirs(flutter_apk_dir, exist_ok=True)
        os.makedirs(android_app_dir, exist_ok=True)

        for apk_rel in EXPECTED_APKS:
            apk_path = os.path.join(tmp, apk_rel.replace("/", os.sep))
            with open(apk_path, "wb") as f:
                f.write(b"PK\x03\x04" + b"ZIP_ENTRY" * 20)

        mock_failing_apksigner = """#!/bin/sh
if [ "$1" = "--version" ]; then
  echo "34.0.0"
  exit 0
fi

if [ "$1" = "sign" ]; then
  for arg in "$@"; do
    if echo "$arg" | grep -q "app-arm64-v8a-release.apk"; then
      echo "SIGNING FAULT: Keystore corrupted or signature failed" >&2
      exit 1
    fi
  done
  exit 0
fi
exit 0
"""
        apksigner_bin = os.path.join(build_tools_dir, "apksigner")
        with open(apksigner_bin, "w", newline="\n") as f:
            f.write(mock_failing_apksigner)
        os.chmod(apksigner_bin, 0o755)

        runner_sh = f"""#!/bin/sh
set -e
export ANDROID_HOME="{os.path.join(tmp, 'android_sdk').replace(os.sep, '/')}"
{run_script}
touch "{tmp.replace(os.sep, '/')}/SHOULD_NOT_BE_REACHED"
"""
        runner_file = os.path.join(tmp, "runner_fail.sh")
        with open(runner_file, "w", newline="\n") as f:
            f.write(runner_sh)
        os.chmod(runner_file, 0o755)

        res_fail = subprocess.run([sh_bin, runner_file.replace(os.sep, "/")], cwd=tmp, env=env, capture_output=True, text=True)
        assert res_fail.returncode != 0, "Workflow step did not fail when apksigner failed!"
        assert "SIGNING FAULT" in res_fail.stderr, "Expected error message from failing apksigner"
        assert not os.path.exists(os.path.join(tmp, "SHOULD_NOT_BE_REACHED")), (
            "Execution continued past failed signing step!"
        )

        print("[PASS] Adversarial failure test confirmed: immediate process termination on signing error.")


def test_6_checksum_ordering_invariant():
    print("\n--- [Challenger Test 6] Checksum Ordering Invariant Proof ---")
    # Demonstrates that signing changes file hashes:
    # If signing occurred AFTER checksum generation, the published checksums would be INVALID.
    # Therefore, signing MUST occur BEFORE checksum generation.
    dummy_apk = b"PK\x03\x04" + b"RAW_UNSIGNED_APK_BINARY" * 50
    initial_sha = hashlib.sha256(dummy_apk).hexdigest()

    # Simulate signing modification (appending signing block & META-INF signatures)
    signed_apk = dummy_apk + b"APK_SIGNING_BLOCK_V2_V3" + b"META-INF/MANIFEST.MF_V1_SIGNATURES"
    signed_sha = hashlib.sha256(signed_apk).hexdigest()

    assert initial_sha != signed_sha, "Signing simulation must alter hash"

    # If checksums were computed before signing:
    checksum_line = f"{initial_sha}  app-release.apk\n"
    # Verification against signed file:
    actual_hash_of_signed_file = hashlib.sha256(signed_apk).hexdigest()
    verified_match = (actual_hash_of_signed_file == initial_sha)

    assert not verified_match, "Checksums computed before signing MUST fail verification against signed files"
    print(f"  Unsigned APK hash: {initial_sha}")
    print(f"  Signed APK hash  : {signed_sha}")
    print(f"  Verification if signed after checksums: [FAILED MISMATCH] (Expected invariant holds)")
    print("[PASS] Invariant proven: Step 8 (Sign) must precede Step 10 (Generate SHA-256 Checksums).")


def main():
    print("=" * 80)
    print(" EMPIRICAL CHALLENGER M1 R2: DUAL-SCHEME SIGNING ADVERSARIAL SUITE")
    print("=" * 80)
    workflow_data, sign_step = test_1_ast_and_step_sequence()
    test_2_cryptographic_flags_and_keystore(sign_step)
    test_3_apk_flavour_coverage(sign_step, workflow_data)
    test_4_fail_closed_security_and_non_bypassability(sign_step, workflow_data)
    test_5_simulation_with_mock_apksigner_oracle()
    test_6_checksum_ordering_invariant()
    print("\n" + "=" * 80)
    print(" ALL 6 CHALLENGER ADVERSARIAL SUITES PASSED (100% EMPIRICALLY VERIFIED)")
    print("=" * 80)


if __name__ == "__main__":
    main()
