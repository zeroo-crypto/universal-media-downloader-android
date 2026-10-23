import 'package:flutter_test/flutter_test.dart';
import 'package:universal_media_downloader/core/storage/hierarchy_manager.dart';
import 'package:universal_media_downloader/core/utils/clean_cancel.dart';

void main() {
  group('HierarchyManager & CleanCancel Logic Tests', () {
    test('Sanitizes illegal characters in filenames', () {
      expect(HierarchyManager.sanitizeName('Artist/Name:*?'), equals('Artist_Name____'));
      expect(HierarchyManager.sanitizeName('Pixiv Media'), equals('Pixiv'));
      expect(HierarchyManager.sanitizeName(''), equals('General'));
    });

    test('Identifies temporary download files accurately', () {
      expect(CleanCancel.isTemporary('video.mp4.part'), isTrue);
      expect(CleanCancel.isTemporary('image.jpg.tmp'), isTrue);
      expect(CleanCancel.isTemporary('video.crdownload'), isTrue);
      expect(CleanCancel.isTemporary('audio.m4a.ytdl'), isTrue);
      expect(CleanCancel.isTemporary('final_video.mp4'), isFalse);
      expect(CleanCancel.isTemporary('photo.jpg'), isFalse);
    });
  });
}
