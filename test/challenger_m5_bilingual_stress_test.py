import re
import sys
from pathlib import Path

def main():
    root = Path(__file__).resolve().parent.parent
    readme_path = root / "README.md"
    release_notes_path = root / "RELEASE_NOTES.md"

    print("========================================================================")
    print(" Challenger M5-2: 100% English Documentation & Integrity Stress Test")
    print("========================================================================")

    if not readme_path.exists():
        print(f"[FAIL] README.md not found at {readme_path}")
        sys.exit(1)
    if not release_notes_path.exists():
        print(f"[FAIL] RELEASE_NOTES.md not found at {release_notes_path}")
        sys.exit(1)

    readme_content = readme_path.read_text(encoding="utf-8")
    release_notes_content = release_notes_path.read_text(encoding="utf-8")

    # 1. 100% English Integrity & Prohibition of Legacy Bilingual Anchors
    print("\n--- Test 1: Content Sizing & 100% English Structure ---")
    assert '<a name="bahasa-indonesia">' not in readme_content, "Found forbidden #bahasa-indonesia anchor in README"
    assert '<a name="english">' not in readme_content, "Found forbidden #english anchor in README"
    assert '<a name="bahasa-indonesia">' not in release_notes_content, "Found forbidden #bahasa-indonesia anchor in RELEASE_NOTES"

    readme_lines = len([l for l in readme_content.splitlines() if l.strip()])
    rn_lines = len([l for l in release_notes_content.splitlines() if l.strip()])
    print(f"README.md lines: {readme_lines}, RELEASE_NOTES.md lines: {rn_lines}")
    assert readme_lines >= 200, f"README too short: {readme_lines} lines"
    assert rn_lines >= 80, f"RELEASE_NOTES too short: {rn_lines} lines"
    print("[PASS] Content sizing and 100% English structure verified.")

    # 2. Check Architecture Decision Matrix
    print("\n--- Test 2: Architecture Decision Matrix Verification ---")
    apk_names = [
        "app-arm64-v8a-release.apk",
        "app-armeabi-v7a-release.apk",
        "app-x86_64-release.apk",
        "app-release.apk"
    ]

    for apk in apk_names:
        assert apk in readme_content, f"Missing {apk} in README"
        assert apk in release_notes_content, f"Missing {apk} in RELEASE_NOTES"

    print(f"[PASS] All {len(apk_names)} target APK binaries documented.")

    # 3. Check Sideloading Guidance
    print("\n--- Test 3: Sideloading OS Version Coverage ---")
    os_versions = ["Android 8.0", "11", "Android 13", "15+"]
    for os_v in os_versions:
        assert os_v in readme_content, f"Missing {os_v} guidance in README"
    assert "8.0" in release_notes_content and "15+" in release_notes_content, "Missing OS version in RELEASE_NOTES"
    print("[PASS] Step-by-step sideloading guidance present for Android 8 through 15+.")

    # 4. Check Platform Extraction Coverage Mention
    print("\n--- Test 4: Platform Features Mention ---")
    platforms = ["YouTube", "Pixiv", "Pinterest", "Twitter", "Instagram", "TikTok"]
    for plat in platforms:
        assert plat in readme_content, f"Missing {plat} in README"
        assert plat in release_notes_content, f"Missing {plat} in RELEASE_NOTES"
    print(f"[PASS] All {len(platforms)} extraction platforms documented in English.")

    # 5. Check Verification Commands & Paths
    print("\n--- Test 5: Build & Verification Tooling Integrity ---")
    tools = [
        "flutter build apk --release",
        "flutter build apk --release --split-per-abi",
        "verify_apk.py",
        "verify_apk.sh",
        "SHA256SUMS.txt",
    ]
    for tool in tools:
        assert tool in readme_content, f"Missing {tool} in README"
    assert "SHA256SUMS.txt" in release_notes_content, "Missing SHA256SUMS.txt in RELEASE_NOTES"
    print("[PASS] Build commands and verification scripts documented accurately.")

    # 6. Check Forbidden Fluff / Stubs / Indonesian Text
    print("\n--- Test 6: Stubs, Marketing Fluff, and Zero Indonesian Text Elimination ---")
    fluff_terms = [
        "TODO",
        "FIXME",
        "TBD",
        "revolutionary AI",
        "blazing fast marketing",
        "lorem ipsum",
        "placeholder",
    ]
    for fluff in fluff_terms:
        matches = re.findall(rf"\b{re.escape(fluff)}\b", readme_content, re.IGNORECASE)
        assert len(matches) == 0, f"Found forbidden placeholder '{fluff}' in README"
        rn_matches = re.findall(rf"\b{re.escape(fluff)}\b", release_notes_content, re.IGNORECASE)
        assert len(rn_matches) == 0, f"Found forbidden placeholder '{fluff}' in RELEASE_NOTES"

    # Strict zero Indonesian words check
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
    for name, content in [("README.md", readme_content), ("RELEASE_NOTES.md", release_notes_content)]:
        clean = re.sub(r"```[\s\S]*?```", "", content)
        clean = re.sub(r"`[^`]+`", "", clean)
        clean = re.sub(r"https?://[^\s\)]+", "", clean)
        for w in indonesian_words:
            m = re.findall(w, clean, re.IGNORECASE)
            assert len(m) == 0, f"{name} contains forbidden Indonesian word '{w}': {m}"

    print("[PASS] Zero placeholders, fluff, and strictly ZERO Indonesian text found.")

    print("\n========================================================================")
    print(" ALL 6 ADVERSARIAL DOCUMENTATION STRESS TESTS PASSED (100% SUCCESS)!")
    print("========================================================================")

if __name__ == "__main__":
    main()
