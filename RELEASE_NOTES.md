# Universal Media Downloader v1.0.0 — Release Notes

<p align="center">
  <b>Standalone On-Device High-Resolution Media Downloader for Android (8.0 – 15+)</b><br>
  <i>Unduh media resolusi tinggi langsung di ponsel tanpa server perantara.</i>
</p>

<p align="center">
  <a href="#bahasa-indonesia"><b>Bahasa Indonesia</b></a> &bull;
  <a href="#english"><b>English</b></a>
</p>

---

<a name="bahasa-indonesia"></a>
# Bahasa Indonesia

Selamat datang di rilis resmi **Universal Media Downloader v1.0.0** untuk sistem operasi Android. Seluruh berkas biner dalam rilis ini telah dioptimalkan dengan perataan biner 4-byte (*4-byte zip alignment*) dan ditandatangani secara kriptografis menggunakan Skema Tanda Tangan APK v1 (JAR), v2, dan v3 sehingga dapat langsung dipasang tanpa galat *"Aplikasi tidak valid"*.

---

### Tautan Unduh Langsung

Silakan pilih berkas biner yang sesuai dengan prosesor perangkat Anda:

| Berkas APK | Arsitektur Target | Ukuran File | Rekomendasi Penggunaan |
| :--- | :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | ~28 MB | **Sangat Direkomendasikan.** Pilihan terbaik untuk 95%+ ponsel Android modern (rilisan 2017 ke atas). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-release.apk) | Universal (FAT Multi-ABI) | ~75 MB | **Pilihan Universal.** Kompatibel dengan semua jenis perangkat Android. Pilih ini jika Anda ragu menentukan jenis CPU ponsel Anda. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | ~26 MB | Khusus untuk perangkat Android generasi lama berbasis 32-bit. |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-x86_64-release.apk) | x86_64 (`x86_64`) | ~30 MB | Khusus untuk Emulator PC (BlueStacks, LDPlayer, Nox, Android Studio AVD) atau laptop Android x86. |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/SHA256SUMS.txt) | Checksum SHA-256 | ~1 KB | Berkas verifikasi integritas kriptografis resmi untuk memastikan berkas tidak rusak atau termodifikasi. |

---

### Matriks Keputusan: "APK Mana yang Harus Saya Unduh?"

| Pertanyaan / Kondisi Perangkat | APK yang Harus Dipilih |
| :--- | :--- |
| Ponsel Anda dibeli antara tahun 2018 hingga sekarang (Samsung, Xiaomi, Vivo, Oppo, Realme, Infinix, Pixel, Poco, dll.)? | **`app-arm64-v8a-release.apk`** |
| Anda tidak tahu jenis prosesor ponsel Anda dan ingin yang pasti langsung berhasil dipasang? | **`app-release.apk`** |
| Ponsel Anda model sangat lama (keluaran sebelum 2017) atau berarsitektur 32-bit? | **`app-armeabi-v7a-release.apk`** |
| Anda menggunakan Emulator Android di komputer Windows/Mac/Linux? | **`app-x86_64-release.apk`** |

> **Cara Cepat Mengecek Arsitektur HP**: Pasang aplikasi gratis seperti **Inware** atau **AIDA64** dari Google Play Store, lalu lihat menu **SoC / System -> Instruction Set**. Jika tertera `arm64-v8a` atau `aarch64`, gunakan **`app-arm64-v8a-release.apk`**.

---

### Panduan Langkah-demi-Langkah Pemasangan & Peringatan Keamanan

Karena aplikasi ini dipasang di luar Google Play Store (*sideloading*), sistem keamanan Android akan menampilkan dialog konfirmasi keamanan standar:

1. **Unduh Berkas APK**: Ketuk salah satu tautan unduhan di atas (disarankan `app-arm64-v8a-release.apk`) melalui peramban web ponsel Anda.
2. **Buka Berkas**: Setelah pengunduhan selesai, ketuk notifikasi selesai unduh atau buka berkas dari pengelola berkas (*File Manager / Downloads*).
3. **Peringatan Sumber Tidak Dikenal (*Unknown Sources*)**:
   - Jika muncul peringatan *"Demi keamanan, ponsel Anda tidak diizinkan memasang aplikasi dari sumber ini"*:
   - Ketuk tombol **Setelan / Pengaturan** (*Settings*).
   - Aktifkan opsi **Izinkan dari sumber ini** (*Allow from this source*).
   - Tekan tombol **Kembali** (*Back*) pada ponsel Anda.
4. **Peringatan Google Play Protect**:
   - Jika muncul jendela dialog *"Aplikasi diblokir oleh Play Protect"* atau *"Aplikasi tidak dikenal / Unrecognized App"*:
   - Ketuk tulisan **Rincian Lebih Lanjut** (*More details*).
   - Ketuk tombol **Tetap Pasang** (*Install anyway*).
5. **Konfirmasi Pemasangan**:
   - Ketuk tombol **Pasang** (*Install*).
   - Tunggu proses pemasangan beberapa detik, lalu ketuk **Buka** (*Open*).

---

### Ringkasan Fitur Unggulan

- **Arsitektur Mandiri Tanpa Server (100% On-Device)**: Tidak ada data atau tautan yang dikirim ke server perantara. Ekstraksi dan pengunduhan berlangsung langsung antara ponsel dan server CDN resmi.
- **Integrasi Menu Bagikan (Share Sheet)**: Unduh langsung dari aplikasi media sosial mana pun cukup dengan menekan tombol **Bagikan** (*Share*) -> pilih **Universal Downloader**.
- **Kompilasi Animasi Pixiv Ugoira ke MP4**: Merakit frame ZIP animasi Pixiv Ugoira menjadi video MP4 berkualitas tinggi secara lokal menggunakan mesin bawaan FFmpeg lengkap dengan durasi delay resmi, serta membersihkan frame sementara seketika tanpa menyisakan sampah penyimpanan.
- **Dukungan Platform Lengkap**:
  - **YouTube**: Video Full HD 1080p, 720p, format audio murni M4A/AAC, YouTube Shorts, dan YouTube Live.
  - **Pixiv**: Ilustrasi master asli, manga/korsel multi-halaman, dan animasi Ugoira.
  - **Pinterest**: Gambar kualitas original (`/originals/`), video pin MP4, tautan pendek `pin.it`, serta seluruh domain regional dunia.
  - **Twitter / X**: Foto resolusi master dan video varian bitrate tertinggi via Syndication API.
  - **TikTok**: Video HD tanpa watermark dan tayangan slide foto (*photo slideshows*).
  - **Instagram**: Video Reels, postingan video feeds, dan korsel foto dengan perlindungan *safe fallback*.
- **Hierarki Penyimpanan Teratur**: Disimpan rapi di `/storage/emulated/0/Download/Media/<Platform>/<Kreator>/...` dengan pengelompokan subfolder otomatis untuk karya multi-halaman.
- **Pembersihan Bersih Saat Pembatalan (Clean Cancel)**: Memusnahkan berkas parsial `.part`, `.tmp`, dan direktori frame sementara seketika jika unduhan dibatalkan atau terputus jaringan.
- **Pengindeksan Galeri Otomatis**: Integrasi native `MediaScannerConnection` memastikan video dan foto langsung tampil di Galeri ponsel dan Google Photos tanpa perlu me-restart perangkat.
- **Ruang Simpan Cookie (Cookie Vault)**: Penyimpanan lokal token autentikasi pribadi (`PHPSESSID`, `auth_token`, `sessionid`) untuk mengunduh karya privat atau dengan batasan usia.

---

### Instruksi Verifikasi Integritas SHA-256

Anda dapat memverifikasi integritas berkas biner yang Anda unduh untuk memastikan berkas asli dan tidak mengalami kerusakan selama proses unduh:

#### Verifikasi di Linux / macOS / WSL
```bash
# Periksa integritas seluruh berkas APK yang ada di folder
sha256sum -c SHA256SUMS.txt
```

#### Verifikasi di Windows (PowerShell)
```powershell
# Menghitung nilai hash SHA-256 berkas APK
Get-FileHash -Algorithm SHA256 app-arm64-v8a-release.apk
Get-FileHash -Algorithm SHA256 app-release.apk
```

#### Verifikasi di Perangkat Android
Anda dapat menggunakan aplikasi pemeriksa hash (seperti **Hash Checker** dari Play Store) atau perintah di **Termux**:
```bash
sha256sum app-arm64-v8a-release.apk
```

---

<br><br>

---

<a name="english"></a>
# English

Welcome to the official release of **Universal Media Downloader v1.0.0** for Android. All binary packages in this release have undergone strict 4-byte zip alignment and are signed deterministically with APK Signature Scheme v1 (JAR signing), v2, and v3 to guarantee error-free installation across all physical Android devices without encountering *"Aplikasi tidak valid"* (Invalid package) errors.

---

### Direct Download Links

Choose the binary artifact corresponding to your device CPU architecture:

| APK Binary | Target Architecture | File Size | Recommended Use Case |
| :--- | :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | ~28 MB | **Highly Recommended.** The optimal choice for 95%+ of modern Android phones (released 2017 or newer). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-release.apk) | Universal (FAT Multi-ABI) | ~75 MB | **Fail-Safe Choice.** Compatible with all Android devices. Select this if you are uncertain about your device CPU. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | ~26 MB | Dedicated to legacy 32-bit Android phones. |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-x86_64-release.apk) | x86_64 (`x86_64`) | ~30 MB | Dedicated to desktop Android emulators (BlueStacks, LDPlayer, Nox, Android Studio AVD) and x86 Android OS. |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/SHA256SUMS.txt) | SHA-256 Checksums | ~1 KB | Official cryptographic hash manifest for verifying binary integrity and authenticity. |

---

### Decision Matrix: "Which APK Should I Download?"

| Device Situation / Question | APK to Select |
| :--- | :--- |
| Your smartphone was purchased between 2018 and the present (Samsung, Xiaomi, Vivo, Oppo, Realme, Infinix, Pixel, Poco, etc.)? | **`app-arm64-v8a-release.apk`** |
| You do not know your processor architecture and want an APK guaranteed to install on any device? | **`app-release.apk`** |
| Your smartphone is an older model (released before 2017) or runs an entry-level 32-bit operating system? | **`app-armeabi-v7a-release.apk`** |
| You are running Android inside a desktop PC emulator (Windows, Mac, or Linux)? | **`app-x86_64-release.apk`** |

> **Quick Hardware Verification**: Install a free utility such as **Inware** or **AIDA64** from Google Play, then check **SoC / System -> Instruction Set**. If it reports `arm64-v8a` or `aarch64`, download **`app-arm64-v8a-release.apk`**.

---

### Step-by-Step Installation & Security Prompt Walkthrough

Because this APK is installed outside the Google Play Store (*sideloading*), Android displays standard security authorization prompts:

1. **Download the APK**: Tap one of the download links above (recommended: `app-arm64-v8a-release.apk`) using your mobile web browser.
2. **Open the Package**: Once the download completes, tap the download notification or locate the APK in your **Downloads / Files** app.
3. **Unknown Sources Prompt**:
   - If a prompt appears stating: *"For your security, your phone is not allowed to install unknown apps from this source"*:
   - Tap **Settings**.
   - Toggle **Allow from this source** to ON.
   - Tap the **Back** navigation button.
4. **Google Play Protect Prompt**:
   - If a dialog appears stating *"Blocked by Play Protect"* or *"Unrecognized App"*:
   - Tap **More details** (or the small expandable drop-down arrow).
   - Tap **Install anyway**.
5. **Complete Installation**:
   - Tap **Install**.
   - Wait a few seconds for the package installer to finish, then tap **Open**.

---

### Key Features Summary

- **100% On-Device Standalone Architecture**: No scraping backend or proxy servers. Network connections establish directly with official content delivery networks.
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

### SHA-256 Checksum Verification Instructions

You can verify the cryptographic integrity of your downloaded APK to ensure it has not been corrupted or tampered with:

#### Verification on Linux / macOS / WSL
```bash
# Verify all APK files against the checksum manifest
sha256sum -c SHA256SUMS.txt
```

#### Verification on Windows (PowerShell)
```powershell
# Compute the SHA-256 checksum for the downloaded APK
Get-FileHash -Algorithm SHA256 app-arm64-v8a-release.apk
Get-FileHash -Algorithm SHA256 app-release.apk
```

#### Verification on Android Devices
You can check hashes on your Android device using **Hash Checker** (from Google Play) or inside **Termux**:
```bash
sha256sum app-arm64-v8a-release.apk
```
