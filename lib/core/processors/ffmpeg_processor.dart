import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FFmpegProcessor {
  /// Assembles Pixiv Ugoira animation from raw ZIP bytes into a high-quality MP4 video.
  /// Adheres strictly to Zero Redundant Files rule: cleans up unpacked temporary frames.
  static Future<File?> assembleUgoiraToMp4({
    required List<int> zipBytes,
    required List<Map<String, dynamic>> framesMeta,
    required String outputMp4Path,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final sessionDir = Directory(p.join(tempDir.path, 'ugoira_${DateTime.now().millisecondsSinceEpoch}'));
    await sessionDir.create(recursive: true);

    try {
      // 1. Unpack ZIP frames into temporary directory
      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive) {
        if (file.isFile) {
          final outFile = File(p.join(sessionDir.path, file.name));
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      // 2. Generate concat demuxer text file with precise frame delays
      // FFmpeg concat demuxer format:
      // file '000000.jpg'
      // duration 0.125
      final concatListFile = File(p.join(sessionDir.path, 'frames.txt'));
      final buffer = StringBuffer();

      for (int i = 0; i < framesMeta.length; i++) {
        final frame = framesMeta[i];
        final frameFile = frame['file'] as String;
        final delayMs = (frame['delay'] as num?)?.toInt() ?? 100;
        final durationSec = delayMs / 1000.0;

        buffer.writeln("file '$frameFile'");
        buffer.writeln("duration $durationSec");
      }
      // Concat demuxer requirement: repeat the last file entry without duration
      if (framesMeta.isNotEmpty) {
        buffer.writeln("file '${framesMeta.last['file']}'");
      }

      await concatListFile.writeAsString(buffer.toString());

      // 3. Execute FFmpeg Kit command to encode MP4 (H.264 yuv420p for max Android compatibility)
      final command = "-y -f concat -safe 0 -i \"${concatListFile.path}\" "
          "-c:v libx264 -pix_fmt yuv420p -movflags faststart \"$outputMp4Path\"";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputMp4Path);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          return outputFile;
        }
      }
      // If cancelled or failed, purge any partial output file
      final partialFile = File(outputMp4Path);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      return null;
    } catch (e) {
      final partialFile = File(outputMp4Path);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      rethrow;
    } finally {
      // 4. Zero Orphaned Frames: purge temporary directory immediately
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
      }
    }
  }

  /// Cancels all running FFmpegKit sessions immediately
  static Future<void> cancelRunningSessions() async {
    try {
      await FFmpegKit.cancel();
    } catch (_) {}
  }

  /// Extracts audio track (AAC/M4A) from an existing video file
  static Future<File?> extractAudio({
    required String videoPath,
    required String outputAudioPath,
  }) async {
    try {
      final command = "-y -i \"$videoPath\" -vn -acodec copy \"$outputAudioPath\"";
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outFile = File(outputAudioPath);
        if (await outFile.exists() && await outFile.length() > 0) {
          return outFile;
        }
      }
      final partialAudio = File(outputAudioPath);
      if (await partialAudio.exists()) {
        await partialAudio.delete();
      }
      return null;
    } catch (e) {
      final partialAudio = File(outputAudioPath);
      if (await partialAudio.exists()) {
        await partialAudio.delete();
      }
      rethrow;
    }
  }
}
