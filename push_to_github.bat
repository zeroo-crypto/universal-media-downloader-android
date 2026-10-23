@echo off
title Push Universal Media Downloader Android to GitHub
cd /d "%~dp0"
echo ======================================================================
echo   Universal Media Downloader Android - Push to GitHub
echo ======================================================================
echo.
echo Pastikan repo kosong 'universal-media-downloader-android' sudah dibuat di:
echo https://github.com/new
echo.
git push -u origin main
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUKSES] Berhasil di-push ke GitHub!
    echo Alur kerja build APK otomatis sekarang berjalan di:
    echo https://github.com/zeroo-crypto/universal-media-downloader-android/actions
) else (
    echo.
    echo [INFO] Jika gagal karena 'Repository not found':
    echo Silakan buka https://github.com/new dan buat repo bernama:
    echo universal-media-downloader-android (Public atau Private, biarkan kosong)
    echo lalu jalankan script ini kembali.
)
echo.
pause
