#!/usr/bin/env python3
"""
Documentation Integrity Adversarial Test Suite for Milestone 4 (R4)
Universal Media Downloader Android

Validates:
1. Internal Anchor Links (TOC, language toggles, heading slug resolution)
2. Direct Download Links (Repository URLs, release tag, ABI filenames, SHA-256 manifest)
3. Documented Commands (Syntax checks, script existence, tool compatibility)
4. Bilingual Structural Symmetry & Section Mirroring
"""

import os
import re
import sys
import unicodedata
import subprocess

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
README_PATH = os.path.join(REPO_ROOT, "README.md")
RELEASE_NOTES_PATH = os.path.join(REPO_ROOT, "RELEASE_NOTES.md")

EXPECTED_RELEASE_TAG = "v1.0.0"
EXPECTED_BASE_URL = f"https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/{EXPECTED_RELEASE_TAG}/"
EXPECTED_ARTIFACTS = [
    "app-arm64-v8a-release.apk",
    "app-release.apk",
    "app-armeabi-v7a-release.apk",
    "app-x86_64-release.apk",
    "SHA256SUMS.txt",
]


def gfm_slugify(heading_text: str) -> str:
    """
    Simulates GitHub Flavored Markdown (GFM) heading slug generation:
    1. Strip markdown links [foo](bar) -> foo
    2. Strip inline formatting like `code`, **bold**, *italic*, <b>, </b>, etc.
    3. Lowercase
    4. Remove punctuation (ASCII punctuation + Unicode punctuation/symbols like en-dash, em-dash, etc.)
       Note: spaces are converted to hyphens; removed characters can leave consecutive spaces which become multiple hyphens.
    5. Strip leading/trailing hyphens.
    """
    # Remove HTML tags
    text = re.sub(r"<[^>]+>", "", heading_text)
    # Convert markdown links [text](url) -> text
    text = re.sub(r"\[([^\]]+)\]\([^\)]+\)", r"\1", text)
    # Remove code backticks
    text = re.sub(r"`", "", text)
    # Remove bold / italic
    text = re.sub(r"[*_]{1,3}", "", text)
    
    text = text.lower()
    
    # In GitHub's slugger:
    # Character removal: [^\w\s-] or unicode punctuation categories P*, S*
    # However, hyphens '-' are preserved.
    # Replace spaces with hyphens.
    result = []
    for char in text:
        if char == " " or char == "-":
            result.append(char)
        elif char.isalnum() or char == "_":
            result.append(char)
        else:
            # punctuation/symbols (including ., (), &, +, en-dash, etc.) are stripped
            pass
            
    slug = "".join(result)
    # Convert all spaces to hyphens
    slug = slug.replace(" ", "-")
    # Leading/trailing hyphens stripped in standard slugger
    slug = slug.strip("-")
    return slug


def extract_anchors_and_headings(content: str):
    """Extract explicit HTML anchors and headings from markdown."""
    explicit_anchors = set()
    # Matches <a name="..."> or <a id="...">
    for m in re.finditer(r'<a\s+(?:name|id)=["\']([^"\']+)["\']', content, re.IGNORECASE):
        explicit_anchors.add(m.group(1))

    headings = []
    for line in content.splitlines():
        hm = re.match(r"^(#{1,6})\s+(.+)$", line.strip())
        if hm:
            headings.append(hm.group(2).strip())

    # Build GFM slug map with duplicate collision handling (-1, -2, etc.)
    slug_counts = {}
    heading_slugs = set()
    for h in headings:
        base_slug = gfm_slugify(h)
        if base_slug in slug_counts:
            slug_counts[base_slug] += 1
            final_slug = f"{base_slug}-{slug_counts[base_slug]}"
        else:
            slug_counts[base_slug] = 0
            final_slug = base_slug
        heading_slugs.add(final_slug)

    return explicit_anchors, heading_slugs, headings


def extract_internal_links(content: str):
    """Find all markdown internal links [text](#anchor) and <a href="#anchor">."""
    links = []
    # Markdown links
    for m in re.finditer(r'\[([^\]]+)\]\((#[^)]+)\)', content):
        links.append((m.group(1), m.group(2)[1:]))  # strip leading #
    # HTML links
    for m in re.finditer(r'<a\s+[^>]*href=["\']#(.*?)["\']', content, re.IGNORECASE):
        links.append(("<html-link>", m.group(1)))
    return links


def extract_download_links(content: str):
    """Find all URLs pointing to release downloads."""
    pattern = r'https://github\.com/[^/\s"\')]+/[^/\s"\')]+/releases/download/[^\s"\')]+'
    return re.findall(pattern, content)


def extract_code_blocks(content: str):
    """Extract all fenced code blocks with language tag."""
    blocks = []
    pattern = r'```([a-zA-Z0-9_-]*)\r?\n(.*?)```'
    for m in re.finditer(pattern, content, re.DOTALL):
        blocks.append((m.group(1).lower(), m.group(2)))
    return blocks


# -------------------------------------------------------------
# TEST SUITE 1: Internal Anchor Integrity
# -------------------------------------------------------------
def test_internal_anchor_integrity():
    print("=== SUITE 1: Internal Anchor & TOC Integrity Test ===")
    files_to_test = [("README.md", README_PATH), ("RELEASE_NOTES.md", RELEASE_NOTES_PATH)]
    failures = []

    for name, path in files_to_test:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        explicit_anchors, heading_slugs, headings = extract_anchors_and_headings(content)
        all_valid_targets = explicit_anchors.union(heading_slugs)
        links = extract_internal_links(content)

        print(f"[{name}] Found {len(explicit_anchors)} explicit anchors, {len(headings)} headings, {len(links)} internal links.")

        for label, target in links:
            if target not in all_valid_targets:
                failures.append(f"[{name}] Broken anchor link '{target}' (label: '{label}') does not match any heading slug or explicit anchor!")
            else:
                print(f"  ✓ Valid anchor: #{target} -> '{label}'")

    if failures:
        for f in failures:
            print(f"  ❌ FAILURE: {f}")
        return False
    print("  ✓ ALL internal anchors and TOC links resolve to valid targets!\n")
    return True


# -------------------------------------------------------------
# TEST SUITE 2: Direct Download Links & Filename Accuracy
# -------------------------------------------------------------
def test_direct_download_links():
    print("=== SUITE 2: Direct Download Links & Filename Accuracy Test ===")
    files_to_test = [("README.md", README_PATH), ("RELEASE_NOTES.md", RELEASE_NOTES_PATH)]
    failures = []

    for name, path in files_to_test:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        dl_links = extract_download_links(content)
        print(f"[{name}] Found {len(dl_links)} direct download links.")

        found_artifacts = {}
        for link in dl_links:
            if not link.startswith(EXPECTED_BASE_URL):
                failures.append(f"[{name}] Link '{link}' does not match expected release URL base '{EXPECTED_BASE_URL}'")
                continue
            
            filename = link[len(EXPECTED_BASE_URL):]
            if filename not in EXPECTED_ARTIFACTS:
                failures.append(f"[{name}] Unexpected or misspelled artifact filename '{filename}' in link: {link}")
            else:
                found_artifacts[filename] = found_artifacts.get(filename, 0) + 1

        print(f"[{name}] Artifact frequency in links: {found_artifacts}")
        # Both files should have at least 1 occurrence of each artifact
        for art in EXPECTED_ARTIFACTS:
            count = found_artifacts.get(art, 0)
            if count < 1:
                failures.append(f"[{name}] Artifact '{art}' only linked {count} times (expected >= 1)")

    if failures:
        for f in failures:
            print(f"  ❌ FAILURE: {f}")
        return False
    print("  ✓ ALL download links are consistent, correctly formatted, and cover all 4 ABIs + SHA256SUMS!\n")
    return True


# -------------------------------------------------------------
# TEST SUITE 3: Documented Shell Commands & Script References
# -------------------------------------------------------------
def test_documented_commands():
    print("=== SUITE 3: Documented Commands & Script Path Validation ===")
    files_to_test = [("README.md", README_PATH), ("RELEASE_NOTES.md", RELEASE_NOTES_PATH)]
    failures = []

    # Check script references
    scripts_to_check = [
        os.path.join(REPO_ROOT, "scripts", "verify_apk.py"),
        os.path.join(REPO_ROOT, "scripts", "verify_apk.sh"),
    ]
    for s in scripts_to_check:
        if not os.path.isfile(s):
            failures.append(f"Documented script file does not exist: {s}")
        else:
            print(f"  ✓ Verified script existence: {os.path.relpath(s, REPO_ROOT)}")

    # Extract all commands from bash and powershell blocks
    for name, path in files_to_test:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        blocks = extract_code_blocks(content)
        for lang, block in blocks:
            if lang in ["bash", "sh", "powershell", "shell"]:
                lines = [line.strip() for line in block.splitlines() if line.strip() and not line.strip().startswith("#")]
                for cmd in lines:
                    print(f"  Testing command syntax from [{name}]: {cmd}")
                    # Validate flutter commands
                    if cmd.startswith("flutter "):
                        subcmd = cmd.split()[1]
                        if subcmd not in ["pub", "test", "build"]:
                            failures.append(f"[{name}] Unknown or suspicious flutter command: {cmd}")
                    # Validate python commands
                    elif cmd.startswith("python "):
                        parts = cmd.split()
                        script_arg = parts[1]
                        if not os.path.exists(os.path.join(REPO_ROOT, script_arg)):
                            failures.append(f"[{name}] Python command references non-existent script: {script_arg}")
                    # Validate verify_apk.sh
                    elif "./scripts/verify_apk.sh" in cmd:
                        pass
                    elif "chmod +x" in cmd:
                        pass
                    # Validate sha256sum
                    elif cmd.startswith("sha256sum"):
                        pass
                    # Validate Get-FileHash
                    elif cmd.startswith("Get-FileHash"):
                        if "-Algorithm SHA256" not in cmd:
                            failures.append(f"[{name}] Get-FileHash missing '-Algorithm SHA256': {cmd}")
                    # Validate cd commands
                    elif cmd.startswith("cd "):
                        pass
                    else:
                        failures.append(f"[{name}] Unrecognized command line: {cmd}")

    if failures:
        for f in failures:
            print(f"  ❌ FAILURE: {f}")
        return False
    print("  ✓ ALL documented commands and script references are valid!\n")
    return True


# -------------------------------------------------------------
# TEST SUITE 4: 100% English Compliance & Zero Indonesian Text
# -------------------------------------------------------------
def test_english_compliance_and_zero_indonesian():
    print("=== SUITE 4: 100% English Compliance & Zero Indonesian Text Test ===")
    failures = []

    # Test README.md
    with open(README_PATH, "r", encoding="utf-8") as f:
        readme = f.read()

    # Must NOT contain bilingual split anchors
    if '<a name="bahasa-indonesia">' in readme or '# Bahasa Indonesia' in readme:
        failures.append("README.md contains legacy Bahasa Indonesia section or anchor")

    # Check key English sections exist
    required_sections = [
        "Direct 1-Click Download Links (v1.0.0)",
        "APK Architecture Decision Matrix",
        "Standalone On-Device Architecture",
        "Architecture Breakdown & Code Structure",
        "Supported Platforms & Features",
        "Android Permissions Specification",
        "Step-by-Step Sideloading Installation Guide",
        "Device Installation Troubleshooting & Conflict Resolution",
        "Storage Hierarchy & File Management",
        "Cookie Vault Configuration",
        "Build & Quality Verification Instructions",
    ]

    for sec in required_sections:
        if sec not in readme:
            failures.append(f"README.md missing required English section: '{sec}'")

    # Check all 6 platforms covered
    platforms = ["YouTube", "Pixiv", "Pinterest", "Twitter", "TikTok", "Instagram"]
    for p in platforms:
        if p not in readme:
            failures.append(f"README.md missing platform '{p}'")

    # Test RELEASE_NOTES.md
    with open(RELEASE_NOTES_PATH, "r", encoding="utf-8") as f:
        rn = f.read()

    if '<a name="bahasa-indonesia">' in rn or '# Bahasa Indonesia' in rn:
        failures.append("RELEASE_NOTES.md contains legacy Bahasa Indonesia section or anchor")

    for p in platforms:
        if p not in rn:
            failures.append(f"RELEASE_NOTES.md missing platform '{p}'")

    if "Play Protect" not in rn or "Install anyway" not in rn:
        failures.append("RELEASE_NOTES.md missing Play Protect instructions")

    if "INSTALL_FAILED_UPDATE_INCOMPATIBLE" not in rn:
        failures.append("RELEASE_NOTES.md missing signature conflict resolution")

    # Zero Indonesian words audit across both documents
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
    ]

    for name, path in [("README.md", README_PATH), ("RELEASE_NOTES.md", RELEASE_NOTES_PATH)]:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        clean = re.sub(r"```[\s\S]*?```", "", content)
        clean = re.sub(r"`[^`]+`", "", clean)
        clean = re.sub(r"https?://[^\s\)]+", "", clean)

        for w in indonesian_words:
            m = re.findall(w, clean, re.IGNORECASE)
            if m:
                failures.append(f"{name} contains prohibited Indonesian text '{w}': {m}")

    if failures:
        for f in failures:
            print(f"  ❌ FAILURE: {f}")
        return False
    print("  ✓ 100% English compliance and zero Indonesian text verified!\n")
    return True


def main():
    print("Running Milestone 4 Adversarial Documentation Test Harness...\n")
    results = [
        test_internal_anchor_integrity(),
        test_direct_download_links(),
        test_documented_commands(),
        test_english_compliance_and_zero_indonesian(),
    ]

    if all(results):
        print("🎉 ALL 4 ADVERSARIAL DOCUMENTATION SUITES PASSED EMPIRICALLY! (100% SUCCESS)")
        sys.exit(0)
    else:
        print("❌ ONE OR MORE SUITES FAILED! REVIEW FAILURES ABOVE.")
        sys.exit(1)


if __name__ == "__main__":
    main()
