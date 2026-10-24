# ZALL — All-in-One Media Downloader for Android

<p align="center">
  <b>High-Performance Standalone On-Device Media Extractor & Downloader (Android 8.0 – 15+)</b><br>
  <i>Download high-resolution media directly on your Android device with zero proxy servers, zero backend dependencies, and complete client-side sovereignty.</i>
</p>

<p align="center">
  <a href="https://github.com/zeroo-crypto/universal-media-downloader-android/actions/workflows/build_apk.yml"><img src="https://github.com/zeroo-crypto/universal-media-downloader-android/actions/workflows/build_apk.yml/badge.svg" alt="Build & Release APK"></a>
  <a href="https://github.com/zeroo-crypto/universal-media-downloader-android/releases/tag/v1.0.0"><img src="https://img.shields.io/github/v/release/zeroo-crypto/universal-media-downloader-android?color=blue&label=Release" alt="GitHub Release"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.1.0%2B-02569B?logo=flutter" alt="Flutter"></a>
  <a href="https://developer.android.com"><img src="https://img.shields.io/badge/Android-8.0%20to%2015%2B%20(API%2024--35)-3DDC84?logo=android" alt="Android"></a>
  <a href="#android-permissions-specification"><img src="https://img.shields.io/badge/Permissions-Scoped%20Storage-informational" alt="Permissions"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

---

## What is ZALL?

**ZALL** is a modern, privacy-respecting Android media downloader designed with a sleek Dark Blue aesthetic (`#141417`, `#202129`, `#3B82F6`). It enables seamless extraction and downloading of videos, high-resolution photos, multi-page albums, and animations directly from leading social platforms:

- **YouTube**: 1080p Full HD, 720p HD, and pure M4A/AAC audio extraction (powered by on-device manifest parser `youtube_explode_dart`).
- **Pixiv**: Original illustrations, multi-page manga albums, user profile/bookmark galleries, R-18 artworks with `PHPSESSID` session support, and animated Ugoira compilation to H.264 MP4.
- **Instagram**: Reels, posts, and multi-item carousel albums via authentic captioned scraper with optional `sessionid` support.
- **Pinterest**: Original master images (`/originals/`), MP4 pin videos, boards, and shortlinks (`pin.it`).
- **TikTok**: HD watermark-free videos, photo slide carousels, and original audio soundtracks.
- **X / Twitter**: Multi-photo tweets and high-bitrate MP4 videos via resilient multi-tier fallback (FxTwitter -> VxTwitter -> Twimg). Zero White Screen crashes.

---

## Table of Contents
1. [Direct 1-Click Download Links (v1.0.0)](#direct-1-click-download-links-v100)
2. [APK Architecture Decision Matrix](#apk-architecture-decision-matrix)
3. [Standalone On-Device Architecture](#standalone-on-device-architecture)
4. [Architecture Breakdown & Code Structure](#architecture-breakdown--code-structure)
5. [Supported Platforms & Features](#supported-platforms--features)
6. [Android Permissions Specification](#android-permissions-specification)
7. [Step-by-Step Sideloading Installation Guide](#step-by-step-sideloading-installation-guide)
8. [Device Installation Troubleshooting & Conflict Resolution](#device-installation-troubleshooting--conflict-resolution)
9. [Storage Hierarchy & File Management](#storage-hierarchy--file-management)
10. [Cookie Vault Configuration](#cookie-vault-configuration)
11. [Build & Quality Verification Instructions](#build--quality-verification-instructions)

---

## Direct 1-Click Download Links (v1.0.0)

All official release binaries are 4-byte zip-aligned and cryptographically dual-signed with **APK Signature Scheme v1 (JAR signing)** and **v2 (Full APK Signing)** to guarantee flawless installation across physical devices running Android 8.0 (API 24) through Android 15+ (API 35):

| Binary Package | Target CPU Architecture | File Size | Recommendation |
| :--- | :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | ~28 MB | **Highly Recommended.** Best performance and smallest footprint for 95%+ of modern smartphones (2017+). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-release.apk) | Universal (Multi-ABI FAT) | ~75 MB | **Fail-Safe Choice.** Bundles C++ libraries for all CPU types. Works on any device if you are unsure of your CPU. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | ~26 MB | Dedicated to older legacy or entry-level 32-bit smartphones. |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-x86_64-release.apk) | x86_64 (`x86_64`) | ~30 MB | Dedicated to PC Android Emulators (BlueStacks, LDPlayer, Nox, Android Studio AVD) and Android x86 laptops. |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/SHA256SUMS.txt) | SHA-256 Checksum Manifest | ~1 KB | Official cryptographic hash manifest for binary tamper detection and integrity verification. |

---

## APK Architecture Decision Matrix

Use the matrix below to select the ideal APK for your device:

| Device Hardware / Scenario | Recommended APK |
| :--- | :--- |
| Smartphone manufactured in 2018 or newer (Samsung, Xiaomi, Pixel, Oppo, Vivo, OnePlus, Realme, Motorola, etc.) | **`app-arm64-v8a-release.apk`** |
| You do not know your processor architecture and want guaranteed installation compatibility | **`app-release.apk`** |
| Legacy device (manufactured before 2017) or running a 32-bit-only operating system | **`app-armeabi-v7a-release.apk`** |
| Android emulator on PC/Mac (BlueStacks, LDPlayer, Android Studio Emulator, Nox) or ChromeOS x86 | **`app-x86_64-release.apk`** |

> **How to verify your phone CPU**: Install a free hardware inspector such as **Inware**, **AIDA64**, or **CPU-Z** from Google Play. Navigate to **SoC / System -> Instruction Set**. If it displays `arm64-v8a` or `aarch64`, download the **ARM64** APK.

---

## Standalone On-Device Architecture

Universal Media Downloader is built upon a **Zero-Backend & Client-Only Sovereignty** model:
- **Zero Proxy Intermediaries**: Your IP address and network requests are never proxied through external servers or third-party scraping APIs. Encrypted HTTPS connections establish directly between your smartphone and the official platform Content Delivery Networks (CDNs).
- **Embedded C++ Multimedia Engine**: Powered by native C++ runtimes (`libc++_shared.so` and `ffmpeg_kit_flutter_new`), your smartphone executes high-performance concat demuxing, frame extraction, and H.264 video compilation locally without cloud dependencies.
- **Robust Foreground Execution**: Utilizes an Android Foreground Service (`flutter_foreground_task`) with persistent notification management to ensure downloads and video rendering survive operating system battery optimizations and Doze mode.

```text
[Input URL / Share Sheet (ACTION_SEND)]
                 │
                 ▼
     [Sanitizer & URL Normalizer] ──────> Strips trailing punctuation, markdown, and tracking tags
                 │
                 ▼
     [Platform Extractor Engine] ───────> Extracts JSON-LD, AJAX payloads, or syndication feeds
                 │
                 ▼
    [Download & Streaming Engine] ──────> Writes chunked streams to temporary .part files via Dio
                 │
        ┌────────┴──────────────────────────┐
        ▼                                   ▼
 [Standard Media Stream]         [Pixiv Ugoira Animation]
        │                                   │
        │                        [Unpack ZIP Frame Archive]
        │                                   │
        │                        [Native FFmpeg Concat Demuxer] ──> Compiles H.264 MP4 (yuv420p)
        │                                   │
        │                        [Zero-Orphan Frame Directory Purge]
        └────────┬──────────────────────────┘
                 │
                 ▼
    [Storage Hierarchy Manager] ────────> Resolves public path (/Download/Media/<Platform>/...)
                 │
                 ▼
   [MediaStore Gallery Scanner] ────────> Dispatches MediaScannerConnection for instant Gallery indexing
```

---

## Architecture Breakdown & Code Structure

The project strictly follows Clean Architecture principles, ensuring modular separation of concerns, high testability, and resilient performance:

```text
lib/
├── core/                        # Core domain models, processors, and system managers
│   ├── constants/platforms.dart # Platform definitions and URL regex detection
│   ├── models/media_item.dart   # Immutable metadata and download task entity models
│   ├── processors/ffmpeg_processor.dart # On-device FFmpeg demuxer & MP4 compiler
│   ├── storage/hierarchy_manager.dart   # Scoped storage path resolution & auto-migration
│   ├── utils/clean_cancel.dart  # Zero-orphan file cleanup for cancelled/interrupted tasks
│   └── utils/url_sanitizer.dart # Comprehensive URL normalization and punctuation stripping
├── extractors/                  # Strategy-based extractor implementations
│   ├── base_extractor.dart      # Abstract extractor contract & common HTTP client
│   ├── extractor_registry.dart  # Central dispatch registry matching URLs to extractors
│   ├── youtube_extractor.dart   # YouTube videos, Shorts, and Live stream extractor
│   ├── pixiv_extractor.dart     # Pixiv illustrations, manga albums, and Ugoira extractor
│   ├── pinterest_extractor.dart # Pinterest original photos, videos, and multi-region ccTLDs
│   ├── twitter_extractor.dart   # Twitter/X master images and high-bitrate video extractor
│   ├── tiktok_extractor.dart    # TikTok watermark-free videos & photo slideshow extractor
│   └── instagram_extractor.dart # Instagram Reels, videos, carousels & safe fallback
├── services/                    # Background infrastructure & native device services
│   ├── download_service.dart    # Provider state management, Dio chunking & queueing
│   ├── share_intent_service.dart# Android ACTION_SEND intent receiver & parser
│   └── cookie_vault_service.dart# Encrypted SharedPreferences storage for session tokens
├── ui/                          # Presentation layer (Material 3)
│   ├── screens/                 # Home, Downloads, and Settings screens
│   └── widgets/                 # MediaPreviewCard, ProgressItem, and status indicators
└── main.dart                    # Application entrypoint, Foreground Service & Provider setup
```

- **Reactive State Management (`Provider`)**: The application leverages `ChangeNotifierProvider<DownloadService>` to orchestrate download lifecycles, active task progress, network retry events, and UI status updates without unnecessary rebuilds.
- **Extractor Strategy Pattern**: All platform extractors inherit from `BaseExtractor` and register with `ExtractorRegistry`. Adding support for new platforms requires zero modifications to existing download workers.
- **Android Foreground Service Integration**: Ongoing downloads register with `FlutterForegroundTask` using `NotificationChannelImportance.LOW`, displaying real-time speed (MB/s) and percentage progress while preventing Android from terminating the worker process.

---

## Supported Platforms & Features

### 1. YouTube
- Supports standard watch links (`youtube.com/watch?v=`), shortlinks (`youtu.be/`), embeds (`/embed/`), **YouTube Shorts** (`/shorts/`), and archived livestreams (**YouTube Live** `/live/`).
- Direct stream extraction supporting up to **1080p Full HD**, 720p HD, and pure audio extraction (**M4A / AAC** 128 kbps).
- Pure on-device stream parsing without intermediate web scrapers.

### 2. Pixiv
- Extracts original master artworks directly from `pximg.net` using official HTTP `Referer` headers.
- Full support for multi-page manga albums and carousel illustrations.
- **Ugoira-to-MP4 On-Device Assembly**: Downloads the original ZIP frame archive, reads exact per-frame delay timings (milliseconds) from official metadata, and compiles them into a smooth H.264 MP4 (`yuv420p` with `-movflags faststart`) using the embedded FFmpeg engine.
- **Zero-Orphan Cleanup**: Temporary uncompressed frame directories are cleanly wiped immediately after FFmpeg encoding finishes.

### 3. Pinterest
- Downloads master original images (automatically converting preview paths like `/236x/` or `/736x/` to `/originals/`).
- Extracts high-definition MP4 Pin video streams.
- Full resolution of shortlinks (`pin.it`) as well as global ccTLD regional domains (`pinterest.com`, `pinterest.co.uk`, `pinterest.de`, `pinterest.fr`, `pinterest.ca`, `pinterest.jp`, etc.).
- Intelligent folder separation: Creator-authored Pins remain in the creator root folder, while saved boards are placed within board-named subfolders.

### 4. Twitter / X
- Full support for both `twitter.com` and `x.com` domains.
- Master resolution photo extraction (`name=orig`).
- Automatically extracts and selects the highest bitrate MP4 video variant via high-speed syndication endpoints without requiring personal API developer keys.

### 5. TikTok
- High-definition video extraction **without watermarks**.
- Seamless expansion and resolution of `vm.tiktok.com` and `vt.tiktok.com` shortlinks.
- Support for TikTok photo slideshow posts (`/photo/` URLs).

### 6. Instagram
- Supports **Instagram Reels**, feed video posts, and carousel photo sets.
- Handles `/p/`, `/reel/`, `/reels/`, and `/tv/` URL formats.
- **Safe Fallback**: Direct CDN fallback prevents HTML authentication error pages from mistakenly saving as `.mp4` video files.

---

## Android Permissions Specification

Universal Media Downloader declares only essential permissions in `AndroidManifest.xml` required for media downloading, file management, and foreground stability:

| Permission Name | Android API Level | Necessity & Technical Justification |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | All versions | Required to establish direct HTTPS connections with platform CDNs to stream media. |
| `android.permission.ACCESS_NETWORK_STATE` | All versions | Detects active network type (Wi-Fi vs Cellular) and network loss during chunk streaming. |
| `android.permission.WAKE_LOCK` | All versions | Keeps the CPU active during intensive FFmpeg video compilation and high-speed chunk streaming. |
| `android.permission.FOREGROUND_SERVICE` | API 28+ (Android 9+) | Enables the background service to persist during long downloads when the app is minimized. |
| `android.permission.FOREGROUND_SERVICE_DATA_SYNC` | API 34+ (Android 14+) | Android 14 requirement specifying that the foreground service performs data transfer operations. |
| `android.permission.POST_NOTIFICATIONS` | API 33+ (Android 13+) | Required to display active download speed, progress bar, and completion notices in the notification shade. |
| `android.permission.READ_EXTERNAL_STORAGE` | API 24–32 (maxSdk 32) | Allows reading existing files in public storage to check for duplicate downloads on Android 8–12. |
| `android.permission.WRITE_EXTERNAL_STORAGE` | API 24–29 (maxSdk 29) | Required to write media files directly into public storage directories on Android 8.0 through 9.0. |
| `android.permission.MANAGE_EXTERNAL_STORAGE` | API 30+ (Android 11+) | All Files Access permission required to create structured `/Download/Media/...` subfolders and migrate sets. |
| `android.permission.READ_MEDIA_IMAGES` | API 33+ (Android 13+) | Granular media permission to query and verify downloaded images on modern Android devices. |
| `android.permission.READ_MEDIA_VIDEO` | API 33+ (Android 13+) | Granular media permission to query and verify downloaded videos on modern Android devices. |
| `android.permission.READ_MEDIA_AUDIO` | API 33+ (Android 13+) | Granular media permission to query and verify downloaded audio tracks on modern Android devices. |

---

## Step-by-Step Sideloading Installation Guide

Because Universal Media Downloader is distributed independently outside the Google Play Store (*sideloading*), Android requires manual authorization:

### Step 1: Download the APK
1. Download your preferred APK variant (recommended: `app-arm64-v8a-release.apk`) using your mobile browser (Chrome, Firefox, Brave, Samsung Internet).
2. When the download finishes, tap the completed notification or open the file in your **Files / File Manager** app.

### Step 2: Grant "Install Unknown Apps" Permission
Depending on your Android operating system version:
- **Android 8.0 through 12 (Oreo to Android 12)**:
  1. A security prompt will state: *"For your security, your phone is not allowed to install unknown apps from this source"*.
  2. Tap **Settings**.
  3. Toggle **Allow from this source** to **ON**.
  4. Tap the **Back** navigation button, then tap **Install**.
- **Android 13 through 15+ (Android 13, 14, 15)**:
  1. If prompted for source permissions, navigate to Settings and enable installation for your browser or file manager.
  2. **Google Play Protect Warning**: If a dialog states *"Blocked by Play Protect"* or *"Unrecognized App"*:
     - Tap **More details** (or the small expandable drop-down arrow).
     - Tap **Install anyway**.
  3. Tap **Install**, then tap **Open** when finished.

---

## Device Installation Troubleshooting & Conflict Resolution

If you encounter installation issues on your physical Android device, follow these verified solutions:

### 1. Resolving "Invalid Package" / Package Parse Error
- **Root Cause**: Older Android versions and custom Android ROMs (such as **MIUI/HyperOS**, **ColorOS/OxygenOS**, and **Samsung OneUI**) strictly require legacy **APK Signature Scheme v1 (JAR signing)**. Builds signed solely with modern Scheme v2/v3 trigger package parsing failures on these ROMs.
- **Resolution**: All official v1.0.0 release binaries are explicitly dual-signed using `apksigner` with both Scheme v1 and Scheme v2 enabled. Always download official binaries directly from the [v1.0.0 Release Page](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/tag/v1.0.0).

### 2. Resolving "App Not Installed" / `INSTALL_FAILED_UPDATE_INCOMPATIBLE`
- **Root Cause**: Android strictly prevents updating an existing application if the new APK's cryptographic signing certificate does not match the certificate of the currently installed version. This occurs if you previously installed a debug build, automated test build, or unofficial fork.
- **Resolution Steps**:
  1. **Uninstall the Previous Version**: Go to `Settings > Apps > Universal Media Downloader` and tap **Uninstall**.
  2. **Check Multi-User / Work Profiles / Secure Folders**:
     - On **Samsung devices**: Check **Secure Folder** and **Dual Messenger** to ensure no previous instance remains installed.
     - On **Xiaomi / POCO devices**: Check **Second Space** and **Dual Apps**.
     - On **Work Profile devices**: Ensure the app is uninstalled from both Personal and Work profiles.
  3. **Clear Package Installer Cache**:
     - Navigate to `Settings > Apps > (Menu / Three dots) > Show System Apps`.
     - Select **Package Installer** (or **Google Package Installer**).
     - Tap **Storage > Clear Cache**.
  4. **Reinstall Release v1.0.0**: Open the downloaded APK and proceed with installation.

### 3. Resolving Storage Access Prompts on Android 11–15
- **Issue**: On Android 11+, creating nested folders inside `/Download/Media/` requires the `MANAGE_EXTERNAL_STORAGE` permission.
- **Resolution**: When the app launches, grant the "All files access" prompt. If missed, enable it manually via `Settings > Apps > Special app access > All files access > Universal Media Downloader > Allow`.

---

## Storage Hierarchy & File Management

All downloaded media is organized within the public storage directory, directly accessible by system gallery apps, file managers, and media players:

```text
/storage/emulated/0/Download/Media/<Platform_Name>/<Creator_Name>/[<WorkId>/]<Filename>
```

### Adaptive Hierarchy Rules
- **First Single Download**: When downloading from a creator for the first time, a single file is saved directly into the creator root:
  `Download/Media/Pixiv/ArtistName/ArtworkTitle_12345678.png`
- **Multi-Page Sets & Subsequent Downloads**: If the post contains multiple items (manga album or carousel) or if a second post by the same creator is downloaded, a dedicated `<WorkId>` subfolder is created automatically to prevent clutter.
- **Automatic Migration**: Any preexisting single files belonging to that same work ID are automatically relocated into the newly established work directory.
- **Pinterest Placement Rules**: Author-created Pins remain in the creator root folder, while saved boards are placed within their respective board-named folders.

### Clean Cancellation & Zero Orphaned Files
- In-progress transfers stream into temporary `.part` files.
- If you tap **Cancel** or if an unrecoverable network disconnection occurs, the cleanup utility purges all partial files (`.part`, `.tmp`, `.crdownload`, and empty 0-byte stubs).
- Ugoira temporary frame extraction directories are guaranteed to be cleaned up within a `finally` block, ensuring no temporary files consume device storage.

### Automatic MediaStore Gallery Scanning
- Immediately after a `.part` file is renamed to its final target path, the application invokes the native platform channel `scanMediaFile`, calling Android's `MediaScannerConnection`.
- New photos and videos appear instantaneously inside the system Gallery, Google Photos, and media players without requiring a device restart.

---

## Cookie Vault Configuration

Public media files can be downloaded without authentication. However, some platforms restrict specific content (such as age-gated R-18 illustrations on Pixiv or posts from protected accounts).

The **Cookie Vault** stores authentication session tokens locally in encrypted app storage:
1. Navigate to the **Settings** tab in the bottom navigation bar.
2. Scroll to the **Cookie Vault** section.
3. Select the platform and enter your session token:
   - **Pixiv**: Enter your account's `PHPSESSID` cookie value.
   - **Twitter / X**: Enter your `auth_token` cookie value.
   - **Instagram**: Enter your `sessionid` cookie value.
4. Tap **Save**. Cookies are stored strictly inside your phone's private `SharedPreferences` and are never transmitted to external third parties.

---

## Build & Quality Verification Instructions

To compile and verify the application directly from source code:

### Prerequisites
- Flutter SDK (`>= 3.1.0`)
- Dart SDK (`>= 3.1.0`)
- Java Development Kit (JDK 17)
- Android SDK Platform-Tools & Build-Tools (version 34.0.0 or 35.0.0)
- Python 3.8+ (for cross-platform automated verification scripts)

### 1. Dependencies & Unit Tests
```bash
# Fetch pub dependencies
flutter pub get

# Run test suites and extractor regex validation
flutter test
```

### 2. Compiling Release APKs
```bash
# Compile single Universal Release APK
flutter build apk --release

# Compile all split-per-ABI release binaries
flutter build apk --release --split-per-abi
```
Generated release binaries are placed in `build/app/outputs/flutter-apk/`.

### 3. Automated APK Quality Gate Verification
The repository includes automated verification scripts that audit 4-byte zip alignment, cryptographic signature schemes v1/v2/v3, non-debug release certificates, and AndroidManifest badging across all 4 release APKs:

- **Cross-Platform Python (Windows / Linux / macOS)**:
  ```bash
  python scripts/verify_apk.py build/app/outputs/flutter-apk
  ```

- **Bash Script (Linux / macOS / WSL)**:
  ```bash
  chmod +x scripts/verify_apk.sh
  ./scripts/verify_apk.sh build/app/outputs/flutter-apk
  ```

Verification criteria enforced:
- `zipalign -c -v 4 <apk>` -> *Verification successful*.
- `apksigner verify --verbose` -> *Verified using v1 scheme: true*, *Verified using v2 scheme: true*, *Verified using v3 scheme: true*.
- `aapt dump badging <apk>` -> Validates package `com.zeroo.universal_media_downloader` and launchable activity `com.zeroo.universal_media_downloader.MainActivity`.

### 4. SHA-256 Checksum Validation
```bash
# Linux / macOS
cd build/app/outputs/flutter-apk
sha256sum *.apk > SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt

# Windows (PowerShell)
cd build\app\outputs\flutter-apk
Get-FileHash -Algorithm SHA256 *.apk
```

---

## License
This project is open-source software licensed under the [MIT License](LICENSE).
