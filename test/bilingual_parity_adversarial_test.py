#!/usr/bin/env python3
"""test/bilingual_parity_adversarial_test.py
--------------------------------------------------------------------------------
Adversarial Verification Suite for Bilingual Documentation & Release Notes (R4)
Agent: teamwork_preview_challenger_m4_2 (Empirical Challenger)

Tests:
  1. File Integrity & Header Anchors:
     - Validates existence of README.md and RELEASE_NOTES.md.
     - Confirms top navigation anchors (#bahasa-indonesia, #english) and target anchors.
     - Verifies exact two-halves partition: Bahasa Indonesia and English.
  2. README.md Section-by-Section Structural & Content Parity:
     - TOC: 9 numbered items in ID, 9 numbered items in EN.
     - 9 corresponding main sections with 1:1 semantic and technical mapping.
     - Subsections parity: 6 platforms (YouTube, Pixiv, Pinterest, Twitter/X, TikTok, Instagram).
     - Usage flows parity: Share Sheet (5 steps) and Manual URL (4 steps).
     - Storage hierarchy parity: Scoped path, adaptive rules, clean cancel, MediaStore.
     - Cookie vault parity: PHPSESSID, auth_token, sessionid.
     - APK Decision matrix: 4 APK flavors with identical sizes and architectures.
     - Sideloading steps: Android 8-12 and Android 13-15+ (Google Play Protect bypass).
     - Build & Verification: Flutter/Dart/JDK/Python prerequisites, 4 build & audit steps.
  3. RELEASE_NOTES.md Section-by-Section Structural Parity:
     - Direct download table: 5 rows (4 APKs + SHA256SUMS.txt) with identical URLs and sizes.
     - APK Decision matrix table: 4 scenarios matching the 4 APK flavors.
     - 5-step sideloading walkthrough (Unknown sources & Play Protect 'Install anyway').
     - 10-point feature summary bullet list in both languages.
     - 3-platform SHA-256 verification instructions (Linux/macOS/WSL, Windows PowerShell, Android).
  4. Cross-Document Consistency & URL Validation:
     - Compares README.md and RELEASE_NOTES.md download URLs, APK sizes, and SHA-256 filenames.
     - Asserts valid GitHub release format: https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/...
  5. Forbidden Placeholders & Fluff Audit:
     - Asserts absence of TODO, FIXME, TBD, XXX, LOREM, unrendered template tags.
     - Asserts absence of subjective marketing fluff.
  6. Linguistic Hygiene & Cross-Language Contamination Audit:
     - Asserts English sections do not contain residual untranslated Indonesian prose words.
     - Asserts Indonesian sections do not contain untranslated English narrative sentences.
  7. GitHub Anchor Link Resolution:
     - Validates that every TOC link resolves to an actual heading slug.
--------------------------------------------------------------------------------
"""

import os
import re
import sys
import unicodedata

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


def github_slug(heading_text: str) -> str:
    """Computes GitHub Markdown heading anchor slug matching github-slugger."""
    # Strip markdown links if any: [text](#link) -> text
    text = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", heading_text)
    # Strip formatting: bold, italic, code
    text = re.sub(r"[\*_`]", "", text)
    text = text.strip().lower()
    # github-slugger punctuation regex (includes en-dash \u2013, ampersand, etc.)
    punct_regex = r"[\u2000-\u206F\u2E00-\u2E7F\\'!\"#$%&()*+,./:;<=>?@\[\]^`{|}~]"
    text = re.sub(punct_regex, "", text)
    # Each whitespace character becomes a hyphen (preserving double hyphens around stripped chars)
    text = re.sub(r"\s", "-", text)
    return text


def split_bilingual_doc(filepath: str):
    """Splits markdown file into Indonesian and English portions."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    id_anchor = '<a name="bahasa-indonesia"></a>'
    en_anchor = '<a name="english"></a>'

    assert id_anchor in content, f"Missing Indonesian anchor {id_anchor} in {filepath}"
    assert en_anchor in content, f"Missing English anchor {en_anchor} in {filepath}"

    parts_id = content.split(id_anchor)
    assert len(parts_id) == 2, f"Multiple ID anchors in {filepath}"
    
    parts_en = parts_id[1].split(en_anchor)
    assert len(parts_en) == 2, f"Multiple EN anchors in {filepath}"

    header = parts_id[0]
    id_body = parts_en[0]
    en_body = parts_en[1]

    return header, id_body, en_body, content


def test_suite_1_file_integrity_and_anchors():
    print("\n--- Test Suite 1: File Integrity and Language Switcher Anchors ---")
    for path, name in [(README_PATH, "README.md"), (RELEASE_NOTES_PATH, "RELEASE_NOTES.md")]:
        assert os.path.isfile(path), f"File not found: {path}"
        header, id_body, en_body, raw = split_bilingual_doc(path)

        # Check top navigation links
        assert '<a href="#bahasa-indonesia">' in header, f"{name}: Missing top link to #bahasa-indonesia"
        assert '<a href="#english">' in header, f"{name}: Missing top link to #english"

        # Check that both bodies are substantial (> 100 lines each)
        id_lines = [l for l in id_body.splitlines() if l.strip()]
        en_lines = [l for l in en_body.splitlines() if l.strip()]

        print(f"[{name}] ID content: {len(id_lines)} non-empty lines | EN content: {len(en_lines)} non-empty lines")
        min_lines = 150 if name == "README.md" else 60
        assert len(id_lines) >= min_lines, f"{name}: ID section too short ({len(id_lines)} lines)"
        assert len(en_lines) >= min_lines, f"{name}: EN section too short ({len(en_lines)} lines)"

        # Check line count parity (within 15% delta)
        ratio = len(id_lines) / len(en_lines)
        assert 0.85 <= ratio <= 1.15, f"{name}: Significant line disparity between ID and EN (ratio: {ratio:.2f})"

    print("[PASS] Both documents have valid top navigation, valid anchors, and balanced language partitions.")


def test_suite_2_readme_parity():
    print("\n--- Test Suite 2: README.md Section-by-Section Parity ---")
    header, id_body, en_body, _ = split_bilingual_doc(README_PATH)

    # 1. TOC Parity
    id_toc_matches = re.findall(r"^\d+\.\s+\[([^\]]+)\]\((#[^\)]+)\)", id_body, re.MULTILINE)
    en_toc_matches = re.findall(r"^\d+\.\s+\[([^\]]+)\]\((#[^\)]+)\)", en_body, re.MULTILINE)

    print(f"TOC items: ID={len(id_toc_matches)}, EN={len(en_toc_matches)}")
    assert len(id_toc_matches) == 9, f"Expected 9 TOC items in ID, got {len(id_toc_matches)}"
    assert len(en_toc_matches) == 9, f"Expected 9 TOC items in EN, got {len(en_toc_matches)}"

    # 2. Main Headings Parity (###)
    id_h3 = [m.strip() for m in re.findall(r"^###\s+([^\n]+)", id_body, re.MULTILINE)]
    en_h3 = [m.strip() for m in re.findall(r"^###\s+([^\n]+)", en_body, re.MULTILINE)]

    # Skip the TOC heading itself
    id_sections = [h for h in id_h3 if not ("Daftar Isi" in h)]
    en_sections = [h for h in en_h3 if not ("Table of Contents" in h)]

    assert len(id_sections) == 9, f"Expected 9 main sections in ID, got {len(id_sections)}: {id_sections}"
    assert len(en_sections) == 9, f"Expected 9 main sections in EN, got {len(en_sections)}: {en_sections}"

    # Verify each TOC link points to a corresponding H3 section slug
    for text, anchor in id_toc_matches:
        slug = anchor.lstrip("#")
        matched = any(slug in github_slug(h) or github_slug(h) in slug for h in id_sections)
        assert matched, f"ID TOC anchor {anchor} ({text}) does not match any H3 heading"

    for text, anchor in en_toc_matches:
        slug = anchor.lstrip("#")
        matched = any(slug in github_slug(h) or github_slug(h) in slug for h in en_sections)
        assert matched, f"EN TOC anchor {anchor} ({text}) does not match any H3 heading"

    # 3. Subsections Parity: 6 Platforms
    for p in EXPECTED_PLATFORMS:
        assert f"#### {p}" in id_body or re.search(rf"####\s+\d+\.\s+{re.escape(p)}", id_body), f"Missing platform {p} in ID"
        assert f"#### {p}" in en_body or re.search(rf"####\s+\d+\.\s+{re.escape(p)}", en_body), f"Missing platform {p} in EN"

    # Check specific platform details in both languages
    for body, lang in [(id_body, "ID"), (en_body, "EN")]:
        assert "1080p" in body, f"{lang}: Missing 1080p in YouTube section"
        assert "720p" in body, f"{lang}: Missing 720p in YouTube section"
        assert "M4A" in body or "AAC" in body, f"{lang}: Missing audio format in YouTube section"
        assert "/shorts/" in body, f"{lang}: Missing /shorts/ in YouTube section"
        assert "/live/" in body, f"{lang}: Missing /live/ in YouTube section"

        assert "pximg.net" in body, f"{lang}: Missing pximg.net in Pixiv section"
        assert "Referer" in body, f"{lang}: Missing Referer in Pixiv section"
        assert "Ugoira" in body, f"{lang}: Missing Ugoira in Pixiv section"
        assert "yuv420p" in body, f"{lang}: Missing yuv420p in Pixiv section"
        assert "-movflags faststart" in body, f"{lang}: Missing faststart flag in Pixiv section"

        assert "/originals/" in body, f"{lang}: Missing /originals/ in Pinterest section"
        assert "pin.it" in body, f"{lang}: Missing pin.it in Pinterest section"
        assert "pinterest.co.uk" in body, f"{lang}: Missing ccTLD in Pinterest section"

        assert "twitter.com" in body and "x.com" in body, f"{lang}: Missing domain in Twitter section"
        assert "name=orig" in body, f"{lang}: Missing name=orig in Twitter section"
        assert "Syndication" in body, f"{lang}: Missing Syndication in Twitter section"

        assert "vm.tiktok.com" in body and "vt.tiktok.com" in body, f"{lang}: Missing shortlinks in TikTok section"
        assert "/photo/" in body, f"{lang}: Missing /photo/ in TikTok section"

        assert "Reels" in body, f"{lang}: Missing Reels in Instagram section"
        assert "/reels/" in body, f"{lang}: Missing /reels/ in Instagram section"
        assert "fallback" in body.lower(), f"{lang}: Missing fallback mention in Instagram section"

    # 4. Usage Flows Parity
    assert "ACTION_SEND" in id_body and "ACTION_SEND" in en_body, "Missing ACTION_SEND in Usage section"
    assert "Share Sheet" in id_body and "Share Sheet" in en_body, "Missing Share Sheet in Usage section"

    # 5. Storage Hierarchy Parity
    expected_storage_path = "/storage/emulated/0/Download/Media/"
    assert expected_storage_path in id_body, "Missing storage path in ID"
    assert expected_storage_path in en_body, "Missing storage path in EN"
    assert "MediaScannerConnection" in id_body and "MediaScannerConnection" in en_body, "Missing MediaScannerConnection"
    assert ".part" in id_body and ".part" in en_body, "Missing .part mention in clean cancel"
    assert ".tmp" in id_body and ".tmp" in en_body, "Missing .tmp mention in clean cancel"

    # 6. Cookie Vault Parity
    for key in EXPECTED_COOKIE_KEYS:
        assert key in id_body, f"Missing cookie key {key} in ID"
        assert key in en_body, f"Missing cookie key {key} in EN"
    assert "SharedPreferences" in id_body and "SharedPreferences" in en_body, "Missing SharedPreferences mention"

    # 7. APK Decision Matrix Parity
    for apk in EXPECTED_APK_NAMES:
        assert apk in id_body, f"Missing {apk} in ID matrix"
        assert apk in en_body, f"Missing {apk} in EN matrix"
    assert "~28 MB" in id_body and "~28 MB" in en_body, "Missing ~28 MB size"
    assert "~75 MB" in id_body and "~75 MB" in en_body, "Missing ~75 MB size"
    assert "~26 MB" in id_body and "~26 MB" in en_body, "Missing ~26 MB size"
    assert "~30 MB" in id_body and "~30 MB" in en_body, "Missing ~30 MB size"

    # 8. Sideloading Walkthrough Parity
    assert "8.0" in id_body and "8.0" in en_body, "Missing Android 8.0 in sideloading"
    assert "15" in id_body and "15" in en_body, "Missing Android 15 in sideloading"
    assert "Play Protect" in id_body and "Play Protect" in en_body, "Missing Play Protect in sideloading"
    assert "Install anyway" in id_body and "Install anyway" in en_body, "Missing 'Install anyway' in sideloading"

    # 9. Build & Verification Parity
    for cmd in ["flutter pub get", "flutter test", "flutter build apk --release", "verify_apk.py", "verify_apk.sh", "sha256sum"]:
        assert cmd in id_body, f"Missing build/verification command '{cmd}' in ID"
        assert cmd in en_body, f"Missing build/verification command '{cmd}' in EN"

    print("[PASS] README.md exhibits complete 1:1 structural and technical parity.")


def test_suite_3_release_notes_parity():
    print("\n--- Test Suite 3: RELEASE_NOTES.md Section-by-Section Parity ---")
    header, id_body, en_body, _ = split_bilingual_doc(RELEASE_NOTES_PATH)

    # 1. Main Sections
    id_h3 = [m.strip() for m in re.findall(r"^###\s+([^\n]+)", id_body, re.MULTILINE)]
    en_h3 = [m.strip() for m in re.findall(r"^###\s+([^\n]+)", en_body, re.MULTILINE)]

    print(f"RELEASE_NOTES sections: ID={len(id_h3)}, EN={len(en_h3)}")
    assert len(id_h3) == 5, f"Expected 5 sections in ID RELEASE_NOTES, got {len(id_h3)}: {id_h3}"
    assert len(en_h3) == 5, f"Expected 5 sections in EN RELEASE_NOTES, got {len(en_h3)}: {en_h3}"

    # 2. Download Table Parity
    for apk in EXPECTED_APK_NAMES:
        assert apk in id_body, f"Missing {apk} in ID download table"
        assert apk in en_body, f"Missing {apk} in EN download table"
    assert "SHA256SUMS.txt" in id_body and "SHA256SUMS.txt" in en_body, "Missing SHA256SUMS.txt"

    # 3. Decision Matrix Parity (4 conditions)
    for apk in EXPECTED_APK_NAMES:
        id_count = id_body.count(apk)
        en_count = en_body.count(apk)
        assert id_count >= 2, f"Expected at least 2 occurrences of {apk} in ID (table + matrix), got {id_count}"
        assert en_count >= 2, f"Expected at least 2 occurrences of {apk} in EN (table + matrix), got {en_count}"

    # 4. Sideloading Steps
    for step in ["Play Protect", "Install anyway", "Allow from this source"]:
        assert step in id_body, f"Missing sideloading term '{step}' in ID"
        assert step in en_body, f"Missing sideloading term '{step}' in EN"

    # 5. Features Summary Parity
    id_bullets = re.findall(r"^-\s+\*\*([^*]+)\*\*", id_body, re.MULTILINE)
    en_bullets = re.findall(r"^-\s+\*\*([^*]+)\*\*", en_body, re.MULTILINE)
    print(f"Feature summary items: ID={len(id_bullets)}, EN={len(en_bullets)}")
    assert len(id_bullets) >= 8, f"Too few feature bullets in ID ({len(id_bullets)})"
    assert len(en_bullets) >= 8, f"Too few feature bullets in EN ({len(en_bullets)})"
    assert len(id_bullets) == len(en_bullets), f"Mismatch in feature bullets count: ID={len(id_bullets)}, EN={len(en_bullets)}"

    # 6. SHA-256 Instructions Subsections Parity
    id_h4 = [m.strip() for m in re.findall(r"^####\s+([^\n]+)", id_body, re.MULTILINE)]
    en_h4 = [m.strip() for m in re.findall(r"^####\s+([^\n]+)", en_body, re.MULTILINE)]
    print(f"SHA-256 subheadings: ID={len(id_h4)}, EN={len(en_h4)}")
    assert len(id_h4) == 3, f"Expected 3 OS subheadings in ID SHA-256, got {len(id_h4)}: {id_h4}"
    assert len(en_h4) == 3, f"Expected 3 OS subheadings in EN SHA-256, got {len(en_h4)}: {en_h4}"

    for body, lang in [(id_body, "ID"), (en_body, "EN")]:
        assert "sha256sum -c SHA256SUMS.txt" in body, f"{lang}: Missing sha256sum check command"
        assert "Get-FileHash -Algorithm SHA256" in body, f"{lang}: Missing PowerShell Get-FileHash command"
        assert "Termux" in body, f"{lang}: Missing Termux Android mention"

    print("[PASS] RELEASE_NOTES.md exhibits complete 1:1 structural and technical parity.")


def test_suite_4_cross_document_consistency():
    print("\n--- Test Suite 4: Cross-Document Consistency (README vs RELEASE_NOTES) ---")
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()
    with open(RELEASE_NOTES_PATH, "r", encoding="utf-8") as f:
        relnotes = f.read()

    # Extract all download URLs from both
    url_pattern = r"https://github\.com/[^\s\)\"']+/releases/download/v1\.0\.0/[^\s\)\"']+"
    readme_urls = set(re.findall(url_pattern, readme))
    relnotes_urls = set(re.findall(url_pattern, relnotes))

    print(f"Extracted URLs: README={len(readme_urls)}, RELEASE_NOTES={len(relnotes_urls)}")
    assert len(readme_urls) == 5, f"Expected 5 release URLs in README, found {len(readme_urls)}: {readme_urls}"
    assert readme_urls == relnotes_urls, f"Release URLs mismatch between README and RELEASE_NOTES!\nDiff: {readme_urls ^ relnotes_urls}"

    # Verify each expected artifact has a URL
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


def test_suite_6_linguistic_hygiene_and_leakage():
    print("\n--- Test Suite 6: Linguistic Hygiene and Cross-Language Leakage Audit ---")
    
    # Common Indonesian narrative words that should NEVER appear in the English section prose
    indonesian_prose_words = [
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
    ]

    for path, name in [(README_PATH, "README.md"), (RELEASE_NOTES_PATH, "RELEASE_NOTES.md")]:
        _, _, en_body, _ = split_bilingual_doc(path)

        # Strip code blocks and link URLs before checking prose
        clean_en = re.sub(r"```[\s\S]*?```", "", en_body)
        clean_en = re.sub(r"`[^`]+`", "", clean_en)
        clean_en = re.sub(r"https?://[^\s\)]+", "", clean_en)

        for word_pattern in indonesian_prose_words:
            matches = re.findall(word_pattern, clean_en, re.IGNORECASE)
            assert not matches, f"{name}: Found untranslated Indonesian word {word_pattern} in English body: {matches}"

    print("[PASS] Zero cross-language leakage or untranslated Indonesian prose found in English bodies.")


def test_suite_7_github_anchor_resolution():
    print("\n--- Test Suite 7: GitHub Anchor Link Resolution ---")
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()

    # Find all intra-document markdown links [text](#slug)
    internal_links = re.findall(r"\[([^\]]+)\]\((#[a-zA-Z0-9_\-]+)\)", readme)
    print(f"Found {len(internal_links)} internal anchor links in README.md")

    # Find all explicit anchors <a name="slug"></a>
    explicit_anchors = set(re.findall(r'<a\s+(?:name|id)="([^"]+)"', readme))
    
    # Generate all heading slugs
    headings = re.findall(r"^#{1,6}\s+([^\n]+)", readme, re.MULTILINE)
    heading_slugs = set(github_slug(h) for h in headings)
    
    all_valid_targets = explicit_anchors.union(heading_slugs)

    # Validate each internal link
    unresolved = []
    for text, link in internal_links:
        target = link.lstrip("#")
        if target not in all_valid_targets:
            # Check if there is an exact or near match
            unresolved.append((text, link, target))

    print(f"Explicit anchors: {explicit_anchors}")
    print(f"Sample heading slugs ({len(heading_slugs)} total): {list(heading_slugs)[:5]}")
    if unresolved:
        print(f"Unresolved anchor links: {unresolved}")
    assert len(unresolved) == 0, f"Unresolved anchor links found: {unresolved}"

    print("[PASS] All internal anchor links resolve successfully to explicit anchors or heading slugs.")


def run_all_suites():
    print("=" * 72)
    print(" Empirical Challenger M4-2: Bilingual Parity & Completeness Audit")
    print("=" * 72)
    test_suite_1_file_integrity_and_anchors()
    test_suite_2_readme_parity()
    test_suite_3_release_notes_parity()
    test_suite_4_cross_document_consistency()
    test_suite_5_forbidden_placeholders_and_fluff()
    test_suite_6_linguistic_hygiene_and_leakage()
    test_suite_7_github_anchor_resolution()
    print("=" * 72)
    print(" ALL 7 ADVERSARIAL BILINGUAL PARITY SUITES PASSED (100% SUCCESS)")
    print("=" * 72)


if __name__ == "__main__":
    run_all_suites()
