import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/core/utils/clean_cancel.dart';
import 'package:universal_media_downloader/core/storage/hierarchy_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempTestDir;

  setUp(() {
    tempTestDir = Directory.systemTemp.createTempSync('adversarial_test_');
  });

  tearDown(() {
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  // =========================================================================
  // GROUP 1: CleanCancel Partial File Extension Resilience & Companion Purging
  // =========================================================================
  group('Adversarial Group 1: CleanCancel Partial File Extensions & Companion Purging', () {
    test('Identifies all 5 standard partial file extensions across uppercase and lowercase', () {
      final validExtensions = ['.part', '.tmp', '.crdownload', '.ytdl', '.download'];
      for (final ext in validExtensions) {
        expect(CleanCancel.isTemporary('sample$ext'), isTrue, reason: 'Failed for $ext');
        expect(CleanCancel.isTemporary('sample${ext.toUpperCase()}'), isTrue, reason: 'Failed for uppercase $ext');
        expect(CleanCancel.isTemporary('path/to/media.mp4$ext'), isTrue);
      }
    });

    test('Negative extension testing: stem-embedded words and valid media extensions are preserved', () {
      final safeFiles = [
        'video.mp4',
        'artwork.jpg',
        'photo.png',
        'audio.m4a',
        'track.mp3',
        'anim.webp',
        'anim.gif',
        'archive.zip',
        'part1_final.mp4',
        'my_party_video.mp4',
        'download_guide.pdf',
        'crdownload_spec.txt',
        'tmp_file_analysis.dart',
        'ytdl_script.py',
        'part.mp4',
        'tmp.jpg',
      ];

      for (final file in safeFiles) {
        expect(CleanCancel.isTemporary(file), isFalse, reason: 'False positive temporary flag for $file');
      }
    });

    test('cleanupPartialFile purges target file if it has a temporary extension directly', () async {
      for (final ext in ['.part', '.tmp', '.crdownload', '.ytdl', '.download']) {
        final f = File(p.join(tempTestDir.path, 'download_target$ext'));
        f.writeAsStringSync('partial chunk data for $ext');
        expect(f.existsSync(), isTrue);

        await CleanCancel.cleanupPartialFile(f.path);

        expect(f.existsSync(), isFalse, reason: 'Target $ext file was not deleted');
      }
    });

    test('cleanupPartialFile purges all companion temporary variants simultaneously while leaving finished file safe', () async {
      final finalTargetPath = p.join(tempTestDir.path, 'movie.mp4');
      final finishedFile = File(finalTargetPath)..writeAsStringSync('VALID NON-EMPTY FINISHED MOVIE STREAM');
      
      // Companion partial files created by downloaders
      final companions = [
        File('$finalTargetPath.part')..writeAsStringSync('part chunk'),
        File('$finalTargetPath.tmp')..writeAsStringSync('tmp buffer'),
        File('$finalTargetPath.crdownload')..writeAsStringSync('cr partial'),
        File('$finalTargetPath.ytdl')..writeAsStringSync('ytdl stream'),
        File('$finalTargetPath.download')..writeAsStringSync('download partial'),
      ];

      for (final c in companions) {
        expect(c.existsSync(), isTrue);
      }

      // Sibling files that must remain untouched
      final siblingFinished = File(p.join(tempTestDir.path, 'other_movie.mp4'))..writeAsStringSync('other finished movie');
      final siblingM4a = File(p.join(tempTestDir.path, 'movie.m4a'))..writeAsStringSync('soundtrack');

      await CleanCancel.cleanupPartialFile(finalTargetPath);

      // Finished file must remain because length > 0 and extension is .mp4
      expect(finishedFile.existsSync(), isTrue, reason: 'Finished movie.mp4 must not be deleted');
      // All companions must be deleted
      for (final c in companions) {
        expect(c.existsSync(), isFalse, reason: 'Companion file ${c.path} was not deleted');
      }
      // Siblings must remain untouched
      expect(siblingFinished.existsSync(), isTrue, reason: 'Sibling file must not be deleted');
      expect(siblingM4a.existsSync(), isTrue, reason: 'Soundtrack must not be deleted');
    });

    test('cleanupPartialFile deletes 0-byte corrupt candidate files', () async {
      final zeroByteFile = File(p.join(tempTestDir.path, 'aborted_stream.mp4'));
      zeroByteFile.writeAsBytesSync([]); // 0 bytes
      expect(zeroByteFile.existsSync(), isTrue);
      expect(zeroByteFile.lengthSync(), equals(0));

      await CleanCancel.cleanupPartialFile(zeroByteFile.path);

      expect(zeroByteFile.existsSync(), isFalse, reason: '0-byte corrupt file must be deleted');
    });

    test('cleanupPartialFile does not delete or alter directories if passed a directory path', () async {
      final subFolder = Directory(p.join(tempTestDir.path, 'important_subfolder'))..createSync();
      File(p.join(subFolder.path, 'keep_me.jpg')).writeAsStringSync('photo');

      await CleanCancel.cleanupPartialFile(subFolder.path);

      expect(subFolder.existsSync(), isTrue, reason: 'Directories must never be deleted by cleanupPartialFile');
      expect(File(p.join(subFolder.path, 'keep_me.jpg')).existsSync(), isTrue);
    });
  });

  // =========================================================================
  // GROUP 2: Directory Sweeping & Preservation Invariants
  // =========================================================================
  group('Adversarial Group 2: Directory Sweeping & Structural Preservation Invariants', () {
    test('cleanupDirectory handles non-existent or empty directories gracefully', () async {
      final nonExistent = Directory(p.join(tempTestDir.path, 'does_not_exist'));
      expect(await CleanCancel.cleanupDirectory(nonExistent), equals(0));

      final emptyDir = Directory(p.join(tempTestDir.path, 'empty_dir'))..createSync();
      expect(await CleanCancel.cleanupDirectory(emptyDir), equals(0));
      expect(emptyDir.existsSync(), isTrue, reason: 'Empty directory itself must be preserved');
    });

    test('cleanupDirectory purges only temporary & zero-byte files, preserving finished files and subdirectories', () async {
      // 1. Subdirectories (MUST SURVIVE)
      final subDir1 = Directory(p.join(tempTestDir.path, 'album_subfolder'))..createSync();
      final subDir2 = Directory(p.join(tempTestDir.path, 'nested_creator'))..createSync();

      // 2. Finished valid files (MUST SURVIVE - both at root and inside nested subdirectories)
      final keepList = [
        File(p.join(tempTestDir.path, 'video.mp4'))..writeAsStringSync('mp4 payload'),
        File(p.join(tempTestDir.path, 'audio.m4a'))..writeAsStringSync('m4a payload'),
        File(p.join(tempTestDir.path, 'image.jpg'))..writeAsStringSync('jpg payload'),
        File(p.join(tempTestDir.path, 'photo.png'))..writeAsStringSync('png payload'),
        File(p.join(tempTestDir.path, 'anim.gif'))..writeAsStringSync('gif payload'),
        File(p.join(tempTestDir.path, 'pack.zip'))..writeAsStringSync('zip payload'),
        // Nested finished valid file to verify recursive preservation:
        File(p.join(subDir1.path, 'nested_valid.jpg'))..writeAsStringSync('nested valid image payload'),
      ];

      // 3. Temporary & zero-byte files to delete (8 root files + 1 nested in album_subfolder = 9 total)
      final nestedPartFile = File(p.join(subDir1.path, 'nested.part'))..writeAsStringSync('nested partial');

      final deleteList = [
        File(p.join(tempTestDir.path, 'v1.mp4.part'))..writeAsStringSync('part'),
        File(p.join(tempTestDir.path, 'v2.tmp'))..writeAsStringSync('tmp'),
        File(p.join(tempTestDir.path, 'v3.crdownload'))..writeAsStringSync('cr'),
        File(p.join(tempTestDir.path, 'v4.ytdl'))..writeAsStringSync('ytdl'),
        File(p.join(tempTestDir.path, 'v5.download'))..writeAsStringSync('download'),
        File(p.join(tempTestDir.path, 'v6.PART'))..writeAsStringSync('uppercase part'),
        File(p.join(tempTestDir.path, 'corrupted_zero1.mp4'))..writeAsBytesSync([]),
        File(p.join(tempTestDir.path, 'corrupted_zero2.jpg'))..writeAsBytesSync([]),
        nestedPartFile, // Accounts for recursive sweeping in nested album_subfolder (9 files total)
      ];

      // Pre-condition assertion: verify candidate count and physical presence before sweep
      expect(deleteList.length, equals(9), reason: 'Delete list must contain exactly 9 candidate files (8 root + 1 nested)');
      for (final f in keepList) {
        expect(f.existsSync(), isTrue);
      }
      for (final f in deleteList) {
        expect(f.existsSync(), isTrue);
      }

      final deletedCount = await CleanCancel.cleanupDirectory(tempTestDir);

      // Verify exact count of 9 deleted files
      expect(deletedCount, equals(9), reason: 'Should delete exactly 9 temporary and 0-byte files across root and subdirectories');
      expect(deletedCount, equals(deleteList.length), reason: 'Deleted count must match deleteList length');

      // Verify all valid files survived (root and nested)
      for (final f in keepList) {
        expect(f.existsSync(), isTrue, reason: 'Valid media file ${f.path} was deleted');
        expect(f.lengthSync(), greaterThan(0), reason: 'Valid media file ${f.path} was corrupted or truncated');
      }

      // Verify subdirectories and parent survived
      expect(tempTestDir.existsSync(), isTrue, reason: 'Parent directory was deleted');
      expect(subDir1.existsSync(), isTrue, reason: 'Subdirectory album_subfolder was deleted');
      expect(subDir2.existsSync(), isTrue, reason: 'Subdirectory nested_creator was deleted');

      // Verify all 9 temporary and zero-byte files are completely deleted
      for (final f in deleteList) {
        expect(f.existsSync(), isFalse, reason: 'Temporary file ${f.path} was not deleted');
      }

      // Explicit individual verification for nested partial file
      expect(nestedPartFile.existsSync(), isFalse, reason: 'Nested temporary file subDir1/nested.part must be purged by recursive sweep');
    });

    test('cleanupDirectory stress test: 50 mixed files handled in single sweep', () async {
      var expectedDeletes = 0;
      for (int i = 0; i < 50; i++) {
        if (i % 3 == 0) {
          // Valid finished file
          File(p.join(tempTestDir.path, 'item_$i.mp4')).writeAsStringSync('content $i');
        } else if (i % 3 == 1) {
          // Temporary companion
          File(p.join(tempTestDir.path, 'item_$i.mp4.part')).writeAsStringSync('partial $i');
          expectedDeletes++;
        } else {
          // Zero-byte file
          File(p.join(tempTestDir.path, 'item_$i.zero')).writeAsBytesSync([]);
          expectedDeletes++;
        }
      }

      final count = await CleanCancel.cleanupDirectory(tempTestDir);
      expect(count, equals(expectedDeletes));
    });
  });

  // =========================================================================
  // GROUP 4: HierarchyManager Adaptive Hierarchy & Storage Routing
  // =========================================================================
  group('Adversarial Group 4: HierarchyManager Adaptive Hierarchy & Platform Storage Rules', () {
    test('Base media directory resolves cleanly and sanitizes trailing generic " Media"', () async {
      final base = await HierarchyManager.getBaseMediaDirectory();
      expect(base.existsSync(), isTrue);
      expect(p.basename(base.path), equals('Media'));

      expect(HierarchyManager.sanitizeName('TikTok Media'), equals('TikTok'));
      expect(HierarchyManager.sanitizeName('Instagram Media'), equals('Instagram'));
      expect(HierarchyManager.sanitizeName('Twitter Media'), equals('Twitter'));
      expect(HierarchyManager.sanitizeName('Artist Media Media'), equals('Artist Media'));
    });

    test('Sanitizes illegal path chars and path traversal sequences', () {
      expect(HierarchyManager.sanitizeName('User:Name?*<File>|'), equals('User_Name___File__'));
      expect(HierarchyManager.sanitizeName('../../etc/passwd'), equals('.._.._etc_passwd'));
      expect(HierarchyManager.sanitizeName(r'..\..\windows\system32'), equals('.._.._windows_system32'));
      expect(HierarchyManager.sanitizeName(''), equals('General'));
      expect(HierarchyManager.sanitizeName('   '), equals('General'));
    });

    test('Visual Platform 1st Download: Single work routes directly to Creator root folder', () async {
      final uniqueCreator = 'Artist_Solo_${DateTime.now().microsecondsSinceEpoch}';

      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.twitter,
        creatorName: uniqueCreator,
        workId: 'tweet_1001',
        isMultiPage: false,
      );

      expect(p.basename(dir.path), equals(uniqueCreator));
      expect(dir.path, isNot(contains('tweet_1001')), reason: 'First download for single work must stay in creator root folder');
    });

    test('Visual Platform Multi-Page Album: 1st download routes to workId subfolder', () async {
      final uniqueCreator = 'Album_Artist_${DateTime.now().microsecondsSinceEpoch}';

      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: uniqueCreator,
        workId: 'illust_album_2001',
        isMultiPage: true,
      );

      expect(p.basename(dir.path), equals('illust_album_2001'));
      expect(p.basename(dir.parent.path), equals(uniqueCreator));
    });

    test('Visual Platform 2nd Download: Automatically routes into workId subfolder when creator directory is non-empty', () async {
      final baseDir = await HierarchyManager.getBaseMediaDirectory();
      final platformDir = Directory(p.join(baseDir.path, 'Instagram'));
      final creatorName = 'Photographer_${DateTime.now().microsecondsSinceEpoch}';
      final creatorDir = Directory(p.join(platformDir.path, creatorName))..createSync(recursive: true);

      // Simulate prior download for this creator
      File(p.join(creatorDir.path, 'prior_photo.jpg')).writeAsStringSync('first downloaded photo');

      // Now 2nd download arrives for a different workId
      final dir2 = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.instagram,
        creatorName: creatorName,
        workId: 'reel_3002',
        isMultiPage: false,
      );

      expect(p.basename(dir2.path), equals('reel_3002'), reason: '2nd download for creator must be placed into workId subfolder');
      expect(p.basename(dir2.parent.path), equals(creatorName));
    });

    test('Auto-Migration: Relocates prior single files matching workId into the new subfolder', () async {
      final baseDir = await HierarchyManager.getBaseMediaDirectory();
      final platformDir = Directory(p.join(baseDir.path, 'Pixiv'));
      final creatorName = 'Mangaka_${DateTime.now().microsecondsSinceEpoch}';
      final creatorDir = Directory(p.join(platformDir.path, creatorName))..createSync(recursive: true);

      // Prior single download: workId '98765432' in creator root
      final priorMatchingFile = File(p.join(creatorDir.path, '98765432_p0.jpg'))..writeAsStringSync('page 0 artwork');
      // Unrelated file for different workId
      final unrelatedFile = File(p.join(creatorDir.path, '11112222_p0.jpg'))..writeAsStringSync('other artwork');

      expect(priorMatchingFile.existsSync(), isTrue);
      expect(unrelatedFile.existsSync(), isTrue);

      // Second download for workId '98765432' arrives (e.g. page 1)
      final targetSubDir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: creatorName,
        workId: '98765432',
        isMultiPage: false,
      );

      expect(p.basename(targetSubDir.path), equals('98765432'));

      // Verify prior matching file was auto-migrated
      final migratedFile = File(p.join(targetSubDir.path, '98765432_p0.jpg'));
      expect(migratedFile.existsSync(), isTrue, reason: 'Old matching file must be relocated to subfolder');
      expect(priorMatchingFile.existsSync(), isFalse, reason: 'Old file in creator root should no longer exist');

      // Verify unrelated file was NOT touched
      expect(unrelatedFile.existsSync(), isTrue, reason: 'Unrelated work in creator root must NOT be moved');
    });

    test('Pinterest: Created Pins MUST stay in creator root folder (MUST NOT be moved to ID subfolder)', () async {
      final creator = 'CraftArtist_${DateTime.now().microsecondsSinceEpoch}';

      // 1. Created pin with explicit isPinterestCreatedPin = true
      final dir1 = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: creator,
        workId: 'pin_887766',
        isPinterestCreatedPin: true,
      );
      expect(p.basename(dir1.path), equals(creator));
      expect(dir1.path, isNot(contains('pin_887766')), reason: 'Created pins must never create a workId subfolder');

      // 2. Created pin even if board name is null
      final dir2 = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: creator,
        workId: 'pin_887766',
        pinterestBoardName: null,
      );
      expect(p.basename(dir2.path), equals(creator));

      // 3. Created pin even when isPinterestCreatedPin = true but a board was mistakenly passed
      final dir3 = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: creator,
        workId: 'pin_887766',
        pinterestBoardName: 'SomeBoard',
        isPinterestCreatedPin: true,
      );
      expect(p.basename(dir3.path), equals(creator), reason: 'isPinterestCreatedPin: true takes precedence over board name');
    });

    test('Pinterest: Saved Boards MUST be routed to designated board subfolder', () async {
      final creator = 'BoardCurator_${DateTime.now().microsecondsSinceEpoch}';

      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: creator,
        workId: 'pin_554433',
        pinterestBoardName: 'Modern Architecture: 2026',
        isPinterestCreatedPin: false,
      );

      expect(p.basename(dir.path), equals('Modern Architecture_ 2026'));
      expect(p.basename(dir.parent.path), equals(creator));
      expect(p.basename(dir.parent.parent.path), equals('Pinterest'));
    });

    test('Video & Audio Platforms (YouTube, Spotify, Telegram) always save to Creator root', () async {
      for (final pfm in [MediaPlatform.youtube, MediaPlatform.spotify, MediaPlatform.telegram, MediaPlatform.googledrive]) {
        final dir = await HierarchyManager.resolveDestinationDirectory(
          platform: pfm,
          creatorName: 'Channel_${pfm.displayName}',
          workId: 'video_or_audio_12345',
        );

        expect(p.basename(dir.path), equals('Channel_${pfm.displayName}'));
        expect(p.basename(dir.parent.path), equals(pfm.displayName));
      }
    });

    test('Filename Collision Counter: increments correctly up to 10 sequential collisions', () async {
      final generatedPaths = <String>[];
      for (int i = 0; i < 10; i++) {
        final path = await HierarchyManager.getUniqueDestinationFilePath(
          directory: tempTestDir,
          baseFileName: 'artwork',
          extension: '.png',
        );
        generatedPaths.add(path);
        // Create the file so next call detects collision
        File(path).writeAsStringSync('frame $i');
      }

      expect(p.basename(generatedPaths[0]), equals('artwork.png'));
      expect(p.basename(generatedPaths[1]), equals('artwork_1.png'));
      expect(p.basename(generatedPaths[2]), equals('artwork_2.png'));
      expect(p.basename(generatedPaths[9]), equals('artwork_9.png'));
    });
  });
}
