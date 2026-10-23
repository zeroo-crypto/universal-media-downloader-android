import 'package:flutter_test/flutter_test.dart';
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/extractors/pixiv_extractor.dart';
import 'package:universal_media_downloader/extractors/youtube_extractor.dart';
import 'package:universal_media_downloader/extractors/pinterest_extractor.dart';
import 'package:universal_media_downloader/extractors/twitter_extractor.dart';
import 'package:universal_media_downloader/extractors/tiktok_extractor.dart';
import 'package:universal_media_downloader/extractors/instagram_extractor.dart';

void main() {
  group('Extractor Regex & Platform Detection Tests', () {
    test('Detects YouTube URLs correctly', () {
      const url1 = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      const url2 = 'https://youtu.be/dQw4w9WgXcQ';
      const url3 = 'https://youtube.com/shorts/3xyzABC1234';

      expect(MediaPlatform.detect(url1), equals(MediaPlatform.youtube));
      expect(MediaPlatform.detect(url2), equals(MediaPlatform.youtube));
      expect(MediaPlatform.detect(url3), equals(MediaPlatform.youtube));

      final yt = YouTubeExtractor();
      expect(yt.canHandle(url1), isTrue);
      expect(yt.extractVideoId(url1), equals('dQw4w9WgXcQ'));
      expect(yt.extractVideoId(url2), equals('dQw4w9WgXcQ'));
    });

    test('Detects Pixiv URLs correctly', () {
      const url1 = 'https://www.pixiv.net/artworks/105356665';
      const url2 = 'https://www.pixiv.net/en/artworks/98765432';

      expect(MediaPlatform.detect(url1), equals(MediaPlatform.pixiv));
      expect(MediaPlatform.detect(url2), equals(MediaPlatform.pixiv));

      final px = PixivExtractor();
      expect(px.canHandle(url1), isTrue);
      expect(px.extractIllustId(url1), equals('105356665'));
      expect(px.extractIllustId(url2), equals('98765432'));
    });

    test('Detects Pinterest URLs correctly', () {
      const url1 = 'https://www.pinterest.com/pin/1234567890/';
      const url2 = 'https://pin.it/abcXYZ12';

      expect(MediaPlatform.detect(url1), equals(MediaPlatform.pinterest));
      expect(MediaPlatform.detect(url2), equals(MediaPlatform.pinterest));

      final pin = PinterestExtractor();
      expect(pin.canHandle(url1), isTrue);
      expect(pin.canHandle(url2), isTrue);
    });

    test('Detects Twitter / X URLs correctly', () {
      const url1 = 'https://twitter.com/elonmusk/status/1234567890123456789';
      const url2 = 'https://x.com/OpenAI/status/9876543210987654321';

      expect(MediaPlatform.detect(url1), equals(MediaPlatform.twitter));
      expect(MediaPlatform.detect(url2), equals(MediaPlatform.twitter));

      final tw = TwitterExtractor();
      expect(tw.canHandle(url1), isTrue);
      expect(tw.canHandle(url2), isTrue);
    });

    test('Detects TikTok URLs correctly', () {
      const url1 = 'https://www.tiktok.com/@creator/video/7123456789012345678';
      const url2 = 'https://vt.tiktok.com/ZSxyz123/';

      expect(MediaPlatform.detect(url1), equals(MediaPlatform.tiktok));
      expect(MediaPlatform.detect(url2), equals(MediaPlatform.tiktok));

      final tt = TikTokExtractor();
      expect(tt.canHandle(url1), isTrue);
      expect(tt.canHandle(url2), isTrue);
    });

    test('Detects Instagram URLs correctly', () {
      const url1 = 'https://www.instagram.com/p/C-xyz123abc/';
      const url2 = 'https://www.instagram.com/reel/C-abc987xyz/';

      expect(MediaPlatform.detect(url1), equals(MediaPlatform.instagram));
      expect(MediaPlatform.detect(url2), equals(MediaPlatform.instagram));

      final ig = InstagramExtractor();
      expect(ig.canHandle(url1), isTrue);
      expect(ig.extractShortcode(url1), equals('C-xyz123abc'));
      expect(ig.extractShortcode(url2), equals('C-abc987xyz'));
    });
  });
}
