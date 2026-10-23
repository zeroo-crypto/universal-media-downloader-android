import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/core/storage/hierarchy_manager.dart';
import 'package:universal_media_downloader/core/utils/clean_cancel.dart';

void main() {
  late Directory tempTestDir;

  setUp(() {
    tempTestDir = Directory.systemTemp.createTempSync('challenger2_adv_test_');
  });

  tearDown(() {
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Adversarial Challenge A: HierarchyManager Malicious & Boundary Folder Names', () {
    test('Sanitizes single dot and double dot to underscore', () {
      expect(HierarchyManager.sanitizeName('.'), equals('_'));
      expect(HierarchyManager.sanitizeName('..'), equals('_'));
    });

    test('Sanitizes triple dots and dots with slashes', () {
      final sanitizedTriple = HierarchyManager.sanitizeName('.../');
      expect(sanitizedTriple, equals('..._'));
      expect(sanitizedTriple, isNot(contains('/')));
      expect(sanitizedTriple, isNot(contains('\\')));

      final sanitizedDots = HierarchyManager.sanitizeName('....');
      expect(sanitizedDots, equals('....'));

      // Test directory creation with '...' and '..._'
      final dirTriple = Directory(p.join(tempTestDir.path, sanitizedTriple));
      dirTriple.createSync(recursive: true);
      expect(dirTriple.existsSync(), isTrue);
    });

    test('Sanitizes leading, trailing, and repeated slashes and backslashes', () {
      expect(HierarchyManager.sanitizeName('/creator/'), equals('_creator_'));
      expect(HierarchyManager.sanitizeName('///creator///'), equals('___creator___'));
      expect(HierarchyManager.sanitizeName(r'\creator\'), equals('_creator_'));
      expect(HierarchyManager.sanitizeName(r'\\\creator\\\'), equals('___creator___'));
      expect(HierarchyManager.sanitizeName('/'), equals('_'));
      expect(HierarchyManager.sanitizeName(r'\'), equals('_'));
      expect(HierarchyManager.sanitizeName('//'), equals('__'));
    });

    test('Sanitizes empty strings, whitespace, and tabs to "General"', () {
      expect(HierarchyManager.sanitizeName(''), equals('General'));
      expect(HierarchyManager.sanitizeName(' '), equals('General'));
      expect(HierarchyManager.sanitizeName('    '), equals('General'));
      expect(HierarchyManager.sanitizeName('\t\n\r'), equals('General'));
    });

    test('Behavior on Windows reserved names (CON, PRN, AUX, NUL, COM1, LPT1)', () async {
      final reservedNames = ['CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM9', 'LPT1', 'LPT9', 'con', 'nul', 'aux'];
      for (final name in reservedNames) {
        final sanitized = HierarchyManager.sanitizeName(name);
        expect(sanitized.isNotEmpty, isTrue);
      }

      // Check resolveDestinationDirectory with reserved names
      for (final name in ['CON', 'PRN', 'AUX', 'COM1']) {
        final dir = await HierarchyManager.resolveDestinationDirectory(
          platform: MediaPlatform.youtube,
          creatorName: name,
        );
        expect(dir.existsSync(), isTrue);
      }

      // NUL is a known Windows filesystem quirk for raw Directory.exists / Directory.create
      // On Android / Linux ext4, NUL is a normal directory name.
      if (Platform.isWindows) {
        try {
          await HierarchyManager.resolveDestinationDirectory(
            platform: MediaPlatform.youtube,
            creatorName: 'NUL',
          );
          print('Windows creator "NUL": resolved successfully');
        } catch (e) {
          print('Windows creator "NUL" expected OS quirk: $e');
        }
      }
    });

    test('Path traversal attempts remain safely confined to parent directory', () {
      final traversalInputs = [
        '../../../../etc/shadow',
        r'..\..\..\..\Windows\System32',
        '/etc/passwd',
        r'C:\Windows\System32',
        '....//....//....//escape',
      ];

      for (final input in traversalInputs) {
        final sanitized = HierarchyManager.sanitizeName(input);
        expect(sanitized, isNot(contains('/')));
        expect(sanitized, isNot(contains(r'\')));
        expect(sanitized, isNot(contains(':')));

        // When joined with base directory, must not escape
        final resolved = p.canonicalize(p.join(tempTestDir.path, sanitized));
        expect(p.isWithin(tempTestDir.path, resolved) || resolved == tempTestDir.path, isTrue,
            reason: 'Path traversal escaped temp directory: $resolved');
      }
    });
  });

  group('Adversarial Challenge B: Clean Cancellation Recursive Sweeping & Media Preservation', () {
    test('Recursive sweeping purges .part and .tmp files in nested folders without touching valid media', () async {
      // Construct deeply nested hierarchy simulating:
      // root/
      //   Pixiv/
      //     Artist1/
      //       work_123/
      //         01.jpg (valid, 1024 bytes)
      //         02.png (valid, 2048 bytes)
      //         03.jpg.part (temp, 500 bytes)
      //         04.tmp (temp, 200 bytes)
      //     Artist2/
      //       single.mp4 (valid, 5000 bytes)
      //       aborted.mp4.part (temp, 300 bytes)
      //       orphan.crdownload (temp, 100 bytes)
      //       stream.ytdl (temp, 150 bytes)
      //       package.download (temp, 50 bytes)
      //       corrupt_zero.mp4 (0 bytes)
      //       corrupt_zero.png (0 bytes)
      //       corrupt_zero.jpg (0 bytes)

      final workDir = Directory(p.join(tempTestDir.path, 'Pixiv', 'Artist1', 'work_123'))..createSync(recursive: true);
      final validJpg = File(p.join(workDir.path, '01.jpg'))..writeAsBytesSync(List.filled(1024, 0xAA));
      final validPng = File(p.join(workDir.path, '02.png'))..writeAsBytesSync(List.filled(2048, 0xBB));
      final tempPart = File(p.join(workDir.path, '03.jpg.part'))..writeAsBytesSync(List.filled(500, 0xCC));
      final tempTmp = File(p.join(workDir.path, '04.tmp'))..writeAsBytesSync(List.filled(200, 0xDD));

      final artist2Dir = Directory(p.join(tempTestDir.path, 'Pixiv', 'Artist2'))..createSync(recursive: true);
      final validMp4 = File(p.join(artist2Dir.path, 'single.mp4'))..writeAsBytesSync(List.filled(5000, 0xEE));
      final tempPart2 = File(p.join(artist2Dir.path, 'aborted.mp4.part'))..writeAsBytesSync(List.filled(300, 0xFF));
      final tempCr = File(p.join(artist2Dir.path, 'orphan.crdownload'))..writeAsBytesSync(List.filled(100, 0x11));
      final tempYtdl = File(p.join(artist2Dir.path, 'stream.ytdl'))..writeAsBytesSync(List.filled(150, 0x22));
      final tempDownload = File(p.join(artist2Dir.path, 'package.download'))..writeAsBytesSync(List.filled(50, 0x33));
      final zeroMp4 = File(p.join(artist2Dir.path, 'corrupt_zero.mp4'))..writeAsBytesSync([]);
      final zeroPng = File(p.join(artist2Dir.path, 'corrupt_zero.png'))..writeAsBytesSync([]);
      final zeroJpg = File(p.join(artist2Dir.path, 'corrupt_zero.jpg'))..writeAsBytesSync([]);

      // Verify all 11 files exist before cleanup
      expect(validJpg.existsSync(), isTrue);
      expect(validPng.existsSync(), isTrue);
      expect(validMp4.existsSync(), isTrue);
      expect(tempPart.existsSync(), isTrue);
      expect(tempTmp.existsSync(), isTrue);
      expect(tempPart2.existsSync(), isTrue);
      expect(tempCr.existsSync(), isTrue);
      expect(tempYtdl.existsSync(), isTrue);
      expect(tempDownload.existsSync(), isTrue);
      expect(zeroMp4.existsSync(), isTrue);
      expect(zeroPng.existsSync(), isTrue);
      expect(zeroJpg.existsSync(), isTrue);

      // Perform recursive cleanup on root
      final deletedCount = await CleanCancel.cleanupDirectory(tempTestDir);

      // Exactly 9 files must be deleted: 6 temporary (.part, .tmp, .part, .crdownload, .ytdl, .download) + 3 zero-byte files
      expect(deletedCount, equals(9), reason: 'Expected 6 temp + 3 zero-byte files purged');

      // Valid files MUST remain untouched
      expect(validJpg.existsSync(), isTrue, reason: 'Valid 01.jpg must not be deleted');
      expect(validPng.existsSync(), isTrue, reason: 'Valid 02.png must not be deleted');
      expect(validMp4.existsSync(), isTrue, reason: 'Valid single.mp4 must not be deleted');
      expect(validJpg.lengthSync(), equals(1024));
      expect(validPng.lengthSync(), equals(2048));
      expect(validMp4.lengthSync(), equals(5000));

      // Temporary and zero-byte files MUST be completely purged
      expect(tempPart.existsSync(), isFalse);
      expect(tempTmp.existsSync(), isFalse);
      expect(tempPart2.existsSync(), isFalse);
      expect(tempCr.existsSync(), isFalse);
      expect(tempYtdl.existsSync(), isFalse);
      expect(tempDownload.existsSync(), isFalse);
      expect(zeroMp4.existsSync(), isFalse);
      expect(zeroPng.existsSync(), isFalse);
      expect(zeroJpg.existsSync(), isFalse);
    });

    test('Non-existent and already-empty directories return 0 safely', () async {
      final nonExistentDir = Directory(p.join(tempTestDir.path, 'does_not_exist'));
      expect(await CleanCancel.cleanupDirectory(nonExistentDir), equals(0));

      final emptyDir = Directory(p.join(tempTestDir.path, 'empty_dir'))..createSync();
      expect(await CleanCancel.cleanupDirectory(emptyDir), equals(0));
    });
  });

  group('Adversarial Challenge C: Migration Precision with WorkId "1"', () {
    test('Ensures workId "1" migrates only files belonging to workId 1, not "10_test.mp4" or "episode_1.mp4"', () async {

      // Create files in creator directory under BaseMediaDirectory:
      final baseDir = await HierarchyManager.getBaseMediaDirectory();
      final creatorName = 'CreatorPrecisionTest_${DateTime.now().millisecondsSinceEpoch}';
      final creatorDir = Directory(p.join(baseDir.path, 'Pixiv', creatorName))..createSync(recursive: true);

      // Files that MUST migrate (belonging to workId "1"):
      final file1 = File(p.join(creatorDir.path, '1_cover.jpg'))..writeAsStringSync('work 1 cover');
      final file2 = File(p.join(creatorDir.path, '1_page1.png'))..writeAsStringSync('work 1 page 1');
      final file3 = File(p.join(creatorDir.path, '1.mp4'))..writeAsStringSync('work 1 single video');

      // Files that MUST NOT migrate (unrelated files containing substring "1"):
      final unrelated1 = File(p.join(creatorDir.path, '10_test.mp4'))..writeAsStringSync('work 10 file');
      final unrelated2 = File(p.join(creatorDir.path, '100_photo.jpg'))..writeAsStringSync('work 100 file');
      final unrelated3 = File(p.join(creatorDir.path, '11_extra.png'))..writeAsStringSync('work 11 file');
      final unrelated4 = File(p.join(creatorDir.path, 'episode_1.mp4'))..writeAsStringSync('episode 1');
      final unrelated5 = File(p.join(creatorDir.path, 'part1_audio.mp3'))..writeAsStringSync('part 1 audio');
      final unrelated6 = File(p.join(creatorDir.path, 'track-1.m4a'))..writeAsStringSync('track 1');
      final unrelated7 = File(p.join(creatorDir.path, 'my_1_drawing.png'))..writeAsStringSync('my drawing');

      // Now call resolveDestinationDirectory with workId: '1'
      final targetWorkDir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: creatorName,
        workId: '1',
      );

      expect(p.basename(targetWorkDir.path), equals('1'));
      expect(targetWorkDir.existsSync(), isTrue);

      // Verify files belonging to workId 1 WERE migrated into targetWorkDir:
      expect(File(p.join(targetWorkDir.path, '1_cover.jpg')).existsSync(), isTrue);
      expect(File(p.join(targetWorkDir.path, '1_page1.png')).existsSync(), isTrue);
      expect(File(p.join(targetWorkDir.path, '1.mp4')).existsSync(), isTrue);

      // And removed from creator root:
      expect(file1.existsSync(), isFalse);
      expect(file2.existsSync(), isFalse);
      expect(file3.existsSync(), isFalse);

      // Verify unrelated files WERE NOT migrated (remain in creator root):
      expect(unrelated1.existsSync(), isTrue, reason: '10_test.mp4 must NOT be migrated by workId 1');
      expect(unrelated2.existsSync(), isTrue, reason: '100_photo.jpg must NOT be migrated by workId 1');
      expect(unrelated3.existsSync(), isTrue, reason: '11_extra.png must NOT be migrated by workId 1');
      expect(unrelated4.existsSync(), isTrue, reason: 'episode_1.mp4 must NOT be migrated by workId 1');
      expect(unrelated5.existsSync(), isTrue, reason: 'part1_audio.mp3 must NOT be migrated by workId 1');
      expect(unrelated6.existsSync(), isTrue, reason: 'track-1.m4a must NOT be migrated by workId 1');
      expect(unrelated7.existsSync(), isTrue, reason: 'my_1_drawing.png must NOT be migrated by workId 1');

      // Verify unrelated files are NOT in targetWorkDir:
      expect(File(p.join(targetWorkDir.path, '10_test.mp4')).existsSync(), isFalse);
      expect(File(p.join(targetWorkDir.path, '100_photo.jpg')).existsSync(), isFalse);
      expect(File(p.join(targetWorkDir.path, '11_extra.png')).existsSync(), isFalse);
      expect(File(p.join(targetWorkDir.path, 'episode_1.mp4')).existsSync(), isFalse);
      expect(File(p.join(targetWorkDir.path, 'part1_audio.mp3')).existsSync(), isFalse);
      expect(File(p.join(targetWorkDir.path, 'track-1.m4a')).existsSync(), isFalse);
      expect(File(p.join(targetWorkDir.path, 'my_1_drawing.png')).existsSync(), isFalse);

      // Cleanup
      try {
        creatorDir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });
}
