import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/platforms.dart';

class CookieVaultService {
  static const String _prefix = 'cookie_vault_';

  static Future<void> saveCookie(MediaPlatform platform, String cookieValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${platform.name}', cookieValue.trim());
  }

  static Future<String?> getCookie(MediaPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('$_prefix${platform.name}');
    if (val != null && val.trim().isNotEmpty) {
      return val.trim();
    }
    return null;
  }

  static Future<void> removeCookie(MediaPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix${platform.name}');
  }

  /// Parses Netscape / curl format cookies.txt and saves relevant session cookies
  static Future<Map<MediaPlatform, String>> importNetscapeCookies(String content) async {
    final Map<MediaPlatform, String> imported = {};
    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('\t');
      if (parts.length >= 7) {
        final domain = parts[0].toLowerCase();
        final name = parts[5].trim();
        final value = parts[6].trim();

        if (domain.contains('pixiv.net') && name == 'PHPSESSID') {
          await saveCookie(MediaPlatform.pixiv, value);
          imported[MediaPlatform.pixiv] = value;
        } else if ((domain.contains('twitter.com') || domain.contains('x.com')) && name == 'auth_token') {
          await saveCookie(MediaPlatform.twitter, value);
          imported[MediaPlatform.twitter] = value;
        } else if (domain.contains('instagram.com') && name == 'sessionid') {
          await saveCookie(MediaPlatform.instagram, value);
          imported[MediaPlatform.instagram] = value;
        }
      }
    }
    return imported;
  }
}
