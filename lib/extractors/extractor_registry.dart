import '../core/constants/platforms.dart';
import '../services/cookie_vault_service.dart';
import 'base_extractor.dart';
import 'pixiv_extractor.dart';
import 'youtube_extractor.dart';
import 'pinterest_extractor.dart';
import 'twitter_extractor.dart';
import 'instagram_extractor.dart';
import 'tiktok_extractor.dart';

class ExtractorRegistry {
  static final List<BaseExtractor> _extractors = [
    PixivExtractor(),
    YouTubeExtractor(),
    PinterestExtractor(),
    TwitterExtractor(),
    InstagramExtractor(),
    TikTokExtractor(),
  ];

  static BaseExtractor? findExtractor(String url) {
    for (final ext in _extractors) {
      if (ext.canHandle(url)) {
        return ext;
      }
    }
    return null;
  }

  static Future<MediaMetadata> extractMedia(String url) async {
    final extractor = findExtractor(url);
    if (extractor == null) {
      throw Exception('Platform not supported or link not recognized: $url');
    }

    final platform = MediaPlatform.detect(url);
    final cookie = await CookieVaultService.getCookie(platform);

    return await extractor.extract(url, cookieToken: cookie);
  }
}
