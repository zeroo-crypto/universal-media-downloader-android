import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/core/utils/url_sanitizer.dart';
import 'package:universal_media_downloader/extractors/pinterest_extractor.dart';
import 'package:universal_media_downloader/extractors/youtube_extractor.dart';
import 'package:universal_media_downloader/services/share_intent_service.dart';

void main() {
  group('Empirical Verification 1: Anti-Cheat & Production Code Verification', () {
    test('Verifies test/extractor_regex_test.dart directly invokes production code without local mocks', () {
      final file = File('test/extractor_regex_test.dart');
      expect(file.existsSync(), isTrue, reason: 'test/extractor_regex_test.dart must exist');
      final content = file.readAsStringSync();

      // Must import ShareIntentService
      expect(content.contains("import 'package:universal_media_downloader/services/share_intent_service.dart';"), isTrue);

      // Must NOT contain duplicate local helper functions
      expect(content.contains('String? sanitizeUrlText('), isFalse);
      expect(content.contains('String? extractUrlImplementation('), isFalse);
      expect(content.contains('String? extractUrl('), isFalse);

      // Must directly invoke ShareIntentService.extractUrl
      expect(content.contains('ShareIntentService.extractUrl('), isTrue);
    });

    test('Verifies test/adversarial_challenge_test.dart directly invokes production code without local mocks', () {
      final file = File('test/adversarial_challenge_test.dart');
      expect(file.existsSync(), isTrue, reason: 'test/adversarial_challenge_test.dart must exist');
      final content = file.readAsStringSync();

      // Must import ShareIntentService
      expect(content.contains("import 'package:universal_media_downloader/services/share_intent_service.dart';"), isTrue);

      // Must NOT contain duplicate local helper functions
      expect(content.contains('String? sanitizeUrlText('), isFalse);
      expect(content.contains('String? extractUrlImplementation('), isFalse);
      expect(content.contains('String? extractUrl('), isFalse);

      // Must directly invoke ShareIntentService.extractUrl
      expect(content.contains('ShareIntentService.extractUrl('), isTrue);
    });

    test('Verifies 1:1 delegation parity between ShareIntentService.extractUrl and UrlSanitizer.extractUrl', () {
      final testCases = [
        'https://youtu.be/dQw4w9WgXcQ.',
        '""https://youtu.be/dQw4w9WgXcQ""',
        'Check this: "https://youtu.be/dQw4w9WgXcQ"',
        '“‘https://www.pinterest.co.uk/pin/1234567890/’”',
        'Forwarded message: (https://www.youtube.com/live/dQw4w9WgXcQ)....?!',
        'https://pin.it/abcXYZ12,',
        'https://vm.tiktok.com/ZSxyz123/:;',
        '[Link](https://x.com/OpenAI/status/9876543210987654321)',
        'No link here just text',
        'https://www.pixiv.net/artworks/105356665',
      ];

      for (final text in testCases) {
        final fromService = ShareIntentService.extractUrl(text);
        final fromSanitizer = UrlSanitizer.extractUrl(text);
        expect(
          fromService,
          equals(fromSanitizer),
          reason: 'Parity mismatch between ShareIntentService and UrlSanitizer for: $text',
        );
      }
    });
  });

  group('Empirical Verification 2: Nested Quotes & Enclosures Stress Testing', () {
    test('Strips multiple levels of nested single, double, and typographic quotes', () {
      final cases = <String, String>{
        '""https://youtu.be/dQw4w9WgXcQ""': 'https://youtu.be/dQw4w9WgXcQ',
        '"""https://youtu.be/dQw4w9WgXcQ"""': 'https://youtu.be/dQw4w9WgXcQ',
        '\'\'https://youtu.be/dQw4w9WgXcQ\'\'': 'https://youtu.be/dQw4w9WgXcQ',
        '\'"https://youtu.be/dQw4w9WgXcQ"\'': 'https://youtu.be/dQw4w9WgXcQ',
        '"\'https://youtu.be/dQw4w9WgXcQ\'"': 'https://youtu.be/dQw4w9WgXcQ',
        '“https://youtu.be/dQw4w9WgXcQ”': 'https://youtu.be/dQw4w9WgXcQ',
        '“‘https://youtu.be/dQw4w9WgXcQ’”': 'https://youtu.be/dQw4w9WgXcQ',
        '“"https://youtu.be/dQw4w9WgXcQ"”': 'https://youtu.be/dQw4w9WgXcQ',
        '‘"https://youtu.be/dQw4w9WgXcQ"’': 'https://youtu.be/dQw4w9WgXcQ',
      };

      cases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for nested quotes: $input');
      });
    });

    test('Strips deeply nested mixed brackets, braces, parentheses, and angle brackets', () {
      final cases = <String, String>{
        '([{"<https://youtu.be/dQw4w9WgXcQ>"}])': 'https://youtu.be/dQw4w9WgXcQ',
        '((((https://youtu.be/dQw4w9WgXcQ))))': 'https://youtu.be/dQw4w9WgXcQ',
        '[[[[https://youtu.be/dQw4w9WgXcQ]]]]': 'https://youtu.be/dQw4w9WgXcQ',
        '{{{{https://youtu.be/dQw4w9WgXcQ}}}}': 'https://youtu.be/dQw4w9WgXcQ',
        '<<<<https://youtu.be/dQw4w9WgXcQ>>>>': 'https://youtu.be/dQw4w9WgXcQ',
        '(["https://youtu.be/dQw4w9WgXcQ"])': 'https://youtu.be/dQw4w9WgXcQ',
        '{[\'https://youtu.be/dQw4w9WgXcQ\']}': 'https://youtu.be/dQw4w9WgXcQ',
      };

      cases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for nested brackets: $input');
      });
    });

    test('Strips quotes and enclosures attached after query parameters and fragments', () {
      final cases = <String, String>{
        '"https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s"': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s',
        '\'https://youtu.be/dQw4w9WgXcQ?si=abcdef123\'': 'https://youtu.be/dQw4w9WgXcQ?si=abcdef123',
        '(https://www.pinterest.co.uk/pin/1234567890/?nic_v3=1a)': 'https://www.pinterest.co.uk/pin/1234567890/?nic_v3=1a',
        '["https://www.youtube.com/live/dQw4w9WgXcQ#t=10m"]': 'https://www.youtube.com/live/dQw4w9WgXcQ#t=10m',
      };

      cases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for query/fragment enclosure: $input');
      });
    });
  });

  group('Empirical Verification 3: Trailing Punctuation Cascades Stress Testing', () {
    test('Strips sequential repeated periods, ellipses, and interrobangs', () {
      final cases = <String, String>{
        'https://youtu.be/dQw4w9WgXcQ.': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ..': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ...': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ.....': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ!': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ?!?!?!': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ!??!': 'https://youtu.be/dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ...?!': 'https://youtu.be/dQw4w9WgXcQ',
      };

      cases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for punctuation cascade: $input');
      });
    });

    test('Strips combinations of commas, colons, semicolons, and parentheses', () {
      final cases = <String, String>{
        'https://pin.it/abcXYZ12,': 'https://pin.it/abcXYZ12',
        'https://pin.it/abcXYZ12;,': 'https://pin.it/abcXYZ12',
        'https://pin.it/abcXYZ12:;.,': 'https://pin.it/abcXYZ12',
        'https://youtu.be/dQw4w9WgXcQ.,:;!?': 'https://youtu.be/dQw4w9WgXcQ',
        'See this (https://youtu.be/dQw4w9WgXcQ),': 'https://youtu.be/dQw4w9WgXcQ',
        'See this (https://youtu.be/dQw4w9WgXcQ)...!': 'https://youtu.be/dQw4w9WgXcQ',
        'Bookmark [https://pin.it/abcXYZ12];': 'https://pin.it/abcXYZ12',
      };

      cases.forEach((input, expected) {
        final result = ShareIntentService.extractUrl(input);
        expect(result, equals(expected), reason: 'Failed for mixed punctuation: $input');
      });
    });
  });

  group('Empirical Verification 4: Regional Pinterest Domains & Routing', () {
    test('MediaPlatform.detect and PinterestExtractor.canHandle across 20+ regional Pinterest domains', () {
      final testUrls = [
        // Standard .com
        'https://www.pinterest.com/pin/1234567890/',
        'https://pinterest.com/pin/1234567890/',
        'https://www.pinterest.com/pin/1234567890',
        // Regional 2-part ccTLDs (.co.uk, .com.au, .co.kr, .com.br, .com.mx, .co.nz)
        'https://www.pinterest.co.uk/pin/1234567890/',
        'https://pinterest.co.uk/pin/1234567890/',
        'https://www.pinterest.com.au/pin/1234567890/',
        'https://pinterest.com.au/pin/1234567890/',
        'https://www.pinterest.co.kr/pin/1234567890/',
        'https://pinterest.co.kr/pin/1234567890/',
        'https://www.pinterest.com.br/pin/1234567890/',
        'https://pinterest.com.br/pin/1234567890/',
        'https://www.pinterest.com.mx/pin/1234567890/',
        'https://www.pinterest.co.nz/pin/1234567890/',
        // Single 2-letter ccTLDs (.de, .fr, .ca, .jp, .it, .es, .at, .ch, .pt, .se, .ie)
        'https://www.pinterest.de/pin/1234567890/',
        'https://www.pinterest.fr/pin/1234567890/',
        'https://www.pinterest.ca/pin/1234567890/',
        'https://www.pinterest.jp/pin/1234567890/',
        'https://www.pinterest.it/pin/1234567890/',
        'https://www.pinterest.es/pin/1234567890/',
        'https://www.pinterest.at/pin/1234567890/',
        'https://www.pinterest.ch/pin/1234567890/',
        'https://www.pinterest.pt/pin/1234567890/',
        'https://www.pinterest.se/pin/1234567890/',
        'https://www.pinterest.ie/pin/1234567890/',
        // Regional subdomains
        'https://id.pinterest.com/pin/1234567890/',
        'https://in.pinterest.com/pin/1234567890/',
        'https://br.pinterest.com/pin/1234567890/',
        'https://uk.pinterest.com/pin/1234567890/',
        'https://au.pinterest.com/pin/1234567890/',
        // Shortlinks
        'https://pin.it/abcXYZ12',
        'https://pin.it/7mK9pL2/',
        'http://pin.it/xyz987',
        'https://pin.it/abcXYZ12?invited_by=user123',
      ];

      final extractor = PinterestExtractor();

      for (final url in testUrls) {
        expect(
          MediaPlatform.detect(url),
          equals(MediaPlatform.pinterest),
          reason: 'MediaPlatform.detect failed for: $url',
        );
        expect(
          extractor.canHandle(url),
          isTrue,
          reason: 'PinterestExtractor.canHandle failed for: $url',
        );
      }
    });

    test('PinterestExtractor rejects non-pin profile and category URLs', () {
      final invalidUrls = [
        'https://www.pinterest.com/username/',
        'https://www.pinterest.co.uk/username/my-board/',
        'https://www.pinterest.com/ideas/home-decor/123456/',
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

  group('Empirical Verification 5: Live YouTube Links & Permutations', () {
    test('YouTubeExtractor handles live streams across standard, mobile, and query variants', () {
      const liveUrls = [
        {'url': 'https://www.youtube.com/live/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtube.com/live/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtube.com/live/dQw4w9WgXcQ/', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://m.youtube.com/live/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/live/dQw4w9WgXcQ?feature=share', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/live/dQw4w9WgXcQ?si=abcdef12345', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/live/dQw4w9WgXcQ#t=10m', 'id': 'dQw4w9WgXcQ'},
      ];

      final yt = YouTubeExtractor();

      for (final item in liveUrls) {
        final url = item['url']!;
        final expectedId = item['id']!;

        expect(
          MediaPlatform.detect(url),
          equals(MediaPlatform.youtube),
          reason: 'MediaPlatform.detect failed for live URL: $url',
        );
        expect(
          yt.canHandle(url),
          isTrue,
          reason: 'YouTubeExtractor.canHandle failed for live URL: $url',
        );
        expect(
          yt.extractVideoId(url),
          equals(expectedId),
          reason: 'extractVideoId mismatch for live URL: $url',
        );
      }
    });

    test('YouTubeExtractor handles standard watch, shorts, youtu.be, embed, and music', () {
      const fullPermutations = [
        {'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/watch?feature=shared&v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL123&index=5', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtu.be/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://youtu.be/dQw4w9WgXcQ?si=abcdef12345', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://www.youtube.com/shorts/3xyzABC1234', 'id': '3xyzABC1234'},
        {'url': 'https://youtube.com/shorts/3xyzABC1234/', 'id': '3xyzABC1234'},
        {'url': 'https://www.youtube.com/embed/dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://m.youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
        {'url': 'https://music.youtube.com/watch?v=dQw4w9WgXcQ', 'id': 'dQw4w9WgXcQ'},
      ];

      final yt = YouTubeExtractor();

      for (final item in fullPermutations) {
        final url = item['url']!;
        final expectedId = item['id']!;

        expect(yt.canHandle(url), isTrue, reason: 'Failed for $url');
        expect(yt.extractVideoId(url), equals(expectedId), reason: 'ID mismatch for $url');
      }
    });

    test('YouTubeExtractor rejects non-video channels, playlists, and user links', () {
      final nonVideos = [
        'https://www.youtube.com/channel/UC1234567890',
        'https://www.youtube.com/@RickAstley',
        'https://www.youtube.com/playlist?list=PL12345',
        'https://www.youtube.com/feed/subscriptions',
        'https://www.youtube.com/watch?v=short',
      ];

      final yt = YouTubeExtractor();
      for (final url in nonVideos) {
        expect(yt.canHandle(url), isFalse, reason: 'YouTubeExtractor should reject $url');
      }
    });
  });

  group('Empirical Verification 6: End-to-End Chat & Share Sheet Flow', () {
    test('Simulates end-to-end extraction from dirty share text to video ID resolution', () {
      final scenarios = [
        {
          'text': 'OMG watch this live stream right now: "https://www.youtube.com/live/dQw4w9WgXcQ".... it is crazy!',
          'expectedUrl': 'https://www.youtube.com/live/dQw4w9WgXcQ',
          'expectedPlatform': MediaPlatform.youtube,
          'expectedId': 'dQw4w9WgXcQ',
        },
        {
          'text': 'Pin from UK: <https://www.pinterest.co.uk/pin/1234567890/> check out the design:)',
          'expectedUrl': 'https://www.pinterest.co.uk/pin/1234567890/',
          'expectedPlatform': MediaPlatform.pinterest,
          'expectedId': null,
        },
        {
          'text': 'Check out this YouTube Short: “https://youtube.com/shorts/3xyzABC1234”?!',
          'expectedUrl': 'https://youtube.com/shorts/3xyzABC1234',
          'expectedPlatform': MediaPlatform.youtube,
          'expectedId': '3xyzABC1234',
        },
        {
          'text': 'Saved from Australian Pinterest: [Pin](https://www.pinterest.com.au/pin/9876543210/);',
          'expectedUrl': 'https://www.pinterest.com.au/pin/9876543210/',
          'expectedPlatform': MediaPlatform.pinterest,
          'expectedId': null,
        },
      ];

      final yt = YouTubeExtractor();
      final pin = PinterestExtractor();

      for (final sc in scenarios) {
        final text = sc['text'] as String;
        final expectedUrl = sc['expectedUrl'] as String;
        final expectedPlatform = sc['expectedPlatform'] as MediaPlatform;
        final expectedId = sc['expectedId'] as String?;

        final extractedUrl = ShareIntentService.extractUrl(text);
        expect(extractedUrl, equals(expectedUrl), reason: 'Extracted URL mismatch for: $text');

        final platform = MediaPlatform.detect(extractedUrl!);
        expect(platform, equals(expectedPlatform), reason: 'Platform detect mismatch for: $extractedUrl');

        if (platform == MediaPlatform.youtube) {
          expect(yt.canHandle(extractedUrl), isTrue);
          expect(yt.extractVideoId(extractedUrl), equals(expectedId));
        } else if (platform == MediaPlatform.pinterest) {
          expect(pin.canHandle(extractedUrl), isTrue);
        }
      }
    });
  });
}
