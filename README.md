# Universal Media Downloader (Android)

Aplikasi pengunduh media mandiri (*standalone on-device*) untuk perangkat Android (Android 8.0 s.d. Android 15+). Berjalan langsung di ponsel tanpa memerlukan server atau PC.

[**>> Unduh Berkas APK Versi Terbaru (v1.0.0) <<**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/latest)

---

## Cara Unduh dan Pasang di HP Android

1. Buka halaman [**Releases**](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/latest).
2. Di bagian **Assets**, ketuk file **`app-release.apk`** untuk mengunduhnya langsung ke HP Anda.
3. Setelah selesai diunduh, buka file tersebut.
4. Jika muncul peringatan keamanan *"Demi keamanan, ponsel Anda tidak diizinkan memasang aplikasi dari sumber ini"*:
   - Pilih **Setelan / Pengaturan** (*Settings*).
   - Aktifkan opsi **Izinkan dari sumber ini** (*Allow from this source*).
5. Tekan **Pasang** (*Install*).

---

## Cara Penggunaan

### 1. Melalui Menu "Bagikan" (Share Sheet) — Paling Cepat
1. Buka aplikasi media sosial di ponsel Anda (YouTube, Pixiv, Twitter/X, Instagram, Pinterest, TikTok).
2. Tekan tombol **Bagikan** (*Share*).
3. Pilih aplikasi **Universal Downloader**.
4. Aplikasi akan terbuka otomatis, membaca link, dan menampilkan tombol **Unduh Sekarang**.

### 2. Melalui Input Manual
1. Salin tautan media yang ingin diunduh.
2. Buka aplikasi **Universal Downloader**.
3. Tekan tombol **Tempel Link** lalu tekan **Periksa URL**.
4. Pilih kualitas atau format yang diinginkan, kemudian tekan **Unduh Sekarang**.

---

## Platform yang Didukung

- **YouTube**: Video 1080p, 720p, Shorts, dan opsi audio saja (M4A).
- **Pixiv**: Ilustrasi resolusi asli, album manga multi-halaman, dan animasi Ugoira (otomatis dikonversi menjadi video MP4 dengan delay resmi).
- **Pinterest**: Gambar resolusi asli (originals) dan video Pin.
- **Twitter / X**: Foto resolusi master dan video MP4 kualitas tertinggi.
- **TikTok**: Video HD tanpa watermark.
- **Instagram**: Video Reels, foto carousel, dan postingan.

---

## Lokasi Penyimpanan File di HP

Semua file yang diunduh tersimpan rapi di penyimpanan publik perangkat:
```text
Penyimpanan Internal/Download/Media/<Platform>/<Nama_Kreator>/...
```
- **Adaptive Hierarchy**: Jika kreator memiliki lebih dari satu karya atau album multi-halaman, berkas dikelompokkan ke subfolder ID karya secara otomatis.
- **Pembersihan Otomatis**: Jika unduhan dibatalkan atau terputus di tengah jalan, berkas sementara (`.part`) otomatis dimusnahkan agar tidak membuang ruang penyimpanan.

---

## Pengaturan Cookie Vault

Untuk mengunduh konten yang membutuhkan login (misalnya ilustrasi Pixiv dengan batasan umur/R-18):
1. Buka tab **Pengaturan** di dalam aplikasi.
2. Pada bagian **Cookie Vault**, pilih platform (misalnya Pixiv).
3. Masukkan token sesi akun Anda (`PHPSESSID` untuk Pixiv, atau `auth_token` untuk Twitter).

---

## Kompilasi dari Kode Sumber (Opsional)

Jika Anda seorang pengembang dan ingin mengompilasi APK sendiri:
```bash
# Pasang dependensi
flutter pub get

# Jalankan pengujian
flutter test

# Bangun APK rilis
flutter build apk --release --split-per-abi
```
