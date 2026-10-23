# Universal Media Downloader (Android)

<p align="center">
  <b>Standalone On-Device Media Extractor & Downloader for Android (8.0 – 15+)</b><br>
  <i>Unduh media resolusi tinggi langsung di perangkat Android Anda tanpa server perantara.</i>
</p>

<p align="center">
  <a href="#bahasa-indonesia"><b>Bahasa Indonesia</b></a> &bull;
  <a href="#english"><b>English</b></a>
</p>

---

<a name="bahasa-indonesia"></a>
# Bahasa Indonesia

Aplikasi pengunduh media mandiri (*standalone on-device*) berperforma tinggi untuk sistem operasi Android (mendukung Android 8.0 Oreo hingga Android 15+). Seluruh proses—mulai dari analisis URL, ekstraksi tautan media, pengunduhan aliran data (chunk streaming), konversi animasi Ugoira menjadi MP4 menggunakan mesin FFmpeg, hingga penataan hierarki penyimpanan publik dan pengindeksan Galeri MediaStore—berjalan 100% secara lokal di ponsel Anda tanpa memerlukan server proksi, PC, atau backend pihak ketiga.

---

### Daftar Isi
1. [Tautan Unduh Cepat](#tautan-unduh-cepat-v100)
2. [Arsitektur Mandiri Pada Perangkat](#arsitektur-mandiri-pada-perangkat-on-device-architecture)
3. [Platform dan Fitur yang Didukung](#platform-dan-fitur-yang-didukung)
4. [Panduan Penggunaan](#panduan-penggunaan)
5. [Hierarki Penyimpanan & Manajemen Berkas](#hierarki-penyimpanan--manajemen-berkas)
6. [Pengaturan Ruang Simpan Cookie (Cookie Vault)](#pengaturan-ruang-simpan-cookie-cookie-vault)
7. [Matriks Keputusan Arsitektur APK](#matriks-keputusan-arsitektur-apk)
8. [Panduan Pemasangan Sideloading (Android 8.0 – 15+)](#panduan-pemasangan-sideloading-android-80--15)
9. [Instruksi Kompilasi & Verifikasi Kualitas APK](#instruksi-kompilasi--verifikasi-kualitas-apk)

---

### Tautan Unduh Cepat (v1.0.0)

Rilis resmi telah ditandatangani secara kriptografis menggunakan Skema Tanda Tangan APK v1 (JAR), v2, dan v3:

| Berkas Unduhan | Arsitektur Target | Keterangan Rekomendasi |
| :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | **Sangat Direkomendasikan** untuk 95%+ ponsel Android modern (ukuran berkas paling optimal ~28 MB). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-release.apk) | Universal (Multi-ABI FAT) | Kompatibel dengan semua perangkat Android; pilih jika Anda tidak mengetahui arsitektur CPU ponsel Anda. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | Khusus untuk perangkat Android generasi lama atau kelas pemula (*entry-level* 32-bit). |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-x86_64-release.apk) | x86_64 (`x86_64`) | Khusus untuk Emulator PC (Android Studio AVD, BlueStacks, LDPlayer) dan Android x86 di laptop/PC. |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/SHA256SUMS.txt) | Checksum SHA-256 | Berkas verifikasi integritas biner resmi untuk mencegah korupsi atau modifikasi tidak sah. |

---

### Arsitektur Mandiri Pada Perangkat (On-Device Architecture)

Aplikasi dirancang dengan filosofi **Zero-Backend & Client-Only Sovereignty**:
- **Bebas Server Perantara**: Alamat IP dan privasi Anda tidak pernah dikirim ke proxy pihak ketiga pengumpul data. Komunikasi HTTP berlangsung langsung antara perangkat Android Anda dan peladen konten asli (CDN).
- **Pemrosesan Multimedia Lokal**: Didukung oleh mesin pustaka C++ bawaan (`libc++_shared.so` dan `ffmpeg_kit_flutter_new`), perangkat Anda mampu merakit animasi Ugoira berkecepatan tinggi, demuxing stream, serta ekstraksi audio tanpa bantuan komputasi awan.
- **Dukungan Layanan Latar Belakang**: Dilengkapi Android Foreground Service (`flutter_foreground_task`) yang menjaga koneksi pengunduhan tetap aktif di latar belakang tanpa dihentikan paksa oleh manajemen baterai sistem operasi.

```text
[Input URL / Share Sheet Intent]
           │
           ▼
[Sanitizer & URL Normalizer] ──> (Pembersihan tanda baca penutup & parameter pelacak)
           │
           ▼
[Platform Extractor Engine] ───> (Analisis JSON-LD, AJAX API, atau Syndication Endpoint)
           │
           ▼
[Download & Streaming Engine] ─> (Unduh berkas sementara .part dengan Dio HTTP chunking)
           │
     ┌─────┴────────────────────────┐
     ▼                              ▼
(Media Standar)            (Animasi Pixiv Ugoira)
     │                              │
     │                     [Ekstraksi ZIP Frames]
     │                              │
     │                     [FFmpeg Concat Demuxer] ──> (Kompilasi H.264 MP4)
     │                              │
     │                     [Pembersihan Frame Sementara (Zero Orphaned Files)]
     └─────┬────────────────────────┘
           │
           ▼
[Storage Hierarchy Manager] ───> (/storage/emulated/0/Download/Media/<Platform>/...)
           │
           ▼
[MediaStore Gallery Scanner] ──> (Pengindeksan instan agar muncul di Galeri & Foto)
```

---

### Platform dan Fitur yang Didukung

#### 1. YouTube
- Mendukung tautan video standar (`youtube.com/watch?v=`), tautan ringkas (`youtu.be/`), tautan sematan (`/embed/`), **YouTube Shorts** (`/shorts/`), dan siaran langsung terarsip (**YouTube Live** `/live/`).
- Opsi kualitas video langsung hingga **1080p Full HD**, 720p HD, serta opsi ekstraksi audio murni (**M4A / AAC** 128 kbps).
- Pemecahan resolusi stream langsung secara mandiri.

#### 2. Pixiv
- Ekstraksi ilustrasi resolusi penuh/asli (*master original resolution*) dari peladen `pximg.net` dengan simulasi header `Referer` resmi.
- Mendukung album manga dan korsel multi-halaman (*multi-page artworks*).
- **Animasi Ugoira ke MP4**: Mengunduh berkas arsip ZIP asli, membaca durasi delay antar-frame (milidetik) dari metadata resmi, dan merakitnya menjadi berkas video MP4 (H.264 `yuv420p` dengan opsi `-movflags faststart`) secara langsung di ponsel.
- **Pembersihan Frame Tanpa Sisa**: Direktori berkas gambar sementara dari dekompresi ZIP langsung dihapus hingga bersih setelah MP4 selesai dikompilasi.

#### 3. Pinterest
- Mengunduh gambar kualitas original (mengubah resolusi pratinjau `/236x/` atau `/736x/` menjadi `/originals/`).
- Mendukung pengunduhan video Pin berformat MP4 resolusi tinggi.
- Mendukung tautan ringkas `pin.it` serta berbagai domain regional Pinterest dunia (ccTLD) seperti `pinterest.com`, `pinterest.co.uk`, `pinterest.de`, `pinterest.fr`, `pinterest.ca`, `pinterest.jp`, dll.
- Hierarki folder cerdas: Berkas Pin yang dibuat (*Created Pins*) disimpan langsung di folder kreator, sedangkan papan koleksi (*Saved Boards*) disimpan dalam subfolder nama papan.

#### 4. Twitter / X
- Mendukung domain `twitter.com` dan `x.com`.
- Mengunduh foto kualitas master (`name=orig`).
- Menyeleksi dan mengunduh varian video MP4 dengan bitrate tertinggi secara otomatis melalui integrasi API sindikasi ringan tanpa perlu token pengembang.

#### 5. TikTok
- Mengunduh video **HD tanpa watermark**.
- Mendukung tautan ringkas `vm.tiktok.com` dan `vt.tiktok.com`.
- Mendukung pengunduhan rangkaian tayangan foto (*photo slideshows* / format `/photo/`).

#### 6. Instagram
- Mendukung video **Instagram Reels**, kiriman video feeds, dan kiriman foto korsel (*carousel*).
- Menangani format URL `/p/`, `/reel/`, `/reels/`, dan `/tv/`.
- **Safe Fallback**: Dilengkapi mekanisme pencegahan galat (*fallback direct CDN*) agar aplikasi tidak salah mengunduh halaman HTML pemblokiran ke dalam berkas berekstensi `.mp4`.

---

### Panduan Penggunaan

#### Metode 1: Melalui Menu "Bagikan" (Share Sheet / ACTION_SEND) — Paling Cepat
1. Buka aplikasi media sosial pilihan Anda (YouTube, Twitter/X, Pixiv, Instagram, Pinterest, TikTok).
2. Temukan karya atau video yang ingin Anda unduh, lalu tekan tombol **Bagikan** (*Share*).
3. Pada daftar aplikasi yang muncul, pilih **Universal Downloader**.
4. Aplikasi akan otomatis terbuka, membaca tautan, mengekstrak pratinjau karya, dan menampilkan opsi resolusi.
5. Tekan tombol **Unduh Sekarang**. Pengunduhan akan berjalan di bilah notifikasi sistem.

#### Metode 2: Melalui Input Tautan Manual
1. Salin tautan media dari peramban atau aplikasi apa pun ke papan klip (*clipboard*).
2. Buka aplikasi **Universal Downloader**.
3. Ketuk tombol **Tempel Link** (atau tempel manual pada kolom isian), kemudian tekan **Periksa URL**.
4. Setelah informasi pratinjau dan daftar format muncul, pilih kualitas yang diinginkan dan tekan **Unduh Sekarang**.

---

### Hierarki Penyimpanan & Manajemen Berkas

Semua berkas yang berhasil diunduh ditempatkan di direktori publik perangkat agar dapat diakses oleh semua pemutar media dan pengelola berkas:

```text
/storage/emulated/0/Download/Media/<Nama_Platform>/<Nama_Kreator>/[<WorkId>/]<Nama_Berkas>
```

#### Aturan Hierarki Adaptif (*Adaptive Hierarchy*)
- **Unduhan Pertama (Single Work)**: Jika seorang kreator baru pertama kali diunduh dan hanya menghasilkan satu berkas, berkas tersebut disimpan langsung di bawah direktori kreator:
  `Download/Media/Pixiv/NamaArtis/JudulKarya_12345678.png`
- **Karya Multi-Halaman & Unduhan Berkala**: Jika karya tersebut memiliki beberapa halaman (misal album manga/korsel) atau terdapat unduhan kedua dari kreator yang sama, sistem otomatis membuat subfolder berlabel ID karya (`<WorkId>`) agar direktori tetap rapi.
- **Auto-Migration**: Berkas tunggal terdahulu yang berasal dari ID karya yang sama akan dipindahkan secara aman ke dalam subfolder karya yang baru dibuat.
- **Pinterest Special Rules**: Berkas Pin buatan kreator (*Created Pins*) dipastikan berada di folder utama kreator, sedangkan berkas dari papan simpanan (*Saved Boards*) dikelompokkan ke dalam subfolder nama papan terkait.

#### Pembersihan Pembatalan Bersih (*Clean Cancel & Zero Orphaned Files*)
- Selama pengunduhan berlangsung, data ditulis dengan ekstensi sementara `.part`.
- Jika Anda menekan tombol **Batal** pada aplikasi atau jika koneksi internet terputus secara fatal, utilitas pembersih otomatis memusnahkan seluruh berkas parsial (`.part`, `.tmp`, `.crdownload`, serta berkas kosong 0-byte).
- Direktori ekstraksi frame animasi Ugoira selalu dimusnahkan seketika melalui blok `finally` pada kode program, menjamin memori penyimpanan ponsel Anda tidak tersita oleh berkas sampah.

#### Pengindeksan Galeri MediaStore Otomatis
- Segera setelah berkas `.part` selesai diubah namanya menjadi berkas tujuan akhir, sistem memicu panggilan platform channel `scanMediaFile` ke antarmuka native Android `MediaScannerConnection`.
- Hasil unduhan langsung terdeteksi oleh Galeri bawaan, Google Photos, dan pemutar musik tanpa perlu memuat ulang (*restart*) ponsel.

---

### Pengaturan Ruang Simpan Cookie (Cookie Vault)

Secara default, sebagian besar media publik dapat diunduh tanpa perlu masuk log (*login*). Namun, beberapa platform membatasi akses pada konten tertentu (misalnya karya dengan pembatasan usia R-18 di Pixiv, atau twit dari akun yang dikunci).

Aplikasi menyediakan fitur **Cookie Vault** yang menyimpan token sesi secara terenkripsi di penyimpanan lokal perangkat:
1. Buka tab **Pengaturan** (*Settings*) di bilah navigasi bawah aplikasi.
2. Temukan bagian **Cookie Vault**.
3. Pilih platform target dan masukkan token sesi Anda:
   - **Pixiv**: Masukkan nilai `PHPSESSID` dari cookie peramban Anda.
   - **Twitter / X**: Masukkan nilai `auth_token`.
   - **Instagram**: Masukkan nilai `sessionid`.
4. Tekan **Simpan**. Token tersebut hanya disimpan di `SharedPreferences` privat ponsel Anda dan tidak pernah dibagikan ke server mana pun.

---

### Matriks Keputusan Arsitektur APK

Pilih berkas biner APK yang sesuai dengan jenis prosesor perangkat Anda untuk performa terbaik dan penghematan memori:

| Nama Berkas APK | Arsitektur CPU | Kompatibilitas Perangkat | Ukuran File | Alasan Pemilihan |
| :--- | :--- | :--- | :--- | :--- |
| **`app-arm64-v8a-release.apk`** | `arm64-v8a` | Ponsel Android 64-bit modern (Snapdragon, MediaTek, Exynos, Tensor rilisan 2017+) | ~28 MB | **Pilihan Utama Terbaik.** Eksekusi kode mesin native 64-bit murni, konsumsi RAM lebih rendah, dan ukuran file unduhan jauh lebih kecil. |
| **`app-release.apk`** | FAT Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | 100% semua ponsel, tablet, dan emulator Android | ~75 MB | **Pilihan Aman Tanpa Ragu.** Berisi pustaka C++ untuk semua arsitektur. Gunakan ini jika Anda tidak yakin jenis prosesor ponsel Anda. |
| **`app-armeabi-v7a-release.apk`** | `armeabi-v7a` | Ponsel Android 32-bit lawas atau perangkat murah (*entry-level*) | ~26 MB | Khusus perangkat lama berbasis arsitektur ARM 32-bit. Tidak dapat dipasang pada perangkat modern yang murni 64-bit (*64-bit only OS*). |
| **`app-x86_64-release.apk`** | `x86_64` | Emulator Android di PC (BlueStacks, LDPlayer, Nox, Android Studio AVD), ChromeOS x86 | ~30 MB | Khusus emulator atau laptop yang menjalankan sistem Android berbasis arsitektur prosesor Intel / AMD 64-bit. |

> **Tips Memeriksa Arsitektur HP**: Anda dapat memasang aplikasi gratis seperti *Inware*, *AIDA64*, atau *CPU-Z* dari Play Store, lalu melihat menu **SoC / System -> Instruction Set**. Jika tertulis `arm64-v8a` atau `aarch64`, unduhlah versi **ARM64**.

---

### Panduan Pemasangan Sideloading (Android 8.0 – 15+)

Karena aplikasi ini didistribusikan secara independen di luar Google Play Store (*sideloading*), sistem keamanan Android memerlukan izin eksplisit dari pengguna.

#### Langkah 1: Mengunduh Berkas APK
1. Unduh berkas APK pilihan Anda (misalnya `app-arm64-v8a-release.apk`) melalui peramban web (Chrome, Firefox, Brave, Samsung Internet) pada ponsel Anda.
2. Setelah unduhan selesai, ketuk pemberitahuan unduhan atau buka berkas dari pengelola berkas (*File Manager / Files*).

#### Langkah 2: Mengaktifkan Izin "Pasang Aplikasi yang Tidak Dikenal"
Tergantung versi Android yang terpasang pada ponsel Anda:

- **Android 8.0 s.d. 12 (Oreo, Pie, 10, 11, 12)**:
  1. Kotak dialog sistem akan muncul: *"Demi keamanan, ponsel Anda tidak diizinkan memasang aplikasi yang tidak dikenal dari sumber ini"*.
  2. Ketuk tombol **Setelan / Pengaturan** (*Settings*).
  3. Aktifkan sakelar **Izinkan dari sumber ini** (*Allow from this source*).
  4. Tekan tombol Kembali (*Back*), lalu ketuk **Pasang** (*Install*).

- **Android 13 s.d. 15+ (Tiramisu, Upside Down Cake, Vanilla Ice Cream)**:
  1. Jika muncul dialog perizinan akses sumber instalasi, ketuk **Pengaturan** dan aktifkan izin untuk peramban atau File Manager yang Anda gunakan.
  2. **Peringatan Google Play Protect**: Jika sistem menampilkan jendela dialog *"Aplikasi diblokir oleh Play Protect"* atau *"Aplikasi tidak dikenal"*:
     - Ketuk teks **Rincian Lebih Lanjut** (*More details* atau tanda panah kecil di bawah peringatan).
     - Ketuk opsi **Tetap Pasang** (*Install anyway*).
  3. Ketuk **Pasang** (*Install*). Setelah selesai, ketuk **Buka** (*Open*).

---

### Instruksi Kompilasi & Verifikasi Kualitas APK

Jika Anda ingin mengompilasi dan mengaudit aplikasi langsung dari kode sumber:

#### Prasyarat Sistem
- Flutter SDK (Versi `>= 3.1.0`)
- Dart SDK (Versi `>= 3.1.0`)
- Java Development Kit (JDK 17)
- Android SDK Platform-Tools & Build-Tools (Versi 34.0.0 atau 35.0.0)
- Python 3.8+ (untuk menjalankan skrip verifikasi otomatis lintas platform)

#### 1. Persiapan Dependensi & Pengujian Unit
```bash
# Mengambil paket dependensi
flutter pub get

# Menjalankan seluruh pengujian unit dan validasi regex ekstraktor
flutter test
```

#### 2. Kompilasi Paket Rilis
```bash
# Membangun APK Rilis Universal tunggal
flutter build apk --release

# Membangun seluruh varian biner per arsitektur (Split-per-ABI)
flutter build apk --release --split-per-abi
```
Berkas biner hasil kompilasi akan berada di direktori `build/app/outputs/flutter-apk/`.

#### 3. Gerbang Kualitas & Verifikasi Integritas Otomatis
Repositori menyediakan skrip verifikasi otomatis yang memvalidasi perataan biner 4-byte (*4-byte zip alignment*), skema tanda tangan kriptografis v1/v2/v3, sertifikat rilis non-debug, serta integritas manifes Android untuk keempat varian APK sekaligus:

- **Menggunakan Python (Lintas Platform - Windows / Linux / macOS)**:
  ```bash
  python scripts/verify_apk.py build/app/outputs/flutter-apk
  ```

- **Menggunakan Bash (Linux / macOS / WSL)**:
  ```bash
  chmod +x scripts/verify_apk.sh
  ./scripts/verify_apk.sh build/app/outputs/flutter-apk
  ```

Output keberhasilan verifikasi mencakup:
- `zipalign -c -v 4 <apk>` -> *Verification successful*.
- `apksigner verify --verbose` -> *Verified using v1 scheme: true*, *Verified using v2 scheme: true*, *Verified using v3 scheme: true*.
- `aapt dump badging <apk>` -> Terverifikasi `package: name='com.zeroo.universal_media_downloader'` dan `launchable-activity: name='com.zeroo.universal_media_downloader.MainActivity'`.

#### 4. Pembuatan dan Pemeriksaan Checksum SHA-256
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

<br><br>

---

<a name="english"></a>
# English

A high-performance, standalone on-device media downloader application built natively for Android (supporting Android 8.0 Oreo through Android 15+). Every operation—including URL parsing, media link extraction, chunked stream downloading, Pixiv Ugoira animation compilation to MP4 via an integrated FFmpeg engine, scoped storage placement, and MediaStore gallery indexing—runs 100% locally on your smartphone without intermediate servers, cloud proxies, or third-party web backends.

---

### Table of Contents
1. [Quick Download Links](#quick-download-links-v100)
2. [Standalone On-Device Architecture](#standalone-on-device-architecture)
3. [Supported Platforms and Extraction Features](#supported-platforms-and-extraction-features)
4. [Usage Instructions](#usage-instructions)
5. [Storage Hierarchy & File Management](#storage-hierarchy--file-management)
6. [Cookie Vault Configuration](#cookie-vault-configuration)
7. [APK Architecture Decision Matrix](#apk-architecture-decision-matrix)
8. [Step-by-Step Sideloading Installation Guide (Android 8.0 – 15+)](#step-by-step-sideloading-installation-guide-android-80--15)
9. [Build & Quality Verification Instructions](#build--quality-verification-instructions)

---

### Quick Download Links (v1.0.0)

All official release binaries are signed deterministically with APK Signature Scheme v1 (JAR signing), v2, and v3:

| Binary Artifact | Target Architecture | Recommendation Details |
| :--- | :--- | :--- |
| [**`app-arm64-v8a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-arm64-v8a-release.apk) | ARM 64-bit (`arm64-v8a`) | **Highly Recommended** for 95%+ of modern Android phones (optimized size ~28 MB). |
| [**`app-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-release.apk) | Universal (Multi-ABI FAT) | Compatible with all Android devices; choose this if you are unsure of your phone CPU. |
| [**`app-armeabi-v7a-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-armeabi-v7a-release.apk) | ARM 32-bit (`armeabi-v7a`) | Dedicated to older legacy or entry-level 32-bit Android phones. |
| [**`app-x86_64-release.apk`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/app-x86_64-release.apk) | x86_64 (`x86_64`) | Dedicated to Android emulators on PC (Android Studio AVD, BlueStacks, LDPlayer) and Android x86 laptops. |
| [**`SHA256SUMS.txt`**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/download/v1.0.0/SHA256SUMS.txt) | SHA-256 Checksums | Official cryptographic checksum manifest for binary tamper detection. |

---

### Standalone On-Device Architecture

Engineered around a **Zero-Backend & Client-Only Sovereignty** model:
- **No Proxy Intermediaries**: Your IP address and network requests are never proxied through external scraper APIs. HTTP sessions establish directly between your device and the upstream content delivery networks (CDNs).
- **Native Embedded Media Engine**: Powered by compiled C++ runtimes (`libc++_shared.so` and `ffmpeg_kit_flutter_new`), your smartphone executes high-performance concat demuxing, frame decoding, and audio stream extraction locally without cloud dependencies.
- **Robust Foreground Execution**: Utilizes an Android Foreground Service (`flutter_foreground_task`) with persistent notification management to prevent operating system battery optimizations from terminating downloads.

```text
[Input URL / Share Sheet Intent]
           │
           ▼
[Sanitizer & URL Normalizer] ──> (Strips trailing punctuation & tracking params)
           │
           ▼
[Platform Extractor Engine] ───> (Extracts JSON-LD, AJAX payloads, or Syndication feeds)
           │
           ▼
[Download & Streaming Engine] ─> (Writes to temporary .part file via Dio HTTP chunking)
           │
     ┌─────┴────────────────────────┐
     ▼                              ▼
(Standard Media)           (Pixiv Ugoira Animation)
     │                              │
     │                     [Unpack ZIP Frames]
     │                              │
     │                     [FFmpeg Concat Demuxer] ──> (Encodes H.264 MP4)
     │                              │
     │                     [Zero-Orphan Cleanup of Temp Frame Files]
     └─────┬────────────────────────┘
           │
           ▼
[Storage Hierarchy Manager] ───> (/storage/emulated/0/Download/Media/<Platform>/...)
           │
           ▼
[MediaStore Gallery Scanner] ──> (Triggers instant visibility in Gallery & Photos)
```

---

### Supported Platforms and Extraction Features

#### 1. YouTube
- Supports standard watch URLs (`youtube.com/watch?v=`), short URLs (`youtu.be/`), embedded links (`/embed/`), **YouTube Shorts** (`/shorts/`), and archived live streams (**YouTube Live** `/live/`).
- Direct stream selection supporting up to **1080p Full HD**, 720p HD, and pure audio extraction (**M4A / AAC** 128 kbps).
- Pure on-device stream link extraction.

#### 2. Pixiv
- Full master original artwork extraction from `pximg.net` storage using official HTTP `Referer` headers.
- Multi-page manga and carousel illustrations support.
- **Ugoira-to-MP4 On-Device Assembly**: Downloads the original ZIP frame archive, parses exact frame delay timings (milliseconds) from official metadata, and compiles them into a standard H.264 MP4 video (`yuv420p` with `-movflags faststart`) directly inside the phone.
- **Zero Residual Frames**: Temporary frame images uncompressed during assembly are wiped cleanly immediately after FFmpeg completes.

#### 3. Pinterest
- Downloads master original image files (automatically transforming preview dimensions such as `/236x/` or `/736x/` to `/originals/`).
- Downloads high-resolution MP4 Pin video streams.
- Full resolution of shortlinks (`pin.it`) as well as global regional domains (ccTLDs) including `pinterest.com`, `pinterest.co.uk`, `pinterest.de`, `pinterest.fr`, `pinterest.ca`, `pinterest.jp`, etc.
- Smart folder placement: Author-created Pins are kept in the creator root directory, while saved boards are structured into board-named subfolders.

#### 4. Twitter / X
- Full support for both `twitter.com` and `x.com` domains.
- Master resolution photo extraction (`name=orig`).
- Automatic selection and download of the highest bitrate MP4 video variant via high-reliability syndication endpoints without requiring personal API developer keys.

#### 5. TikTok
- High-definition video extraction **without watermarks**.
- Seamless expansion and resolution of `vm.tiktok.com` and `vt.tiktok.com` shortlinks.
- Support for TikTok photo slideshow posts (`/photo/` URLs).

#### 6. Instagram
- Supports **Instagram Reels**, standard feed videos, and carousel photo sets.
- Handles `/p/`, `/reel/`, `/reels/`, and `/tv/` URL formats.
- **Safe Fallback**: Includes a direct CDN fallback mechanism to ensure web HTML authentication error pages are never mistakenly saved with an `.mp4` extension.

---

### Usage Instructions

#### Flow 1: Android System Share Sheet (ACTION_SEND) — Fastest
1. Open any social media app on your phone (YouTube, Twitter/X, Pixiv, Instagram, Pinterest, TikTok).
2. Tap the **Share** button on the post or video.
3. Select **Universal Downloader** from the Android application picker.
4. The application will launch or foreground automatically, extract the media metadata, and display available formats.
5. Tap **Download Now**. The download progress will display in your Android notification shade.

#### Flow 2: Manual URL Paste
1. Copy the URL of any supported post to your clipboard.
2. Launch the **Universal Downloader** app.
3. Tap **Paste Link** (or paste manually into the input field) and tap **Check URL**.
4. Once metadata and resolution options appear, select your preferred quality and tap **Download Now**.

---

### Storage Hierarchy & File Management

All completed files are organized inside the device's public storage tree, accessible by third-party file managers and players:

```text
/storage/emulated/0/Download/Media/<Platform_Name>/<Creator_Name>/[<WorkId>/]<Filename>
```

#### Adaptive Hierarchy Rules
- **First Single Download**: If an artist is downloaded for the first time with a single media file, it is saved directly into the creator root folder:
  `Download/Media/Pixiv/ArtistName/ArtworkTitle_12345678.png`
- **Multi-Page Sets & Subsequent Downloads**: If the post contains multiple items (manga album or carousel) or if a second post by the same creator is downloaded, the app creates a dedicated `<WorkId>` subfolder to prevent folder clutter.
- **Automatic Migration**: Any preexisting single files belonging to that same work ID are automatically relocated into the newly established work directory.
- **Pinterest Rules**: Creator-authored Pins remain in the creator root folder, while saved boards are placed within their respective board-named folders.

#### Clean Cancellation & Zero Orphaned Files
- In-progress transfers write to temporary `.part` files.
- If you tap **Cancel** or if an unrecoverable network failure occurs, the background worker automatically deletes all partial files (`.part`, `.tmp`, `.crdownload`, and empty 0-byte stubs).
- Ugoira temporary frame extraction directories are guaranteed to be cleaned up within a `finally` block, ensuring no temporary files consume device storage.

#### Automatic MediaStore Gallery Scanning
- Immediately after a `.part` file is renamed to its final target path, the application invokes the native platform channel `scanMediaFile`, calling Android's `MediaScannerConnection`.
- New photos and videos appear instantaneously inside the system Gallery, Google Photos, and media players without requiring a device restart.

---

### Cookie Vault Configuration

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

### APK Architecture Decision Matrix

Choose the APK package tailored to your phone's processor for minimal memory usage and optimal performance:

| APK File Name | CPU Architecture | Device Compatibility | File Size | Recommended Reason |
| :--- | :--- | :--- | :--- | :--- |
| **`app-arm64-v8a-release.apk`** | `arm64-v8a` | Modern 64-bit Android smartphones (Snapdragon, MediaTek, Exynos, Tensor 2017+) | ~28 MB | **Top Recommendation.** Native 64-bit performance, lowest RAM consumption, and smallest download footprint. |
| **`app-release.apk`** | FAT Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | 100% of all Android phones, tablets, and emulators | ~75 MB | **Fail-Safe Choice.** Bundles C++ libraries for all architectures. Use this if you are uncertain of your device processor. |
| **`app-armeabi-v7a-release.apk`** | `armeabi-v7a` | Older legacy 32-bit Android phones or entry-level chipsets | ~26 MB | For older 32-bit ARM hardware. Cannot be installed on modern 64-bit-only Android releases. |
| **`app-x86_64-release.apk`** | `x86_64` | PC Android Emulators (BlueStacks, LDPlayer, Nox, Android Studio AVD), ChromeOS x86 | ~30 MB | For Intel/AMD 64-bit desktop emulators and x86 Android OS environments. |

> **How to verify your phone CPU**: Download an inspector app such as *Inware*, *AIDA64*, or *CPU-Z* from the Play Store and inspect **SoC -> Instruction Set**. If it indicates `arm64-v8a` or `aarch64`, download the **ARM64** APK.

---

### Step-by-Step Sideloading Installation Guide (Android 8.0 – 15+)

Because Universal Media Downloader is distributed independently outside the Google Play Store (*sideloading*), Android requires manual authorization.

#### Step 1: Downloading the APK
1. Download your preferred APK variant (e.g. `app-arm64-v8a-release.apk`) using your web browser (Chrome, Firefox, Brave, Samsung Internet) or file manager.
2. Once the download finishes, tap the completed download notification or open the file from your **Files** application.

#### Step 2: Granting "Install Unknown Apps" Permission
Depending on your Android operating system version:

- **Android 8.0 through 12 (Oreo, Pie, 10, 11, 12)**:
  1. A security prompt will appear: *"For your security, your phone is not allowed to install unknown apps from this source"*.
  2. Tap **Settings**.
  3. Toggle the switch for **Allow from this source** to ON.
  4. Tap the **Back** navigation button, then tap **Install**.

- **Android 13 through 15+ (Tiramisu, Upside Down Cake, Vanilla Ice Cream)**:
  1. If prompted for source permissions, navigate to Settings and enable installation for your browser or file manager.
  2. **Google Play Protect Warning**: If a dialog states *"Blocked by Play Protect"* or *"Unrecognized App"*:
     - Tap **More details** (or the small expandable arrow beneath the message).
     - Tap **Install anyway**.
  3. Tap **Install**. Once completed, tap **Open**.

---

### Build & Quality Verification Instructions

To compile and verify the application directly from source code:

#### Prerequisites
- Flutter SDK (`>= 3.1.0`)
- Dart SDK (`>= 3.1.0`)
- Java Development Kit (JDK 17)
- Android SDK Platform-Tools & Build-Tools (version 34.0.0 or 35.0.0)
- Python 3.8+ (for cross-platform automated verification scripts)

#### 1. Dependencies & Unit Tests
```bash
# Fetch pub dependencies
flutter pub get

# Run test suites and extractor regex validation
flutter test
```

#### 2. Compiling Release APKs
```bash
# Compile single Universal Release APK
flutter build apk --release

# Compile all split-per-ABI release binaries
flutter build apk --release --split-per-abi
```
Generated release binaries are placed in `build/app/outputs/flutter-apk/`.

#### 3. Automated APK Quality Gate Verification
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

#### 4. SHA-256 Checksum Validation
```bash
# Linux / macOS
cd build/app/outputs/flutter-apk
sha256sum *.apk > SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt

# Windows (PowerShell)
cd build\app\outputs\flutter-apk
Get-FileHash -Algorithm SHA256 *.apk
```
