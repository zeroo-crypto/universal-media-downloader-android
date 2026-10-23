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
  group('Empirical Challenge 1: ShareIntentService.extractUrl Edge Cases', () {
    test('Nested quotes & multi-layer enclosure stripping', () {
      final cases = <String, String>{
        '""https://youtu.be/dQw4w9WgXcQ""': 'https://youtu.be/dQw4w9WgXcQ',
        '\'"https://youtu.be/dQw4w9WgXcQ"\'': 'https://youtu.be/dQw4w9WgXcQ',
        '“‘https://youtu.be/dQw4w9WgXcQ’”': 'https://youtu.be/dQw4w9WgXcQ',
        '"""https://youtu.be/dQw4w9WgXcQ"""': 'https://youtu.be/dQw4w9WgXcQ',
        '({[<https://youtu.be/dQw4w9WgXcQ>]}))': 'https://youtu.be/dQw4w9WgXcQ',
        '["https://youtu.be/dQw4w9WgXcQ"]': 'https://youtu.be/dQw4w9WgXcQ',
        '(\'https://youtu.be/dQw4w9WgXcQ\')': 'https://youtu.be/dQw4w9WgXcQ',
        '“"https://youtu.be/dQw4w9WgXcQ"”': 'https://youtu.be/dQw4w9WgXcQ',
        '{"https://youtu.be/dQw4w9WgXcQ"}': 'https://youtu.be/dQw4w9WgXcQ',
        '<"https://youtu.be/dQw4w9WgXcQ">': 'https://youtu.be/dQw4w9WgXcQ',
      };

      cases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for nested quotes: $input');
      });
    });

    test('Mixed whitespace, multi-line, tabs, carriage returns', () {
      final whitespaceCases = <String, String>{
        '\r\n\t https://youtu.be/dQw4w9WgXcQ \r\n': 'https://youtu.be/dQw4w9WgXcQ',
        '  \n   \t  https://pin.it/abcXYZ12   \t \n ': 'https://pin.it/abcXYZ12',
        'Message header\n\nhttps://vm.tiktok.com/ZSxyz123/\n\nMessage footer': 'https://vm.tiktok.com/ZSxyz123/',
        '\t\t"https://x.com/user/status/1234567890123456789"\t\t': 'https://x.com/user/status/1234567890123456789',
      };

      whitespaceCases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for whitespace: $input');
      });
    });

    test('Complex punctuation cascades and sentence boundaries', () {
      final punctuationCases = <String, String>{
        'https://youtu.be/dQw4w9WgXcQ...': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?!?!?!': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ.,:;!?': 'https://youtu.be/dQw4w9WgXcQ',
        'Did you see this (https://www.instagram.com/reel/C-abc987xyz/)?': 'https://www.instagram.com/reel/C-abc987xyz/',
        'Bookmark [https://www.pinterest.co.uk/pin/1234567890/];': 'https://www.pinterest.co.uk/pin/1234567890/',
        '{link: https://www.pixiv.net/artworks/105356665,}': 'https://www.pixiv.net/artworks/105356665',
      };

      punctuationCases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for punctuation cascade: $input');
      });
    });

    test('Markdown text structures', () {
      final markdownCases = <String, String>{
        'Standard link: [Watch Here](https://youtu.be/dQw4w9WgXcQ)': 'https://youtu.be/dQw4w9WgXcQ',
        'Auto link: <https://www.tiktok.com/@creator/photo/7123456789012345678>': 'https://www.tiktok.com/@creator/photo/7123456789012345678',
        'Link with title: [Title](https://pin.it/abcXYZ12 "Pinterest Pin")': 'https://pin.it/abcXYZ12',
        'Footnote style: [^1]: https://x.com/OpenAI/status/9876543210987654321': 'https://x.com/OpenAI/status/9876543210987654321',
        'Inline code: `https://www.instagram.com/p/C-xyz123abc/`': 'https://www.instagram.com/p/C-xyz123abc/`',
      };

      for (final entry in markdownCases.entries) {
        final result = ShareIntentService.extractUrl(entry.key);
        // Ensure the core URL is reliably extracted
        expect(result, isNotNull);
        expect(result!.startsWith('http'), isTrue);
      }

      expect(ShareIntentService.extractUrl('Standard link: [Watch Here](https://youtu.be/dQw4w9WgXcQ)'), equals('https://youtu.be/dQw4w9WgXcQ'));
      expect(ShareIntentService.extractUrl('Auto link: <https://www.tiktok.com/@creator/photo/7123456789012345678>'), equals('https://www.tiktok.com/@creator/photo/7123456789012345678'));
      expect(ShareIntentService.extractUrl('Link with title: [Title](https://pin.it/abcXYZ12 "Pinterest Pin")'), equals('https://pin.it/abcXYZ12'));
      expect(ShareIntentService.extractUrl('Footnote style: [^1]: https://x.com/OpenAI/status/9876543210987654321'), equals('https://x.com/OpenAI/status/9876543210987654321'));
    });

    test('Emojis around URLs', () {
      // 1. Emojis separated by space
      const spaceEmoji = 'Check out 🔥 https://youtu.be/dQw4w9WgXcQ 🔥 amazing';
      expect(ShareIntentService.extractUrl(spaceEmoji), equals('https://youtu.be/dQw4w9WgXcQ'));

      // 2. Preceding emoji directly attached (e.g. 🔗https://...)
      const prependedEmoji = '🔗https://youtu.be/dQw4w9WgXcQ';
      // In Dart regex 'https?:\/\/[^\s]+', the match starts at 'https://'
      expect(ShareIntentService.extractUrl(prependedEmoji), equals('https://youtu.be/dQw4w9WgXcQ'));
    });
  });

  group('Empirical Challenge 2: Pinterest Multi-Regional Domains & Shortlinks', () {
    test('MediaPlatform.detect and PinterestExtractor across all regional ccTLDs', () {
      final regionalUrls = [
        'https://www.pinterest.co.uk/pin/1234567890/',
        'https://pinterest.co.uk/pin/1234567890/',
        'https://www.pinterest.com.au/pin/1234567890/',
        'https://pinterest.com.au/pin/1234567890/',
        'https://www.pinterest.co.kr/pin/1234567890/',
        'https://pinterest.co.kr/pin/1234567890/',
        'https://www.pinterest.com.br/pin/1234567890/',
        'https://pinterest.com.br/pin/1234567890/',
        'https://www.pinterest.com.mx/pin/1234567890/',
        'https://www.pinterest.de/pin/1234567890/',
        'https://www.pinterest.fr/pin/1234567890/',
        'https://www.pinterest.es/pin/1234567890/',
        'https://www.pinterest.it/pin/1234567890/',
        'https://www.pinterest.jp/pin/1234567890/',
        'https://www.pinterest.ca/pin/1234567890/',
        'https://www.pinterest.at/pin/1234567890/',
        'https://www.pinterest.ch/pin/1234567890/',
        'https://www.pinterest.cl/pin/1234567890/',
        'https://www.pinterest.co.nz/pin/1234567890/',
        'https://www.pinterest.ie/pin/1234567890/',
        'https://www.pinterest.pt/pin/1234567890/',
        'https://www.pinterest.se/pin/1234567890/',
        // Regional subdomains
        'https://id.pinterest.com/pin/1234567890/',
        'https://in.pinterest.com/pin/1234567890/',
        'https://br.pinterest.com/pin/1234567890/',
        'https://uk.pinterest.com/pin/1234567890/',
        'https://au.pinterest.com/pin/1234567890/',
        'https://ar.pinterest.com/pin/1234567890/',
        // Shortlinks
        'https://pin.it/abcXYZ12',
        'https://pin.it/7mK9pL2/',
        'http://pin.it/xyz987',
        'https://pin.it/abcXYZ12?invited_by=user123',
        // Pin ID variations
        'https://www.pinterest.com/pin/1234567890',
        'https://www.pinterest.com/pin/1234567890/?nic_v3=1a',
        'https://www.pinterest.com/pin/abc-DEF_123/',
      ];

      final extractor = PinterestExtractor();

      for (final url in regionalUrls) {
        expect(
          MediaPlatform.detect(url),
          equals(MediaPlatform.pinterest),
          reason: 'MediaPlatform.detect failed for $url',
        );
        expect(
          extractor.canHandle(url),
          isTrue,
          reason: 'PinterestExtractor.canHandle failed for $url',
        );
      }
    });

    test('Pinterest negative / non-pin cases rejected', () {
      final invalidUrls = [
        'https://www.pinterest.com/username/',
        'https://www.pinterest.co.uk/username/board-name/',
        'https://www.pinterest.com/ideas/nature-photography/987654321/',
        'https://www.pinterest.com/today/',
      ];

      final extractor = PinterestExtractor();
      for (final url in invalidUrls) {
        expect(
          extractor.canHandle(url),
          isFalse,
          reason: 'PinterestExtractor should reject non-pin URL: $url',
        );
      }
    });
  });

  group('Empirical Challenge 3: YouTubeExtractor Full Permutations', () {
    test('Standard watch, shorts, live, youtu.be, embed, mobile, music with exact video ID', () {
      const testCases = [
        // Standard watch
        {'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/watch?feature=shared&v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&list=PL123&index=5', 'id': 'dQw4w9WgXcQ'},
        // youtu.be
        {'url': 'https://youtu.be/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtu.be/dQw4w9WgXcQ?si=abcdef12345', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtu.be/dQw4w9WgXcQ?t=10', 'id': 'dQw4w9WgXcQ'},
        // shorts
        {'url': 'https://www.youtube.com/shorts/3xyzABC1234', 'id': '3xyzABC1234'},
        {'url': 'https://youtube.com/shorts/3xyzABC1234/', 'id': '3xyzABC1234'},
        {'url': 'https://www.youtube.com/shorts/3xyzABC1234?feature=share', 'id': '3xyzABC1234'},
        // live
        {'url': 'https://www.youtube.com/live/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtube.com/live/dQw4w9WgXcQ/', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/live/dQw4w9WgXcQ?feature=share', 'id': 'dQw4w9WgXcQ'},
        // embed
        {'url': 'https://www.youtube.com/embed/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1', 'id': 'dQw4w9WgXcQ'},
        // mobile
        {'url': 'https://m.youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        // music
        {'url': 'https://music.youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
      ];

      final yt = YouTubeExtractor();
      for (final tc in testCases) {
        final url = tc['url']!;
        final expectedId = tc['id']!;

        expect(
          MediaPlatform.detect(url),
          equals(MediaPlatform.youtube),
          reason: 'MediaPlatform.detect failed for $url',
        );
        expect(
          yt.canHandle(url),
          isTrue,
          reason: 'YouTubeExtractor.canHandle failed for $url',
        );
        expect(
          yt.extractVideoId(url),
          equals(expectedId),
          reason: 'extractVideoId mismatch for $url',
        );
      }
    });

    test('YouTube negative / non-video cases', () {
      final invalidUrls = [
        'https://www.youtube.com/channel/UC1234567890',
        'https://www.youtube.com/@RickAstley',
        'https://www.youtube.com/playlist?list=PL12345',
        'https://www.youtube.com/feed/subscriptions',
        'https://www.youtube.com/watch?v=tooshort',
      ];

      final yt = YouTubeExtractor();
      for (final url in invalidUrls) {
        expect(
          yt.canHandle(url),
          isFalse,
          reason: 'YouTubeExtractor should reject $url',
        );
      }
    });
  });

  group('Empirical Challenge 4: TikTokExtractor vm.tiktok.com and Photo Slideshows', () {
    test('vm.tiktok.com, vt.tiktok.com, video, and photo slideshows', () {
      const testCases = [
        // Standard video
        'https://www.tiktok.com/@creator/video/7123456789012345678',
        'https://www.tiktok.com/@user.with_dots-123/video/7123456789012345678',
        // Photo slideshow
        'https://www.tiktok.com/@creator/photo/7123456789012345678',
        'https://www.tiktok.com/@cool.artist_01/photo/7123456789012345678?is_from_webapp=1',
        // vm shortlinks
        'https://vm.tiktok.com/ZSxyz123/',
        'https://vm.tiktok.com/ZSxyz123',
        'https://vm.tiktok.com/ZSxyz123/?k=1',
        // vt shortlinks
        'https://vt.tiktok.com/ZSxyz123/',
        'https://vt.tiktok.com/ZSxyz123',
        'https://vt.tiktok.com/ZSxyz123/?k=1',
        // direct v
        'https://www.tiktok.com/v/7123456789012345678',
        'https://m.tiktok.com/v/7123456789012345678.html',
      ];

      final tt = TikTokExtractor();
      for (final url in testCases) {
        expect(
          MediaPlatform.detect(url),
          equals(MediaPlatform.tiktok),
          reason: 'MediaPlatform.detect failed for $url',
        );
        expect(
          tt.canHandle(url),
          isTrue,
          reason: 'TikTokExtractor.canHandle failed for $url',
        );
      }
    });

    test('TikTok photo regex extracts correct photo workId', () {
      const photoUrl = 'https://www.tiktok.com/@creator/photo/7123456789012345678';
      final match = RegExp(r'/(?:video|photo)/(\d+)').firstMatch(photoUrl);
      expect(match?.group(1), equals('7123456789012345678'));
    });

    test('TikTok negative / non-video cases', () {
      final invalidUrls = [
        'https://www.tiktok.com/@username',
        'https://www.tiktok.com/foryou',
        'https://www.tiktok.com/live',
        'https://www.tiktok.com/discover',
      ];

      final tt = TikTokExtractor();
      for (final url in invalidUrls) {
        expect(
          tt.canHandle(url),
          isFalse,
          reason: 'TikTokExtractor should reject $url',
        );
      }
    });
  });

  group('Empirical Challenge 5: Instagram, Twitter/X, and Pixiv Verification', () {
    test('Instagram: /p/, /reel/, /reels/, /tv/ across all variations', () {
      const cases = [
        {'url': 'https://www.instagram.com/p/C-xyz123abc/', 'code': 'C-xyz123abc'},
        {'url': 'https://www.instagram.com/reel/C-abc987xyz/', 'code': 'C-abc987xyz'},
        {'url': 'https://www.instagram.com/reels/C-abc987xyz/', 'code': 'C-abc987xyz'},
        {'url': 'https://www.instagram.com/tv/B9xyz123abc/', 'code': 'B9xyz123abc'},
        {'url': 'https://instagram.com/reels/C-abc987xyz/?igsh=MWQ1', 'code': 'C-abc987xyz'},
        {'url': 'https://www.instagram.com/reel/C-abc987xyz', 'code': 'C-abc987xyz'},
        {'url': 'https://www.instagram.com/reels/C-abc987xyz', 'code': 'C-abc987xyz'},
      ];

      final ig = InstagramExtractor();
      for (final c in cases) {
        final url = c['url']!;
        final code = c['code']!;
        expect(MediaPlatform.detect(url), equals(MediaPlatform.instagram));
        expect(ig.canHandle(url), isTrue);
        expect(ig.extractShortcode(url), equals(code));
      }
    });

    test('Twitter/X: status urls across domains and handles', () {
      const urls = [
        'https://twitter.com/elonmusk/status/1234567890123456789',
        'https://x.com/OpenAI/status/9876543210987654321',
        'https://mobile.twitter.com/user_name_1/status/1234567890123456789',
        'https://mobile.x.com/user_name/status/1234567890123456789',
        'https://x.com/user/status/1234567890123456789/photo/1',
        'https://x.com/user/status/1234567890123456789/video/1',
        'https://twitter.com/user/status/1234567890123456789?s=20&t=abc',
      ];

      final tw = TwitterExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.twitter));
        expect(tw.canHandle(url), isTrue);
      }
    });

    test('Pixiv: artworks, multi-locale, and member_illust', () {
      const urls = [
        'https://www.pixiv.net/artworks/105356665',
        'https://www.pixiv.net/en/artworks/105356665',
        'https://www.pixiv.net/ja/artworks/105356665',
        'https://www.pixiv.net/zh/artworks/105356665',
        'https://www.pixiv.net/zh-tw/artworks/105356665',
        'https://www.pixiv.net/member_illust.php?mode=medium&illust_id=105356665',
      ];

      final px = PixivExtractor();
      for (final url in urls) {
        expect(MediaPlatform.detect(url), equals(MediaPlatform.pixiv));
        expect(px.canHandle(url), isTrue);
        expect(px.extractIllustId(url), equals('105356665'));
      }
    });
  });

  group('Empirical Challenge 6: End-to-End Extraction Pipeline Simulation', () {
    test('Simulates raw share sheet text to platform detection and extractor routing', () {
      final sharedMessages = [
        {
          'raw': 'Look at this funny YouTube reel! "https://youtube.com/shorts/3xyzABC1234?feature=share" laughing so hard',
          'platform': MediaPlatform.youtube,
          'expectedId': '3xyzABC1234',
        },
        {
          'raw': 'Forwarded message: Watch livestream (https://www.youtube.com/live/dQw4w9WgXcQ).',
          'platform': MediaPlatform.youtube,
          'expectedId': 'dQw4w9WgXcQ',
        },
        {
          'raw': 'Saved from Pinterest UK: <https://www.pinterest.co.uk/pin/1234567890/> check it out',
          'platform': MediaPlatform.pinterest,
          'expectedId': '1234567890',
        },
        {
          'raw': 'Saved from Pinterest Australia: “https://www.pinterest.com.au/pin/9876543210/”',
          'platform': MediaPlatform.pinterest,
          'expectedId': '9876543210',
        },
        {
          'raw': 'TikTok slideshow link: \'https://www.tiktok.com/@creator/photo/7123456789012345678\'!!!',
          'platform': MediaPlatform.tiktok,
          'expectedId': '7123456789012345678',
        },
        {
          'raw': 'TikTok shortlink: {https://vm.tiktok.com/ZSxyz123/}',
          'platform': MediaPlatform.tiktok,
          'expectedId': 'ZSxyz123',
        },
        {
          'raw': 'Instagram reels link: [Reel](https://www.instagram.com/reels/C-abc987xyz/?igsh=test123)',
          'platform': MediaPlatform.instagram,
          'expectedId': 'C-abc987xyz',
        },
      ];

      for (final msg in sharedMessages) {
        final raw = msg['raw'] as String;
        final expectedPlatform = msg['platform'] as MediaPlatform;
        final expectedId = msg['expectedId'] as String;

        // Step 1: Extract URL from shared text
        final extractedUrl = ShareIntentService.extractUrl(raw);
        expect(extractedUrl, isNotNull, reason: 'Failed to extract URL from $raw');

        // Step 2: Platform detection
        final platform = MediaPlatform.detect(extractedUrl!);
        expect(platform, equals(expectedPlatform), reason: 'Platform mismatch for $extractedUrl');

        // Step 3: Specific extractor routing & verification
        switch (platform) {
          case MediaPlatform.youtube:
            final yt = YouTubeExtractor();
            expect(yt.canHandle(extractedUrl), isTrue);
            expect(yt.extractVideoId(extractedUrl), equals(expectedId));
            break;
          case MediaPlatform.pinterest:
            final pin = PinterestExtractor();
            expect(pin.canHandle(extractedUrl), isTrue);
            break;
          case MediaPlatform.tiktok:
            final tt = TikTokExtractor();
            expect(tt.canHandle(extractedUrl), isTrue);
            break;
          case MediaPlatform.instagram:
            final ig = InstagramExtractor();
            expect(ig.canHandle(extractedUrl), isTrue);
            expect(ig.extractShortcode(extractedUrl), equals(expectedId));
            break;
          default:
            throw Exception('Unexpected platform $platform');
        }
      }
    });
  });
}
