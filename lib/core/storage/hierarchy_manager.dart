import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/platforms.dart';

/// Manages directory structure and file paths following the Project Memory Vault Rules:
/// - Base: /storage/emulated/0/Download/Media/<Platform>/...
/// - Adaptive Hierarchy for Visual Platforms (Pixiv, Twitter, Instagram, TikTok, Facebook)
/// - Strict rules for Pinterest (Created Pins in creator root, Saved Boards in board subfolder)
/// - Clean naming (No generic '<Platform> Media' folders)
class HierarchyManager {
  static const String rootMediaFolder = 'Media';

  /// Resolves the base root directory for all downloads.
  /// Defaults to Android's public `/storage/emulated/0/Download/Media`
  static Future<Directory> getBaseMediaDirectory() async {
    Directory? downloadDir;
    try {
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          downloadDir = publicDownload;
        } else {
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (extDirs != null && extDirs.isNotEmpty) {
            downloadDir = extDirs.first;
          }
        }
      }
      downloadDir ??= await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      downloadDir = await getApplicationDocumentsDirectory();
    }

    final mediaDir = Directory(p.join(downloadDir.path, rootMediaFolder));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Sanitizes folder and file names to be valid across Windows and Android FAT/ext4 file systems.
  static String sanitizeName(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty) {
      cleaned = 'General';
    }
    // Prevent generic blacklist folder names like "Pixiv Media"
    if (cleaned.endsWith(' Media')) {
      cleaned = cleaned.substring(0, cleaned.length - 6).trim();
    }
    return cleaned;
  }

  /// Determines the exact destination directory according to platform-specific rules.
  static Future<Directory> resolveDestinationDirectory({
    required MediaPlatform platform,
    required String creatorName,
    String? workId,
    bool isMultiPage = false,
    String? pinterestBoardName,
    bool isPinterestCreatedPin = false,
  }) async {
    final baseDir = await getBaseMediaDirectory();
    final platformDir = Directory(p.join(baseDir.path, platform.displayName));
    if (!await platformDir.exists()) {
      await platformDir.create(recursive: true);
    }

    final safeCreator = sanitizeName(creatorName.isEmpty ? 'General' : creatorName);
    final creatorDir = Directory(p.join(platformDir.path, safeCreator));
    if (!await creatorDir.exists()) {
      await creatorDir.create(recursive: true);
    }

    // 1. Platform Pinterest Rules
    if (platform == MediaPlatform.pinterest) {
      if (isPinterestCreatedPin || pinterestBoardName == null || pinterestBoardName.isEmpty) {
        // Created Pins stay directly in creator root folder (DILARANG dipindahkan ke subfolder ID)
        return creatorDir;
      } else {
        // Saved Boards stay in subfolder of the board name
        final safeBoard = sanitizeName(pinterestBoardName);
        final boardDir = Directory(p.join(creatorDir.path, safeBoard));
        if (!await boardDir.exists()) {
          await boardDir.create(recursive: true);
        }
        return boardDir;
      }
    }

    // 2. Video & Audio Platforms (YouTube, Spotify, Telegram)
    if (platform == MediaPlatform.youtube ||
        platform == MediaPlatform.spotify ||
        platform == MediaPlatform.telegram ||
        platform == MediaPlatform.googledrive) {
      return creatorDir;
    }

    // 3. Visual Platforms Adaptive Hierarchy (Pixiv, Twitter, Instagram, TikTok, Facebook)
    // Check if creator folder already has existing files or if this is multi-page/album
    final existingItems = await creatorDir.list().toList();
    final existingFiles = existingItems.whereType<File>().toList();
    final existingDirs = existingItems.whereType<Directory>().toList();

    final hasPriorDownloads = existingFiles.isNotEmpty || existingDirs.isNotEmpty;

    if (workId != null && workId.isNotEmpty && (isMultiPage || hasPriorDownloads)) {
      // Condition 2: Multi-page album OR 2nd+ download for the same creator -> Save to workId subfolder
      final safeWorkId = sanitizeName(workId);
      final workDir = Directory(p.join(creatorDir.path, safeWorkId));
      if (!await workDir.exists()) {
        await workDir.create(recursive: true);
      }

      // Auto-Migration: If creator root contains prior single files matching this workId, relocate them
      await _autoMigrateMatchingFiles(creatorDir, workDir, safeWorkId);

      return workDir;
    }

    // Condition 1: First download & single work -> Save directly to creator root
    return creatorDir;
  }

  /// Automatically relocates old files from creator root into the workId subfolder
  static Future<void> _autoMigrateMatchingFiles(
    Directory creatorDir,
    Directory targetWorkDir,
    String workId,
  ) async {
    try {
      final files = await creatorDir.list().where((e) => e is File).cast<File>().toList();
      for (final file in files) {
        final filename = p.basename(file.path);
        if (filename.startsWith(workId) || filename.contains(workId)) {
          final newPath = p.join(targetWorkDir.path, filename);
          if (!await File(newPath).exists()) {
            await file.rename(newPath);
          }
        }
      }
    } catch (_) {
      // Ignore migration errors defensibly
    }
  }

  /// Builds a clean destination file path, ensuring no overwrite unless requested
  static Future<String> getUniqueDestinationFilePath({
    required Directory directory,
    required String baseFileName,
    required String extension,
  }) async {
    final cleanExt = extension.startsWith('.') ? extension : '.$extension';
    final safeBase = sanitizeName(baseFileName);
    var candidatePath = p.join(directory.path, '$safeBase$cleanExt');

    var counter = 1;
    while (await File(candidatePath).exists()) {
      candidatePath = p.join(directory.path, '${safeBase}_$counter$cleanExt');
      counter++;
    }
    return candidatePath;
  }
}
