@echo off
title Push Universal Media Downloader Android to GitHub
cd /d "%~dp0"
echo ======================================================================
echo   Universal Media Downloader Android - Push to GitHub
echo ======================================================================
echo.
echo Make sure an empty repository 'universal-media-downloader-android' is created at:
echo https://github.com/new
echo.
git push -u origin main
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Successfully pushed to GitHub!
    echo Automated APK build workflow is now running at:
    echo https://github.com/zeroo-crypto/universal-media-downloader-android/actions
) else (
    echo.
    echo [INFO] If push failed due to 'Repository not found':
    echo Please open https://github.com/new and create a repository named:
    echo universal-media-downloader-android (Public or Private, leave it empty)
    echo then run this script again.
)
echo.
pause
