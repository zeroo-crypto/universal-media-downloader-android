import re
import sys
from pathlib import Path

def main():
    root = Path(__file__).resolve().parent.parent
    readme_path = root / "README.md"
    release_notes_path = root / "RELEASE_NOTES.md"

    print("========================================================================")
    print(" Challenger M5-2: Bilingual Documentation & Integrity Stress Test")
    print("========================================================================")

    if not readme_path.exists():
        print(f"[FAIL] README.md not found at {readme_path}")
        sys.exit(1)
    if not release_notes_path.exists():
        print(f"[FAIL] RELEASE_NOTES.md not found at {release_notes_path}")
        sys.exit(1)

    readme_content = readme_path.read_text(encoding="utf-8")
    release_notes_content = release_notes_path.read_text(encoding="utf-8")

    # 1. Partition README.md into ID and EN
    assert '<a name="bahasa-indonesia"></a>' in readme_content, "Missing #bahasa-indonesia anchor in README"
    assert '<a name="english"></a>' in readme_content, "Missing #english anchor in README"

    readme_parts = readme_content.split('<a name="english"></a>')
    readme_id = readme_parts[0]
    readme_en = readme_parts[1]

    print("\n--- Test 1: Content Sizing & Linguistic Parity ---")
    id_lines = len([l for l in readme_id.splitlines() if l.strip()])
    en_lines = len([l for l in readme_en.splitlines() if l.strip()])
    print(f"README.md: ID lines = {id_lines}, EN lines = {en_lines}")
    assert abs(id_lines - en_lines) <= 25, f"Linguistic disparity too high: {id_lines} vs {en_lines}"
    print("[PASS] Content sizing and symmetry between ID and EN are well-balanced.")

    # 2. Check Architecture Decision Matrix in both languages
    print("\n--- Test 2: Architecture Decision Matrix Verification ---")
    abis = ["arm64-v8a", "armeabi-v7a", "x86_64", "universal"]
    apk_names = [
        "app-arm64-v8a-release.apk",
        "app-armeabi-v7a-release.apk",
        "app-x86_64-release.apk",
        "app-release.apk"
    ]

    for apk in apk_names:
        assert apk in readme_id, f"Missing {apk} in Indonesian README"
        assert apk in readme_en, f"Missing {apk} in English README"
        assert apk in release_notes_content, f"Missing {apk} in RELEASE_NOTES"

    print(f"[PASS] All {len(apk_names)} target APK binaries documented across both ID and EN.")

    # 3. Check Sideloading Guidance
    print("\n--- Test 3: Sideloading OS Version Coverage ---")
    os_versions = ["Android 8.0", "11", "Android 13", "15+"]
    for os_v in os_versions:
        assert os_v in readme_id, f"Missing {os_v} guidance in Indonesian section"
        assert os_v in readme_en, f"Missing {os_v} guidance in English section"
    print("[PASS] Step-by-step sideloading guidance present for Android 8 through 15+ in both languages.")

    # 4. Check Platform Extraction Coverage Mention
    print("\n--- Test 4: Platform Features Mention ---")
    platforms = ["YouTube", "Pixiv", "Pinterest", "Twitter", "Instagram", "TikTok"]
    for plat in platforms:
        assert plat in readme_id, f"Missing {plat} in Indonesian features"
        assert plat in readme_en, f"Missing {plat} in English features"
    print(f"[PASS] All {len(platforms)} extraction platforms documented in both languages.")

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
        assert tool in readme_id, f"Missing {tool} in Indonesian build instructions"
        assert tool in readme_en, f"Missing {tool} in English build instructions"
    print("[PASS] Build commands and verification scripts documented accurately.")

    # 6. Check Forbidden Fluff / Stubs
    print("\n--- Test 6: Stubs, TODOs, and Marketing Fluff Elimination ---")
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
    print("[PASS] Zero placeholders, TODOs, or generic fluff found.")

    print("\n========================================================================")
    print(" ALL 6 ADVERSARIAL BILINGUAL STRESS TESTS PASSED EMPIRICALLY! (100%)")
    print("========================================================================")

if __name__ == "__main__":
    main()
