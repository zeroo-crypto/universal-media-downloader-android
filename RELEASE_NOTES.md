# ZALL v1.0.2 — Official Release Notes

<p align="center">
  <b>ZALL: High-Performance Standalone On-Device Media Extractor & Downloader for Android (8.0 – 15+)</b><br>
  <i>Download high-resolution media directly on your Android device without proxy servers, cloud scrapers, or third-party backends.</i>
</p>

---

## What's New in v1.0.2 (Engine v2.1.2)

- 🎥 **YouTube DASH High-Resolution & Audio Muxing**:
  - Full resolution picker: **4K 2160p**, **2K 1440p**, **Full HD 1080p**, **HD 720p**, **480p**, **360p**, and standalone **M4A Audio**.
  - High-res streams ($>720\text{p}$) are automatically muxed locally via the integrated FFmpeg demuxer (`-c:v copy -c:a aac -movflags faststart`) with the best standalone audio track.
- 🚀 **TikTok HTTP 403 Forbidden Error Bypass**:
  - Injected official browser headers and `Referer: https://www.tiktok.com/` into all direct video and photo slideshow downloads, eliminating the "tidak bisa menghubungi server http 403" error.
- 🔑 **Netscape cookies.txt Vault Import**:
  - Full support for importing standard `cookies.txt` (curl/Netscape format).
  - Automatically extracts and registers Pixiv `PHPSESSID` (unlocking R-18 and bookmark galleries), Twitter `auth_token`, and Instagram `sessionid`.
- 💾 **Real Device Storage Gauge (StatFs 64-bit)**:
  - Real-time internal storage monitoring using Android `StatFs` (`blockSizeLong * blockCountLong`) to prevent 32-bit integer overflow.
  - Dynamically displays used GB, total capacity, remaining quota, and circular color gauge in Settings.
- 🌐 **Reactive Multi-Language Switcher (i18n)**:
  - Full reactive language switcher supporting **Bahasa Indonesia** (`id`), **English (US)** (`en`), and **日本語** (`ja`) with persistent state.
- 🎨 **Official Brand Vector Logos**:
  - Replaced generic Material icons with custom pixel-perfect vector painters for YouTube, Pixiv, Instagram, Pinterest, TikTok, and X/Twitter.
- 🧹 **Zero Orphaned Files & Clean Cancellation**:
  - Enhanced cancellation handler cleans up all temporary `.video.part`, `.audio.part`, and `.part` files immediately.

---

## Direct 1-Click Download Links (v1.0.2)

Pilih dan unduh paket APK sesuai spesifikasi perangkat Android Anda:

| Binary Package | Target CPU Architecture | Ukuran File | Rekomendasi Penggunaan |
| :--- | :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.2/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | ~28 MB | **SANGAT DIREKOMENDASIKAN.** Pilihan tercepat dan terbaik untuk 95%+ HP Android modern (keluaran 2018 ke atas: Samsung, Xiaomi, Oppo, Vivo, Realme, Poco, Infinix, Pixel). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.2/app-release.apk) | Universal (FAT Multi-ABI) | ~75 MB | **Pilihan Universal.** Kompatibel dengan semua jenis prosesor Android. Pilih jika Anda tidak tahu jenis prosesor HP Anda. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.2/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | ~26 MB | Khusus untuk HP Android lawas (32-bit / rilis sebelum 2017). |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.2/app-x86_64-release.apk) | x86_64 (`x86_64`) | ~30 MB | Khusus untuk emulator Android di PC (BlueStacks, LDPlayer, Nox, AVD). |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.2/SHA256SUMS.txt) | SHA-256 Checksums | ~1 KB | Berkas verifikasi integritas checksum kriptografis. |

---

## Panduan Pemasangan

1. **HAPUS (UNINSTALL) APLIKASI LAMA TERLEBIH DAHULU**:
   - Dari HP Anda: `Pengaturan > Aplikasi > ZALL > Hapus Instalan / Copot Pemasangan`.
   - Hal ini wajib dilakukan agar Android Package Manager tidak menolak pembaruan paket.
2. **PASTIKAN MENGUNDUH `app-arm64-v8a-release.apk`**:
   - Untuk HP Android modern, gunakan `app-arm64-v8a-release.apk`.
3. **IZINKAN SUMBER TIDAK DIKENAL**:
   - Jika browser atau File Manager Anda meminta izin pasang aplikasi dari sumber ini, aktifkan toggle izinkan.
4. **JIKA MUNCUL GOOGLE PLAY PROTECT**:
   - Klik **"Detail selengkapnya"** (*More details*), lalu pilih **"Tetap instal"** (*Install anyway*).
