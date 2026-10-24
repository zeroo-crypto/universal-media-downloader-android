# Universal Media Downloader v1.0.0 — Official Release Notes

<p align="center">
  <b>High-Performance Standalone On-Device Media Extractor & Downloader for Android (8.0 – 15+)</b><br>
  <i>Download high-resolution media directly on your Android device without proxy servers, cloud scrapers, or third-party backends.</i>
</p>

---

## Release Overview

We are proud to announce the official release of **Universal Media Downloader v1.0.0** for Android. 

All release binaries have been built with 4-byte zip alignment and signed deterministically using **APK Signature Scheme v1 (JAR signing)** and **v2 (Full APK Signing)**. This explicit dual-scheme signing resolves physical device installation issues ("invalid package" / package parse error) across all Android versions (Android 8.0 Oreo through Android 15+) and custom vendor ROMs (MIUI/HyperOS, ColorOS, OneUI).

---

## Direct 1-Click Download Links

Download the binary package tailored to your device processor:

| Binary Package | Target CPU Architecture | File Size | Recommended Use Case |
| :--- | :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | ~28 MB | **Highly Recommended.** The optimal choice for 95%+ of modern Android phones (released 2017 or newer). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-release.apk) | Universal (FAT Multi-ABI) | ~75 MB | **Fail-Safe Choice.** Compatible with all Android devices. Select this if you are uncertain about your device CPU. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | ~26 MB | Dedicated to legacy 32-bit Android phones. |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-x86_64-release.apk) | x86_64 (`x86_64`) | ~30 MB | Dedicated to desktop Android emulators (BlueStacks, LDPlayer, Nox, Android Studio AVD) and x86 Android OS. |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/SHA256SUMS.txt) | SHA-256 Checksums | ~1 KB | Official cryptographic hash manifest for verifying binary integrity and authenticity. |

---

## Decision Matrix: "Which APK Should I Download?"

| Device Situation / Question | APK to Select |
| :--- | :--- |
| Your smartphone was purchased between 2018 and the present (Samsung, Xiaomi, Vivo, Oppo, Realme, Infinix, Pixel, Poco, etc.)? | **`app-arm64-v8a-release.apk`** |
| You do not know your processor architecture and want an APK guaranteed to install on any device? | **`app-release.apk`** |
| Your smartphone is an older model (released before 2017) or runs an entry-level 32-bit operating system? | **`app-armeabi-v7a-release.apk`** |
| You are running Android inside a desktop PC emulator (Windows, Mac, or Linux)? | **`app-x86_64-release.apk`** |

> **Quick Hardware Verification**: Install a free utility such as **Inware** or **AIDA64** from Google Play, then check **SoC / System -> Instruction Set**. If it reports `arm64-v8a` or `aarch64`, download **`app-arm64-v8a-release.apk`**.

---

## Step-by-Step Installation & Security Walkthrough

Because this APK is installed outside the Google Play Store (*sideloading*), Android displays standard security authorization prompts:

1. **Download the APK**: Tap one of the download links above (recommended: `app-arm64-v8a-release.apk`) using your mobile web browser.
2. **Open the Package**: Once the download completes, tap the download notification or locate the APK in your **Downloads / Files** app.
3. **Unknown Sources Prompt**:
   - If a prompt appears stating: *"For your security, your phone is not allowed to install unknown apps from this source"*:
   - Tap **Settings**.
   - Toggle **Allow from this source** to **ON**.
   - Tap the **Back** navigation button.
4. **Google Play Protect Prompt**:
   - If a dialog appears stating *"Blocked by Play Protect"* or *"Unrecognized App"*:
   - Tap **More details** (or the small expandable drop-down arrow).
   - Tap **Install anyway**.
5. **Complete Installation**:
   - Tap **Install**.
   - Wait a few seconds for the package installer to finish, then tap **Open**.

---

## Device Installation Troubleshooting & Conflict Resolution

If your device encounters an installation failure, consult the troubleshooting resolutions below:

### Resolving Signature Conflict (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`)
- **Symptom**: The installer reports *"App not installed"* or *"Package conflicts with an existing package by the same name"*.
- **Cause**: Android enforces cryptographic security: you cannot install a release APK over an existing debug or pre-release version signed with a different key.
- **Fix**:
  1. Uninstall the existing Universal Media Downloader app completely (`Settings > Apps > Universal Media Downloader > Uninstall`).
  2. If using Samsung Secure Folder, Xiaomi Second Space, or Android Work Profile, ensure the app is deleted from those spaces as well.
  3. Clear the Package Installer cache: `Settings > Apps > Show System Apps > Package Installer > Storage > Clear Cache`.
  4. Tap the downloaded v1.0.0 APK to install cleanly.

### Resolving "Invalid Package" on Custom Android ROMs
- **Symptom**: MIUI, HyperOS, or ColorOS displays *"Invalid Package"* or *"Failed to parse package"*.
- **Cause**: AGP 8+ builds historically omitted JAR Signature Scheme v1, causing older package installers or customized vendor package parsers to reject the APK.
- **Fix**: Release v1.0.0 binaries are explicitly dual-signed with both Scheme v1 (JAR) and Scheme v2 (Full APK), verified using `apksigner`. Ensure you download official binaries from the v1.0.0 release assets.

---

## Key Features & Highlights

- **100% On-Device Standalone Architecture**: No scraping backend or proxy servers. Network connections establish directly with official platform content delivery networks.
- **Android Share Sheet Integration (`ACTION_SEND`)**: Download directly from social media applications by tapping **Share** -> selecting **Universal Downloader**.
- **Pixiv Ugoira-to-MP4 Assembly**: Unpacks original Ugoira ZIP frames, reads exact delay metadata, and compiles them into an H.264 MP4 video via an embedded FFmpeg demuxer engine, with guaranteed instant cleanup of temporary frames (Zero Orphaned Files).
- **Comprehensive Platform Coverage**:
  - **YouTube**: 1080p Full HD, 720p HD, pure M4A/AAC audio extraction, Shorts, and Live stream support.
  - **Pixiv**: Original master illustrations, multi-page manga albums, and animated Ugoira works.
  - **Pinterest**: Master original images (`/originals/`), MP4 pin videos, `pin.it` shortlinks, and worldwide ccTLDs.
  - **Twitter / X**: Original master photos and highest bitrate MP4 videos via high-speed syndication endpoints.
  - **TikTok**: HD watermark-free video downloads and photo slideshow extraction.
  - **Instagram**: Reels, feed videos, and photo carousels with safe CDN fallback mechanisms.
- **Structured Storage Hierarchy**: Files are saved to `/storage/emulated/0/Download/Media/<Platform>/<Creator>/...` with adaptive subfolders for multi-page works and automatic file migration.
- **Clean Cancellation Management**: In-progress `.part` and `.tmp` files are immediately purged if a download is cancelled or interrupted.
- **Instant MediaStore Indexing**: Integrated native `MediaScannerConnection` triggers instant visibility in Android Gallery and Google Photos.
- **Local Cookie Vault**: Encrypted on-device storage for account session cookies (`PHPSESSID`, `auth_token`, `sessionid`) for authenticated and age-restricted downloads.

---

## SHA-256 Checksum Verification Instructions

You can verify the cryptographic integrity of your downloaded APK to ensure it has not been corrupted or tampered with:

### Verification on Linux / macOS / WSL
```bash
# Verify all APK files against the checksum manifest
sha256sum -c SHA256SUMS.txt
```

### Verification on Windows (PowerShell)
```powershell
# Compute the SHA-256 checksum for the downloaded APK
Get-FileHash -Algorithm SHA256 app-arm64-v8a-release.apk
Get-FileHash -Algorithm SHA256 app-release.apk
```

### Verification on Android Devices
You can check hashes directly on your Android device using **Hash Checker** (from Google Play) or inside **Termux**:
```bash
sha256sum app-arm64-v8a-release.apk
```
