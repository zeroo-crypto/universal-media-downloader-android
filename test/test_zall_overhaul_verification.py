import os
import re
import unittest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

class TestZallOverhaulVerification(unittest.TestCase):
    def test_app_label_in_manifest(self):
        manifest_path = os.path.join(REPO_ROOT, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')
        self.assertTrue(os.path.exists(manifest_path), "AndroidManifest.xml must exist")
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('android:label="ZALL"', content, "App label must be ZALL")
        self.assertIn('android:icon="@mipmap/ic_launcher"', content)
        self.assertIn('android:roundIcon="@mipmap/ic_launcher_round"', content)

    def test_launcher_icons_exist_all_densities(self):
        res_dir = os.path.join(REPO_ROOT, 'android', 'app', 'src', 'main', 'res')
        densities = ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi']
        for d in densities:
            sq_icon = os.path.join(res_dir, d, 'ic_launcher.png')
            rd_icon = os.path.join(res_dir, d, 'ic_launcher_round.png')
            self.assertTrue(os.path.exists(sq_icon), f"Square launcher icon missing for {d}")
            self.assertTrue(os.path.exists(rd_icon), f"Round launcher icon missing for {d}")
            self.assertGreater(os.path.getsize(sq_icon), 500, f"Icon {sq_icon} must not be empty")
            self.assertGreater(os.path.getsize(rd_icon), 500, f"Icon {rd_icon} must not be empty")

    def test_zall_theme_palette(self):
        theme_path = os.path.join(REPO_ROOT, 'lib', 'ui', 'theme', 'zall_theme.dart')
        self.assertTrue(os.path.exists(theme_path), "zall_theme.dart must exist")
        with open(theme_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check required hex colors
        self.assertIn('0xFF141417', content, "Main background #141417 missing")
        self.assertIn('0xFF202129', content, "Card surface #202129 missing")
        self.assertIn('0xFF14151B', content, "Circle surface #14151B missing")
        self.assertIn('0xFF3B82F6', content, "Primary Blue #3B82F6 missing")
        self.assertIn('0xFF2563EB', content, "Action Blue #2563EB missing")
        self.assertIn('0xFF60A5FA', content, "Highlight Blue #60A5FA missing")
        self.assertIn('GoogleFonts.poppinsTextTheme', content, "Poppins font theme missing")

    def test_no_unwanted_sections(self):
        home_path = os.path.join(REPO_ROOT, 'lib', 'ui', 'screens', 'home_screen.dart')
        with open(home_path, 'r', encoding='utf-8') as f:
            home_content = f.read()
        self.assertNotIn('Alat Cepat', home_content, "Alat Cepat section must NOT be present")

        settings_path = os.path.join(REPO_ROOT, 'lib', 'ui', 'screens', 'settings_screen.dart')
        with open(settings_path, 'r', encoding='utf-8') as f:
            settings_content = f.read()
        self.assertNotIn('Apresiasi', settings_content, "Apresiasi section must NOT be present")
        self.assertNotIn('PayPal', settings_content, "PayPal must NOT be present")
        self.assertNotIn('QRIS', settings_content, "QRIS must NOT be present")

    def test_six_platform_badges_in_home(self):
        home_path = os.path.join(REPO_ROOT, 'lib', 'ui', 'screens', 'home_screen.dart')
        with open(home_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('Platform yang Didukung', content)
        self.assertIn('YouTube', content)
        self.assertIn('Pixiv', content)
        self.assertIn('Instagram', content)
        self.assertIn('Pinterest', content)
        self.assertIn('TikTok', content)
        self.assertIn('Twitter/X', content)

    def test_batch_download_support(self):
        service_path = os.path.join(REPO_ROOT, 'lib', 'services', 'download_service.dart')
        with open(service_path, 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertIn('enqueueBatchDownload', content, "enqueueBatchDownload method must exist")
        self.assertIn('deleteDownloadedFile', content, "deleteDownloadedFile method must exist")

    def test_all_screens_exist(self):
        screens = [
            os.path.join(REPO_ROOT, 'lib', 'ui', 'screens', 'home_screen.dart'),
            os.path.join(REPO_ROOT, 'lib', 'ui', 'screens', 'gallery_screen.dart'),
            os.path.join(REPO_ROOT, 'lib', 'ui', 'screens', 'settings_screen.dart'),
            os.path.join(REPO_ROOT, 'lib', 'ui', 'widgets', 'media_preview_sheet.dart'),
            os.path.join(REPO_ROOT, 'lib', 'ui', 'widgets', 'zall_illustrations.dart'),
        ]
        for s in screens:
            self.assertTrue(os.path.exists(s), f"Screen or widget file missing: {s}")

if __name__ == '__main__':
    unittest.main()
