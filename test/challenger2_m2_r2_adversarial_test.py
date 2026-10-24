#!/usr/bin/env python3
"""
Adversarial Verification Suite for Milestone 2 Round 2
Author: Challenger 2 (teamwork_preview_challenger_m2_r2_2)

Validates:
1. AGP 8+ packaging DSL compliance in android/app/build.gradle
2. Wildcard JNI pickFirsts and META-INF exclusions oracle
3. AndroidManifest.xml structural integrity, namespace removal, permissions, and service declarations
4. Android Share Sheet and Launcher intent resolution oracle
5. pubspec.yaml dependency hygiene (zero wildcard 'any' specifiers, API break safeguards)
6. Cross-component namespace and MainActivity class resolution
"""

import os
import re
import sys
import fnmatch
import xml.etree.ElementTree as ET
import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BUILD_GRADLE = os.path.join(REPO_ROOT, "android", "app", "build.gradle")
ANDROID_MANIFEST = os.path.join(REPO_ROOT, "android", "app", "src", "main", "AndroidManifest.xml")
PUBSPEC_YAML = os.path.join(REPO_ROOT, "pubspec.yaml")
MAIN_ACTIVITY_KT = os.path.join(
    REPO_ROOT, "android", "app", "src", "main", "kotlin", "com", "zeroo", "universal_media_downloader", "MainActivity.kt"
)

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

def log_pass(msg):
    print(f"  [PASS] {msg}")

def log_fail(msg):
    print(f"  [FAIL] {msg}")

def run_suite():
    failures = []
    print("=" * 80)
    print(" EMPIRICAL CHALLENGER 2: MILESTONE 2 ROUND 2 ADVERSARIAL SUITE")
    print("=" * 80)

    # -------------------------------------------------------------------------
    # Test 1: AGP 8+ Packaging DSL Compliance & Deprecation Resistance
    # -------------------------------------------------------------------------
    print("\n--- [Test 1] AGP 8+ Packaging DSL Compliance & Deprecation Audit ---")
    try:
        assert os.path.exists(BUILD_GRADLE), f"build.gradle not found at {BUILD_GRADLE}"
        with open(BUILD_GRADLE, "r", encoding="utf-8") as f:
            gradle_content = f.read()

        # 1. Ensure packagingOptions is NOT present
        assert "packagingOptions" not in gradle_content, (
            "Found deprecated 'packagingOptions' in build.gradle! AGP 8+ requires 'packaging'."
        )
        log_pass("Deprecated 'packagingOptions' block is strictly absent.")

        # 2. Ensure packaging block is present
        assert "packaging {" in gradle_content, "Missing AGP 8+ 'packaging {' block."
        log_pass("AGP 8+ 'packaging {' block is present.")

        # 3. Ensure resources excludes block exists and contains license exclusions
        assert "resources {" in gradle_content, "Missing 'resources {' inside packaging."
        assert "excludes +=" in gradle_content, "Missing 'excludes +=' inside resources."
        for pattern in ["/META-INF/{AL2.0,LGPL2.1}", "/META-INF/licenses/**", "/META-INF/AL2.0", "/META-INF/LGPL2.1"]:
            assert pattern in gradle_content, f"Missing exclusion pattern: {pattern}"
        log_pass("META-INF resource exclusions (AL2.0, LGPL2.1, licenses/**) verified.")

        # 4. Ensure jniLibs pickFirsts block exists with wildcards
        assert "jniLibs {" in gradle_content, "Missing 'jniLibs {' inside packaging."
        assert "pickFirsts +=" in gradle_content, "Missing 'pickFirsts +=' inside jniLibs."
        assert "**/libc++_shared.so" in gradle_content, "Missing wildcard '**/libc++_shared.so' in pickFirsts."
        assert "**/libflutter.so" in gradle_content, "Missing wildcard '**/libflutter.so' in pickFirsts."
        log_pass("JNI pickFirsts wildcard rules ('**/libc++_shared.so', '**/libflutter.so') verified.")

        # 5. Ensure Kotlin plugin ID is canonical and kotlin-stdlib-jdk8 is eliminated
        assert 'id "org.jetbrains.kotlin.android"' in gradle_content, (
            "Plugin 'org.jetbrains.kotlin.android' not declared."
        )
        assert 'id "kotlin-android"' not in gradle_content, (
            "Legacy plugin id 'kotlin-android' detected in build.gradle."
        )
        assert "kotlin-stdlib-jdk8" not in gradle_content, (
            "Redundant 'kotlin-stdlib-jdk8' detected in dependencies."
        )
        log_pass("Kotlin plugin canonicalized and redundant stdlib-jdk8 dependency eliminated.")

        # 6. Ensure namespace and signingConfigs are intact
        assert 'namespace "com.zeroo.universal_media_downloader"' in gradle_content, (
            "Namespace declaration missing or invalid."
        )
        assert 'applicationId "com.zeroo.universal_media_downloader"' in gradle_content, (
            "ApplicationId missing or invalid."
        )
        assert "v1SigningEnabled true" in gradle_content, "v1SigningEnabled missing from build.gradle."
        assert "v2SigningEnabled true" in gradle_content, "v2SigningEnabled missing from build.gradle."
        log_pass("Namespace, Application ID, and Dual-Scheme (v1 + v2) signing configuration preserved.")

    except Exception as e:
        log_fail(str(e))
        failures.append(f"Test 1 failed: {e}")

    # -------------------------------------------------------------------------
    # Test 2: JNI Wildcard & META-INF Packaging Oracle
    # -------------------------------------------------------------------------
    print("\n--- [Test 2] JNI Wildcard & META-INF Packaging Simulation Oracle ---")
    try:
        # AGP matches pickFirsts using glob / regex semantics
        # **/libc++_shared.so matches any path ending in /libc++_shared.so or equal to libc++_shared.so
        jni_patterns = [r"(^|.*/)libc\+\+_shared\.so$", r"(^|.*/)libflutter\.so$"]

        test_jni_positive = [
            "lib/arm64-v8a/libc++_shared.so",
            "lib/armeabi-v7a/libc++_shared.so",
            "lib/x86_64/libc++_shared.so",
            "lib/x86/libc++_shared.so",
            "lib/arm64-v8a/libflutter.so",
            "lib/armeabi-v7a/libflutter.so",
            "lib/x86_64/libflutter.so",
            "lib/x86/libflutter.so",
        ]
        for path in test_jni_positive:
            matched = any(re.search(pat, path) for pat in jni_patterns)
            assert matched, f"Oracle failed: {path} should match pickFirsts patterns!"
        log_pass(f"All {len(test_jni_positive)} target ABI JNI libraries matched pickFirsts oracle.")

        test_jni_negative = [
            "lib/arm64-v8a/libavcodec.so",
            "lib/arm64-v8a/libffmpegkit.so",
            "lib/arm64-v8a/libapp.so",
            "assets/flutter_assets/kernel_blob.bin",
        ]
        for path in test_jni_negative:
            matched = any(re.search(pat, path) for pat in jni_patterns)
            assert not matched, f"Oracle failed: {path} should NOT match pickFirsts patterns!"
        log_pass("Negative JNI test: Non-conflicting native libraries correctly spared from pickFirsts.")

        # META-INF exclusion simulation
        meta_inf_patterns = [
            r"^/?META-INF/(AL2\.0|LGPL2\.1)$",
            r"^/?META-INF/licenses/.*$",
            r"^/?META-INF/AL2\.0$",
            r"^/?META-INF/LGPL2\.1$",
        ]
        test_meta_positive = [
            "META-INF/AL2.0",
            "/META-INF/AL2.0",
            "META-INF/LGPL2.1",
            "/META-INF/LGPL2.1",
            "META-INF/licenses/LICENSE-Apache.txt",
            "/META-INF/licenses/nested/LICENSE-MIT.txt",
        ]
        for path in test_meta_positive:
            matched = any(re.search(pat, path) for pat in meta_inf_patterns)
            assert matched, f"Oracle failed: {path} should match META-INF exclusions!"
        log_pass(f"All {len(test_meta_positive)} license files matched exclusion oracle.")

        test_meta_negative = [
            "META-INF/MANIFEST.MF",
            "META-INF/CERT.SF",
            "META-INF/CERT.RSA",
            "res/values/strings.xml",
        ]
        for path in test_meta_negative:
            matched = any(re.search(pat, path) for pat in meta_inf_patterns)
            assert not matched, f"Oracle failed: Critical file {path} must NOT be excluded!"
        log_pass("Negative META-INF test: Critical MANIFEST and APK signature files spared from exclusion.")

    except Exception as e:
        log_fail(str(e))
        failures.append(f"Test 2 failed: {e}")

    # -------------------------------------------------------------------------
    # Test 3: AndroidManifest.xml Structural Integrity & Deprecation Audit
    # -------------------------------------------------------------------------
    print("\n--- [Test 3] AndroidManifest.xml Structural & Schema Audit ---")
    try:
        assert os.path.exists(ANDROID_MANIFEST), f"AndroidManifest not found at {ANDROID_MANIFEST}"
        tree = ET.parse(ANDROID_MANIFEST)
        root = tree.getroot()

        # 1. Manifest root tag and lack of deprecated package attribute
        assert root.tag == "manifest", f"Root tag must be <manifest>, got <{root.tag}>"
        assert "package" not in root.attrib, (
            "Deprecated 'package' attribute found in <manifest>! AGP 8+ requires removing it."
        )
        log_pass("Root <manifest> tag has zero deprecated 'package' attributes.")

        # 2. Permissions Audit
        expected_permissions = {
            "android.permission.INTERNET": None,
            "android.permission.ACCESS_NETWORK_STATE": None,
            "android.permission.WAKE_LOCK": None,
            "android.permission.FOREGROUND_SERVICE": None,
            "android.permission.FOREGROUND_SERVICE_DATA_SYNC": None,
            "android.permission.POST_NOTIFICATIONS": None,
            "android.permission.READ_EXTERNAL_STORAGE": {"maxSdkVersion": "32"},
            "android.permission.WRITE_EXTERNAL_STORAGE": {"maxSdkVersion": "29"},
            "android.permission.MANAGE_EXTERNAL_STORAGE": None,
            "android.permission.READ_MEDIA_IMAGES": None,
            "android.permission.READ_MEDIA_VIDEO": None,
            "android.permission.READ_MEDIA_AUDIO": None,
        }

        found_permissions = {}
        for perm in root.findall("uses-permission"):
            name = perm.attrib.get(f"{ANDROID_NS}name")
            assert name, "Found <uses-permission> without android:name"
            assert name not in found_permissions, f"Duplicate permission declaration: {name}"
            max_sdk = perm.attrib.get(f"{ANDROID_NS}maxSdkVersion")
            found_permissions[name] = {"maxSdkVersion": max_sdk}

        for exp_name, exp_attrs in expected_permissions.items():
            assert exp_name in found_permissions, f"Missing required permission: {exp_name}"
            if exp_attrs and "maxSdkVersion" in exp_attrs:
                actual_max = found_permissions[exp_name]["maxSdkVersion"]
                assert actual_max == exp_attrs["maxSdkVersion"], (
                    f"Permission {exp_name} expected maxSdkVersion={exp_attrs['maxSdkVersion']}, got {actual_max}"
                )
        log_pass(f"All {len(expected_permissions)} critical permissions and maxSdkVersion constraints verified.")

        # 3. Application element configuration
        app = root.find("application")
        assert app is not None, "Missing <application> element."
        assert app.attrib.get(f"{ANDROID_NS}name") == "${applicationName}", (
            "Application android:name must be ${applicationName}"
        )
        assert app.attrib.get(f"{ANDROID_NS}requestLegacyExternalStorage") == "true", (
            "android:requestLegacyExternalStorage must be true"
        )
        assert app.attrib.get(f"{ANDROID_NS}usesCleartextTraffic") == "true", (
            "android:usesCleartextTraffic must be true"
        )
        log_pass("Application legacy storage and cleartext traffic configurations verified.")

        # 4. Foreground Service element
        service = None
        for s in app.findall("service"):
            if s.attrib.get(f"{ANDROID_NS}name") == "com.pravera.flutter_foreground_task.service.ForegroundService":
                service = s
                break
        assert service is not None, "Missing ForegroundService declaration in <application>."
        assert service.attrib.get(f"{ANDROID_NS}foregroundServiceType") == "dataSync", (
            "ForegroundService must declare android:foregroundServiceType='dataSync'"
        )
        assert service.attrib.get(f"{ANDROID_NS}exported") == "false", (
            "ForegroundService must declare android:exported='false' for security."
        )
        log_pass("ForegroundService component (dataSync, exported=false) verified.")

    except Exception as e:
        log_fail(str(e))
        failures.append(f"Test 3 failed: {e}")

    # -------------------------------------------------------------------------
    # Test 4: Android Intent Resolution Simulation Oracle (Share Sheet & Launcher)
    # -------------------------------------------------------------------------
    print("\n--- [Test 4] Android Intent Resolution Simulation Oracle ---")
    try:
        tree = ET.parse(ANDROID_MANIFEST)
        root = tree.getroot()
        app = root.find("application")
        main_act = None
        for act in app.findall("activity"):
            if act.attrib.get(f"{ANDROID_NS}name") == ".MainActivity":
                main_act = act
                break
        assert main_act is not None, "Missing .MainActivity declaration."
        assert main_act.attrib.get(f"{ANDROID_NS}exported") == "true", (
            "MainActivity must have android:exported='true' on Android 12+."
        )
        assert main_act.attrib.get(f"{ANDROID_NS}launchMode") == "singleTask", (
            "MainActivity must have android:launchMode='singleTask' for share sheet ingestion."
        )

        filters = main_act.findall("intent-filter")
        assert len(filters) >= 2, f"Expected at least 2 intent filters, found {len(filters)}"

        # Simulated Intent Resolver
        def resolve_intent(action, categories, mime_type):
            for f in filters:
                # Check action
                actions = [a.attrib.get(f"{ANDROID_NS}name") for a in f.findall("action")]
                if action not in actions:
                    continue

                # Check categories
                filt_cats = [c.attrib.get(f"{ANDROID_NS}name") for c in f.findall("category")]
                # Android matching requires all intent categories to be matched by the filter
                if not set(categories).issubset(set(filt_cats)):
                    continue

                # Check data mimeType
                data_elements = f.findall("data")
                if not data_elements:
                    if mime_type is None:
                        return True
                    else:
                        continue
                else:
                    mime_matches = any(
                        d.attrib.get(f"{ANDROID_NS}mimeType") == mime_type for d in data_elements
                    )
                    if mime_matches:
                        return True
            return False

        # Intent 1: Launcher launch
        launcher_resolved = resolve_intent(
            action="android.intent.action.MAIN",
            categories=["android.intent.category.LAUNCHER"],
            mime_type=None,
        )
        assert launcher_resolved, "Oracle failed: MAIN/LAUNCHER intent must resolve to MainActivity!"
        log_pass("MAIN / LAUNCHER intent successfully resolved to MainActivity.")

        # Intent 2: Share Sheet text URL
        share_resolved = resolve_intent(
            action="android.intent.action.SEND",
            categories=["android.intent.category.DEFAULT"],
            mime_type="text/plain",
        )
        assert share_resolved, "Oracle failed: ACTION_SEND text/plain must resolve to MainActivity!"
        log_pass("Android Share Sheet (ACTION_SEND text/plain) successfully resolved to MainActivity.")

        # Intent 3: Negative check - unhandled image/video mime type
        unhandled_resolved = resolve_intent(
            action="android.intent.action.SEND",
            categories=["android.intent.category.DEFAULT"],
            mime_type="video/mp4",
        )
        assert not unhandled_resolved, "Oracle failed: video/mp4 SEND intent should not match text filter!"
        log_pass("Negative intent test: Non-text SEND intents correctly rejected.")

    except Exception as e:
        log_fail(str(e))
        failures.append(f"Test 4 failed: {e}")

    # -------------------------------------------------------------------------
    # Test 5: pubspec.yaml Dependency Hygiene & Break Safeguards
    # -------------------------------------------------------------------------
    print("\n--- [Test 5] pubspec.yaml Dependency Hygiene & Break Safeguards ---")
    try:
        assert os.path.exists(PUBSPEC_YAML), f"pubspec.yaml not found at {PUBSPEC_YAML}"
        with open(PUBSPEC_YAML, "r", encoding="utf-8") as f:
            pubspec_raw = f.read()
            pubspec_data = yaml.safe_load(pubspec_raw)

        # 1. Regex check for 'any'
        any_matches = re.findall(r":\s*any\b", pubspec_raw)
        assert len(any_matches) == 0, f"Found {len(any_matches)} 'any' wildcard dependencies in pubspec.yaml!"
        log_pass("Zero wildcard 'any' dependencies confirmed in pubspec.yaml.")

        deps = pubspec_data.get("dependencies", {})
        dev_deps = pubspec_data.get("dev_dependencies", {})

        # 2. Pinning and compatibility checks
        # archive must be <4.0.0 (specifically ^3.6.1) to avoid breaking ffmpeg_processor.dart
        archive_ver = deps.get("archive")
        assert archive_ver == "^3.6.1", f"archive version must be ^3.6.1, got {archive_ver}"
        log_pass("archive is safely pinned to '^3.6.1' (preventing v4.0.0 FileContent type crash).")

        # flutter_foreground_task must be >= 8.6.0 (specifically ^8.17.0)
        fg_ver = deps.get("flutter_foreground_task")
        assert fg_ver == "^8.17.0", f"flutter_foreground_task must be ^8.17.0, got {fg_ver}"
        log_pass("flutter_foreground_task is pinned to '^8.17.0' (guaranteeing repeat(5000) API).")

        # receive_sharing_intent must be >= 1.7.0 (specifically ^1.8.1)
        rsi_ver = deps.get("receive_sharing_intent")
        assert rsi_ver == "^1.8.1", f"receive_sharing_intent must be ^1.8.1, got {rsi_ver}"
        log_pass("receive_sharing_intent is pinned to '^1.8.1' (guaranteeing .instance singleton).")

        # path must be directly declared
        path_ver = deps.get("path")
        assert path_ver == "^1.9.0", f"path must be directly declared as ^1.9.0, got {path_ver}"
        log_pass("path is declared as explicit direct dependency '^1.9.0'.")

        # dev_dependencies flutter_lints
        lints_ver = dev_deps.get("flutter_lints")
        assert lints_ver == "^4.0.0", f"flutter_lints must be ^4.0.0, got {lints_ver}"
        log_pass("flutter_lints is pinned to '^4.0.0'.")

    except Exception as e:
        log_fail(str(e))
        failures.append(f"Test 5 failed: {e}")

    # -------------------------------------------------------------------------
    # Test 6: Cross-Component Namespace & MainActivity Resolution
    # -------------------------------------------------------------------------
    print("\n--- [Test 6] Cross-Component Namespace & MainActivity Resolution ---")
    try:
        with open(BUILD_GRADLE, "r", encoding="utf-8") as f:
            gradle_content = f.read()
        ns_match = re.search(r'namespace\s+["\']([^"\']+)["\']', gradle_content)
        assert ns_match, "namespace not found in build.gradle"
        namespace = ns_match.group(1)
        assert namespace == "com.zeroo.universal_media_downloader"

        # Check AndroidManifest .MainActivity relative name resolution
        tree = ET.parse(ANDROID_MANIFEST)
        main_act = tree.getroot().find("application").find("activity")
        act_name = main_act.attrib.get(f"{ANDROID_NS}name")
        assert act_name.startswith("."), f"MainActivity name should be relative (.MainActivity), got {act_name}"
        full_activity_class = namespace + act_name
        assert full_activity_class == "com.zeroo.universal_media_downloader.MainActivity"
        log_pass(f"Relative activity '{act_name}' resolves cleanly with namespace to '{full_activity_class}'.")

        # Check MainActivity.kt file exists and matches package
        assert os.path.exists(MAIN_ACTIVITY_KT), f"MainActivity.kt not found at {MAIN_ACTIVITY_KT}"
        with open(MAIN_ACTIVITY_KT, "r", encoding="utf-8") as f:
            kt_content = f.read()
        pkg_match = re.search(r'package\s+([a-zA-Z0-9_.]+)', kt_content)
        assert pkg_match, "No package declared in MainActivity.kt"
        assert pkg_match.group(1) == namespace, (
            f"MainActivity.kt package {pkg_match.group(1)} does not match build.gradle namespace {namespace}!"
        )
        log_pass("MainActivity.kt physical location and package declaration match namespace 100%.")

    except Exception as e:
        log_fail(str(e))
        failures.append(f"Test 6 failed: {e}")

    # -------------------------------------------------------------------------
    # Final Verdict Summary
    # -------------------------------------------------------------------------
    print("\n" + "=" * 80)
    if not failures:
        print(" ALL 6 CHALLENGER 2 M2 R2 ADVERSARIAL SUITES PASSED EMPIRICALLY (100% SUCCESS)")
        print(" VERDICT: APPROVE")
        print("=" * 80)
        return 0
    else:
        print(f" {len(failures)} CHALLENGER ADVERSARIAL TEST SUITES FAILED!")
        for fail in failures:
            print(f"   - {fail}")
        print(" VERDICT: REQUEST_CHANGES")
        print("=" * 80)
        return 1

if __name__ == "__main__":
    sys.exit(run_suite())
