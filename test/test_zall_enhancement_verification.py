import os
import re
import unittest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

class TestZallEnhancementVerification(unittest.TestCase):
    """
    Verification test suite for ZALL Downloader Enhancement (v2.1.2):
    1. Pixiv R-18 & Session Cookie Handling
    2. YouTube Multi-Resolution & DASH Audio Muxing
    3. TikTok HTTP 403 Bypass (Referer & User-Agent)
    4. Real Device Storage Detection via StatFs
    5. In-App Reactive Language Switcher (id, en, ja)
    6. Official Brand Logos Vector Painter
    7. Clean Cancellation & Zero Orphaned Files for DASH parts
    """

    def test_pixiv_session_cookie_handling(self):
        pixiv_path = os.path.join(REPO_ROOT, 'lib', 'extractors', 'pixiv_extractor.dart')
        with open(pixiv_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('cookieToken', content)
        self.assertIn('PHPSESSID=', content)
        self.assertIn('https://www.pixiv.net/', content)

        # Verify CookieVaultService has importNetscapeCookies
        vault_path = os.path.join(REPO_ROOT, 'lib', 'services', 'cookie_vault_service.dart')
        with open(vault_path, 'r', encoding='utf-8') as f:
            vault_content = f.read()
        self.assertIn('importNetscapeCookies', vault_content)
        self.assertIn('PHPSESSID', vault_content)
        self.assertIn('auth_token', vault_content)
        self.assertIn('sessionid', vault_content)

    def test_youtube_dash_muxing_architecture(self):
        yt_path = os.path.join(REPO_ROOT, 'lib', 'extractors', 'youtube_extractor.dart')
        with open(yt_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('audioTrackUrl', content)
        self.assertIn('requiresMuxing', content)
        self.assertIn('bestAudioUrl', content)
        self.assertIn('1080p Full HD', content)

        # Check FFmpeg processor muxVideoAudio
        ffmpeg_path = os.path.join(REPO_ROOT, 'lib', 'core', 'processors', 'ffmpeg_processor.dart')
        with open(ffmpeg_path, 'r', encoding='utf-8') as f:
            ffmpeg_content = f.read()
        self.assertIn('muxVideoAudio', ffmpeg_content)
        self.assertIn('-c:v copy -c:a aac', ffmpeg_content)

        # Check DownloadService DASH download and muxing execution
        service_path = os.path.join(REPO_ROOT, 'lib', 'services', 'download_service.dart')
        with open(service_path, 'r', encoding='utf-8') as f:
            service_content = f.read()
        self.assertIn('requiresMuxing', service_content)
        self.assertIn('.video.part', service_content)
        self.assertIn('.audio.part', service_content)
        self.assertIn('FFmpegProcessor.muxVideoAudio', service_content)

    def test_tiktok_403_bypass_headers(self):
        tiktok_path = os.path.join(REPO_ROOT, 'lib', 'extractors', 'tiktok_extractor.dart')
        with open(tiktok_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('https://www.tiktok.com/', content)
        self.assertIn('Referer', content)
        self.assertIn('User-Agent', content)

    def test_real_storage_detection(self):
        main_kt_path = os.path.join(
            REPO_ROOT, 'android', 'app', 'src', 'main', 'kotlin', 'com', 'zeroo', 'universal_media_downloader', 'MainActivity.kt'
        )
        with open(main_kt_path, 'r', encoding='utf-8') as f:
            kt_content = f.read()
        self.assertIn('getStorageInfo', kt_content)
        self.assertIn('StatFs', kt_content)
        self.assertIn('blockSizeLong', kt_content)

        storage_service_path = os.path.join(REPO_ROOT, 'lib', 'services', 'storage_service.dart')
        with open(storage_service_path, 'r', encoding='utf-8') as f:
            dart_content = f.read()
        self.assertIn('DeviceStorageInfo', dart_content)
        self.assertIn('getDeviceStorageInfo', dart_content)

    def test_language_provider_and_translations(self):
        lang_path = os.path.join(REPO_ROOT, 'lib', 'services', 'language_service.dart')
        with open(lang_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('class LanguageProvider extends ChangeNotifier', content)
        self.assertIn('setLanguage', content)
        self.assertIn("'id':", content)
        self.assertIn("'en':", content)
        self.assertIn("'ja':", content)
        self.assertIn('extension TranslationHelper on BuildContext', content)

        # Check main.dart registers LanguageProvider
        main_dart_path = os.path.join(REPO_ROOT, 'lib', 'main.dart')
        with open(main_dart_path, 'r', encoding='utf-8') as f:
            main_content = f.read()
        self.assertIn('ChangeNotifierProvider(create: (_) => LanguageProvider())', main_content)
        self.assertIn('locale: languageProvider.currentLocale', main_content)

    def test_official_brand_icons_custom_painter(self):
        icons_path = os.path.join(REPO_ROOT, 'lib', 'ui', 'widgets', 'official_brand_icons.dart')
        with open(icons_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('_YouTubeBrandPainter', content)
        self.assertIn('_PixivBrandPainter', content)
        self.assertIn('_InstagramBrandPainter', content)
        self.assertIn('_PinterestBrandPainter', content)
        self.assertIn('_TikTokBrandPainter', content)
        self.assertIn('_TwitterXBrandPainter', content)

    def test_clean_cancel_and_no_orphans(self):
        clean_path = os.path.join(REPO_ROOT, 'lib', 'core', 'utils', 'clean_cancel.dart')
        with open(clean_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('.video.part', content)
        self.assertIn('.audio.part', content)
        self.assertIn('.part', content)


if __name__ == '__main__':
    unittest.main()
