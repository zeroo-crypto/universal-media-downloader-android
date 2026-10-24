# ZALL v1.0.1 — Official Release Notes

<p align="center">
  <b>ZALL: High-Performance Standalone On-Device Media Extractor & Downloader for Android (8.0 – 15+)</b><br>
  <i>Download high-resolution media directly on your Android device without proxy servers, cloud scrapers, or third-party backends.</i>
</p>

---

## What's New in v1.0.1

- 🎨 **Official Custom App Icon**: Fully integrated new high-definition brand icon across all Android densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) and **Adaptive Icons** (`mipmap-anydpi-v26`) for modern Android devices (Samsung One UI, Pixel Launcher, Xiaomi HyperOS, ColorOS).
- 🛡️ **Dual-Scheme Signing & 4KB Page-Alignment**: Re-aligned all release APKs with `zipalign -p -f 4` (page-aligning uncompressed native `.so` libraries to 4096 bytes) and deterministically signed using **APK Signature Scheme v1 (JAR signing)** and **v2 (Full APK Signing)**.
- ⚡ **Resolution of "Aplikasi Tidak Valid" (Package Parse & Update Errors)**:
  - Upgraded build version code to `versionCode: 2` (`v1.0.1+2`).
  - Standardized AndroidManifest resources (`ic_launcher` and `ic_launcher_round`).
  - Added clear guidance for users upgrading from previous test builds.

---

## Direct 1-Click Download Links

Pilih dan unduh paket APK sesuai spesifikasi perangkat Android Anda:

| Binary Package | Target CPU Architecture | Ukuran File | Rekomendasi Penggunaan |
| :--- | :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.1/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | ~28 MB | **SANGAT DIREKOMENDASIKAN.** Pilihan tercepat dan terbaik untuk 95%+ HP Android modern (keluaran 2018 ke atas seperti Samsung, Xiaomi, Oppo, Vivo, Realme, Poco, Infinix, Pixel). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.1/app-release.apk) | Universal (FAT Multi-ABI) | ~75 MB | **Pilihan Universal.** Kompatibel dengan semua jenis prosesor Android. Pilih jika Anda tidak tahu jenis prosesor HP Anda. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.1/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | ~26 MB | Khusus untuk HP Android lawas (32-bit / rilis sebelum 2017). |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.1/app-x86_64-release.apk) | x86_64 (`x86_64`) | ~30 MB | Khusus untuk emulator Android di PC (BlueStacks, LDPlayer, Nox, AVD). |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.1/SHA256SUMS.txt) | SHA-256 Checksums | ~1 KB | Berkas verifikasi integritas checksum kriptografis. |

---

## PENTING: Cara Mengatasi "Aplikasi Tidak Valid" Saat Instalasi

Jika HP Anda memunculkan notifikasi *"Aplikasi tidak valid"*, *"Paket tampaknya tidak valid"*, atau *"Aplikasi tidak terpasang"*:

1. **HAPUS (UNINSTALL) APLIKASI LAMA TERLEBIH DAHULU**:
   - Jika di HP Anda sebelumnya sudah terpasang aplikasi ZALL versi lama (v1.0.0 atau versi uji coba):
   - **Wajib copot pemasangan (Uninstall) aplikasi lama terlebih dahulu** dari `Pengaturan > Aplikasi > ZALL > Hapus Instalan / Copot Pemasangan`.
   - *Alasan*: Android secara ketat menolak pemasangan (*update*) jika aplikasi lama dipasang dengan sertifikat atau build yang berbeda demi keamanan sistem Anda.
2. **PASTIKAN MENGUNDUH `app-arm64-v8a-release.apk`**:
   - Jangan salah mengunduh versi `x86_64` (karena versi ini hanya untuk emulator PC). Untuk HP Android biasa, unduh **`app-arm64-v8a-release.apk`**.
3. **PASTIKAN UNDUHAN SELESAI 100%**:
   - Periksa ukuran file di pengelola berkas (*File Manager*). Jika file APK hanya terunduh separuh karena koneksi terputus, Android tidak akan bisa mengurai paket (*corrupted APK*).
4. **IZINKAN SUMBER TIDAK DIKENAL**:
   - Buka `Pengaturan > Keamanan / Privasi > Instal Aplikasi Tidak Dikenal` -> Aktifkan untuk browser (Chrome/Brave) atau File Manager yang Anda gunakan.
5. **JIKA MUNCUL GOOGLE PLAY PROTECT**:
   - Klik **"Detail selengkapnya"** (*More details*), lalu pilih **"Tetap instal"** (*Install anyway*).

---

## Fitur Unggulan ZALL v1.0.1

- 🌟 **Desain Antarmuka Dark Blue Modern**: Mengikuti standar UI ZALL dengan warna Dark Blue `#141417`, Surface Card `#202129`, dan aksen Blue `#3B82F6` dengan font Poppins.
- 🖼️ **Media Preview Bottom Sheet**: Tinjau judul media, thumbnail visual, informasi pembuat, dan durasi sebelum memulai proses pengunduhan.
- 📦 **Multi-Media & Album Batch Download**:
  - **Pixiv**: Mendukung ilustrasi tunggal, album manga multi-halaman, dan animasi Ugoira (otomatis dikonversi ke MP4 H.264 via FFmpeg).
  - **Instagram**: Mendukung Reels, postingan video, dan carousel multi-foto.
  - **Pinterest**: Mengunduh foto resolusi asli (`/originals/`) dan video Pin MP4 kualitas tinggi.
  - **Twitter / X**: Mengunduh video bitrate tertinggi dan galeri multi-foto tanpa crash.
  - **TikTok**: Video HD tanpa tanda air (*no watermark*).
  - **YouTube**: Video 1080p, 720p, Shorts, dan audio M4A/AAC murni.
- 🔐 **Cookie Vault Terintegrasi**: Pengaturan terenkripsi lokal untuk memasukkan sesi cookie (`PHPSESSID`, `auth_token`, `sessionid`) bagi unduhan konten yang memerlukan login.
- 📂 **Penyimpanan Terstruktur**: Disimpan rapi di `/storage/emulated/0/Download/Media/<Platform>/<Kreator>/` dan langsung terindeks di Galeri HP.
