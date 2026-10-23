import 'package:flutter_test/flutter_test.dart';
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/extractors/pixiv_extractor.dart';
import 'package:universal_media_downloader/extractors/youtube_extractor.dart';
import 'package:universal_media_downloader/extractors/pinterest_extractor.dart';
import 'package:universal_media_downloader/extractors/twitter_extractor.dart';
import 'package:universal_media_downloader/extractors/tiktok_extractor.dart';
import 'package:universal_media_downloader/extractors/instagram_extractor.dart';
import 'package:universal_media_downloader/services/share_intent_service.dart';
// Avoid extractor_registry.dart import to prevent pulling shared_preferences

void main() {
  group('Adversarial Challenge 1: URL Extraction & Trailing Punctuation/Enclosure Sanitization', () {
    test('Standard punctuation: .,!?;:)>] stripped successfully', () {
      final cases = {
        'https://youtu.be/dQw4w9WgXcQ.': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ,': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ!': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ;': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ:': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ)': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ]': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ>': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ...?!': 'https://youtu.be/dQw4w9WgXcQ',
        '(https://youtu.be/dQw4w9WgXcQ)': 'https://youtu.be/dQw4w9WgXcQ',
        '[https://youtu.be/dQw4w9WgXcQ]': 'https://youtu.be/dQw4w9WgXcQ',
        '<https://youtu.be/dQw4w9WgXcQ>': 'https://youtu.be/dQw4w9WgXcQ',
      };

      cases.forEach((input, expected) {
        final actual = ShareIntentService.extractUrl(input);
        expect(actual, equals(expected), reason: 'Failed for input: $input');
      });
    });

    test('Quotes and Braces: double quotes, single quotes, curly quotes, curly braces', () {
      final quoteCases = <String, String>{
        '"https://youtu.be/dQw4w9WgXcQ"': 'https://youtu.be/dQw4w9WgXcQ"', // Note: does it keep quote?
        'Check this: "https://youtu.be/dQw4w9WgXcQ"': 'https://youtu.be/dQw4w9WgXcQ"',
        '\'https://youtu.be/dQw4w9WgXcQ\'': 'https://youtu.be/dQw4w9WgXcQ\'',
        '{https://youtu.be/dQw4w9WgXcQ}': 'https://youtu.be/dQw4w9WgXcQ}',
        '“https://youtu.be/dQw4w9WgXcQ”': 'https://youtu.be/dQw4w9WgXcQ”',
        '‘https://youtu.be/dQw4w9WgXcQ’': 'https://youtu.be/dQw4w9WgXcQ’',
      };

      quoteCases.forEach((input, rawOutput) {
        final actual = ShareIntentService.extractUrl(input);
        // Record exact behavior: whether quotes/braces are stripped or retained
        print('Quote test: "$input" -> "$actual"');
      });
    });

    test('Trailing Emojis: emojis directly attached without trailing space', () {
      final emojiCases = [
        'https://youtu.be/dQw4w9WgXcQ🔥',
        'https://www.pixiv.net/artworks/105356665❤️',
        'https://x.com/user/status/1234567890123456789✨',
        'https://www.instagram.com/reel/C-abc987xyz/👍',
        'https://vm.tiktok.com/ZSxyz123/🎉',
        'https://pin.it/abcXYZ12📌',
      ];

      for (final input in emojiCases) {
        final actual = ShareIntentService.extractUrl(input);
        print('Emoji test: "$input" -> "$actual"');
      }
    });

    test('CJK Fullwidth Punctuation: Japanese/Chinese periods and brackets', () {
      final cjkCases = [
        'https://www.pixiv.net/artworks/105356665。',
        'https://www.pixiv.net/artworks/105356665！',
        'https://www.pixiv.net/artworks/105356665？',
        '「https://www.pixiv.net/artworks/105356665」',
      ];

      for (final input in cjkCases) {
        final actual = ShareIntentService.extractUrl(input);
        print('CJK test: "$input" -> "$actual"');
      }
    });

    test('Markdown Links and multi-line chat embeds', () {
      const markdown = 'Check this out [Watch Video](https://youtu.be/dQw4w9WgXcQ)';
      final actual = ShareIntentService.extractUrl(markdown);
      expect(actual, equals('https://youtu.be/dQw4w9WgXcQ'));

      const multiUrl = 'First: https://youtu.be/dQw4w9WgXcQ and second: https://x.com/user/status/123456789';
      final first = ShareIntentService.extractUrl(multiUrl);
      expect(first, equals('https://youtu.be/dQw4w9WgXcQ'));
    });
  });

  group('Adversarial Challenge 2: Platform Extractor Regex Hardening & Edge Cases', () {
    test('YouTube Extractor: standard, shorts, embed, mobile, music, live, query permutations', () {
      final yt = YouTubeExtractor();
      final validUrls = [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'https://youtube.com/shorts/3xyzABC1234',
        'https://www.youtube.com/shorts/3xyzABC1234/',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL123&index=1',
        'https://www.youtube.com/watch?feature=shared&v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?si=abcdef12345',
        'https://www.youtube.com/v/dQw4w9WgXcQ',
        'https://www.youtube.com/e/dQw4w9WgXcQ',
        // What about live stream format?
        'https://www.youtube.com/live/dQw4w9WgXcQ',
      ];

      for (final url in validUrls) {
        final canHandle = yt.canHandle(url);
        final videoId = yt.extractVideoId(url);
        print('YouTube: $url -> canHandle: $canHandle, videoId: $videoId');
      }

      final invalidUrls = [
        'https://www.youtube.com/channel/UC1234567890',
        'https://www.youtube.com/user/RickAstleyVEVO',
        'https://www.youtube.com/playlist?list=PL12345',
        'https://youtube.com/watch?v=tooshort',
        'https://vimeo.com/123456789',
      ];

      for (final url in invalidUrls) {
        expect(yt.canHandle(url), isFalse, reason: 'YouTube should reject $url');
      }
    });

    test('Pixiv Extractor: artworks, multi-locales, old illust_id, pximg direct, mobile', () {
      final px = PixivExtractor();
      final validUrls = [
        'https://www.pixiv.net/artworks/105356665',
        'https://www.pixiv.net/en/artworks/105356665',
        'https://www.pixiv.net/ja/artworks/105356665',
        'https://www.pixiv.net/zh/artworks/105356665',
        'https://www.pixiv.net/zh-tw/artworks/105356665',
        'https://www.pixiv.net/member_illust.php?mode=medium&illust_id=105356665',
        'https://touch.pixiv.net/member_illust.php?mode=medium&illust_id=105356665',
        'https://www.pixiv.net/artworks/105356665?ref=recommend#comment',
      ];

      for (final url in validUrls) {
        expect(px.canHandle(url), isTrue, reason: 'Pixiv should handle $url');
        expect(px.extractIllustId(url), equals('105356665'));
      }

      final invalidUrls = [
        'https://www.pixiv.net/users/12345',
        'https://www.pixiv.net/novel/show.php?id=12345',
        'https://www.pixiv.net/request',
      ];

      for (final url in invalidUrls) {
        expect(px.canHandle(url), isFalse, reason: 'Pixiv should reject $url');
      }
    });

    test('Pinterest Extractor: shortlinks, regional ccTLDs, two-part ccTLDs, subdomains', () {
      final pin = PinterestExtractor();
      final validUrls = [
        'https://pin.it/abcXYZ12',
        'https://pin.it/abcXYZ12/',
        'https://pin.it/abcXYZ12?invited_by=user',
        'https://www.pinterest.com/pin/1234567890/',
        'https://pinterest.com/pin/1234567890/',
        'https://www.pinterest.com/pin/1234567890',
        'https://www.pinterest.co.uk/pin/1234567890/',
        'https://www.pinterest.com.au/pin/1234567890/',
        'https://www.pinterest.co.kr/pin/1234567890/',
        'https://www.pinterest.de/pin/1234567890/',
        'https://www.pinterest.fr/pin/1234567890/',
        'https://www.pinterest.ca/pin/1234567890/',
        'https://www.pinterest.jp/pin/1234567890/',
        'https://id.pinterest.com/pin/1234567890/',
      ];

      for (final url in validUrls) {
        final canHandle = pin.canHandle(url);
        final platformDetected = MediaPlatform.detect(url);
        print('Pinterest: $url -> canHandle: $canHandle, MediaPlatform: $platformDetected');
      }

      final invalidUrls = [
        'https://www.pinterest.com/username/',
        'https://www.pinterest.com/username/my-board/',
        'https://www.pinterest.com/ideas/home-decor/',
      ];

      for (final url in invalidUrls) {
        expect(pin.canHandle(url), isFalse, reason: 'Pinterest should reject $url');
      }
    });

    test('Additional Edge Cases: YouTube live, TikTok /t/ shortlinks, Twitter /i/web', () {
      final yt = YouTubeExtractor();
      final tt = TikTokExtractor();
      final tw = TwitterExtractor();

      // YouTube /live/
      const ytLive = 'https://www.youtube.com/live/dQw4w9WgXcQ';
      print('YouTube live: $ytLive -> canHandle: ${yt.canHandle(ytLive)}');

      // TikTok /t/
      const ttT = 'https://www.tiktok.com/t/ZT8abc123/';
      print('TikTok /t/ shortlink: $ttT -> canHandle: ${tt.canHandle(ttT)}');

      // Twitter /i/web
      const twWeb = 'https://twitter.com/i/web/status/1234567890123456789';
      print('Twitter /i/web: $twWeb -> canHandle: ${tw.canHandle(twWeb)}');

      // Pixiv pximg illustId
      final px = PixivExtractor();
      const pximg = 'https://i.pximg.net/img-original/img/2026/10/23/00/00/00/105356665_p0.jpg';
      final pxIllustId = px.extractIllustId(pximg);
      print('Pixiv pximg: $pximg -> illustId: $pxIllustId (matches 105356665? ${pxIllustId == '105356665'})');
    });

    test('Twitter/X Extractor: twitter.com, x.com, mobile, photo/video subpaths, handles with underscores', () {
      final tw = TwitterExtractor();
      final validUrls = [
        'https://twitter.com/elonmusk/status/1234567890123456789',
        'https://x.com/OpenAI/status/1234567890123456789',
        'https://mobile.twitter.com/user/status/1234567890123456789',
        'https://mobile.x.com/user/status/1234567890123456789',
        'https://x.com/user_name_123/status/1234567890123456789',
        'https://x.com/user/status/1234567890123456789/photo/1',
        'https://x.com/user/status/1234567890123456789/video/1',
        'https://x.com/user/status/1234567890123456789?s=20&t=abcdef',
      ];

      for (final url in validUrls) {
        expect(tw.canHandle(url), isTrue, reason: 'Twitter should handle $url');
      }

      final invalidUrls = [
        'https://x.com/user',
        'https://twitter.com/explore',
        'https://x.com/i/bookmarks',
      ];

      for (final url in invalidUrls) {
        expect(tw.canHandle(url), isFalse, reason: 'Twitter should reject $url');
      }
    });

    test('Instagram Extractor: posts, singular reel, plural reels, tv, query params, trailing slashes', () {
      final ig = InstagramExtractor();
      final validUrls = [
        'https://www.instagram.com/p/C-abc987xyz/',
        'https://www.instagram.com/p/C-abc987xyz',
        'https://www.instagram.com/reel/C-abc987xyz/',
        'https://www.instagram.com/reel/C-abc987xyz',
        'https://www.instagram.com/reels/C-abc987xyz/',
        'https://www.instagram.com/reels/C-abc987xyz',
        'https://www.instagram.com/tv/C-abc987xyz/',
        'https://instagram.com/p/C-abc987xyz/',
        'https://www.instagram.com/reel/C-abc987xyz/?igsh=MWQ2',
      ];

      for (final url in validUrls) {
        expect(ig.canHandle(url), isTrue, reason: 'Instagram should handle $url');
        expect(ig.extractShortcode(url), equals('C-abc987xyz'));
      }

      final invalidUrls = [
        'https://www.instagram.com/username/',
        'https://www.instagram.com/stories/username/12345/',
        'https://www.instagram.com/explore/',
      ];

      for (final url in invalidUrls) {
        expect(ig.canHandle(url), isFalse, reason: 'Instagram should reject $url');
      }
    });

    test('TikTok Extractor: video, photo slideshows, vt shortlinks, vm shortlinks, v format, mobile', () {
      final tt = TikTokExtractor();
      final validUrls = [
        'https://www.tiktok.com/@user/video/7123456789012345678',
        'https://www.tiktok.com/@user.name_1/video/7123456789012345678',
        'https://www.tiktok.com/@user/photo/7123456789012345678',
        'https://www.tiktok.com/v/7123456789012345678',
        'https://vt.tiktok.com/ZSxyz123/',
        'https://vt.tiktok.com/ZSxyz123',
        'https://vm.tiktok.com/ZSxyz123/',
        'https://vm.tiktok.com/ZSxyz123',
        'https://vt.tiktok.com/ZSxyz123/?k=1',
        'https://m.tiktok.com/v/7123456789012345678.html',
      ];

      for (final url in validUrls) {
        final canHandle = tt.canHandle(url);
        print('TikTok: $url -> canHandle: $canHandle');
      }

      final invalidUrls = [
        'https://www.tiktok.com/@username',
        'https://www.tiktok.com/foryou',
        'https://www.tiktok.com/live',
      ];

      for (final url in invalidUrls) {
        expect(tt.canHandle(url), isFalse, reason: 'TikTok should reject $url');
      }
    });

    test('Downstream Registry Matching with Raw Trailing Emojis and Quotes', () {
      final extractors = [
        PixivExtractor(),
        YouTubeExtractor(),
        PinterestExtractor(),
        TwitterExtractor(),
        InstagramExtractor(),
        TikTokExtractor(),
      ];

      final testCases = [
        // Attached quotes
        {'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ"', 'platform': 'youtube'},
        {'url': 'https://youtu.be/dQw4w9WgXcQ"', 'platform': 'youtube'},
        {'url': 'https://www.instagram.com/reel/C-abc987xyz/"', 'platform': 'instagram'},
        {'url': 'https://x.com/user/status/1234567890123456789"', 'platform': 'twitter'},
        {'url': 'https://www.pixiv.net/artworks/105356665"', 'platform': 'pixiv'},
        // Attached emojis
        {'url': 'https://youtu.be/dQw4w9WgXcQ🔥', 'platform': 'youtube'},
        {'url': 'https://www.instagram.com/reel/C-abc987xyz/👍', 'platform': 'instagram'},
        {'url': 'https://x.com/user/status/1234567890123456789✨', 'platform': 'twitter'},
        {'url': 'https://www.pixiv.net/artworks/105356665❤️', 'platform': 'pixiv'},
      ];

      for (final c in testCases) {
        final raw = c['url']!;
        dynamic matched;
        for (final ext in extractors) {
          if (ext.canHandle(raw)) {
            matched = ext;
            break;
          }
        }
        print('Downstream match for "$raw" -> extractor: ${matched?.runtimeType}');
      }
    });
  });
}
