<div align="center">

# 🚀 Universal Media Downloader AI Agent (Android APK)

### Aplikasi Pengunduh Media Mandiri (Standalone On-Device) untuk Semua HP Android
**100% Berjalan di HP • Tanpa Butuh PC • Tanpa Perlu Server • Integrasi Tombol Bagikan**

[![Android](https://img.shields.io/badge/Platform-Android%208.0%2B%20(Oreo%20s.d.%2015%2B)-brightgreen?style=for-the-badge&logo=android)](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/latest)
[![Release](https://img.shields.io/github/v/release/zeroo-crypto/universal-media-downloader-android?style=for-the-badge&color=blue)](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/zeroo-crypto/universal-media-downloader-android/build_apk.yml?style=for-the-badge&logo=githubactions)](https://github.com/zeroo-crypto/universal-media-downloader-android/actions)

<br/>

<a href="https://github.com/zeroo-crypto/universal-media-downloader-android/releases/latest">
  <img src="https://img.shields.io/badge/📥%20KLIK%20DI%20SINI%20UNTUK%20DOWNLOAD%20APK%20(GRATIS)-0088CC?style=for-the-badge&logo=android&logoColor=white" height="55" alt="Download APK"/>
</a>

<br/><br/>
</div>

---

## 📖 Apa Itu Universal Media Downloader?

**Universal Media Downloader** adalah aplikasi Android mandiri untuk mengunduh, mengekstrak resolusi tertinggi, dan merapikan koleksi media Anda dari berbagai platform populer (YouTube, Pixiv, Twitter/X, TikTok, Instagram, Pinterest) langsung ke galeri HP Anda.

Semua proses konversi (seperti mengubah animasi Pixiv Ugoira menjadi video MP4, ekstraksi lagu MP3/M4A, pembersihan file sampah) dikerjakan secara lokal di dalam HP Anda.

---

## 📥 Panduan Download & Install (Untuk Orang Awam & Pemula)

Anda tidak perlu paham coding atau seluk-beluk GitHub untuk menggunakannya. Cukup ikuti 4 langkah mudah ini:

### 1. Download Berkas APK
Klik tombol biru **[DOWNLOAD APK DI SINI](https://github.com/zeroo-crypto/universal-media-downloader-android/releases/latest)** di atas, lalu pada bagian paling bawah (**Assets**), pilih:
- **`app-release.apk`** *(Disarankan untuk semua merk HP Android: Samsung, Xiaomi, Oppo, Vivo, Realme, Infinix, Pixel, dll)*.

### 2. Buka File Hasil Download
Setelah proses download selesai di browser HP Anda (Chrome, Samsung Internet, dll), buka file **`app-release.apk`**.

### 3. Izinkan Pemasangan Aplikasi
Jika muncul pemberitahuan keamanan:
> *"Demi keamanan, ponsel Anda tidak diizinkan memasang aplikasi tidak dikenal dari sumber ini"*
- Ketuk **Pengaturan (Settings)**.
- Aktifkan tombol centang **"Izinkan dari sumber ini"** (*Allow from this source*).
- Tekan tombol kembali (*Back*).

### 4. Pasang (Install)
Ketuk tombol **Pasang (Install)** dan tunggu beberapa detik hingga selesai. Aplikasi siap digunakan!

---

## ⚡ Cara Pakai: Super Cepat via Tombol "Bagikan"

Anda tidak perlu repot-repot menyalin dan menempel link secara manual!

1. Buka aplikasi medsos favorit Anda (YouTube, Pixiv, TikTok, Twitter/X, Instagram, atau Pinterest).
2. Temukan video atau gambar yang ingin Anda simpan.
3. Ketuk tombol **Bagikan (Share)** -> lalu pilih ikon **Universal Downloader**.
4. Aplikasi akan otomatis terbuka, menganalisis media resolusi tertinggi, dan menampilkan tombol **Unduh Sekarang**!

> *(Tersedia juga opsi manual: Anda bisa menyalin link lalu menekan tombol **"Tempel Link"** di beranda aplikasi).*

---

## 🎯 Platform yang Didukung

| Platform | Format & Kualitas yang Didukung | Fitur Khusus |
| :--- | :--- | :--- |
| **YouTube** | Video 1080p Full HD, 720p HD, Audio M4A (160kbps), Shorts | Pilihan resolusi bebas & unduh audio lagu saja |
| **Pixiv** | Ilustrasi High-Res (JPG/PNG), Manga Multi-Halaman (Album), Ugoira | Animasi Ugoira (ZIP) otomatis dirakit jadi video **MP4 mulus** on-device! |
| **Pinterest** | Foto Kualitas Asli (*Originals*), Video Pin MP4 | Pemisahan rapi antara Created Pins & Saved Boards |
| **Twitter / X** | Foto Master Resolusi Maksimal (`?name=orig`), Video MP4 Bitrate Tertinggi | Penataan folder otomatis berdasarkan nama user |
| **TikTok** | Video HD Jernih **Tanpa Watermark** | Mendukung link pendek (`vt.tiktok.com`) |
| **Instagram** | Video Reels HD, Foto Carousel Multi-Slide, Postingan | Otomatis mengunduh slide lengkap |

---

## 📁 Struktur Folder Rapi di HP Anda (Anti-Berantakan)

Berkas yang diunduh tidak akan berserakan di sembarang tempat. Semuanya tertata otomatis di folder publik HP Anda:
```text
Penyimpanan Internal/Download/Media/
├── YouTube/<Nama_Channel>/video.mp4
├── Pixiv/<Nama_Artis>/<ID_Karya>/gambar.jpg
├── Pixiv/<Nama_Artis>/<ID_Karya>/animasi.mp4
├── Pinterest/<Nama_Kreator>/pin.jpg
├── Twitter/<Username>/foto.jpg
└── TikTok/<Username>/video.mp4
```

- **Adaptive Hierarchy**: Jika seorang kreator memiliki lebih dari 1 karya atau album manga, aplikasi otomatis mengelompokkannya ke subfolder ID karya masing-masing.
- **Zero Orphaned Files**: Jika unduhan dibatalkan di tengah jalan, berkas sementara (`.part` / `.tmp`) otomatis dimusnahkan agar memori HP Anda tetap bersih.

---

## ❓ Tanya Jawab (FAQ)

<details>
<summary><b>1. Apakah aplikasi ini aman digunakan?</b></summary>
Sangat aman! Seluruh kode aplikasi bersifat terbuka (open source) dan transparan. Tidak ada pelacak, tidak ada iklan pihak ketiga, dan tidak ada pengiriman data pribadi ke server manapun.
</details>

<details>
<summary><b>2. Apakah butuh PC atau laptop yang menyala?</b></summary>
Sama sekali TIDAK. Aplikasi ini 100% mandiri (*Standalone On-Device*) dan menjalankan seluruh tugas ekstraksi dan konversi langsung menggunakan prosesor ponsel Android Anda.
</details>

<details>
<summary><b>3. Bagaimana jika ingin mengunduh karya Pixiv yang dibatasi umur (R-18)?</b></summary>
Buka menu <b>Pengaturan</b> di dalam aplikasi -> pada bagian <b>Cookie Vault</b>, masukkan token <code>PHPSESSID</code> dari akun Pixiv Anda. Aplikasi akan langsung mengenali izin akun Anda.
</details>

---

<div align="center">
Dibuat dengan ❤️ untuk kemudahan menikmati dan mengarsipkan karya media di Android.
</div>
