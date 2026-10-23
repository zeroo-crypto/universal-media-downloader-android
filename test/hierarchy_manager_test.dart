import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/core/storage/hierarchy_manager.dart';

void main() {
  late Directory tempTestDir;

  setUp(() {
    tempTestDir = Directory.systemTemp.createTempSync('hierarchy_manager_test_');
  });

  tearDown(() {
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Tier 1: Feature Coverage — Name Sanitization & Basic Paths', () {
    test('Sanitizes illegal filesystem characters in filenames', () {
      expect(HierarchyManager.sanitizeName('Artist/Name:*?'), equals('Artist_Name___'));
      expect(HierarchyManager.sanitizeName('Folder<Name>|Test"'), equals('Folder_Name__Test_'));
      expect(HierarchyManager.sanitizeName(r'Windows\Path/Test'), equals('Windows_Path_Test'));
    });

    test('Strips blacklisted generic " Media" folder suffix', () {
      expect(HierarchyManager.sanitizeName('Pixiv Media'), equals('Pixiv'));
      expect(HierarchyManager.sanitizeName('Twitter Media'), equals('Twitter'));
      expect(HierarchyManager.sanitizeName('Artist Media'), equals('Artist'));
    });

    test('Defaults empty or whitespace-only names to "General"', () {
      expect(HierarchyManager.sanitizeName(''), equals('General'));
      expect(HierarchyManager.sanitizeName('   '), equals('General'));
    });

    test('Resolves base media directory containing "Media" root folder', () async {
      final baseDir = await HierarchyManager.getBaseMediaDirectory();
      expect(baseDir.existsSync(), isTrue);
      expect(p.basename(baseDir.path), equals('Media'));
    });

    test('getUniqueDestinationFilePath generates clean filename when no conflict exists', () async {
      final destPath = await HierarchyManager.getUniqueDestinationFilePath(
        directory: tempTestDir,
        baseFileName: 'artwork_100',
        extension: 'png',
      );

      expect(p.basename(destPath), equals('artwork_100.png'));
    });
  });

  group('Tier 2: Boundary & Corner Cases — Collision Counting & Traversal Sequences', () {
    test('Handles extensions with and without leading dot seamlessly', () async {
      final pathWithDot = await HierarchyManager.getUniqueDestinationFilePath(
        directory: tempTestDir,
        baseFileName: 'clip',
        extension: '.mp4',
      );
      final pathWithoutDot = await HierarchyManager.getUniqueDestinationFilePath(
        directory: tempTestDir,
        baseFileName: 'clip2',
        extension: 'mp4',
      );

      expect(destExt(pathWithDot), equals('.mp4'));
      expect(destExt(pathWithoutDot), equals('.mp4'));
    });

    test('Resolves sequential filename collisions (_1, _2, _3)', () async {
      // 1. Existing base file
      File(p.join(tempTestDir.path, 'video.mp4')).writeAsStringSync('original');

      // 2. First collision
      final firstCollision = await HierarchyManager.getUniqueDestinationFilePath(
        directory: tempTestDir,
        baseFileName: 'video',
        extension: 'mp4',
      );
      expect(p.basename(firstCollision), equals('video_1.mp4'));
      File(firstCollision).writeAsStringSync('first');

      // 3. Second collision
      final secondCollision = await HierarchyManager.getUniqueDestinationFilePath(
        directory: tempTestDir,
        baseFileName: 'video',
        extension: 'mp4',
      );
      expect(p.basename(secondCollision), equals('video_2.mp4'));
    });

    test('Sanitizes directory traversal sequences defensively', () {
      expect(HierarchyManager.sanitizeName('../../etc/passwd'), equals('.._.._etc_passwd'));
      expect(HierarchyManager.sanitizeName('..\\..\\windows'), equals('.._.._windows'));
    });

    test('Sanitizes name with internal spaces without stripping inner words', () {
      expect(HierarchyManager.sanitizeName('Awesome Creator Art'), equals('Awesome Creator Art'));
    });

    test('Handles long names with special unicode characters safely', () {
      final sanitized = HierarchyManager.sanitizeName('星野アイ - 輝くステージ ★ 2026: The Movie');
      expect(sanitized, contains('星野アイ'));
      expect(sanitized, isNot(contains(':')));
    });
  });

  group('Tier 3: Cross-Feature Combinations — Pinterest Storage Routing & Visual Adaptive Logic', () {
    test('Pinterest: Created Pins retain root retention in creator directory', () async {
      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: 'IllustratorAnna',
        workId: 'pin_987654321',
        isPinterestCreatedPin: true,
      );

      expect(p.basename(dir.path), equals('IllustratorAnna'));
      expect(dir.path, isNot(contains('pin_987654321')), reason: 'Created pins must not be moved to subfolder');
    });

    test('Pinterest: Saved Boards are routed to designated board subfolder', () async {
      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pinterest,
        creatorName: 'CuratorBob',
        workId: 'pin_112233',
        pinterestBoardName: 'Anime Wallpapers',
        isPinterestCreatedPin: false,
      );

      expect(p.basename(dir.path), equals('Anime Wallpapers'));
      expect(p.basename(dir.parent.path), equals('CuratorBob'));
    });

    test('YouTube: Saves directly to channel creator root directory', () async {
      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.youtube,
        creatorName: 'Veritasium',
        workId: 'dQw4w9WgXcQ',
      );

      expect(p.basename(dir.path), equals('Veritasium'));
      expect(p.basename(dir.parent.path), equals('YouTube'));
    });

    test('Visual Platforms: Multi-page carousel is routed to workId subfolder', () async {
      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: 'MangaArtist',
        workId: 'illust_554433',
        isMultiPage: true,
      );

      expect(p.basename(dir.path), equals('illust_554433'));
      expect(p.basename(dir.parent.path), equals('MangaArtist'));
    });

    test('Visual Platforms: First single download routes to creator root folder', () async {
      // Creator folder with no prior downloads
      final dir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.twitter,
        creatorName: 'SoloArtist_FirstDownload_${DateTime.now().millisecondsSinceEpoch}',
        workId: '1234567890',
        isMultiPage: false,
      );

      expect(p.basename(dir.path), contains('SoloArtist_FirstDownload'));
    });
  });

  group('Tier 4: Real-World Application Scenarios — Creator Download Stacking & Auto-Migration', () {
    test('Auto-migrates matching single files into workId subfolder when second file arrives', () async {
      // Simulate creator directory
      final baseDir = await HierarchyManager.getBaseMediaDirectory();
      final platformDir = Directory(p.join(baseDir.path, 'Pixiv'));
      final creatorDir = Directory(p.join(platformDir.path, 'ArtistMigrationTest_${DateTime.now().millisecondsSinceEpoch}'));
      creatorDir.createSync(recursive: true);

      // User's prior download: a single image matching workId '778899'
      final priorFile = File(p.join(creatorDir.path, '778899_p0.jpg'));
      priorFile.writeAsStringSync('prior download artwork');
      expect(priorFile.existsSync(), isTrue);

      // Now user downloads second item for same creator with workId '778899'
      final targetWorkDir = await HierarchyManager.resolveDestinationDirectory(
        platform: MediaPlatform.pixiv,
        creatorName: p.basename(creatorDir.path),
        workId: '778899',
        isMultiPage: false,
      );

      expect(p.basename(targetWorkDir.path), equals('778899'));

      // Verify prior file was automatically migrated into the subfolder
      final migratedFile = File(p.join(targetWorkDir.path, '778899_p0.jpg'));
      expect(migratedFile.existsSync(), isTrue, reason: 'Old file must be moved to new workId subfolder');
      expect(priorFile.existsSync(), isFalse, reason: 'Old file in root should no longer exist');
    });

    test('Simultaneous downloads with name collision get safe unique paths', () async {
      final paths = <String>[];
      for (int i = 0; i < 3; i++) {
        final path = await HierarchyManager.getUniqueDestinationFilePath(
          directory: tempTestDir,
          baseFileName: 'photo',
          extension: 'jpg',
        );
        paths.add(path);
        File(path).writeAsStringSync('photo content $i');
      }

      expect(p.basename(paths[0]), equals('photo.jpg'));
      expect(p.basename(paths[1]), equals('photo_1.jpg'));
      expect(p.basename(paths[2]), equals('photo_2.jpg'));
    });
  });
}

String destExt(String path) => p.extension(path);
