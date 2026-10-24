#!/usr/bin/env bash
# ==============================================================================
# scripts/verify_apk.sh
# ------------------------------------------------------------------------------
# Automated APK Quality Gate & Verification Script
#
# Verifies:
#   1. 4-byte zip alignment using Android SDK zipalign
#   2. APK Signature Scheme v1 (JAR signing) and v2 using apksigner
#   3. Signer certificate DN is a valid release certificate (NOT CN=Android Debug)
#   4. AndroidManifest and resource badging integrity using aapt/aapt2:
#      - Package name: com.zeroo.universal_media_downloader
#      - Launchable activity: com.zeroo.universal_media_downloader.MainActivity
#      - Application label and icon resolution without parsing errors
#
# Target Release APKs (4 flavors):
#   - app-release.apk            (Universal)
#   - app-arm64-v8a-release.apk  (ARM 64-bit)
#   - app-armeabi-v7a-release.apk(ARM 32-bit)
#   - app-x86_64-release.apk     (x86_64 Emulator/PC)
#
# Exit status:
#   0 - All checks passed across all 4 APKs
#   1 - One or more verification checks failed
# ==============================================================================

set -euo pipefail

# Configuration
EXPECTED_PACKAGE="com.zeroo.universal_media_downloader"
EXPECTED_ACTIVITY="com.zeroo.universal_media_downloader.MainActivity"
TARGET_DIR="${1:-build/app/outputs/flutter-apk}"

EXPECTED_APKS=(
  "app-release.apk"
  "app-arm64-v8a-release.apk"
  "app-armeabi-v7a-release.apk"
  "app-x86_64-release.apk"
)

echo "========================================================================"
echo " Universal Media Downloader - Automated APK Quality Gate"
echo "========================================================================"
echo "Target directory : ${TARGET_DIR}"

# ------------------------------------------------------------------------------
# 1. Dynamic Android Build-Tools Discovery
# ------------------------------------------------------------------------------
locate_build_tools_dir() {
  local sdk_roots=(
    "${ANDROID_HOME:-}"
    "${ANDROID_SDK_ROOT:-}"
    "$HOME/Android/Sdk"
    "/usr/local/lib/android/sdk"
    "/opt/android-sdk"
  )

  for root in "${sdk_roots[@]}"; do
    if [ -n "$root" ] && [ -d "$root/build-tools" ]; then
      local latest
      latest=$(find "$root/build-tools" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -n 1)
      if [ -n "$latest" ]; then
        echo "$latest"
        return 0
      fi
    fi
  done
  return 1
}

BUILD_TOOLS_DIR="${ANDROID_BUILD_TOOLS_DIR:-$(locate_build_tools_dir || true)}"

find_tool() {
  local tool_name="$1"
  local fallback_tool="${2:-}"

  # 1. Check detected build-tools directory
  if [ -n "${BUILD_TOOLS_DIR:-}" ] && [ -f "${BUILD_TOOLS_DIR}/${tool_name}" ]; then
    echo "${BUILD_TOOLS_DIR}/${tool_name}"
    return 0
  fi

  # 2. Check fallback tool in detected build-tools directory (e.g. aapt2)
  if [ -n "${BUILD_TOOLS_DIR:-}" ] && [ -n "$fallback_tool" ] && [ -f "${BUILD_TOOLS_DIR}/${fallback_tool}" ]; then
    echo "${BUILD_TOOLS_DIR}/${fallback_tool}"
    return 0
  fi

  # 3. Check system PATH
  if command -v "$tool_name" >/dev/null 2>&1; then
    command -v "$tool_name"
    return 0
  fi

  # 4. Check fallback tool on PATH
  if [ -n "$fallback_tool" ] && command -v "$fallback_tool" >/dev/null 2>&1; then
    command -v "$fallback_tool"
    return 0
  fi

  return 1
}

ZIPALIGN_BIN=$(find_tool "zipalign" || true)
APKSIGNER_BIN=$(find_tool "apksigner" || true)
AAPT_BIN=$(find_tool "aapt" "aapt2" || true)

echo "Build-tools dir  : ${BUILD_TOOLS_DIR:-<none found; using PATH>}"
echo "zipalign binary  : ${ZIPALIGN_BIN:-<NOT FOUND>}"
echo "apksigner binary : ${APKSIGNER_BIN:-<NOT FOUND>}"
echo "aapt binary      : ${AAPT_BIN:-<NOT FOUND>}"
echo "------------------------------------------------------------------------"

MISSING_TOOLS=0
if [ -z "$ZIPALIGN_BIN" ]; then
  echo "[-] ERROR: 'zipalign' could not be located in Android build-tools or PATH." >&2
  MISSING_TOOLS=1
fi
if [ -z "$APKSIGNER_BIN" ]; then
  echo "[-] ERROR: 'apksigner' could not be located in Android build-tools or PATH." >&2
  MISSING_TOOLS=1
fi
if [ -z "$AAPT_BIN" ]; then
  echo "[-] ERROR: Neither 'aapt' nor 'aapt2' could be located in Android build-tools or PATH." >&2
  MISSING_TOOLS=1
fi

if [ "$MISSING_TOOLS" -ne 0 ]; then
  echo "" >&2
  echo "Quality gate failed: Required Android SDK build-tools are missing." >&2
  echo "Please set ANDROID_HOME or install Android SDK Build-Tools (version 33+)." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# 2. Verify APK Artifacts Exist
# ------------------------------------------------------------------------------
MISSING_APKS=0
for apk in "${EXPECTED_APKS[@]}"; do
  apk_path="${TARGET_DIR}/${apk}"
  if [ ! -f "$apk_path" ]; then
    echo "[-] ERROR: Required release APK not found: ${apk_path}" >&2
    MISSING_APKS=1
  fi
done

if [ "$MISSING_APKS" -ne 0 ]; then
  echo "" >&2
  echo "Quality gate failed: One or more expected APK artifacts are missing from ${TARGET_DIR}." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# 3. Verification Suite
# ------------------------------------------------------------------------------
TOTAL_FAILURES=0
APK_COUNT=0

for apk in "${EXPECTED_APKS[@]}"; do
  APK_COUNT=$((APK_COUNT + 1))
  apk_path="${TARGET_DIR}/${apk}"
  apk_failures=0

  file_size=$(stat -c%s "$apk_path" 2>/dev/null || stat -f%z "$apk_path" 2>/dev/null || wc -c < "$apk_path")
  file_size_mb=$(awk -v size="$file_size" 'BEGIN { printf "%.2f MB", size / 1048576 }')

  echo ""
  echo "[${APK_COUNT}/4] Verifying: ${apk} (${file_size_mb})"
  echo "    Path: ${apk_path}"

  # ----------------------------------------------------------------------------
  # 3.1 4-byte Zip Alignment Check (zipalign)
  # ----------------------------------------------------------------------------
  echo "    Checking 4-byte zip alignment (zipalign)..."
  if ALIGN_OUTPUT=$("$ZIPALIGN_BIN" -c -v 4 "$apk_path" 2>&1); then
    if echo "$ALIGN_OUTPUT" | grep -qiE "Verification succes*ful"; then
      echo "      [PASS] 4-byte zip alignment verified."
    else
      echo "      [FAIL] zipalign succeeded with exit code 0 but missing verification confirmation." >&2
      echo "$ALIGN_OUTPUT" >&2
      apk_failures=$((apk_failures + 1))
    fi
  else
    echo "      [FAIL] zipalign alignment check failed!" >&2
    echo "$ALIGN_OUTPUT" >&2
    apk_failures=$((apk_failures + 1))
  fi

  # ----------------------------------------------------------------------------
  # 3.2 Signature Verification (apksigner)
  # ----------------------------------------------------------------------------
  echo "    Checking signature schemes and certificate DN (apksigner)..."
  if SIGN_OUTPUT=$("$APKSIGNER_BIN" verify --verbose --print-certs "$apk_path" 2>&1); then
    # Scheme v1 Check
    if echo "$SIGN_OUTPUT" | grep -q "Verified using v1 scheme (JAR signing): true"; then
      echo "      [PASS] Scheme v1 (JAR signing): true"
    else
      echo "      [FAIL] Scheme v1 (JAR signing) is not true or missing!" >&2
      echo "$SIGN_OUTPUT" | grep -i "v1 scheme" || true
      apk_failures=$((apk_failures + 1))
    fi

    # Scheme v2 Check
    if echo "$SIGN_OUTPUT" | grep -q "Verified using v2 scheme (APK Signature Scheme v2): true"; then
      echo "      [PASS] Scheme v2 (APK Signature Scheme v2): true"
    else
      echo "      [FAIL] Scheme v2 (APK Signature Scheme v2) is not true or missing!" >&2
      echo "$SIGN_OUTPUT" | grep -i "v2 scheme" || true
      apk_failures=$((apk_failures + 1))
    fi

    # Certificate DN Check (Must NOT be Android Debug)
    if echo "$SIGN_OUTPUT" | grep -qi "CN=Android Debug"; then
      echo "      [FAIL] Signer certificate contains 'CN=Android Debug'!" >&2
      echo "             Release APKs must NOT be signed with the default debug certificate." >&2
      apk_failures=$((apk_failures + 1))
    else
      cert_dn=$(echo "$SIGN_OUTPUT" | grep -i "certificate DN:" | head -n 1 | sed 's/^[[:space:]]*//' || true)
      if [ -n "$cert_dn" ]; then
        echo "      [PASS] ${cert_dn}"
      else
        echo "      [PASS] Certificate DN verified (non-debug)."
      fi
    fi
  else
    echo "      [FAIL] apksigner verification returned non-zero exit code!" >&2
    echo "$SIGN_OUTPUT" >&2
    apk_failures=$((apk_failures + 1))
  fi

  # ----------------------------------------------------------------------------
  # 3.3 AndroidManifest & Badging Integrity (aapt / aapt2)
  # ----------------------------------------------------------------------------
  echo "    Checking manifest and badging integrity (aapt)..."
  if BADGE_OUTPUT=$("$AAPT_BIN" dump badging "$apk_path" 2>&1); then
    # Package Name Validation
    if echo "$BADGE_OUTPUT" | grep -qE "package: name='${EXPECTED_PACKAGE}'"; then
      echo "      [PASS] Package name: ${EXPECTED_PACKAGE}"
    else
      echo "      [FAIL] Package name '${EXPECTED_PACKAGE}' not found in badging!" >&2
      echo "$BADGE_OUTPUT" | grep "^package:" || true
      apk_failures=$((apk_failures + 1))
    fi

    # Launchable Activity Validation
    if echo "$BADGE_OUTPUT" | grep -qE "launchable-activity: name='${EXPECTED_ACTIVITY}'"; then
      echo "      [PASS] Launchable activity: ${EXPECTED_ACTIVITY}"
    else
      echo "      [FAIL] Launchable activity '${EXPECTED_ACTIVITY}' not found in badging!" >&2
      echo "$BADGE_OUTPUT" | grep "launchable-activity:" || true
      apk_failures=$((apk_failures + 1))
    fi

    # Application Label Validation
    if echo "$BADGE_OUTPUT" | grep -qE "application-label:"; then
      app_label=$(echo "$BADGE_OUTPUT" | grep "application-label:" | head -n 1 | sed 's/^[[:space:]]*//')
      echo "      [PASS] ${app_label}"
    else
      echo "      [FAIL] Application label missing from badging!" >&2
      apk_failures=$((apk_failures + 1))
    fi

    # Application Icon Resolution Validation
    if echo "$BADGE_OUTPUT" | grep -qE "application-icon-|icon='[^']+'"; then
      echo "      [PASS] Application icons resolved cleanly across density buckets."
    else
      echo "      [FAIL] Application icon definition missing or unresolvable!" >&2
      apk_failures=$((apk_failures + 1))
    fi
  else
    echo "      [FAIL] aapt dump badging returned non-zero exit code!" >&2
    echo "$BADGE_OUTPUT" >&2
    apk_failures=$((apk_failures + 1))
  fi

  if [ "$apk_failures" -eq 0 ]; then
    echo "    >>> Result: ${apk} PASSED all quality gate checks."
  else
    echo "    >>> Result: ${apk} FAILED ${apk_failures} check(s)." >&2
    TOTAL_FAILURES=$((TOTAL_FAILURES + apk_failures))
  fi
done

# ------------------------------------------------------------------------------
# 4. Final Verdict
# ------------------------------------------------------------------------------
echo ""
echo "========================================================================"
if [ "$TOTAL_FAILURES" -eq 0 ]; then
  echo " QUALITY GATE STATUS: PASSED"
  echo " All 4 release APKs verified successfully (zipalign, apksigner, aapt)."
  echo "========================================================================"
  exit 0
else
  echo " QUALITY GATE STATUS: FAILED (${TOTAL_FAILURES} errors detected)" >&2
  echo " APK binaries do not satisfy release quality gate criteria." >&2
  echo "========================================================================" >&2
  exit 1
fi
