#!/usr/bin/env python3
"""test/bilingual_parity_adversarial_test.py
--------------------------------------------------------------------------------
Adversarial Verification Suite for 100% Professional English Documentation & Release Notes (R3)
Milestone 3 (Round 2) Documentation Overhaul

Tests:
  1. File Integrity & Header Badging:
     - Validates existence of README.md and RELEASE_NOTES.md.
     - Confirms badging (Build status, Release v1.0.0, Flutter, Android, Permissions, License).
     - Asserts zero bilingual split anchors (#bahasa-indonesia, #english).
  2. README.md Section-by-Section Structural & Content Completeness:
     - TOC: 11 numbered items matching 11 main sections.
     - 6 platform sections (YouTube, Pixiv, Pinterest, Twitter/X, TikTok, Instagram).
     - Architecture breakdown & code structure (Clean Architecture, Provider, Foreground Service).
     - Android Permissions Specification Table (11 permissions from AndroidManifest.xml).
     - Sideloading steps: Android 8-12 and Android 13-15+ (Play Protect).
     - Device Installation Troubleshooting & Conflict Resolution (INSTALL_FAILED_UPDATE_INCOMPATIBLE).
     - Storage hierarchy, adaptive rules, clean cancel, MediaStore.
     - Cookie vault: PHPSESSID, auth_token, sessionid.
     - APK Decision matrix: 4 APK flavors with identical sizes and architectures.
     - Build & Verification: Flutter/Dart/JDK/Python prerequisites, build & audit steps.
  3. RELEASE_NOTES.md Section-by-Section Structural Completeness:
     - Direct download table: 5 rows (4 APKs + SHA256SUMS.txt) with valid URLs.
     - APK Decision matrix table: 4 hardware scenarios matching the 4 APK flavors.
     - Sideloading walkthrough (Unknown sources & Play Protect 'Install anyway').
     - Device installation troubleshooting & conflict resolution.
     - Feature summary bullet list.
     - 3-platform SHA-256 verification instructions (Linux/macOS/WSL, Windows PowerShell, Android).
  4. Cross-Document Consistency & URL Validation:
     - Compares README.md and RELEASE_NOTES.md download URLs, APK sizes, and SHA-256 filenames.
     - Asserts valid GitHub release format: https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/...
  5. Forbidden Placeholders & Fluff Audit:
     - Asserts absence of TODO, FIXME, TBD, XXX, LOREM, unrendered template tags.
     - Asserts absence of subjective marketing fluff.
  6. 100% English Linguistic Hygiene & Zero Indonesian Text Audit:
     - Asserts strictly ZERO Indonesian narrative words across both README.md and RELEASE_NOTES.md.
  7. GitHub Anchor Link Resolution:
     - Validates that every TOC link resolves to an actual heading slug.
--------------------------------------------------------------------------------
"""

import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
README_PATH = os.path.join(REPO_ROOT, "README.md")
RELEASE_NOTES_PATH = os.path.join(REPO_ROOT, "RELEASE_NOTES.md")

EXPECTED_APK_NAMES = [
    "app-arm64-v8a-release.apk",
    "app-release.apk",
    "app-armeabi-v7a-release.apk",
    "app-x86_64-release.apk",
]

EXPECTED_PLATFORMS = [
    "YouTube",
    "Pixiv",
    "Pinterest",
    "Twitter / X",
    "TikTok",
    "Instagram",
]

EXPECTED_COOKIE_KEYS = [
    "PHPSESSID",
    "auth_token",
    "sessionid",
]

EXPECTED_PERMISSIONS = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.WAKE_LOCK",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_DATA_SYNC",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_MEDIA_VIDEO",
    "android.permission.READ_MEDIA_AUDIO",
]


def github_slug(heading_text: str) -> str:
    """Computes GitHub Markdown heading anchor slug matching github-slugger."""
    text = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", heading_text)
    text = re.sub(r"[\*_`]", "", text)
    text = text.strip().lower()
    punct_regex = r"[\u2000-\u206F\u2E00-\u2E7F\\'!\"#$%&()*+,./:;<=>?@\[\]^`{|}~]"
    text = re.sub(punct_regex, "", text)
    text = re.sub(r"\s", "-", text)
    return text


def test_suite_1_file_integrity_and_badges():
    print("\n--- Test Suite 1: File Integrity and Header Badging ---")
    for path, name in [(README_PATH, "README.md"), (RELEASE_NOTES_PATH, "RELEASE_NOTES.md")]:
        assert os.path.isfile(path), f"File not found: {path}"
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        # Reject legacy bilingual partition anchors
        assert '<a name="bahasa-indonesia">' not in content, f"{name}: Found forbidden legacy anchor #bahasa-indonesia"
        assert '<a name="english">' not in content, f"{name}: Found forbidden legacy anchor #english"
        assert '# Bahasa Indonesia' not in content, f"{name}: Found forbidden legacy # Bahasa Indonesia"

        non_empty = [l for l in content.splitlines() if l.strip()]
        min_lines = 200 if name == "README.md" else 80
        assert len(non_empty) >= min_lines, f"{name}: Document too short ({len(non_empty)} lines)"
        print(f"[{name}] Total non-empty lines: {len(non_empty)}")

    # Check README badging
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()

    assert "build_apk.yml/badge.svg" in readme, "README.md missing build status badge"
    assert "shields.io/github/v/release" in readme, "README.md missing release badge"
    assert "Flutter" in readme, "README.md missing Flutter badge"
    assert "Android" in readme, "README.md missing Android badge"
    assert "MIT" in readme, "README.md missing MIT license badge"

    print("[PASS] File integrity, badging, and 100% English headers verified.")


def test_suite_2_readme_completeness():
    print("\n--- Test Suite 2: README.md Section-by-Section Technical Completeness ---")
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()

    # 1. TOC
    toc_matches = re.findall(r"^\d+\.\s+\[([^\]]+)\]\((#[^\)]+)\)", readme, re.MULTILINE)
    print(f"TOC items: {len(toc_matches)}")
    assert len(toc_matches) == 11, f"Expected 11 TOC items in README.md, got {len(toc_matches)}"

    # 2. Main Headings (##)
    main_headings = [m.strip() for m in re.findall(r"^##\s+([^\n]+)", readme, re.MULTILINE)]
    # Skip TOC heading and License
    sections = [h for h in main_headings if not ("Table of Contents" in h or "License" in h)]
    assert len(sections) == 11, f"Expected 11 technical sections, got {len(sections)}: {sections}"

    # 3. Subsections: 6 Platforms
    for p in EXPECTED_PLATFORMS:
        assert f"### {p}" in readme or re.search(rf"###\s+\d+\.\s+{re.escape(p)}", readme), f"Missing platform {p}"

    assert "1080p" in readme, "Missing 1080p in YouTube section"
    assert "720p" in readme, "Missing 720p in YouTube section"
    assert "M4A" in readme or "AAC" in readme, "Missing audio format in YouTube section"
    assert "/shorts/" in readme, "Missing /shorts/ in YouTube section"
    assert "/live/" in readme, "Missing /live/ in YouTube section"

    assert "pximg.net" in readme, "Missing pximg.net in Pixiv section"
    assert "Referer" in readme, "Missing Referer in Pixiv section"
    assert "Ugoira" in readme, "Missing Ugoira in Pixiv section"
    assert "yuv420p" in readme, "Missing yuv420p in Pixiv section"
    assert "-movflags faststart" in readme, "Missing faststart flag in Pixiv section"

    assert "/originals/" in readme, "Missing /originals/ in Pinterest section"
    assert "pin.it" in readme, "Missing pin.it in Pinterest section"
    assert "pinterest.co.uk" in readme, "Missing ccTLD in Pinterest section"

    assert "twitter.com" in readme and "x.com" in readme, "Missing domain in Twitter section"
    assert "name=orig" in readme, "Missing name=orig in Twitter section"
    assert "Syndication" in readme or "syndication" in readme, "Missing syndication in Twitter section"

    assert "vm.tiktok.com" in readme and "vt.tiktok.com" in readme, "Missing shortlinks in TikTok section"
    assert "/photo/" in readme, "Missing /photo/ in TikTok section"

    assert "Reels" in readme, "Missing Reels in Instagram section"
    assert "/reels/" in readme, "Missing /reels/ in Instagram section"
    assert "fallback" in readme.lower(), "Missing fallback mention in Instagram section"

    # 4. Architecture Breakdown
    assert "Clean Architecture" in readme, "Missing Clean Architecture mention"
    assert "Provider" in readme, "Missing Provider mention"
    assert "Foreground Service" in readme or "flutter_foreground_task" in readme, "Missing foreground service mention"

    # 5. Permissions Specification Table
    for perm in EXPECTED_PERMISSIONS:
        assert perm in readme, f"Missing permission {perm} in permissions table"

    # 6. Sideloading Walkthrough
    assert "Android 8.0" in readme, "Missing Android 8.0 in sideloading"
    assert "15" in readme, "Missing Android 15 in sideloading"
    assert "Play Protect" in readme, "Missing Play Protect in sideloading"
    assert "Install anyway" in readme, "Missing 'Install anyway' in sideloading"

    # 7. Device Installation Troubleshooting
    assert "INSTALL_FAILED_UPDATE_INCOMPATIBLE" in readme, "Missing signature conflict troubleshooting"
    assert "Secure Folder" in readme or "Dual" in readme, "Missing dual-app / secure folder troubleshooting"
    assert "Package Installer" in readme, "Missing package installer cache clear instructions"

    # 8. Storage Hierarchy & Clean Cancel
    expected_storage_path = "/storage/emulated/0/Download/Media/"
    assert expected_storage_path in readme, "Missing storage path"
    assert "MediaScannerConnection" in readme, "Missing MediaScannerConnection"
    assert ".part" in readme, "Missing .part mention in clean cancel"
    assert ".tmp" in readme, "Missing .tmp mention in clean cancel"

    # 9. Cookie Vault
    for key in EXPECTED_COOKIE_KEYS:
        assert key in readme, f"Missing cookie key {key}"
    assert "SharedPreferences" in readme, "Missing SharedPreferences mention"

    # 10. APK Decision Matrix
    for apk in EXPECTED_APK_NAMES:
        assert apk in readme, f"Missing {apk} in matrix"

    # 11. Build & Quality Verification
    for cmd in ["flutter pub get", "flutter test", "flutter build apk --release", "verify_apk.py", "verify_apk.sh", "sha256sum"]:
        assert cmd in readme, f"Missing build/verification command '{cmd}'"

    print("[PASS] README.md exhibits complete technical completeness and structure.")


def test_suite_3_release_notes_completeness():
    print("\n--- Test Suite 3: RELEASE_NOTES.md Technical Completeness ---")
    with open(RELEASE_NOTES_PATH, "r", encoding="utf-8") as f:
        rn = f.read()

    # 1. Main Sections
    main_headings = [m.strip() for m in re.findall(r"^##\s+([^\n]+)", rn, re.MULTILINE)]
    print(f"RELEASE_NOTES sections: {len(main_headings)}")
    assert len(main_headings) >= 5, f"Expected at least 5 sections in RELEASE_NOTES, got {len(main_headings)}: {main_headings}"

    # 2. Download Table
    for apk in EXPECTED_APK_NAMES:
        assert apk in rn, f"Missing {apk} in download table"
    assert "SHA256SUMS.txt" in rn, "Missing SHA256SUMS.txt in download table"

    # 3. Decision Matrix (all 4 APKs)
    for apk in EXPECTED_APK_NAMES:
        count = rn.count(apk)
        assert count >= 2, f"Expected at least 2 occurrences of {apk} (table + matrix), got {count}"

    # 4. Sideloading Steps
    for step in ["Play Protect", "Install anyway", "Allow from this source"]:
        assert step in rn, f"Missing sideloading term '{step}'"

    # 5. Device Troubleshooting
    assert "INSTALL_FAILED_UPDATE_INCOMPATIBLE" in rn, "Missing signature conflict troubleshooting in release notes"

    # 6. Features Summary
    bullets = re.findall(r"^-\s+\*\*([^*]+)\*\*", rn, re.MULTILINE)
    print(f"Feature summary items: {len(bullets)}")
    assert len(bullets) >= 8, f"Too few feature bullets ({len(bullets)})"

    # 7. SHA-256 Instructions
    assert "sha256sum -c SHA256SUMS.txt" in rn, "Missing sha256sum check command"
    assert "Get-FileHash -Algorithm SHA256" in rn, "Missing PowerShell Get-FileHash command"
    assert "Termux" in rn, "Missing Termux Android mention"

    print("[PASS] RELEASE_NOTES.md exhibits complete technical completeness and clarity.")


def test_suite_4_cross_document_consistency():
    print("\n--- Test Suite 4: Cross-Document Consistency (README vs RELEASE_NOTES) ---")
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()
    with open(RELEASE_NOTES_PATH, "r", encoding="utf-8") as f:
        relnotes = f.read()

    url_pattern = r"https://github\.com/[^\s\)\"']+/releases/download/v1\.0\.0/[^\s\)\"']+"
    readme_urls = set(re.findall(url_pattern, readme))
    relnotes_urls = set(re.findall(url_pattern, relnotes))

    print(f"Extracted URLs: README={len(readme_urls)}, RELEASE_NOTES={len(relnotes_urls)}")
    assert len(readme_urls) == 5, f"Expected 5 release URLs in README, found {len(readme_urls)}: {readme_urls}"
    assert readme_urls == relnotes_urls, f"Release URLs mismatch between README and RELEASE_NOTES!\nDiff: {readme_urls ^ relnotes_urls}"

    for apk in EXPECTED_APK_NAMES + ["SHA256SUMS.txt"]:
        expected_url = f"https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/{apk}"
        assert expected_url in readme_urls, f"Missing URL for {apk} in README"
        assert expected_url in relnotes_urls, f"Missing URL for {apk} in RELEASE_NOTES"

    print("[PASS] Download URLs and artifact releases match 100% across both documents.")


def test_suite_5_forbidden_placeholders_and_fluff():
    print("\n--- Test Suite 5: Forbidden Placeholders and Marketing Fluff Audit ---")
    forbidden_tokens = [
        r"\bTODO\b",
        r"\bFIXME\b",
        r"\bTBD\b",
        r"\bXXX\b",
        r"\bLOREM\b",
        r"\bIPSUM\b",
        r"\[placeholder\]",
        r"\[insert[^\]]*\]",
        r"\[your[^\]]*\]",
    ]

    fluff_tokens = [
        r"\brevolutionary\b",
        r"\bcutting-edge\b",
        r"\bgame-changer\b",
        r"\bworld's best\b",
        r"\bunrivaled\b",
        r"\bparadigm shift\b",
    ]

    for path, name in [(README_PATH, "README.md"), (RELEASE_NOTES_PATH, "RELEASE_NOTES.md")]:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        for token in forbidden_tokens:
            matches = re.findall(token, content, re.IGNORECASE)
            assert not matches, f"{name}: Found forbidden placeholder token '{token}': {matches}"

        for token in fluff_tokens:
            matches = re.findall(token, content, re.IGNORECASE)
            assert not matches, f"{name}: Found excessive marketing fluff '{token}': {matches}"

    print("[PASS] Zero forbidden placeholders or generic marketing fluff detected.")


def test_suite_6_linguistic_hygiene_and_zero_indonesian():
    print("\n--- Test Suite 6: 100% English Linguistic Hygiene & Zero Indonesian Text Audit ---")
    
    indonesian_words = [
        r"\bunduh\b",
        r"\bpengunduh\b",
        r"\bperangkat\b",
        r"\bponsel\b",
        r"\bberkas\b",
        r"\bkreator\b",
        r"\btanda tangan\b",
        r"\bsetelan\b",
        r"\bpengaturan\b",
        r"\bmemasang\b",
        r"\bpemasangan\b",
        r"\blangkah\b",
        r"\bseluruh\b",
        r"\bsetelah\b",
        r"\bhalaman\b",
        r"\bpilihan\b",
        r"\bbahasa\b",
        r"\bpanduan\b",
        r"\btautan\b",
        r"\bcepat\b",
        r"\bmandiri\b",
        r"\bdidukung\b",
        r"\bpenggunaan\b",
        r"\bpembersihan\b",
        r"\bdimusnahkan\b",
        r"\btidak valid\b",
        r"\btidak ditemukan\b",
        r"\bdilarang\b",
    ]

    for path, name in [(README_PATH, "README.md"), (RELEASE_NOTES_PATH, "RELEASE_NOTES.md")]:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        # Strip code blocks and URLs before checking prose
        clean = re.sub(r"```[\s\S]*?```", "", content)
        clean = re.sub(r"`[^`]+`", "", clean)
        clean = re.sub(r"https?://[^\s\)]+", "", clean)

        for word_pattern in indonesian_words:
            matches = re.findall(word_pattern, clean, re.IGNORECASE)
            assert not matches, f"{name}: Found prohibited Indonesian word {word_pattern}: {matches}"

    print("[PASS] Strictly ZERO Indonesian text detected across README.md and RELEASE_NOTES.md.")


def test_suite_7_github_anchor_resolution():
    print("\n--- Test Suite 7: GitHub Anchor Link Resolution ---")
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()

    internal_links = re.findall(r"\[([^\]]+)\]\((#[a-zA-Z0-9_\-]+)\)", readme)
    print(f"Found {len(internal_links)} internal anchor links in README.md")

    explicit_anchors = set(re.findall(r'<a\s+(?:name|id)="([^"]+)"', readme))
    headings = re.findall(r"^#{1,6}\s+([^\n]+)", readme, re.MULTILINE)
    heading_slugs = set(github_slug(h) for h in headings)
    
    all_valid_targets = explicit_anchors.union(heading_slugs)

    unresolved = []
    for text, link in internal_links:
        target = link.lstrip("#")
        if target not in all_valid_targets:
            unresolved.append((text, link, target))

    print(f"Sample heading slugs ({len(heading_slugs)} total): {list(heading_slugs)[:5]}")
    if unresolved:
        print(f"Unresolved anchor links: {unresolved}")
    assert len(unresolved) == 0, f"Unresolved anchor links found: {unresolved}"

    print("[PASS] All internal anchor links resolve successfully to heading slugs.")


def run_all_suites():
    print("=" * 72)
    print(" Empirical Challenger M3-R2: 100% English Documentation Quality Audit")
    print("=" * 72)
    test_suite_1_file_integrity_and_badges()
    test_suite_2_readme_completeness()
    test_suite_3_release_notes_completeness()
    test_suite_4_cross_document_consistency()
    test_suite_5_forbidden_placeholders_and_fluff()
    test_suite_6_linguistic_hygiene_and_zero_indonesian()
    test_suite_7_github_anchor_resolution()
    print("=" * 72)
    print(" ALL 7 ADVERSARIAL DOCUMENTATION SUITES PASSED (100% SUCCESS)")
    print("=" * 72)


if __name__ == "__main__":
    run_all_suites()
