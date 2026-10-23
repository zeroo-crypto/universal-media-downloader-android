import 'package:flutter_test/flutter_test.dart';
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/extractors/pixiv_extractor.dart';
import 'package:universal_media_downloader/extractors/youtube_extractor.dart';
import 'package:universal_media_downloader/extractors/pinterest_extractor.dart';
import 'package:universal_media_downloader/extractors/twitter_extractor.dart';
import 'package:universal_media_downloader/extractors/tiktok_extractor.dart';
import 'package:universal_media_downloader/extractors/instagram_extractor.dart';
import 'package:universal_media_downloader/services/share_intent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Tier 1: Feature Coverage — Platform Detection & Standard URL Extraction', () {
    test('YouTube: detects standard watch, youtu.be, shorts, and embed URLs', () {
      const urls = [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'https://youtube.com/shorts/3xyzABC1234',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/live/dQw4w9WgXcQ',
      ];

      final yt = YouTubeExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.youtube), reason: 'Failed for $url');
        expect(yt.canHandle(url), isTrue, reason: 'canHandle failed for $url');
      }

      expect(yt.extractVideoId(urls[0]), equals('dQw4w9WgXcQ'));
      expect(yt.extractVideoId(urls[1]), equals('dQw4w9WgXcQ'));
      expect(yt.extractVideoId(urls[2]), equals('3xyzABC1234'));
      expect(yt.extractVideoId(urls[3]), equals('dQw4w9WgXcQ'));
      expect(yt.extractVideoId(urls[4]), equals('dQw4w9WgXcQ'));
      expect(yt.extractVideoId(urls[5]), equals('dQw4w9WgXcQ'));
    });

    test('Pixiv: detects standard artworks, locale prefixes, and illust_id queries', () {
      const urls = [
        'https://www.pixiv.net/artworks/105356665',
        'https://www.pixiv.net/en/artworks/98765432',
        'https://www.pixiv.net/member_illust.php?mode=medium&illust_id=11223344',
        'https://www.pixiv.net/artworks/77665544?ref=recommend',
        'https://i.pximg.net/img-original/img/2026/10/23/00/00/00/105356665_p0.jpg',
      ];

      final px = PixivExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.pixiv), reason: 'Failed for $url');
        expect(px.canHandle(url), isTrue, reason: 'canHandle failed for $url');
      }

      expect(px.extractIllustId(urls[0]), equals('105356665'));
      expect(px.extractIllustId(urls[1]), equals('98765432'));
      expect(px.extractIllustId(urls[2]), equals('11223344'));
      expect(px.extractIllustId(urls[3]), equals('77665544'));
    });

    test('Pinterest: detects pin.it shortlinks and standard pin URLs', () {
      const urls = [
        'https://www.pinterest.com/pin/1234567890/',
        'https://pin.it/abcXYZ12',
        'https://pinterest.com/pin/9876543210/',
        'https://www.pinterest.com/pin/112233445566778899/',
        'https://pin.it/7mK9pL2',
        'https://www.pinterest.co.uk/pin/1234567890/',
        'https://www.pinterest.com.au/pin/1234567890/',
      ];

      final pin = PinterestExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.pinterest), reason: 'Failed for $url');
        expect(pin.canHandle(url), isTrue, reason: 'canHandle failed for $url');
      }
    });

    test('Twitter/X: detects twitter.com and x.com status links across users', () {
      const urls = [
        'https://twitter.com/elonmusk/status/1234567890123456789',
        'https://x.com/OpenAI/status/9876543210987654321',
        'https://twitter.com/NASA/status/1122334455667788990',
        'https://x.com/flutterdev/status/5544332211009988776',
        'https://twitter.com/user_123/status/998877665544332211',
      ];

      final tw = TwitterExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.twitter), reason: 'Failed for $url');
        expect(tw.canHandle(url), isTrue, reason: 'canHandle failed for $url');
      }
    });

    test('TikTok: detects video URLs and shortlinks', () {
      const urls = [
        'https://www.tiktok.com/@creator/video/7123456789012345678',
        'https://vt.tiktok.com/ZSxyz123/',
        'https://vm.tiktok.com/ZSxyz123/',
        'https://www.tiktok.com/@creator/photo/7123456789012345678',
        'https://www.tiktok.com/@dancer_official/video/6987654321098765432',
        'https://vt.tiktok.com/ZSNabc987/',
        'https://www.tiktok.com/@comedy/video/7001122334455667788',
      ];

      final tt = TikTokExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.tiktok), reason: 'Failed for $url');
        expect(tt.canHandle(url), isTrue, reason: 'canHandle failed for $url');
      }
    });

    test('Instagram: detects post /p/, reel, and tv shortcodes', () {
      const urls = [
        'https://www.instagram.com/p/C-xyz123abc/',
        'https://www.instagram.com/reel/C-abc987xyz/',
        'https://www.instagram.com/reels/C-abc987xyz/',
        'https://www.instagram.com/tv/B9xyz123abc/',
        'https://www.instagram.com/p/DF123456789/',
        'https://www.instagram.com/reel/DE987654321/',
      ];

      final ig = InstagramExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.instagram), reason: 'Failed for $url');
        expect(ig.canHandle(url), isTrue, reason: 'canHandle failed for $url');
      }

      expect(ig.extractShortcode(urls[0]), equals('C-xyz123abc'));
      expect(ig.extractShortcode(urls[1]), equals('C-abc987xyz'));
      expect(ig.extractShortcode(urls[2]), equals('C-abc987xyz'));
      expect(ig.extractShortcode(urls[3]), equals('B9xyz123abc'));
      expect(ig.extractShortcode(urls[4]), equals('DF123456789'));
      expect(ig.extractShortcode(urls[5]), equals('DE987654321'));
    });
  });

  group('Tier 2: Boundary & Corner Cases — Query Params, Fragments & Complex Formats', () {
    test('YouTube: handles timestamps, playlist contexts, and extra parameters', () {
      final yt = YouTubeExtractor();
      const complexUrls = [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL123456789&index=2',
        'https://youtu.be/dQw4w9WgXcQ?si=abcdef123456',
        'https://www.youtube.com/watch?app=desktop&v=dQw4w9WgXcQ#t=30s',
        'https://youtube.com/shorts/3xyzABC1234?feature=share',
      ];

      for (final url in complexUrls) {
        expect(yt.canHandle(url), isTrue, reason: 'Failed for $url');
        final id = yt.extractVideoId(url);
        expect(id, isNotNull);
        expect(id!.length, equals(11));
      }
    });

    test('Pixiv: handles non-English locales and query parameters', () {
      final px = PixivExtractor();
      const localeUrls = [
        'https://www.pixiv.net/ja/artworks/105356665',
        'https://www.pixiv.net/zh/artworks/105356665',
        'https://www.pixiv.net/artworks/105356665?lang=en&source=feed',
      ];

      for (final url in localeUrls) {
        expect(px.canHandle(url), isTrue);
        expect(px.extractIllustId(url), equals('105356665'));
      }
    });

    test('Twitter/X: handles analytics tracking params and photo subpaths', () {
      final tw = TwitterExtractor();
      const trackedUrls = [
        'https://twitter.com/OpenAI/status/9876543210987654321?s=20&t=abc',
        'https://x.com/OpenAI/status/9876543210987654321/photo/1',
        'https://twitter.com/user/status/1234567890123456789?ref_src=twsrc%5Etfw',
      ];

      for (final url in trackedUrls) {
        expect(tw.canHandle(url), isTrue);
      }
    });

    test('Instagram: handles tracking query parameters', () {
      final ig = InstagramExtractor();
      const trackedUrls = [
        'https://www.instagram.com/p/C-xyz123abc/?igsh=MWQ1ZGUxMzBkMA==',
        'https://www.instagram.com/reel/C-abc987xyz/?utm_source=ig_web_copy_link',
      ];

      for (final url in trackedUrls) {
        expect(ig.canHandle(url), isTrue);
        expect(ig.extractShortcode(url), isNotNull);
      }
    });

    test('Non-matching and malformed URLs correctly rejected', () {
      final yt = YouTubeExtractor();
      final px = PixivExtractor();
      final tw = TwitterExtractor();
      final ig = InstagramExtractor();

      const invalidUrls = [
        'https://vimeo.com/123456789',
        'https://dailymotion.com/video/x7xyz',
        'https://example.com/not/a/video',
        'https://twitter.com/only_username',
        'https://instagram.com/explore/',
        'https://pixiv.net/users/123456',
      ];

      for (final url in invalidUrls) {
        expect(yt.canHandle(url), isFalse, reason: 'YouTube should not handle $url');
        expect(px.canHandle(url), isFalse, reason: 'Pixiv should not handle $url');
        expect(tw.canHandle(url), isFalse, reason: 'Twitter should not handle $url');
        expect(ig.canHandle(url), isFalse, reason: 'Instagram should not handle $url');
      }
    });
  });

  group('Tier 3: Cross-Feature Combinations — Trailing Punctuation Stripping & Sanitization', () {
    test('Strips trailing periods from shared text URLs', () {
      const input = 'https://youtu.be/dQw4w9WgXcQ.';
      final cleaned = ShareIntentService.extractUrl(input);
      expect(cleaned, equals('https://youtu.be/dQw4w9WgXcQ'));
      expect(YouTubeExtractor().extractVideoId(cleaned!), equals('dQw4w9WgXcQ'));
    });

    test('Strips trailing exclamation marks and question marks', () {
      const input1 = 'https://www.pixiv.net/artworks/105356665!';
      const input2 = 'https://x.com/user/status/1234567890123456789?';
      
      final cleaned1 = ShareIntentService.extractUrl(input1);
      final cleaned2 = ShareIntentService.extractUrl(input2);

      expect(cleaned1, equals('https://www.pixiv.net/artworks/105356665'));
      expect(cleaned2, equals('https://x.com/user/status/1234567890123456789'));
      expect(PixivExtractor().extractIllustId(cleaned1!), equals('105356665'));
    });

    test('Strips trailing commas, semicolons, and colons', () {
      const input1 = 'https://pin.it/abcXYZ12,';
      const input2 = 'https://www.instagram.com/p/C-xyz123abc/;';
      const input3 = 'https://vt.tiktok.com/ZSxyz123/:';

      expect(ShareIntentService.extractUrl(input1), equals('https://pin.it/abcXYZ12'));
      expect(ShareIntentService.extractUrl(input2), equals('https://www.instagram.com/p/C-xyz123abc/'));
      expect(ShareIntentService.extractUrl(input3), equals('https://vt.tiktok.com/ZSxyz123/'));
    });

    test('Strips closing parentheses and brackets from URLs embedded in sentences', () {
      const input1 = '(see https://youtu.be/dQw4w9WgXcQ)';
      const input2 = '[link https://www.pixiv.net/artworks/105356665]';

      expect(ShareIntentService.extractUrl(input1), equals('https://youtu.be/dQw4w9WgXcQ'));
      expect(ShareIntentService.extractUrl(input2), equals('https://www.pixiv.net/artworks/105356665'));
    });

    test('Strips multiple sequential trailing punctuation characters', () {
      const input = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ...?!';
      final cleaned = ShareIntentService.extractUrl(input);
      expect(cleaned, equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(YouTubeExtractor().extractVideoId(cleaned!), equals('dQw4w9WgXcQ'));
    });

    test('Strips quotes, smart quotes, and curly braces from URLs', () {
      const input1 = '"https://youtu.be/dQw4w9WgXcQ"';
      const input2 = '\'https://pin.it/abcXYZ12\'';
      const input3 = '{https://vm.tiktok.com/ZSxyz123/}';
      const input4 = '“https://www.pinterest.co.uk/pin/1234567890/”';
      const input5 = '‘https://www.instagram.com/reels/C-abc987xyz/’';

      expect(ShareIntentService.extractUrl(input1), equals('https://youtu.be/dQw4w9WgXcQ'));
      expect(ShareIntentService.extractUrl(input2), equals('https://pin.it/abcXYZ12'));
      expect(ShareIntentService.extractUrl(input3), equals('https://vm.tiktok.com/ZSxyz123/'));
      expect(ShareIntentService.extractUrl(input4), equals('https://www.pinterest.co.uk/pin/1234567890/'));
      expect(ShareIntentService.extractUrl(input5), equals('https://www.instagram.com/reels/C-abc987xyz/'));
    });
  });

  group('Tier 4: Real-World Application Scenarios — Conversational Share Sheet Messages', () {
    test('Extracts YouTube link from casual chat message', () {
      const chat = 'Bro you have to watch this immediately https://youtu.be/dQw4w9WgXcQ it is hilarious!';
      final extracted = ShareIntentService.extractUrl(chat);
      expect(extracted, equals('https://youtu.be/dQw4w9WgXcQ'));
      expect(MediaPlatform.detect(extracted!), equals(MediaPlatform.youtube));
      expect(YouTubeExtractor().extractVideoId(extracted), equals('dQw4w9WgXcQ'));
    });

    test('Extracts Pixiv artwork link from multi-line text with emojis', () {
      const chat = '🎨 New masterpiece dropped!\nCheck it out here: https://www.pixiv.net/artworks/105356665.\nLet me know your thoughts!';
      final extracted = ShareIntentService.extractUrl(chat);
      expect(extracted, equals('https://www.pixiv.net/artworks/105356665'));
      expect(PixivExtractor().extractIllustId(extracted!), equals('105356665'));
    });

    test('Extracts Twitter link from forwarded message with hashtags', () {
      const forwarded = 'Breaking news on AI: https://x.com/OpenAI/status/9876543210987654321 #AI #Tech';
      final extracted = ShareIntentService.extractUrl(forwarded);
      expect(extracted, equals('https://x.com/OpenAI/status/9876543210987654321'));
      expect(TwitterExtractor().canHandle(extracted!), isTrue);
    });

    test('Extracts Instagram Reel link copied from share drawer', () {
      const shareText = 'Watch this reel by creator: https://www.instagram.com/reel/C-abc987xyz/?igsh=xyz123';
      final extracted = ShareIntentService.extractUrl(shareText);
      expect(extracted, equals('https://www.instagram.com/reel/C-abc987xyz/?igsh=xyz123'));
      expect(InstagramExtractor().canHandle(extracted!), isTrue);
      expect(InstagramExtractor().extractShortcode(extracted), equals('C-abc987xyz'));
    });

    test('Extracts Pinterest pin from bookmark export', () {
      const bookmark = 'Saved pin: https://pin.it/abcXYZ12 - design inspiration';
      final extracted = ShareIntentService.extractUrl(bookmark);
      expect(extracted, equals('https://pin.it/abcXYZ12'));
      expect(PinterestExtractor().canHandle(extracted!), isTrue);
    });
  });
}
