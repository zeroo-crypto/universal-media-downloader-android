import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/platforms.dart';
import '../../core/storage/hierarchy_manager.dart';
import '../../core/utils/clean_cancel.dart';
import '../../services/cookie_vault_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../theme/zall_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'Sesuai Sistem';
  bool _notificationsEnabled = true;
  bool _pipEnabled = true;
  String _cacheSize = '0.0 MB';

  DeviceStorageInfo? _storageInfo;
  String? _pixivCookie;
  String? _twitterCookie;
  String? _instagramCookie;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = await StorageService.getDeviceStorageInfo();
    final pixiv = await CookieVaultService.getCookie(MediaPlatform.pixiv);
    final twitter = await CookieVaultService.getCookie(MediaPlatform.twitter);
    final ig = await CookieVaultService.getCookie(MediaPlatform.instagram);

    if (mounted) {
      setState(() {
        _storageInfo = storage;
        _pixivCookie = pixiv;
        _twitterCookie = twitter;
        _instagramCookie = ig;
      });
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF232634),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLanguageDialog() {
    final langProvider = context.read<LanguageProvider>();
    final currentCode = langProvider.languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Text(
          context.tr('setting_language'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Bahasa Indonesia', style: TextStyle(color: Colors.white)),
              value: 'id',
              groupValue: currentCode,
              activeColor: ZallTheme.primaryBlue,
              onChanged: (val) {
                if (val != null) {
                  langProvider.setLanguage(val);
                  Navigator.pop(ctx);
                  _showToast('Bahasa diatur ke Bahasa Indonesia');
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English (US)', style: TextStyle(color: Colors.white)),
              value: 'en',
              groupValue: currentCode,
              activeColor: ZallTheme.primaryBlue,
              onChanged: (val) {
                if (val != null) {
                  langProvider.setLanguage(val);
                  Navigator.pop(ctx);
                  _showToast('Language set to English (US)');
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('日本語 (Japanese)', style: TextStyle(color: Colors.white)),
              value: 'ja',
              groupValue: currentCode,
              activeColor: ZallTheme.primaryBlue,
              onChanged: (val) {
                if (val != null) {
                  langProvider.setLanguage(val);
                  Navigator.pop(ctx);
                  _showToast('言語が日本語に設定されました');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Text(context.tr('setting_theme'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(context.tr('setting_theme_system'), style: const TextStyle(color: Colors.white)),
              value: 'Sesuai Sistem',
              groupValue: _selectedTheme,
              activeColor: ZallTheme.primaryBlue,
              onChanged: (val) {
                setState(() => _selectedTheme = val!);
                Navigator.pop(ctx);
                _showToast('Tema diatur ke ${context.tr('setting_theme_system')}');
              },
            ),
            RadioListTile<String>(
              title: Text(context.tr('setting_theme_dark'), style: const TextStyle(color: Colors.white)),
              value: 'Gelap (Dark Blue)',
              groupValue: _selectedTheme,
              activeColor: ZallTheme.primaryBlue,
              onChanged: (val) {
                setState(() => _selectedTheme = val!);
                Navigator.pop(ctx);
                _showToast('Tema diatur ke ${context.tr('setting_theme_dark')}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cleanCache() async {
    final dir = await HierarchyManager.getBaseMediaDirectory();
    await CleanCancel.cleanupDirectory(dir);
    setState(() {
      _cacheSize = '0.0 MB';
    });
    _showToast('Cache berhasil dibersihkan');
  }

  void _editCookieDialog(MediaPlatform platform, String currentVal) async {
    final controller = TextEditingController(text: currentVal);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Text('Cookie ${platform.displayName}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              platform == MediaPlatform.pixiv
                  ? 'Masukkan nilai token PHPSESSID dari cookie browser Anda:'
                  : platform == MediaPlatform.twitter
                      ? 'Masukkan nilai auth_token dari cookie browser Anda:'
                      : 'Masukkan nilai sessionid dari cookie browser Anda:',
              style: const TextStyle(fontSize: 12, color: ZallTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: platform == MediaPlatform.pixiv
                    ? '12345678_abcdef...'
                    : 'Token cookie...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF14151B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(context.tr('cookie_dialog_clear'), style: const TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(ctx, ''),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZallTheme.actionBlue),
            child: Text(context.tr('cookie_dialog_save')),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result.isEmpty) {
        await CookieVaultService.removeCookie(platform);
        _showToast('Cookie ${platform.displayName} dihapus');
      } else {
        await CookieVaultService.saveCookie(platform, result);
        _showToast('Cookie ${platform.displayName} berhasil disimpan');
      }
      _loadSettings();
    }
  }

  void _showImportNetscapeDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Text(context.tr('cookie_import_file'), style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tempel isi file cookies.txt (format Netscape / curl) di bawah:',
              style: TextStyle(fontSize: 12, color: ZallTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white),
              decoration: InputDecoration(
                hintText: '.pixiv.net\tTRUE\t/\tTRUE\t1750000000\tPHPSESSID\t...\n.twitter.com\tTRUE\t/\tTRUE\t1750000000\tauth_token\t...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF14151B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(context.tr('cancel'), style: const TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZallTheme.actionBlue),
            child: Text(context.tr('cookie_dialog_save')),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final imported = await CookieVaultService.importNetscapeCookies(result);
      if (imported.isNotEmpty) {
        final names = imported.keys.map((k) => k.displayName).join(', ');
        _showToast('Berhasil mengimpor cookie untuk: $names');
      } else {
        _showToast('Tidak ada cookie yang cocok ditemukan dalam format Netscape');
      }
      _loadSettings();
    }
  }

  void _showFaqDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Text(context.tr('help_faq'), style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. Bagaimana cara mengunduh video YouTube dengan audio?\n'
                'Salin link video dari YouTube lalu tempel pada kolom input ZALL. Resolusi 1080p ke atas otomatis dimuxing dengan audio kualitas tinggi.\n\n'
                '2. Bagaimana cara mengunduh karya Pixiv R-18 & Multi-page?\n'
                'Untuk karya publik cukup tempel tautan. Untuk karya R-18 atau bookmark pribadi, masukkan token PHPSESSID atau impor cookies.txt di menu Cookie Sesi.\n\n'
                '3. Mengapa TikTok terkadang error HTTP 403?\n'
                'ZALL v2.1.2 sudah dilengkapi header browser resmi dan Referer bypass sehingga unduhan video dan slideshow foto TikTok berjalan mulus tanpa error.\n\n'
                '4. Di mana letak file yang diunduh?\n'
                'File tersimpan di folder publik Download/Media perangkat Anda dan langsung terindeks di Galeri HP.',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: ZallTheme.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZallTheme.actionBlue),
            child: const Text('Mengerti'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Text(context.tr('help_contact'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Ada kendala atau ingin request fitur?\n\n'
              '• GitHub Issues: github.com/zeroo-crypto/universal-media-downloader-android\n'
              '• Developer: Zeroo Studio\n\n'
              'Kami selalu siap membantu Anda!',
              style: TextStyle(fontSize: 13, height: 1.5, color: ZallTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZallTheme.actionBlue),
            child: const Text('Tutup'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1D26),
        title: Row(
          children: const [
            Text('ZA', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            Text('LL', style: TextStyle(fontWeight: FontWeight.w300, color: Colors.white)),
            Text(' Downloader', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Versi: 2.1.2 (Release Stable)\n\n'
              'ZALL adalah All-in-One Media Downloader modern untuk mengunduh media dari YouTube, Pixiv, Instagram, Pinterest, TikTok, dan X/Twitter dengan kecepatan tinggi dan tanpa watermark.\n\n'
              '© 2026 ZALL Studio. Hak cipta dilindungi.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: ZallTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ZallTheme.actionBlue),
            child: const Text('Tutup'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: ZallTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            // Top Bar: Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 10),

            // Title: "Pengaturan"
            Text(
              context.tr('settings_title'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // Storage Widget (Dynamic from real device StorageService)
            _buildStorageWidget(),
            const SizedBox(height: 28),

            // Group 1: Aplikasi
            Text(
              context.tr('cat_app'),
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // 1. Bahasa
            _buildSettingRow(
              iconBg: const Color(0xFFD8EEFF),
              icon: const Icon(Icons.language, color: Color(0xFF1D74F5), size: 22),
              title: context.tr('setting_language'),
              trailingText: langProvider.displayName,
              onTap: _showLanguageDialog,
            ),
            const SizedBox(height: 12),

            // 2. Notifikasi
            _buildSettingRow(
              iconBg: const Color(0xFFFFE6D5),
              icon: const Icon(Icons.notifications_active, color: Color(0xFFEA580C), size: 22),
              title: context.tr('setting_notifications'),
              subtitle: _notificationsEnabled ? 'Aktif' : 'Nonaktif',
              onTap: () {
                setState(() => _notificationsEnabled = !_notificationsEnabled);
                _showToast('Notifikasi: ${_notificationsEnabled ? 'Aktif' : 'Nonaktif'}');
              },
            ),
            const SizedBox(height: 12),

            // 3. Tema
            _buildSettingRow(
              iconBg: const Color(0xFFDBEAFE),
              icon: const Icon(Icons.dark_mode_outlined, color: Color(0xFF2563EB), size: 22),
              title: context.tr('setting_theme'),
              trailingText: _selectedTheme,
              onTap: _showThemeDialog,
            ),
            const SizedBox(height: 12),

            // 4. Bersihkan Cache
            _buildSettingRow(
              iconBg: const Color(0xFFD7F4FF),
              icon: const Icon(Icons.refresh, color: Color(0xFF0284C7), size: 22),
              title: context.tr('setting_clean_cache'),
              subtitle: '$_cacheSize dapat dibersihkan',
              onTap: _cleanCache,
            ),
            const SizedBox(height: 12),

            // 5. Layar Mengambang (Toggle Switch)
            _buildPipSwitchRow(),
            const SizedBox(height: 12),

            // 6. Cookie Sesi (Pixiv, Twitter, Instagram)
            _buildCookieVaultSection(),
            const SizedBox(height: 28),

            // Group 2: Bantuan
            Text(
              context.tr('cat_help'),
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // 1. Pertanyaan Umum
            _buildSettingRow(
              iconBg: const Color(0xFFFFE6D5),
              icon: const Icon(Icons.help_outline, color: Color(0xFFEA580C), size: 22),
              title: context.tr('help_faq'),
              onTap: _showFaqDialog,
            ),
            const SizedBox(height: 12),

            // 2. Hubungi Kami
            _buildSettingRow(
              iconBg: const Color(0xFFD8EEFF),
              icon: const Icon(Icons.support_agent, color: Color(0xFF0284C7), size: 22),
              title: context.tr('help_contact'),
              onTap: _showContactDialog,
            ),
            const SizedBox(height: 12),

            // 3. Tentang Aplikasi
            _buildSettingRow(
              iconBg: const Color(0xFFDBEAFE),
              icon: const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 22),
              title: context.tr('help_about'),
              subtitle: 'v2.1.2',
              onTap: _showAboutDialog,
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageWidget() {
    final info = _storageInfo;
    final percentage = info != null ? (info.percentage * 100).toInt() : 0;
    final progressValue = info?.percentage ?? 0.0;
    final color = progressValue > 0.9
        ? const Color(0xFFEF4444)
        : (progressValue > 0.75 ? const Color(0xFFF59E0B) : ZallTheme.primaryBlue);

    return InkWell(
      onTap: () {
        if (info != null) {
          _showToast('${context.tr('storage_internal')}: ${context.tr('storage_used')} ${info.formattedUsed} ${context.tr('storage_of')} ${info.formattedTotal} ($percentage%)');
        } else {
          _loadSettings();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ZallTheme.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            // Circular Progress Indicator
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFF2A2B36),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),

            // Storage Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('storage_internal'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info != null
                        ? '${context.tr('storage_used')} ${info.formattedUsed} ${context.tr('storage_of')} ${info.formattedTotal}'
                        : 'Memuat data penyimpanan...',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD4D4D8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info != null
                        ? 'Tersisa: ${info.formattedAvailable}'
                        : 'Menghitung sisa kuota...',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: ZallTheme.highlightBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required Color iconBg,
    required Widget icon,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ZallTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Row(
              children: [
                if (trailingText != null) ...[
                  Text(
                    trailingText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ZallTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25262F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipSwitchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.picture_in_picture_alt, color: Color(0xFF2563EB), size: 22),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('setting_pip'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('setting_pip_sub'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: ZallTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: _pipEnabled,
            activeColor: Colors.white,
            activeTrackColor: ZallTheme.primaryBlue,
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: const Color(0xFF25262F),
            onChanged: (val) {
              setState(() => _pipEnabled = val);
              _showToast('${context.tr('setting_pip')}: ${_pipEnabled ? 'Aktif' : 'Nonaktif'}');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCookieVaultSection() {
    return Container(
      decoration: BoxDecoration(
        color: ZallTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 18, color: ZallTheme.highlightBlue),
              const SizedBox(width: 8),
              Text(
                context.tr('cat_cookies'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showImportNetscapeDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ZallTheme.primaryBlue.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ZallTheme.primaryBlue.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_upload_outlined, size: 13, color: ZallTheme.highlightBlue),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('cookie_import_file'),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ZallTheme.highlightBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Diperlukan jika ingin mengunduh konten Pixiv 18+, bookmark pribadi, atau akun X/Instagram private.',
            style: TextStyle(fontSize: 11, color: ZallTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          // Pixiv PHPSESSID
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.palette, color: ZallTheme.pixivBlue, size: 22),
            title: const Text('Pixiv (PHPSESSID)', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(
              _pixivCookie != null ? 'Tersimpan (Aktif)' : context.tr('cookie_pixiv_sub'),
              style: TextStyle(
                fontSize: 11,
                color: _pixivCookie != null ? Colors.green : ZallTheme.textMuted,
              ),
            ),
            trailing: const Icon(Icons.edit, size: 18, color: Colors.white60),
            onTap: () => _editCookieDialog(MediaPlatform.pixiv, _pixivCookie ?? ''),
          ),
          Divider(color: ZallTheme.dividerColor.withOpacity(0.5), height: 1),
          // Twitter auth_token
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.alternate_email, color: Colors.white, size: 22),
            title: const Text('Twitter / X (auth_token)', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(
              _twitterCookie != null ? 'Tersimpan (Aktif)' : context.tr('cookie_twitter_sub'),
              style: TextStyle(
                fontSize: 11,
                color: _twitterCookie != null ? Colors.green : ZallTheme.textMuted,
              ),
            ),
            trailing: const Icon(Icons.edit, size: 18, color: Colors.white60),
            onTap: () => _editCookieDialog(MediaPlatform.twitter, _twitterCookie ?? ''),
          ),
          Divider(color: ZallTheme.dividerColor.withOpacity(0.5), height: 1),
          // Instagram sessionid
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.camera_alt, color: Color(0xFFE1306C), size: 22),
            title: const Text('Instagram (sessionid)', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(
              _instagramCookie != null ? 'Tersimpan (Aktif)' : context.tr('cookie_instagram_sub'),
              style: TextStyle(
                fontSize: 11,
                color: _instagramCookie != null ? Colors.green : ZallTheme.textMuted,
              ),
            ),
            trailing: const Icon(Icons.edit, size: 18, color: Colors.white60),
            onTap: () => _editCookieDialog(MediaPlatform.instagram, _instagramCookie ?? ''),
          ),
        ],
      ),
    );
  }
}
