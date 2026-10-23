# Universal Media Downloader Android — Test Infrastructure Specification (TEST_INFRA.md)

## 1. Test Philosophy & Integrity Guardrails

### 1.1 Core Principles
The testing framework of **Universal Media Downloader Android** is constructed around **Opaque-Box, Requirement-Driven Verification**:
- **Requirement-Driven**: Tests are designed directly from authoritative specifications (`ORIGINAL_REQUEST.md`, `PROJECT.md`, Android Compatibility Definition Document, and APK Signature Scheme v2/v3 specifications), rather than conforming to implementation idiosyncrasies.
- **Zero-Facade Guarantee**: Facade tests that trivially succeed or bypass core validation are strictly prohibited. Every test asserts genuine state transitions, output artifacts, HTTP payload interpretations, and error cascades.
- **Hermetic Isolation**: Tests run independently in arbitrary order. Filesystem tests create dedicated temporary scratch spaces and sanitize state in `setUp()` and `tearDown()` blocks.
- **Deterministic Offline Execution**: Network calls are decoupled using hermetic mock clients (`http.testing.MockClient` / mock handlers), preventing flakiness from upstream rate limits or network outages.

---

## 2. Test Architecture & Runner Invocations

### 2.1 Execution Runners
The project adheres to standard Flutter / Dart test runner conventions:

| Scope | Command | Purpose |
|---|---|---|
| **Full Test Suite** | `flutter test` (or `dart test`) | Executes all unit, regex, mock, hierarchy, cancel, and quality gate tests |
| **Extractor Regex Suite** | `flutter test test/extractor_regex_test.dart` | Validates URL regex matchers, shortlink resolution, query strings, and trailing punctuation stripping |
| **Mock Network & API Suite** | `flutter test test/extractor_mock_test.dart` | Verifies JSON payload parsing, multi-stream handling, Ugoira frames, and HTTP status codes via MockClient |
| **Hierarchy & Storage Suite** | `flutter test test/hierarchy_manager_test.dart` | Tests adaptive directory layout, Pinterest board rules, workId auto-migration, and name sanitization |
| **Clean Cancel Suite** | `flutter test test/clean_cancel_test.dart` | Verifies temporary extension matching, 0-byte detection, cancellation cleanup, and directory purging |
| **APK Quality Gate Suite** | `flutter test test/apk_quality_gate_test.dart` | Tests validation logic for `apksigner`, `aapt dump badging`, `zipalign`, and SHA-256 generation |

---

## 3. Test Tier Hierarchy

### 3.1 Tier 1: Feature Coverage (Core Happy Paths >= 5 per feature)
Tier 1 ensures that every core function executes correctly when provided standard inputs.
- **T1.1 YouTube Extractor**: Standard watch URLs, shortened `youtu.be`, mobile shorts, embed URLs, timestamped query parameters.
- **T1.2 Pixiv Extractor**: Single artwork illustration, multi-page manga carousel, Ugoira animation metadata, `/en/` locale prefixes, query string variations.
- **T1.3 Pinterest Extractor**: Standard `/pin/` URL, shortlink `pin.it`, regional domains (`pinterest.co.uk`, `pinterest.de`, `pinterest.fr`), JSON-LD schema parsing, `/originals/` image upgrades.
- **T1.4 Twitter/X Extractor**: Standard `twitter.com` status, `x.com` status, high-bitrate MP4 selection, original quality photo (`?name=orig`), multi-photo tweet albums.
- **T1.5 TikTok Extractor**: Standard `@user/video/` URL, `vm.tiktok.com` shortlinks, `vt.tiktok.com` shortlinks, TikWM JSON response parsing, photo album slide format.
- **T1.6 Instagram Extractor**: Post URL (`/p/`), Reel URL (`/reel/`), Reels plural (`/reels/`), IGTV (`/tv/`), JSON item parsing.
- **T1.7 Hierarchy Manager**: Base media directory resolution, creator folder resolution, Pinterest board subfolders, Pinterest created pins root retention, filename sanitization.
- **T1.8 Clean Cancel**: Partial file detection (`.part`), temporary file detection (`.tmp`), browser temp detection (`.crdownload`, `.download`), YouTube DL temp (`.ytdl`), completed file preservation.
- **T1.9 APK Quality Gate**: `apksigner` v1 & v2 validation, `aapt` package name verification, `aapt` activity check, `zipalign -c 4` verification, SHA-256 hash formatting.

### 3.2 Tier 2: Boundary & Corner Cases (>= 5 per feature)
Tier 2 stress-tests boundary limits, malformed inputs, edge characters, and exceptional conditions.
- **T2.1 Trailing Punctuation & Noise**: URLs ending with trailing dots (`.`), commas (`,`), exclamation marks (`!`), question marks (`?`), semicolons (`;`), parentheses (`)`), and brackets (`]`).
- **T2.2 Malformed URLs**: Incomplete IDs, empty strings, spaces, invalid schemes (`ftp://`, missing protocol), and non-matching platform domains.
- **T2.3 Illegal Filename Characters**: Path traversal sequences (`../`), FAT/NTFS forbidden characters (`\ / : * ? " < > |`), empty titles, strings with only spaces, and trailing blacklist phrases (` Media`).
- **T2.4 HTTP Error Handling**: HTTP 404 (media deleted), HTTP 403 (cookie required / R-18 restricted), HTTP 500 (upstream server failure), malformed/empty JSON responses, non-JSON HTML error pages.
- **T2.5 File Collision & Race Conditions**: Target file existing (`file.mp4`), multiple collisions (`file_1.mp4`, `file_2.mp4`), 0-byte file truncation vs valid non-zero partial downloads.
- **T2.6 Corrupt APK Verification**: Missing v2 signature (rejected), unaligned zip (rejected), missing launchable activity (rejected), bad package name (rejected), truncated APK file (rejected).

### 3.3 Tier 3: Cross-Feature Combinations
Tier 3 tests the interaction contracts between interconnected modules:
- **T3.1 Intent -> Extractor -> Hierarchy**: Share sheet intent extracts dirty URL -> Registry detects platform -> Extractor fetches metadata -> HierarchyManager resolves destination path.
- **T3.2 Ugoira Download -> FFmpeg Assembly -> Hierarchy**: Pixiv extractor flags `isUgoira: true` with frame delays -> Temp directory stores ZIP frames -> HierarchyManager allocates workId folder.
- **T3.3 Multi-Page Scraping -> Collision Resolution -> Clean Cancel**: Multi-page stream generation -> Destination collision checks (`_1`, `_2`) -> Cancellation halfway cleans partial files while keeping completed pages intact.
- **T3.4 Pinterest Board Detection -> Storage Segregation**: Pin with board metadata routes to `<Creator>/<BoardName>`, while Pin marked as Created routes to `<Creator>` root.

### 3.4 Tier 4: Real-World Application Scenarios
Tier 4 simulates actual end-to-end device environments:
- **T4.1 Share Sheet Conversational Paste**: User copies message from chat app: `"Check out this insane artwork https://www.pixiv.net/artworks/105356665! Must see"` -> System sanitizes URL, extracts metadata, and maps directory without crashing.
- **T4.2 Creator Download Stacking & Auto-Migration**: User downloads artwork #1 for creator `Alice` (saved to root `Media/Pixiv/Alice/100_art.jpg`). User later downloads artwork #2 for creator `Alice` -> System automatically creates subfolder `Media/Pixiv/Alice/100` and relocates file #1 seamlessly.
- **T4.3 User Cancels Large Video Download**: User starts downloading a 500MB YouTube video, cancels at 45% -> System triggers `CleanCancel.cleanupPartialFile`, immediately purging `.part` and 0-byte artifacts with 0 bytes of disk bloat.
- **T4.4 CI Release Binary Quality Gate**: Automated build generates 4 APKs -> Script invokes `zipalign`, `apksigner`, `aapt`, and generates `sha256sum.txt` -> Verification detects and halts release if any APK is unsigned or misaligned.

---

## 4. Complete Feature Inventory & Test Mapping

| # | Feature (from PROJECT.md) | Milestone | Test File | Test Group / Identifier |
|---|---|---|---|---|
| 1 | Deterministic Release Signing | M1 | `test/apk_quality_gate_test.dart` | `ApkQualityGate.verifySignatures` |
| 2 | Gradle Wrapper Provisioning | M1 | `test/apk_quality_gate_test.dart` | `BuildInfrastructure.gradleWrapper` |
| 3 | Legacy Launcher Icon Fallback | M1 | `test/apk_quality_gate_test.dart` | `ApkQualityGate.manifestAndResources` |
| 4 | CI Build Staging Isolation | M1 | `test/apk_quality_gate_test.dart` | `BuildInfrastructure.ciStaging` |
| 5 | Automated APK Verification Script | M2 | `test/apk_quality_gate_test.dart` | `ApkQualityGate.fullPipelineValidation` |
| 6 | CI Quality Gate Integration | M2 | `test/apk_quality_gate_test.dart` | `ApkQualityGate.exitCodeAndReport` |
| 7 | Full ABI Artifact Distribution | M2 | `test/apk_quality_gate_test.dart` | `ApkQualityGate.abiMatrixCheck` |
| 8 | Dynamic Share Sheet Handling | M3 | `test/extractor_regex_test.dart` | `ShareIntent.dynamicUrlCapture` |
| 9 | Shared URL Text Sanitization | M3 | `test/extractor_regex_test.dart` | `ShareIntent.urlSanitizationAndPunctuation` |
| 10 | YouTube Stream Resolution | M3 | `test/extractor_mock_test.dart` | `YouTubeExtractorMock.streamResolution` |
| 11 | Pixiv Ugoira to MP4 Assembly | M3 | `test/extractor_mock_test.dart` | `PixivExtractorMock.ugoiraMetadataParsing` |
| 12 | Instagram Reels & Safe Fallback | M3 | `test/extractor_regex_test.dart`, `test/extractor_mock_test.dart` | `InstagramExtractor.regexAndReelsPath` |
| 13 | TikTok Shortlink & Photo Support | M3 | `test/extractor_regex_test.dart`, `test/extractor_mock_test.dart` | `TikTokExtractor.shortlinksAndPhotos` |
| 14 | Pinterest Multi-TLD Support | M3 | `test/extractor_regex_test.dart`, `test/extractor_mock_test.dart` | `PinterestExtractor.multiTldAndBoardScraping` |
| 15 | Storage Hierarchy Compliance | M3 | `test/hierarchy_manager_test.dart` | `HierarchyManager.adaptiveDirectoryLayout` |
| 16 | MediaScanner Gallery Indexing | M3 | `test/hierarchy_manager_test.dart` | `HierarchyManager.storageLayoutContracts` |
| 17 | Clean Temp Cancellation Cleanup | M3 | `test/clean_cancel_test.dart` | `CleanCancel.orphanedFilePurge` |
| 18 | Mirrored Bilingual README | M4 | `test/apk_quality_gate_test.dart` | `DocumentationAudit.readmeBilingualCompleteness` |
| 19 | Mirrored Bilingual Release Notes | M4 | `test/apk_quality_gate_test.dart` | `DocumentationAudit.releaseNotesCompleteness` |
| 20 | Sideloading Installation Guide | M4 | `test/apk_quality_gate_test.dart` | `DocumentationAudit.sideloadingInstructionCheck` |
| 21 | Comprehensive Test Suite | M5 | Full Suite in `test/` | All 5 test suites (Tiers 1-4) |

---

## 5. Test Suite Verification & Quality Metrics

1. **Assertion Completeness**: Every test must contain explicit, meaningful matchers (`equals`, `contains`, `isTrue`, `isFalse`, `throwsA`).
2. **Zero Facades**: Stubs must accurately emulate backend RFC protocols and JSON contracts.
3. **Execution Time**: The complete unit and mock suite runs in under 10 seconds.
