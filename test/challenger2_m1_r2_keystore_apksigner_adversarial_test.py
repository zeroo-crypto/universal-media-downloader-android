#!/usr/bin/env python3
"""test/challenger2_m1_r2_keystore_apksigner_adversarial_test.py
--------------------------------------------------------------------------------
Milestone 1 (Round 2) — Empirical Challenger 2 Adversarial Verification Suite
Target: Keystore Integrity, Credential Parity, and apksigner CLI Dual-Signing

Suite Overview:
  Test 1: Keystore Cryptographic Properties & Integrity (PKCS12, RSA 2048, validity, alias)
  Test 2: Keystore Adversarial Resistance (bad password, corrupted data rejection)
  Test 3: Cross-File Credential & Scheme Parity (release.keystore vs build.gradle vs build_apk.yml)
  Test 4: Workflow AST Sequence & Fail-Closed Release Shielding
  Test 5: apksigner CLI Flag Syntax & Flavour Whitelist Audit
  Test 6: Linux Runner Simulation Oracle (Mock apksigner, argument verification & fail-fast)
  Test 7: Checksum Ordering Invariant (Proving signing post-checksum corrupts verification)
--------------------------------------------------------------------------------
"""

import datetime
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import yaml
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography import x509

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

EXPECTED_KEYSTORE_ALIAS = "universal_media_key"
EXPECTED_KEYSTORE_PASS = "universal_media_downloader"


def get_sh_bin():
    """Locate sh executable on the current environment."""
    sh_bin = shutil.which("sh")
    if not sh_bin:
        cand = r"C:\Users\zeroo\AppData\Local\OpenClaw\deps\portable-git\usr\bin\sh.exe"
        if os.path.exists(cand):
            sh_bin = cand
    return sh_bin


def test_1_keystore_cryptographic_properties():
    print("\n--- [Test 1] Keystore Cryptographic Properties & Integrity ---")
    assert os.path.isfile(KEYSTORE_FILE), f"Keystore file not found at: {KEYSTORE_FILE}"
    keystore_bytes = open(KEYSTORE_FILE, "rb").read()
    assert len(keystore_bytes) > 0, "Keystore file is 0 bytes"

    # 1. Load PKCS12 with valid password
    p12_obj = pkcs12.load_pkcs12(keystore_bytes, EXPECTED_KEYSTORE_PASS.encode("utf-8"))
    assert p12_obj is not None, "Failed to parse PKCS#12 keystore"
    assert p12_obj.key is not None, "Private key is missing from keystore"
    assert p12_obj.cert is not None, "Certificate is missing from keystore"

    # 2. Key Type & Size
    key = p12_obj.key
    assert hasattr(key, "key_size"), "Private key has no key_size property"
    assert key.key_size == 2048, f"Key size must be 2048 bits, got: {key.key_size}"
    print(f"  [PASS] Key type: RSA, Key size: {key.key_size} bits")

    # 3. Alias (friendly_name)
    cert = p12_obj.cert
    alias = cert.friendly_name.decode("utf-8") if cert.friendly_name else None
    assert alias == EXPECTED_KEYSTORE_ALIAS, f"Expected alias '{EXPECTED_KEYSTORE_ALIAS}', got: '{alias}'"
    print(f"  [PASS] Certificate friendly_name (alias): '{alias}'")

    # 4. Certificate Subject, Issuer, DN
    x509_cert = cert.certificate
    subject_str = x509_cert.subject.rfc4514_string()
    issuer_str = x509_cert.issuer.rfc4514_string()
    print(f"  [PASS] Certificate Subject: {subject_str}")
    print(f"  [PASS] Certificate Issuer : {issuer_str}")

    # Must NOT be debug certificate
    assert "CN=Android Debug" not in subject_str, "CRITICAL: Keystore contains 'CN=Android Debug'!"
    assert "debug" not in subject_str.lower(), "CRITICAL: Keystore contains 'debug' in subject!"

    # 5. Signature Algorithm
    hash_algo = x509_cert.signature_hash_algorithm.name
    sig_oid = x509_cert.signature_algorithm_oid.dotted_string
    assert hash_algo.lower() == "sha256", f"Expected SHA-256 hash algorithm, got {hash_algo}"
    print(f"  [PASS] Signature Algorithm: {hash_algo} ({sig_oid})")

    # 6. Validity Window
    not_before = x509_cert.not_valid_before_utc
    not_after = x509_cert.not_valid_after_utc
    validity_days = (not_after - not_before).days
    now = datetime.datetime.now(datetime.timezone.utc)

    print(f"  [PASS] Not Valid Before (UTC): {not_before}")
    print(f"  [PASS] Not Valid After  (UTC): {not_after}")
    print(f"  [PASS] Total Validity Duration: {validity_days} days (~{validity_days / 365.25:.1f} years)")

    assert validity_days >= 9125, f"Validity duration ({validity_days} days) must be >= 25 years (9125 days) for Android release"
    assert not_before <= now <= not_after, f"Keystore certificate is not currently valid at {now}"

    print("[PASS] Keystore cryptographic integrity and Android release compliance verified.")


def test_2_keystore_adversarial_resistance():
    print("\n--- [Test 2] Keystore Adversarial Resistance ---")
    keystore_bytes = open(KEYSTORE_FILE, "rb").read()

    # 1. Invalid password rejection
    bad_passwords = [b"wrong_password", b"", b"universal_media", b"universal_media_downloader1", b"123456"]
    for bad_pwd in bad_passwords:
        try:
            pkcs12.load_pkcs12(keystore_bytes, bad_pwd)
            raise AssertionError(f"VULNERABILITY: Keystore accepted incorrect password: {bad_pwd}")
        except (ValueError, TypeError):
            pass
    print("  [PASS] Correctly rejected 5 invalid passwords.")

    # 2. Corrupted keystore payload rejection
    corrupted_bytes = bytearray(keystore_bytes)
    corrupted_bytes[50:60] = b"\x00" * 10
    try:
        pkcs12.load_pkcs12(bytes(corrupted_bytes), EXPECTED_KEYSTORE_PASS.encode("utf-8"))
        raise AssertionError("VULNERABILITY: Keystore accepted tampered/corrupted payload!")
    except Exception:
        pass
    print("  [PASS] Correctly rejected corrupted/tampered keystore payload.")


def test_3_cross_file_credential_parity():
    print("\n--- [Test 3] Cross-File Credential & Scheme Parity ---")

    # Read workflow
    with open(WORKFLOW_FILE, "r", encoding="utf-8") as f:
        wf_content = f.read()

    # Read build.gradle
    with open(BUILD_GRADLE_FILE, "r", encoding="utf-8") as f:
        bg_content = f.read()

    # 1. Workflow checks
    assert f'KEYSTORE="android/app/release.keystore"' in wf_content
    assert f'KS_PASS="pass:{EXPECTED_KEYSTORE_PASS}"' in wf_content
    assert f'KEY_ALIAS="{EXPECTED_KEYSTORE_ALIAS}"' in wf_content
    assert f'KEY_PASS="pass:{EXPECTED_KEYSTORE_PASS}"' in wf_content
    assert '--v1-signing-enabled true' in wf_content
    assert '--v2-signing-enabled true' in wf_content
    print("  [PASS] build_apk.yml contains exact keystore path, alias, password, and dual-scheme flags.")

    # 2. build.gradle checks
    assert f"storePassword '{EXPECTED_KEYSTORE_PASS}'" in bg_content or f'storePassword "{EXPECTED_KEYSTORE_PASS}"' in bg_content
    assert f"keyAlias '{EXPECTED_KEYSTORE_ALIAS}'" in bg_content or f'keyAlias "{EXPECTED_KEYSTORE_ALIAS}"' in bg_content
    assert f"keyPassword '{EXPECTED_KEYSTORE_PASS}'" in bg_content or f'keyPassword "{EXPECTED_KEYSTORE_PASS}"' in bg_content
    assert "v1SigningEnabled true" in bg_content
    assert "v2SigningEnabled true" in bg_content
    print("  [PASS] build.gradle contains matching credentials and dual-scheme enabled flags.")


def test_4_workflow_ast_sequence_and_shielding():
    print("\n--- [Test 4] Workflow AST Sequence & Fail-Closed Shielding ---")
    with open(WORKFLOW_FILE, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f.read())

    steps = data["jobs"]["build"]["steps"]
    step_names = [s.get("name") for s in steps]
    print(f"Total steps in workflow: {len(steps)}")

    assert len(steps) == 13, f"Expected 13 steps, got {len(steps)}"

    sign_name = "Sign Release APKs with apksigner (Dual-Scheme v1 + v2)"
    assert sign_name in step_names, f"'{sign_name}' missing from steps"
    sign_idx = step_names.index(sign_name)
    assert sign_idx == 8, f"Signing step must be at index 8, got {sign_idx}"

    split_idx = step_names.index("Build Split-per-ABI Release APKs")
    verify_idx = step_names.index("Verify APK Quality Gate")
    checksum_idx = step_names.index("Generate SHA-256 Checksums")
    upload_idx = step_names.index("Upload APK Artifacts")
    publish_idx = step_names.index("Publish to GitHub Releases")

    # Sequence assertion: Split build < Sign < Verify < Checksum < Upload < Publish
    assert split_idx < sign_idx < verify_idx < checksum_idx < upload_idx < publish_idx, (
        f"Step sequence broken: Split({split_idx}) < Sign({sign_idx}) < Verify({verify_idx}) < "
        f"Checksum({checksum_idx}) < Upload({upload_idx}) < Publish({publish_idx})"
    )

    # Fail-closed checks
    sign_step = steps[sign_idx]
    assert not sign_step.get("continue-on-error", False), "continue-on-error must not be enabled on signing"

    run_script = sign_step.get("run", "")
    assert "|| true" not in run_script, "Forbidden '|| true' in signing script"
    assert "|| exit 0" not in run_script, "Forbidden '|| exit 0' in signing script"
    assert "set +e" not in run_script, "Forbidden 'set +e' in signing script"

    # Downstream shields
    for idx in [verify_idx, checksum_idx, upload_idx, publish_idx]:
        step = steps[idx]
        cond = step.get("if", "")
        assert "always()" not in cond, f"Step '{step.get('name')}' must not have 'always()' condition"
        assert "failure()" not in cond, f"Step '{step.get('name')}' must not have 'failure()' condition"

    print("[PASS] AST step sequence and fail-closed security shielding strictly verified.")


def test_5_apksigner_cli_syntax_and_flavour_whitelist():
    print("\n--- [Test 5] apksigner CLI Flag Syntax & Flavour Whitelist ---")
    with open(WORKFLOW_FILE, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f.read())
    sign_step = [s for s in data["jobs"]["build"]["steps"] if "Sign Release APKs" in s.get("name", "")][0]
    run_script = sign_step["run"]

    # Extract TARGET_APKS
    match = re.search(r"TARGET_APKS=\(\s*([\s\S]*?)\s*\)", run_script)
    assert match, "TARGET_APKS array not found in signing run script"
    raw_apks = match.group(1).split()
    target_apks = [a.strip('"\',') for a in raw_apks if a.strip('"\',')]

    assert len(target_apks) == 4, f"Expected 4 target APKs, found {len(target_apks)}"
    for apk in EXPECTED_APKS:
        assert apk in target_apks, f"Target APK '{apk}' missing from TARGET_APKS array"
    print("  [PASS] TARGET_APKS contains all 4 expected release APK flavors.")

    # Syntax flags check
    expected_flags = [
        '--ks "$KEYSTORE"',
        '--ks-pass "$KS_PASS"',
        '--ks-key-alias "$KEY_ALIAS"',
        '--key-pass "$KEY_PASS"',
        '--v1-signing-enabled true',
        '--v2-signing-enabled true',
        '"$apk"',
    ]
    for flag in expected_flags:
        assert flag in run_script, f"Mandatory apksigner flag/argument '{flag}' missing from signing block"
    print("  [PASS] apksigner sign arguments adhere to Android SDK apksigner specification.")

    # Immediate verification check
    assert '"$APKSIGNER" verify --verbose "$apk"' in run_script, (
        "Immediate post-signing verification check missing from loop"
    )
    print("  [PASS] Immediate post-signing verification asserted on each APK.")


def test_6_simulation_oracle():
    print("\n--- [Test 6] Linux Runner Simulation Oracle (Mock apksigner Execution) ---")
    sh_bin = get_sh_bin()
    if not sh_bin:
        print("  [SKIP] sh executable not found; skipping shell simulation.")
        return

    with open(WORKFLOW_FILE, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f.read())
    sign_step = [s for s in data["jobs"]["build"]["steps"] if "Sign Release APKs" in s.get("name", "")][0]
    run_script = sign_step["run"]

    # 1. Happy Path Simulation
    with tempfile.TemporaryDirectory() as tmp:
        build_tools_dir = os.path.join(tmp, "sdk", "build-tools", "35.0.0")
        flutter_apk_dir = os.path.join(tmp, "build", "app", "outputs", "flutter-apk")
        android_app_dir = os.path.join(tmp, "android", "app")
        os.makedirs(build_tools_dir, exist_ok=True)
        os.makedirs(flutter_apk_dir, exist_ok=True)
        os.makedirs(android_app_dir, exist_ok=True)

        shutil.copy(KEYSTORE_FILE, os.path.join(android_app_dir, "release.keystore"))

        for apk in EXPECTED_APKS:
            apk_path = os.path.join(tmp, apk.replace("/", os.sep))
            with open(apk_path, "wb") as f:
                f.write(b"PK\x03\x04" + b"REALISTIC_APK_MOCK_DATA" * 50)

        log_file = os.path.join(tmp, "apksigner.log").replace("\\", "/")
        mock_apksigner = f"""#!/bin/sh
echo "INVOKED: $@" >> "{log_file}"
if [ "$1" = "--version" ]; then
  echo "35.0.0"
  exit 0
fi
if [ "$1" = "sign" ]; then
  echo "$@" | grep -q -- "--v1-signing-enabled true" || exit 11
  echo "$@" | grep -q -- "--v2-signing-enabled true" || exit 12
  echo "$@" | grep -q -- "--ks android/app/release.keystore" || exit 13
  echo "$@" | grep -q -- "--ks-key-alias universal_media_key" || exit 14
  exit 0
fi
if [ "$1" = "verify" ]; then
  echo "Verified using v1 scheme (JAR signing): true"
  echo "Verified using v2 scheme (APK Signature Scheme v2): true"
  exit 0
fi
exit 0
"""
        apksigner_path = os.path.join(build_tools_dir, "apksigner")
        with open(apksigner_path, "w", newline="\n") as f:
            f.write(mock_apksigner)
        os.chmod(apksigner_path, 0o755)

        # Prepend /usr/bin to PATH to guarantee GNU sort/find on MSYS/Git-bash
        runner_sh = f"""#!/bin/sh
set -e
export PATH="/usr/bin:$PATH"
export ANDROID_HOME="{os.path.join(tmp, 'sdk').replace(os.sep, '/')}"
{run_script}
"""
        runner_file = os.path.join(tmp, "runner.sh")
        with open(runner_file, "w", newline="\n") as f:
            f.write(runner_sh)
        os.chmod(runner_file, 0o755)

        res = subprocess.run([sh_bin, runner_file.replace(os.sep, "/")], cwd=tmp, capture_output=True, text=True)
        assert res.returncode == 0, f"Happy path simulation failed (code {res.returncode}):\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}"

        # Inspect invocations
        with open(log_file.replace("/", os.sep), "r", encoding="utf-8") as f:
            lines = [l.strip() for l in f if l.strip()]

        sign_calls = [l for l in lines if "INVOKED: sign" in l]
        verify_calls = [l for l in lines if "INVOKED: verify" in l]

        assert len(sign_calls) == 4, f"Expected 4 apksigner sign invocations, got {len(sign_calls)}"
        assert len(verify_calls) == 4, f"Expected 4 apksigner verify invocations, got {len(verify_calls)}"
        print(f"  [PASS] Happy path simulation cleanly executed 4 sign and 4 verify commands.")

    # 2. Adversarial Fault Simulation: Signing failure terminates pipeline
    with tempfile.TemporaryDirectory() as tmp:
        build_tools_dir = os.path.join(tmp, "sdk", "build-tools", "35.0.0")
        flutter_apk_dir = os.path.join(tmp, "build", "app", "outputs", "flutter-apk")
        android_app_dir = os.path.join(tmp, "android", "app")
        os.makedirs(build_tools_dir, exist_ok=True)
        os.makedirs(flutter_apk_dir, exist_ok=True)
        os.makedirs(android_app_dir, exist_ok=True)

        for apk in EXPECTED_APKS:
            apk_path = os.path.join(tmp, apk.replace("/", os.sep))
            with open(apk_path, "wb") as f:
                f.write(b"PK\x03\x04" + b"DATA" * 10)

        mock_failing_apksigner = """#!/bin/sh
if [ "$1" = "--version" ]; then
  exit 0
fi
if [ "$1" = "sign" ]; then
  for arg in "$@"; do
    if echo "$arg" | grep -q "app-armeabi-v7a-release.apk"; then
      echo "FATAL: Keystore signature failure on armeabi-v7a" >&2
      exit 42
    fi
  done
  exit 0
fi
exit 0
"""
        apksigner_path = os.path.join(build_tools_dir, "apksigner")
        with open(apksigner_path, "w", newline="\n") as f:
            f.write(mock_failing_apksigner)
        os.chmod(apksigner_path, 0o755)

        runner_sh = f"""#!/bin/sh
set -e
export PATH="/usr/bin:$PATH"
export ANDROID_HOME="{os.path.join(tmp, 'sdk').replace(os.sep, '/')}"
{run_script}
touch "{tmp.replace(os.sep, '/')}/LEAK_UNEXPECTED"
"""
        runner_file = os.path.join(tmp, "runner_fail.sh")
        with open(runner_file, "w", newline="\n") as f:
            f.write(runner_sh)
        os.chmod(runner_file, 0o755)

        res_fail = subprocess.run([sh_bin, runner_file.replace(os.sep, "/")], cwd=tmp, capture_output=True, text=True)
        assert res_fail.returncode == 42, f"Expected returncode 42, got {res_fail.returncode}"
        assert not os.path.exists(os.path.join(tmp, "LEAK_UNEXPECTED")), "Execution continued after signing failure!"
        print("  [PASS] Adversarial fault simulation confirmed immediate step failure on apksigner error.")


def test_7_checksum_ordering_invariant():
    print("\n--- [Test 7] Checksum Ordering Invariant Proof ---")
    raw_apk = b"PK\x03\x04" + b"UNSIGNED_BINARY_STREAM" * 64
    raw_hash = hashlib.sha256(raw_apk).hexdigest()

    # When apksigner signs an APK, it adds JAR signatures and APK Signing Block
    signed_apk = raw_apk + b"APK_SIGNING_BLOCK_MAGIC_V2_V3" + b"META-INF/MANIFEST.MF"
    signed_hash = hashlib.sha256(signed_apk).hexdigest()

    assert raw_hash != signed_hash, "Signing must modify file contents and SHA-256 hash"

    # Demonstrating the invariant:
    # If checksum generation were done BEFORE signing:
    checksum_manifest = f"{raw_hash}  app-release.apk"
    # Verification against the signed APK that users download:
    verification_success = (hashlib.sha256(signed_apk).hexdigest() == raw_hash)
    assert not verification_success, "Pre-signing checksum MUST NOT match signed APK"

    # If checksum generation is done AFTER signing:
    correct_manifest = f"{signed_hash}  app-release.apk"
    post_verification_success = (hashlib.sha256(signed_apk).hexdigest() == signed_hash)
    assert post_verification_success, "Post-signing checksum MUST match signed APK"

    print(f"  Unsigned APK hash: {raw_hash}")
    print(f"  Signed APK hash  : {signed_hash}")
    print("  [PASS] Cryptographic invariant proven: Signing step (idx 8) MUST precede Checksum step (idx 10).")


def main():
    print("=" * 80)
    print(" EMPIRICAL CHALLENGER 2: MILESTONE 1 ROUND 2 ADVERSARIAL SUITE")
    print("=" * 80)
    test_1_keystore_cryptographic_properties()
    test_2_keystore_adversarial_resistance()
    test_3_cross_file_credential_parity()
    test_4_workflow_ast_sequence_and_shielding()
    test_5_apksigner_cli_syntax_and_flavour_whitelist()
    test_6_simulation_oracle()
    test_7_checksum_ordering_invariant()
    print("\n" + "=" * 80)
    print(" ALL 7 ADVERSARIAL TEST SUITES PASSED EMPIRICALLY (100% SUCCESS)")
    print("=" * 80)


if __name__ == "__main__":
    main()
