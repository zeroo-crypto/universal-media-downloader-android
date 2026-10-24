import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'app_selected_language';

  Locale _currentLocale = const Locale('id', 'ID');
  Locale get currentLocale => _currentLocale;

  String get languageCode => _currentLocale.languageCode;

  String get displayName {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English (US)';
      case 'ja':
        return '日本語 (Japanese)';
      case 'id':
      default:
        return 'Bahasa Indonesia';
    }
  }

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null && savedCode.isNotEmpty) {
      _currentLocale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (code == _currentLocale.languageCode) return;
    _currentLocale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLocale.languageCode]?[key] ??
        _translations['id']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'id': {
      // Home Screen
      'hero_title_1': 'Semua Bisa,\nSatu ',
      'hero_title_2': 'Aplikasi!',
      'hero_subtitle':
          'Tak perlu repot ganti-ganti aplikasi. Cukup satu ketukan untuk mengunduh.',
      'input_hint': 'Tempel link di sini...',
      'supported_platforms': 'Platform yang Didukung',
      'recent_downloads': 'Baru Diunduh',
      'clear_all': 'Hapus Semua',
      'view_gallery': 'Lihat Galeri >',
      'no_downloads': 'Belum Ada Unduhan',
      'no_downloads_desc': 'Tidak ada file yang ditemukan. Coba unduh dulu, ya!',
      'toast_paste_ok': 'Link berhasil ditempel dari clipboard',
      'toast_clipboard_empty': 'Clipboard kosong',
      'toast_link_empty': 'Silakan masukkan link terlebih dahulu',
      'toast_analyzing': 'Menganalisis tautan media...',
      'toast_starting_download': 'Memulai unduhan: ',
      'toast_starting_batch': 'Memulai unduh semua media...',
      'toast_analysis_failed': 'Gagal menganalisis link: ',

      // Gallery Screen
      'gallery_title': 'Galeri',
      'clean_gallery': 'Bersihkan Galeri',
      'filter_all': 'Semua',
      'delete_title': 'Hapus Unduhan?',
      'delete_desc': 'File ini akan dihapus dari penyimpanan perangkat Anda.',
      'cancel': 'Batal',
      'delete': 'Hapus',
      'play_open': 'Buka / Putar',

      // Settings Screen
      'settings_title': 'Pengaturan',
      'storage_internal': 'Penyimpanan Internal',
      'storage_used': 'Terpakai',
      'storage_of': 'dari',
      'cat_app': 'Aplikasi',
      'setting_language': 'Bahasa',
      'setting_notifications': 'Notifikasi',
      'setting_theme': 'Tema',
      'setting_theme_system': 'Sesuai Sistem',
      'setting_theme_dark': 'Gelap (Dark Blue)',
      'setting_clean_cache': 'Bersihkan Cache',
      'setting_pip': 'Layar Mengambang',
      'setting_pip_sub': 'Saat video diputar (Picture-in-Picture)',
      'cat_cookies': 'Cookie Sesi (Vault)',
      'cookie_pixiv_sub': 'Untuk akses R-18 & Galeri Bookmark (PHPSESSID)',
      'cookie_twitter_sub': 'Untuk video HD & Akun Privat (auth_token)',
      'cookie_instagram_sub': 'Untuk Carousel & Reels Privat (sessionid)',
      'cat_help': 'Bantuan',
      'help_faq': 'Pertanyaan Umum',
      'help_contact': 'Hubungi Kami',
      'help_about': 'Tentang Aplikasi',
      'cookie_dialog_save': 'Simpan',
      'cookie_dialog_clear': 'Hapus Cookie',
      'cookie_import_file': 'Impor cookies.txt (Netscape)',

      // Preview Bottom Sheet
      'preview_choose_format': 'Pilih Kualitas / Format:',
      'preview_download_all': 'Unduh Semua',
      'preview_download_single': 'Unduh Item Pilihan Saja',
      'preview_download_now': 'Unduh Sekarang',
      'preview_creator': 'Kreator: ',
      'preview_items_count': 'Item Media (Album)',
    },
    'en': {
      // Home Screen
      'hero_title_1': 'All in One,\nOne ',
      'hero_title_2': 'App!',
      'hero_subtitle':
          'No need to switch between apps. Just one tap to download any media.',
      'input_hint': 'Paste link here...',
      'supported_platforms': 'Supported Platforms',
      'recent_downloads': 'Recent Downloads',
      'clear_all': 'Clear All',
      'view_gallery': 'View Gallery >',
      'no_downloads': 'No Downloads Yet',
      'no_downloads_desc': 'No files found. Try downloading some media first!',
      'toast_paste_ok': 'Link pasted from clipboard',
      'toast_clipboard_empty': 'Clipboard is empty',
      'toast_link_empty': 'Please enter or paste a media link first',
      'toast_analyzing': 'Analyzing media link...',
      'toast_starting_download': 'Starting download: ',
      'toast_starting_batch': 'Starting batch download...',
      'toast_analysis_failed': 'Failed to analyze link: ',

      // Gallery Screen
      'gallery_title': 'Gallery',
      'clean_gallery': 'Clean Gallery',
      'filter_all': 'All',
      'delete_title': 'Delete Download?',
      'delete_desc': 'This file will be permanently removed from device storage.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'play_open': 'Open / Play',

      // Settings Screen
      'settings_title': 'Settings',
      'storage_internal': 'Internal Storage',
      'storage_used': 'Used',
      'storage_of': 'of',
      'cat_app': 'Application',
      'setting_language': 'Language',
      'setting_notifications': 'Notifications',
      'setting_theme': 'Theme',
      'setting_theme_system': 'Follow System',
      'setting_theme_dark': 'Dark (Dark Blue)',
      'setting_clean_cache': 'Clear Cache',
      'setting_pip': 'Picture-in-Picture',
      'setting_pip_sub': 'When video is playing',
      'cat_cookies': 'Session Cookies (Vault)',
      'cookie_pixiv_sub': 'For R-18 & Bookmark Galleries (PHPSESSID)',
      'cookie_twitter_sub': 'For HD Video & Private Tweets (auth_token)',
      'cookie_instagram_sub': 'For Private Carousels & Reels (sessionid)',
      'cat_help': 'Help & Support',
      'help_faq': 'Frequently Asked Questions',
      'help_contact': 'Contact Us',
      'help_about': 'About ZALL',
      'cookie_dialog_save': 'Save',
      'cookie_dialog_clear': 'Clear Cookie',
      'cookie_import_file': 'Import cookies.txt (Netscape)',

      // Preview Bottom Sheet
      'preview_choose_format': 'Select Quality / Format:',
      'preview_download_all': 'Download All',
      'preview_download_single': 'Download Selected Only',
      'preview_download_now': 'Download Now',
      'preview_creator': 'Creator: ',
      'preview_items_count': 'Media Items (Album)',
    },
    'ja': {
      // Home Screen
      'hero_title_1': 'すべてをひとつに、\nひとつの',
      'hero_title_2': 'アプリで！',
      'hero_subtitle':
          'アプリを切り替える必要はありません。ワンタップですべてのメディアを保存。',
      'input_hint': 'ここにリンクを貼り付け...',
      'supported_platforms': '対応プラットフォーム',
      'recent_downloads': '最近のダウンロード',
      'clear_all': 'すべてクリア',
      'view_gallery': 'ギャラリーを見る >',
      'no_downloads': 'ダウンロード履歴なし',
      'no_downloads_desc': 'ファイルが見つかりません。まずはリンクをダウンロードしてみましょう！',
      'toast_paste_ok': 'クリップボードから貼り付けました',
      'toast_clipboard_empty': 'クリップボードは空です',
      'toast_link_empty': 'リンクを入力してください',
      'toast_analyzing': 'メディアを解析中...',
      'toast_starting_download': 'ダウンロードを開始: ',
      'toast_starting_batch': '一括ダウンロードを開始...',
      'toast_analysis_failed': 'リンクの解析に失敗しました: ',

      // Gallery Screen
      'gallery_title': 'ギャラリー',
      'clean_gallery': 'ギャラリー整理',
      'filter_all': 'すべて',
      'delete_title': 'ファイルを削除しますか？',
      'delete_desc': 'このファイルは端末のストレージから完全に削除されます。',
      'cancel': 'キャンセル',
      'delete': '削除',
      'play_open': '開く / 再生',

      // Settings Screen
      'settings_title': '設定',
      'storage_internal': '内部ストレージ',
      'storage_used': '使用中',
      'storage_of': '/',
      'cat_app': 'アプリ設定',
      'setting_language': '言語 (Language)',
      'setting_notifications': '通知',
      'setting_theme': 'テーマ',
      'setting_theme_system': 'システム連動',
      'setting_theme_dark': 'ダーク (Dark Blue)',
      'setting_clean_cache': 'キャッシュをクリア',
      'setting_pip': 'ピクチャー・イン・ピクチャー',
      'setting_pip_sub': '動画再生時のフローティング画面',
      'cat_cookies': 'セッションCookie (Vault)',
      'cookie_pixiv_sub': 'R-18およびブックマーク保存用 (PHPSESSID)',
      'cookie_twitter_sub': '高画質動画および非公開ツイート用 (auth_token)',
      'cookie_instagram_sub': '非公開リール＆カルーセル用 (sessionid)',
      'cat_help': 'ヘルプ＆サポート',
      'help_faq': 'よくある質問 (FAQ)',
      'help_contact': 'お問い合わせ',
      'help_about': 'アプリについて',
      'cookie_dialog_save': '保存',
      'cookie_dialog_clear': 'Cookieを削除',
      'cookie_import_file': 'cookies.txt (Netscape) をインポート',

      // Preview Bottom Sheet
      'preview_choose_format': '画質・フォーマットを選択:',
      'preview_download_all': 'すべてダウンロード',
      'preview_download_single': '選択項目のみダウンロード',
      'preview_download_now': '今すぐダウンロード',
      'preview_creator': '作成者: ',
      'preview_items_count': '件のメディア (アルバム)',
    },
  };
}

extension TranslationHelper on BuildContext {
  String tr(String key) {
    try {
      return Provider.of<LanguageProvider>(this, listen: true).translate(key);
    } catch (_) {
      return key;
    }
  }
}
