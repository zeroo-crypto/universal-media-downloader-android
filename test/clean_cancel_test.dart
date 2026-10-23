import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:universal_media_downloader/core/utils/clean_cancel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempTestDir;

  setUp(() {
    tempTestDir = Directory.systemTemp.createTempSync('clean_cancel_test_');
  });

  tearDown(() {
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Tier 1: Feature Coverage — Extension Matching & Basic Deletion', () {
    test('Accurately identifies all 5 specified temporary download extensions', () {
      expect(CleanCancel.isTemporary('video.mp4.part'), isTrue);
      expect(CleanCancel.isTemporary('image.jpg.tmp'), isTrue);
      expect(CleanCancel.isTemporary('large_movie.crdownload'), isTrue);
      expect(CleanCancel.isTemporary('stream_audio.m4a.ytdl'), isTrue);
      expect(CleanCancel.isTemporary('package.zip.download'), isTrue);
    });

    test('Preserves valid final media file extensions', () {
      expect(CleanCancel.isTemporary('video.mp4'), isFalse);
      expect(CleanCancel.isTemporary('artwork.jpg'), isFalse);
      expect(CleanCancel.isTemporary('illustration.png'), isFalse);
      expect(CleanCancel.isTemporary('soundtrack.m4a'), isFalse);
      expect(CleanCancel.isTemporary('archive.zip'), isFalse);
      expect(CleanCancel.isTemporary('animation.gif'), isFalse);
    });

    test('cleanupPartialFile deletes target file with temporary extension', () async {
      final tempFile = File(p.join(tempTestDir.path, 'download_active.mp4.part'));
      tempFile.writeAsStringSync('partial chunk data');
      expect(tempFile.existsSync(), isTrue);

      await CleanCancel.cleanupPartialFile(tempFile.path);

      expect(tempFile.existsSync(), isFalse, reason: 'Temporary .part file must be deleted');
    });

    test('cleanupPartialFile deletes associated .part companion file', () async {
      final finalPath = p.join(tempTestDir.path, 'video.mp4');
      final partFile = File('$finalPath.part');
      partFile.writeAsStringSync('downloading chunk...');
      expect(partFile.existsSync(), isTrue);

      await CleanCancel.cleanupPartialFile(finalPath);

      expect(partFile.existsSync(), isFalse, reason: 'Associated .part file must be cleaned up');
    });

    test('cleanupPartialFile deletes 0-byte corrupt candidate files', () async {
      final zeroByteFile = File(p.join(tempTestDir.path, 'corrupted_zero.mp4'));
      zeroByteFile.writeAsBytesSync([]); // 0 bytes
      expect(zeroByteFile.existsSync(), isTrue);
      expect(zeroByteFile.lengthSync(), equals(0));

      await CleanCancel.cleanupPartialFile(zeroByteFile.path);

      expect(zeroByteFile.existsSync(), isFalse, reason: '0-byte file must be deleted');
    });
  });

  group('Tier 2: Boundary & Corner Cases — Case Sensitivity, Traversal & Non-Existent Files', () {
    test('Handles case-insensitive temporary extensions (.PART, .TMP, .CRDOWNLOAD)', () {
      expect(CleanCancel.isTemporary('VIDEO.MP4.PART'), isTrue);
      expect(CleanCancel.isTemporary('IMAGE.JPG.TMP'), isTrue);
      expect(CleanCancel.isTemporary('STREAM.CRDOWNLOAD'), isTrue);
      expect(CleanCancel.isTemporary('AUDIO.YTDL'), isTrue);
      expect(CleanCancel.isTemporary('FILE.DOWNLOAD'), isTrue);
    });

    test('Does not flag files with temporary words embedded in the stem', () {
      expect(CleanCancel.isTemporary('my.part.video.mp4'), isFalse);
      expect(CleanCancel.isTemporary('tmp_photo.jpg'), isFalse);
      expect(CleanCancel.isTemporary('download_manager.apk'), isFalse);
      expect(CleanCancel.isTemporary('part1_scene.mp4'), isFalse);
    });

    test('Preserves non-zero completed media file when cleanupPartialFile is called', () async {
      final completedFile = File(p.join(tempTestDir.path, 'valid_completed.mp4'));
      completedFile.writeAsStringSync('COMPLETE VALID VIDEO DATA STREAM 1080P');
      expect(completedFile.lengthSync(), greaterThan(0));

      await CleanCancel.cleanupPartialFile(completedFile.path);

      expect(completedFile.existsSync(), isTrue, reason: 'Valid non-zero files must not be deleted');
    });

    test('Handles non-existent file path without throwing unhandled exceptions', () async {
      final nonExistentPath = p.join(tempTestDir.path, 'non_existent_file.mp4');
      expect(File(nonExistentPath).existsSync(), isFalse, reason: 'Target file must initially not exist');
      expect(tempTestDir.listSync().length, equals(0), reason: 'Directory must initially be empty');

      // Track non-throwing asynchronous completion
      var completedNormally = false;
      try {
        await CleanCancel.cleanupPartialFile(nonExistentPath);
        completedNormally = true;
      } catch (_) {
        completedNormally = false;
      }

      // 1. Verify non-throwing completion
      expect(completedNormally, isTrue, reason: 'cleanupPartialFile must complete without throwing unhandled exceptions');

      // 2. Verify target file and all temporary companion variants do not exist
      expect(File(nonExistentPath).existsSync(), isFalse, reason: 'Target file must not exist');
      for (final ext in CleanCancel.temporaryExtensions) {
        expect(File('$nonExistentPath$ext').existsSync(), isFalse, reason: 'Companion file with extension $ext must not exist');
      }

      // 3. Verify directory entity counts and directory preservation
      expect(tempTestDir.existsSync(), isTrue, reason: 'Parent test directory must be preserved');
      expect(tempTestDir.listSync().length, equals(0), reason: 'Directory entity count must remain 0 after cleanup of non-existent file');
    });

    test('cleanupDirectory returns 0 on empty directory', () async {
      final emptyDir = Directory(p.join(tempTestDir.path, 'empty_sub'));
      emptyDir.createSync();

      final deleted = await CleanCancel.cleanupDirectory(emptyDir);
      expect(deleted, equals(0));
    });
  });

  group('Tier 3: Cross-Feature Combinations — Multi-Companion Purge & Directory Sweeping', () {
    test('Purges all temporary companion variants (.part, .tmp) simultaneously', () async {
      final targetPath = p.join(tempTestDir.path, 'movie.mp4');
      final partFile = File('$targetPath.part');
      final tmpFile = File('$targetPath.tmp');
      final ytdlFile = File('$targetPath.ytdl');
      final crFile = File('$targetPath.crdownload');

      partFile.writeAsStringSync('part data');
      tmpFile.writeAsStringSync('tmp data');
      ytdlFile.writeAsStringSync('ytdl data');
      crFile.writeAsStringSync('cr data');

      expect(partFile.existsSync(), isTrue);
      expect(tmpFile.existsSync(), isTrue);
      expect(ytdlFile.existsSync(), isTrue);
      expect(crFile.existsSync(), isTrue);

      await CleanCancel.cleanupPartialFile(targetPath);

      expect(partFile.existsSync(), isFalse);
      expect(tmpFile.existsSync(), isFalse);
      expect(ytdlFile.existsSync(), isFalse);
      expect(crFile.existsSync(), isFalse);
    });

    test('cleanupDirectory purges only temporary & 0-byte files, keeping valid media untouched', () async {
      // 1. Valid files to keep
      final valid1 = File(p.join(tempTestDir.path, 'art_piece.png'))..writeAsStringSync('valid artwork');
      final valid2 = File(p.join(tempTestDir.path, 'audio_track.m4a'))..writeAsStringSync('valid audio');

      // 2. Temporary files to delete
      final temp1 = File(p.join(tempTestDir.path, 'video.mp4.part'))..writeAsStringSync('temp chunk');
      final temp2 = File(p.join(tempTestDir.path, 'photo.jpg.tmp'))..writeAsStringSync('temp photo');
      final temp3 = File(p.join(tempTestDir.path, 'file.crdownload'))..writeAsStringSync('temp chrome');

      // 3. 0-byte corrupt files to delete
      final zero1 = File(p.join(tempTestDir.path, 'aborted.mp4'))..writeAsBytesSync([]);
      final zero2 = File(p.join(tempTestDir.path, 'broken.jpg'))..writeAsBytesSync([]);

      final totalDeleted = await CleanCancel.cleanupDirectory(tempTestDir);

      expect(totalDeleted, equals(5), reason: 'Should delete exactly 3 temporary + 2 zero-byte files');
      expect(valid1.existsSync(), isTrue, reason: 'Valid PNG must remain');
      expect(valid2.existsSync(), isTrue, reason: 'Valid M4A must remain');
      expect(temp1.existsSync(), isFalse);
      expect(temp2.existsSync(), isFalse);
      expect(temp3.existsSync(), isFalse);
      expect(zero1.existsSync(), isFalse);
      expect(zero2.existsSync(), isFalse);
    });
  });

  group('Tier 4: Real-World Application Scenarios — User Cancellation & Storage Maintenance', () {
    test('Simulated download cancellation at 80% leaves zero orphaned bytes on disk', () async {
      // Scenario: Download task writes 10MB chunk into .part file
      final finalTargetPath = p.join(tempTestDir.path, 'large_tutorial.mp4');
      final activePartFile = File('$finalTargetPath.part');
      activePartFile.writeAsBytesSync(List<int>.filled(50000, 1)); // 50KB mock chunk

      expect(activePartFile.existsSync(), isTrue);
      expect(activePartFile.lengthSync(), equals(50000));

      // User taps Cancel button in Download Queue -> cancel token triggers cleanup
      await CleanCancel.cleanupPartialFile(finalTargetPath);

      expect(activePartFile.existsSync(), isFalse);
      expect(File(finalTargetPath).existsSync(), isFalse);
    });

    test('Simulated app crash during stream allocation leaves 0-byte file which gets purged', () async {
      // Scenario: File handle created on disk before network fails with connection reset
      final crashedFile = File(p.join(tempTestDir.path, 'stream_error.mp4'));
      crashedFile.createSync(); // 0 bytes

      expect(crashedFile.existsSync(), isTrue);
      expect(crashedFile.lengthSync(), equals(0));

      // CleanCancel invoked upon exception catch
      await CleanCancel.cleanupPartialFile(crashedFile.path);

      expect(crashedFile.existsSync(), isFalse);
    });

    test('Settings maintenance sweep purges orphaned session fragments safely', () async {
      // Scenario: 3 abandoned downloads from prior app crash
      File(p.join(tempTestDir.path, 'orphan1.ytdl')).writeAsStringSync('old stream');
      File(p.join(tempTestDir.path, 'orphan2.tmp')).writeAsStringSync('old buffer');
      File(p.join(tempTestDir.path, 'valid_user_saved.jpg')).writeAsStringSync('important photo');

      final cleanedCount = await CleanCancel.cleanupDirectory(tempTestDir);

      expect(cleanedCount, equals(2));
      expect(File(p.join(tempTestDir.path, 'valid_user_saved.jpg')).existsSync(), isTrue);
    });
  });
}
