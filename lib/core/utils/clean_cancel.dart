import 'dart:io';

/// Zero Orphaned Files Utility
/// Automatically purges .part, .tmp, .crdownload, and 0-byte corrupt files
/// upon cancellation or network abort.
class CleanCancel {
  static const List<String> temporaryExtensions = [
    '.part',
    '.tmp',
    '.crdownload',
    '.ytdl',
    '.download',
    '.video.part',
    '.audio.part',
  ];

  /// Cleans up a specific target file and any related .part/.tmp temporary files
  static Future<void> cleanupPartialFile(String targetFilePath) async {
    try {
      final file = File(targetFilePath);
      if (await file.exists()) {
        final length = await file.length();
        if (length == 0 || isTemporary(targetFilePath)) {
          await file.delete();
        }
      }

      // Also clean up <targetFilePath>.part or <targetFilePath>.tmp
      for (final ext in temporaryExtensions) {
        final partFile = File('$targetFilePath$ext');
        if (await partFile.exists()) {
          await partFile.delete();
        }
      }
    } catch (_) {
      // Defensively ignore delete errors
    }
  }

  /// Checks if a file path has a temporary extension
  static bool isTemporary(String path) {
    final lower = path.toLowerCase();
    for (final ext in temporaryExtensions) {
      if (lower.endsWith(ext)) return true;
    }
    return false;
  }

  /// Scans a directory and purges all orphaned temporary files or 0-byte files
  static Future<int> cleanupDirectory(Directory dir) async {
    var deletedCount = 0;
    try {
      if (!await dir.exists()) return 0;

      final entities = await dir.list(recursive: true, followLinks: false).toList();
      for (final entity in entities) {
        if (entity is File) {
          final isTemp = isTemporary(entity.path);
          final isZeroByte = (await entity.length()) == 0;

          if (isTemp || isZeroByte) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
    } catch (_) {}
    return deletedCount;
  }
}
