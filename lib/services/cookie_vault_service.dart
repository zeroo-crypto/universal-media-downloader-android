import 'package:shared_preferences/shared_preferences.dart';
import '../constants/platforms.dart';

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
}
