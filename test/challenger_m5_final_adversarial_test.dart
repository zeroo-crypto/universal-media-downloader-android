import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/core/storage/hierarchy_manager.dart';
import 'package:universal_media_downloader/core/utils/clean_cancel.dart';
import 'package:universal_media_downloader/core/utils/url_sanitizer.dart';
import 'package:universal_media_downloader/extractors/base_extractor.dart';
import 'package:universal_media_downloader/extractors/instagram_extractor.dart';
import 'package:universal_media_downloader/extractors/pinterest_extractor.dart';
import 'package:universal_media_downloader/extractors/pixiv_extractor.dart';
import 'package:universal_media_downloader/extractors/tiktok_extractor.dart';
import 'package:universal_media_downloader/extractors/twitter_extractor.dart';
import 'package:universal_media_downloader/extractors/youtube_extractor.dart';
import 'package:universal_media_downloader/services/share_intent_service.dart';

void main() {
  late Directory tempTestDir;

  setUp(() {
    tempTestDir = Directory.systemTemp.createTempSync('m5_challenger_adv_');
  });

  tearDown(() {
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('M5 Adversarial Suite 1: Media Extraction & URL Sanitization Rigor', () {
    test('Extreme punctuation, Unicode quotes, and Markdown enclosures stripping', () {
      final testCases = <String, String>{
        // Standard Markdown links
        '[Watch Video](https://www.youtube.com/watch?v=dQw4w9WgXcQ)': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        '<https://pin.it/abcXYZ12>': 'https://pin.it/abcXYZ12',
        // Typographic & curly quotes
        '“https://x.com/OpenAI/status/1234567890123456789”': 'https://x.com/OpenAI/status/1234567890123456789',
        '‘https://www.pixiv.net/artworks/105356665’': 'https://www.pixiv.net/artworks/105356665',
        // Multiple nested enclosures
        '({[<"https://www.tiktok.com/@creator/video/7123456789012345678">]})':
            'https://www.tiktok.com/@creator/video/7123456789012345678',
        // Trailing sentence punctuation cascades
        'Did you see this? https://youtu.be/dQw4w9WgXcQ...?!': 'https://youtu.be/dQw4w9WgXcQ',
        'Link: "https://www.pinterest.com/pin/1234567890/"; check it': 'https://www.pinterest.com/pin/1234567890/',
        'See (https://www.youtube.com/live/dQw4w9WgXcQ), then let me know': 'https://www.youtube.com/live/dQw4w9WgXcQ',
        // Query parameters with URL-encoded characters followed by punctuation
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=youtu.be&t=100s...':
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ&feature=youtu.be&t=100s',
      };

      testCases.forEach((input, expected) {
        final extracted = UrlSanitizer.extractUrl(input);
        expect(extracted, equals(expected), reason: 'Failed to extract clean URL from: $input');
        // Parity with ShareIntentService
        expect(ShareIntentService.extractUrl(input), equals(extracted));
      });
    });

    test('Registry canHandle accurately matches all 6 platform extractors', () {
      final extractors = <BaseExtractor>[
        PixivExtractor(),
        YouTubeExtractor(),
        PinterestExtractor(),
        TwitterExtractor(),
        InstagramExtractor(),
        TikTokExtractor(),
      ];

      BaseExtractor? findMatch(String url) {
        for (final ext in extractors) {
          if (ext.canHandle(url)) return ext;
        }
        return null;
      }

      final platforms = <String, Type>{
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ': YouTubeExtractor,
        'https://youtu.be/dQw4w9WgXcQ': YouTubeExtractor,
        'https://youtube.com/shorts/3xyzABC1234': YouTubeExtractor,
        'https://youtube.com/live/dQw4w9WgXcQ': YouTubeExtractor,
        'https://www.pixiv.net/artworks/105356665': PixivExtractor,
        'https://www.pixiv.net/en/artworks/105356665': PixivExtractor,
        'https://www.pinterest.com/pin/1234567890/': PinterestExtractor,
        'https://www.pinterest.co.uk/pin/1234567890/': PinterestExtractor,
        'https://pin.it/abcXYZ12': PinterestExtractor,
        'https://x.com/OpenAI/status/1234567890123456789': TwitterExtractor,
        'https://twitter.com/user/status/1234567890123456789': TwitterExtractor,
        'https://www.instagram.com/reel/C3bXyZ123/': InstagramExtractor,
        'https://www.instagram.com/p/C3bXyZ123/': InstagramExtractor,
        'https://www.tiktok.com/@creator/video/7123456789012345678': TikTokExtractor,
        'https://vm.tiktok.com/ZSxyz123/': TikTokExtractor,
        'https://vt.tiktok.com/ZSxyz123/': TikTokExtractor,
      };

      platforms.forEach((url, expectedType) {
        final extractor = findMatch(url);
        expect(extractor, isNotNull, reason: 'Failed to resolve extractor for $url');
        expect(extractor.runtimeType, equals(expectedType), reason: 'Wrong extractor type for $url');
      });
    });

    test('Registry canHandle returns null for unsupported, invalid, or generic URLs', () {
      final extractors = <BaseExtractor>[
        PixivExtractor(),
        YouTubeExtractor(),
        PinterestExtractor(),
        TwitterExtractor(),
        InstagramExtractor(),
        TikTokExtractor(),
      ];

      BaseExtractor? findMatch(String url) {
        for (final ext in extractors) {
          if (ext.canHandle(url)) return ext;
        }
        return null;
      }

      final unsupportedUrls = [
        'https://example.com/some/random/video.mp4',
        'https://github.com/flutter/flutter',
        'https://en.wikipedia.org/wiki/Dart_(programming_language)',
        'https://news.ycombinator.com',
        'https://medium.com/@author/story',
        'http://localhost:8080/stream',
      ];

      for (final url in unsupportedUrls) {
        final extractor = findMatch(url);
        expect(extractor, isNull, reason: 'Expected null extractor for unsupported: $url');
      }
    });

    test('Negative extractor parsing on malformed inputs throws descriptive exceptions', () async {
      final yt = YouTubeExtractor();
      try {
        await yt.extract('https://www.youtube.com/watch?v=short');
        expect(false, isTrue, reason: 'Expected exception for malformed short YouTube URL');
      } catch (e) {
        expect(e.toString(), contains('tidak valid'));
      }

      final pixiv = PixivExtractor();
      try {
        await pixiv.extract('https://www.pixiv.net/artworks/abc');
        expect(false, isTrue, reason: 'Expected exception for malformed Pixiv URL');
      } catch (e) {
        expect(e.toString(), contains('tidak valid'));
      }

      final twitter = TwitterExtractor();
      try {
        await twitter.extract('https://x.com/status/123');
        expect(false, isTrue, reason: 'Expected exception for malformed Twitter URL');
      } catch (e) {
        expect(e.toString(), contains('tidak valid'));
      }

      final ig = InstagramExtractor();
      try {
        await ig.extract('https://instagram.com/stories/user/123');
        expect(false, isTrue, reason: 'Expected exception for non-media Instagram URL');
      } catch (e) {
        expect(e.toString(), contains('tidak valid'));
      }
    });
  });

  group('M5 Adversarial Suite 2: Storage Invariants & HierarchyManager Rules', () {
    test('Enforces strict platform routing invariants across all media platforms', () async {
      // 1. YouTube, Spotify, Telegram, Google Drive ALWAYS route to creator root
      for (final platform in [
        MediaPlatform.youtube,
        MediaPlatform.spotify,
        MediaPlatform.telegram,
        MediaPlatform.googledrive
      ]) {
        final dir = await HierarchyManager.resolveDestinationDirectory(
          platform: platform,
          creatorName: 'TestChannel',
          workId: 'Work123',
          isMultiPage: true, // Should still go to creator root!
        );
        expect(p.basename(dir.path), equals('TestChannel'));
      }

      // 2. Pinterest Created Pin MUST stay in creator root
      final pinCreatedDir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: 'PinCreator',
        isPinterestCreatedPin: true,
        pinterestBoardName: 'IgnoredBoard',
      );
      expect(p.basename(pinCreatedDir.path), equals('PinCreator'));

      // 3. Pinterest Saved Board MUST go into creator/board subfolder
      final pinBoardDir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: 'PinCreator',
        isPinterestCreatedPin: false,
        pinterestBoardName: 'Design Inspiration',
      );
      expect(p.basename(pinBoardDir.path), equals('Design Inspiration'));
      expect(p.basename(pinBoardDir.parent.path), equals('PinCreator'));
    });

    test('Visual platform adaptive hierarchy: single work -> root, multi-page -> workId subfolder', () async {
      final uniqueCreator = 'AdaptiveArtist_${DateTime.now().microsecondsSinceEpoch}';

      // 1st single download in fresh directory -> creator root
      final dir1 = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: uniqueCreator,
        workId: 'Work999',
        isMultiPage: false,
      );
      expect(p.basename(dir1.path), equals(uniqueCreator));

      // Multi-page album -> workId subfolder
      final dir2 = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: uniqueCreator,
        workId: 'Work888',
        isMultiPage: true,
      );
      expect(p.basename(dir2.path), equals('Work888'));
      expect(p.basename(dir2.parent.path), equals(uniqueCreator));

      // Cleanup
      try {
        dir1.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('Massive filename collision resilience up to 50 iterations', () async {
      final collisionDir = Directory(p.join(tempTestDir.path, 'CollisionTest'))..createSync(recursive: true);

      // Create base file + 49 collision files: base.mp4, base_1.mp4, ... base_49.mp4
      File(p.join(collisionDir.path, 'video.mp4')).writeAsStringSync('0');
      for (int i = 1; i < 50; i++) {
        File(p.join(collisionDir.path, 'video_$i.mp4')).writeAsStringSync('$i');
      }

      // 51st file must safely get video_50.mp4
      final uniquePath = await HierarchyManager.getUniqueDestinationFilePath(
        directory: collisionDir,
        baseFileName: 'video',
        extension: 'mp4',
      );

      expect(p.basename(uniquePath), equals('video_50.mp4'));
      expect(File(uniquePath).existsSync(), isFalse);
    });

    test('Sanitization handles edge-case strings without throwing exceptions', () {
      final inputs = [
        'Normal Name',
        'Name with   multiple    spaces',
        'Name:with:colons:and:slashes/and\\backslashes',
        '<Illegal>|"Chars"?*',
        '...',
        '..',
        '.',
        '   ',
        '',
        'YouTube Media',
        'Instagram Media',
        'Special #Hashtag & Symbol!',
        'Emoji 🎨 Illustration ✨',
      ];

      for (final input in inputs) {
        final sanitized = HierarchyManager.sanitizeName(input);
        expect(sanitized.isNotEmpty, isTrue, reason: 'Sanitization produced empty string for: $input');
        expect(sanitized, isNot(contains('/')));
        expect(sanitized, isNot(contains(r'\')));
        expect(sanitized, isNot(contains(':')));
        expect(sanitized, isNot(contains('*')));
        expect(sanitized, isNot(contains('?')));
        expect(sanitized, isNot(contains('"')));
        expect(sanitized, isNot(contains('<')));
        expect(sanitized, isNot(contains('>')));
        expect(sanitized, isNot(contains('|')));
      }
    });
  });

  group('M5 Adversarial Suite 3: Clean Cancellation & Zero Orphan Invariants', () {
    test('Case-insensitive recognition of all temporary download extensions', () {
      final validTemps = [
        'file.part',
        'file.PART',
        'file.Part',
        'file.tmp',
        'file.TMP',
        'file.crdownload',
        'file.CRDOWNLOAD',
        'file.ytdl',
        'file.YTDL',
        'file.download',
        'file.DOWNLOAD',
        'path/to/my/download.mp4.part',
        'C:\\Users\\Download\\video.tmp',
      ];

      for (final path in validTemps) {
        expect(CleanCancel.isTemporary(path), isTrue, reason: 'Failed to recognize temp: $path');
      }

      final nonTemps = [
        'video.mp4',
        'image.jpg',
        'photo.png',
        'audio.m4a',
        'animation.gif',
        'archive.zip',
        'document.pdf',
        'party_night.mp4',
        'temporary_solution.jpg',
        'template.tmp.mp4', // Ends with .mp4!
      ];

      for (final path in nonTemps) {
        expect(CleanCancel.isTemporary(path), isFalse, reason: 'Falsely flagged non-temp: $path');
      }
    });

    test('Multi-level nested directory sweep removes all temp & 0-byte files, preserves all real media', () async {
      // Create nested test structure
      final deepDir = Directory(p.join(tempTestDir.path, 'Media', 'YouTube', 'ChannelA', 'sub'))..createSync(recursive: true);

      // 5 valid non-empty files
      final v1 = File(p.join(tempTestDir.path, 'root_valid.mp4'))..writeAsBytesSync([1, 2, 3]);
      final v2 = File(p.join(deepDir.path, 'video.mp4'))..writeAsBytesSync(List.filled(500, 0x11));
      final v3 = File(p.join(deepDir.path, 'audio.m4a'))..writeAsBytesSync(List.filled(200, 0x22));
      final v4 = File(p.join(deepDir.path, 'cover.jpg'))..writeAsBytesSync(List.filled(100, 0x33));
      final v5 = File(p.join(deepDir.path, 'party_clip.mp4'))..writeAsBytesSync(List.filled(400, 0x44));

      // 8 temporary files
      final t1 = File(p.join(deepDir.path, 'download_1.mp4.part'))..writeAsBytesSync([1]);
      final t2 = File(p.join(deepDir.path, 'temp_file.tmp'))..writeAsBytesSync([2]);
      final t3 = File(p.join(deepDir.path, 'chrome.crdownload'))..writeAsBytesSync([3]);
      final t4 = File(p.join(deepDir.path, 'stream.ytdl'))..writeAsBytesSync([4]);
      final t5 = File(p.join(deepDir.path, 'app.download'))..writeAsBytesSync([5]);
      final t6 = File(p.join(deepDir.path, 'caps.PART'))..writeAsBytesSync([6]);
      final t7 = File(p.join(deepDir.path, 'caps.TMP'))..writeAsBytesSync([7]);
      final t8 = File(p.join(deepDir.path, 'caps.CRDOWNLOAD'))..writeAsBytesSync([8]);

      // 4 zero-byte corrupt candidate files
      final z1 = File(p.join(deepDir.path, 'corrupt.mp4'))..writeAsBytesSync([]);
      final z2 = File(p.join(deepDir.path, 'corrupt.jpg'))..writeAsBytesSync([]);
      final z3 = File(p.join(tempTestDir.path, 'corrupt_root.png'))..writeAsBytesSync([]);
      final z4 = File(p.join(deepDir.path, 'corrupt.m4a'))..writeAsBytesSync([]);

      // Total items to delete: 8 temp + 4 zero-byte = 12 items
      final deleted = await CleanCancel.cleanupDirectory(tempTestDir);
      expect(deleted, equals(12));

      // Verify all valid files survive
      expect(v1.existsSync(), isTrue);
      expect(v2.existsSync(), isTrue);
      expect(v3.existsSync(), isTrue);
      expect(v4.existsSync(), isTrue);
      expect(v5.existsSync(), isTrue);

      // Verify all temp and zero-byte files are gone
      for (final f in [t1, t2, t3, t4, t5, t6, t7, t8, z1, z2, z3, z4]) {
        expect(f.existsSync(), isFalse, reason: 'File should have been deleted: ${f.path}');
      }
    });

    test('cleanupPartialFile purges companion files (.part, .tmp) cleanly and idempotently', () async {
      final target = File(p.join(tempTestDir.path, 'video.mp4'))..writeAsBytesSync([1, 2, 3]);
      final part = File(p.join(tempTestDir.path, 'video.mp4.part'))..writeAsBytesSync([4, 5]);
      final tmp = File(p.join(tempTestDir.path, 'video.mp4.tmp'))..writeAsBytesSync([6, 7]);
      final cr = File(p.join(tempTestDir.path, 'video.mp4.crdownload'))..writeAsBytesSync([8, 9]);

      // Run cleanup on target
      await CleanCancel.cleanupPartialFile(target.path);

      // Finished valid target must remain intact, but companions must be gone
      expect(target.existsSync(), isTrue);
      expect(part.existsSync(), isFalse);
      expect(tmp.existsSync(), isFalse);
      expect(cr.existsSync(), isFalse);

      // Calling again must be safe and idempotent
      await CleanCancel.cleanupPartialFile(target.path);
      expect(target.existsSync(), isTrue);
    });
  });
}
