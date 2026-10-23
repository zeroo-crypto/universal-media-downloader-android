# Universal Media Downloader - Android APK (Standalone On-Device)

Aplikasi Android mandiri (*Standalone On-Device*) untuk mengunduh, mengekstrak, dan menata berkas media dari berbagai platform populer (YouTube, Pixiv, Pinterest, Twitter/X, TikTok, Instagram) langsung di ponsel Android tanpa membutuhkan PC atau server backend.

---

## Fitur Utama

1. **Android Share Sheet Integration (`ACTION_SEND`)**:
   - Cukup tekan tombol **"Bagikan"** (Share) dari aplikasi YouTube, Pixiv, Twitter, Pinterest, Instagram, atau TikTok -> pilih **Universal Downloader**.
   - Aplikasi otomatis membaca tautan, mengekstrak resolusi tertinggi, dan menampilkan kartu konfirmasi unduhan.

2. **Kepatuhan Aturan Hierarki Folder (Anti-Amnesia Memory Rules)**:
   - Tersimpan di: `/storage/emulated/0/Download/Media/<Platform>/<Nama_Creator>/...`
   - **Adaptive Hierarchy**: Karya tunggal pertama tersimpan di root artis. Unduhan ke-2 atau album multi-halaman otomatis masuk ke subfolder ID karya disertai migrasi otomatis file lama.
   - **Aturan Pinterest**: Created Pins tersimpan di root nama kreator, sedangkan Saved Boards tersimpan di subfolder nama board.
   - **Zero Generic Folders**: Melarang folder sampah bernama `<Platform> Media`.

3. **Background Service & Status Bar Notification**:
   - Berjalan stabil di latar belakang menggunakan `flutter_foreground_task` sehingga tidak terbunuh oleh Android Doze Mode.
   - Bilah notifikasi interaktif menampilkan progres persentase, kecepatan unduh (MB/s), serta tombol batal.

4. **On-Device Media Processing**:
   - **Pixiv Ugoira**: Mengunduh ZIP frame langsung di memori ponsel dan mengompilasinya menjadi video MP4 berkualitas tinggi (H.264) menggunakan engine mobile `FFmpeg-Kit` dengan delay resmi Pixiv.
   - **Zero Redundant GIF**: Otomatis memusnahkan frame sementara dan file perantara setelah MP4 tervalidasi.

5. **Zero Orphaned Files & Clean Cancellation**:
   - Jika unduhan dibatalkan atau terputus, seluruh file perantara (`.part`, `.tmp`, `.crdownload`, dan file 0-byte) otomatis dibersihkan seketika.

6. **In-App Cookie Vault**:
   - Pengaturan penyimpanan token sesi untuk akses konten terbatas (Pixiv `PHPSESSID` untuk karya R-18, Twitter `auth_token`, Instagram `sessionid`).

---

## Struktur Repositori

```text
universal-media-downloader-android/
├── .github/workflows/
│   └── build_apk.yml             # Otomasi build APK via GitHub Actions Cloud
├── android/
│   └── app/
│       ├── src/main/AndroidManifest.xml  # Permissions & Share Intent Filter
│       └── build.gradle                  # MinSDK 24, TargetSDK 34, ABI splits
├── lib/
│   ├── core/
│   │   ├── constants/platforms.dart      # Platform & Media type definitions
│   │   ├── storage/hierarchy_manager.dart# Penegakan aturan hierarki folder
│   │   ├── processors/ffmpeg_processor.dart # FFmpeg-Kit mobile assembler
│   │   └── utils/clean_cancel.dart       # Zero orphaned files cleaner
│   ├── extractors/
│   │   ├── base_extractor.dart           # Kontrak dasar ekstraktor
│   │   ├── pixiv_extractor.dart          # Single, Manga, Ugoira zip -> MP4
│   │   ├── youtube_extractor.dart        # Video 1080p/720p & Audio M4A
│   │   ├── pinterest_extractor.dart      # High-res Pins & Boards
│   │   ├── twitter_extractor.dart        # Original Photos & High-bitrate MP4
│   │   ├── tiktok_extractor.dart         # Watermark-free HD video
│   │   └── extractor_registry.dart       # Master URL dispatcher & router
│   ├── services/
│   │   ├── download_service.dart         # Queue worker, Dio stream & notifications
│   │   ├── share_intent_service.dart     # Share Sheet receiver
│   │   └── cookie_vault_service.dart     # Local encrypted session vault
│   ├── ui/
│   │   ├── screens/                      # Home, Downloads, Settings
│   │   └── widgets/                      # Preview & Progress cards
│   └── main.dart                         # Entry point aplikasi
└── pubspec.yaml                          # Dependensi Flutter
```

---

## Cara Kompilasi & Menghasilkan File APK

### Opsi 1: Otomatis via GitHub Actions (Tanpa Perlu Pasang Apapun di PC)
1. Buat repositori baru di GitHub (bisa private atau public).
2. Push folder proyek ini ke repositori Anda:
   ```bash
   git init
   git add .
   git commit -m "feat: Universal Media Downloader Standalone Android APK"
   git branch -M main
   git remote add origin https://github.com/USERNAME/REPO_NAME.git
   git push -u origin main
   ```
3. Buka tab **Actions** di GitHub -> alur kerja **Build Android APK** akan otomatis berjalan.
4. Setelah selesai (~3-5 menit), unduh berkas APK siap pakai (`app-arm64-v8a-release.apk` atau `app-release.apk`) di bagian **Artifacts**.

### Opsi 2: Kompilasi Lokal di PC
Jika di komputer Anda sudah terpasang Flutter SDK dan Android SDK:
```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan pengujian
flutter test

# 3. Bangun berkas APK Release
flutter build apk --release --split-per-abi

# Hasil APK akan tersedia di:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
