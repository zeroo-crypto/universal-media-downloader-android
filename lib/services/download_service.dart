import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../core/constants/platforms.dart';
import '../core/storage/hierarchy_manager.dart';
import '../core/processors/ffmpeg_processor.dart';
import '../core/utils/clean_cancel.dart';
import '../extractors/base_extractor.dart';
import '../extractors/instagram_extractor.dart';

enum DownloadStatus {
  queued,
  downloading,
  processing,
  completed,
  cancelled,
  failed,
}

class DownloadTask {
  final String id;
  final MediaMetadata metadata;
  final MediaStreamItem selectedStream;
  DownloadStatus status;
  double progress; // 0.0 to 1.0
  int receivedBytes;
  int totalBytes;
  double speedBytesPerSec;
  String? savedFilePath;
  String? errorMessage;
  CancelToken cancelToken;

  DownloadTask({
    required this.id,
    required this.metadata,
    required this.selectedStream,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.savedFilePath,
    this.errorMessage,
    CancelToken? cancelToken,
  }) : cancelToken = cancelToken ?? CancelToken();
}

class DownloadService extends ChangeNotifier {
  final List<DownloadTask> _tasks = [];
  final Dio _dio = Dio();

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  DownloadTask? get activeTask {
    try {
      return _tasks.firstWhere((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.processing);
    } catch (_) {
      return null;
    }
  }

  /// Initiates downloading of a media item
  Future<void> enqueueDownload(MediaMetadata metadata, MediaStreamItem stream) async {
    final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
    final task = DownloadTask(
      id: taskId,
      metadata: metadata,
      selectedStream: stream,
    );

    _tasks.insert(0, task);
    notifyListeners();

    _processQueue();
  }

  static const MethodChannel _mediaScannerChannel =
      MethodChannel('com.zeroo.universal_media_downloader/media_scanner');

  /// Indexes media file with Android MediaStore so it appears immediately in Gallery/Photos
  static Future<void> scanMediaFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        await _mediaScannerChannel.invokeMethod('scanFile', {'path': filePath});
      }
    } catch (e) {
      debugPrint('MediaScanner platform channel error: $e');
    }
  }

  /// Completes a task and triggers MediaStore indexing
  Future<void> completeTask(DownloadTask task) async {
    task.status = DownloadStatus.completed;
    task.progress = 1.0;
    if (task.savedFilePath != null) {
      await scanMediaFile(task.savedFilePath!);
    }
    notifyListeners();
  }

  void cancelTask(String taskId) {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      if (task.status == DownloadStatus.downloading ||
          task.status == DownloadStatus.queued ||
          task.status == DownloadStatus.processing) {
        task.cancelToken.cancel('Cancelled by user');
        if (task.metadata.isUgoira || task.status == DownloadStatus.processing) {
          FFmpegProcessor.cancelRunningSessions();
        }
        task.status = DownloadStatus.cancelled;
        if (task.savedFilePath != null) {
          CleanCancel.cleanupPartialFile(task.savedFilePath!);
        }
        notifyListeners();
        _updateNotification('Download Cancelled', task.metadata.title, 0.0);
      }
    } catch (_) {}
  }

  Future<void> _processQueue() async {
    final pending = _tasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (pending.isEmpty) return;

    // Check if an existing task is currently running
    if (activeTask != null) return;

    final task = pending.first;
    await _executeDownload(task);
    _processQueue(); // Process next item
  }

  Future<void> _executeDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    notifyListeners();

    var lastBytes = 0;
    var lastTime = DateTime.now();

    try {
      // 1. Resolve Destination Directory based on Project Memory Vault Rules
      final targetDir = await HierarchyManager.resolveDestinationDirectory(
        platform: task.metadata.platform,
        creatorName: task.metadata.creatorName,
        workId: task.metadata.workId,
        isMultiPage: task.metadata.isMultiPage,
        pinterestBoardName: task.metadata.pinterestBoardName,
        isPinterestCreatedPin: task.metadata.isPinterestCreatedPin,
      );

      final cleanBaseName = task.metadata.workId.isNotEmpty
          ? '${task.metadata.workId}_${HierarchyManager.sanitizeName(task.metadata.title)}'
          : HierarchyManager.sanitizeName(task.metadata.title);

      final destinationPath = await HierarchyManager.getUniqueDestinationFilePath(
        directory: targetDir,
        baseFileName: cleanBaseName,
        extension: task.selectedStream.extension,
      );

      task.savedFilePath = destinationPath;
      final partFilePath = '$destinationPath.part';

      // Eliminate silent HTML download: throw ExtractorException if trying to download webpage HTML
      final streamUrl = task.selectedStream.url.toLowerCase();
      final streamUri = Uri.tryParse(streamUrl);
      final streamHost = streamUri?.host.toLowerCase() ?? '';
      final isInstagram = streamHost == 'instagram.com' ||
          streamHost == 'www.instagram.com' ||
          streamHost == 'm.instagram.com' ||
          streamUrl.startsWith('https://www.instagram.com/') ||
          streamUrl.startsWith('https://instagram.com/') ||
          streamUrl.startsWith('http://www.instagram.com/') ||
          streamUrl.startsWith('http://instagram.com/') ||
          streamUrl.startsWith('https://m.instagram.com/') ||
          streamUrl.startsWith('http://m.instagram.com/');
      if (isInstagram &&
          (streamUrl.contains('/p/') || streamUrl.contains('/reel/') || streamUrl.contains('/reels/') || streamUrl.contains('/tv/')) &&
          !streamUrl.contains('/media/')) {
        throw ExtractorException(
          'No video/image stream found for Instagram (${task.metadata.workId}). sessionid Cookie required in Settings.',
        );
      }

      // 2. Special Handler for Pixiv Ugoira (ZIP to MP4 assembly)
      if (task.metadata.isUgoira && task.metadata.ugoiraFrames != null) {
        task.status = DownloadStatus.downloading;
        _updateNotification('Downloading Animation Frames...', task.metadata.title, 0.3);

        final response = await _dio.get<List<int>>(
          task.selectedStream.url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: task.selectedStream.headers,
          ),
          cancelToken: task.cancelToken,
          onReceiveProgress: (received, total) {
            task.receivedBytes = received;
            task.totalBytes = total;
            task.progress = total > 0 ? (received / total) * 0.5 : 0.0;
            notifyListeners();
          },
        );

        task.status = DownloadStatus.processing;
        _updateNotification('Assembling MP4 Video (FFmpeg)...', task.metadata.title, 0.7);
        notifyListeners();

        // Assemble frames via FFmpeg
        final mp4File = await FFmpegProcessor.assembleUgoiraToMp4(
          zipBytes: response.data!,
          framesMeta: task.metadata.ugoiraFrames!,
          outputMp4Path: destinationPath,
        );

        if (mp4File != null && await mp4File.exists()) {
          task.status = DownloadStatus.completed;
          task.progress = 1.0;
          _updateNotification('Download Complete (MP4)', task.metadata.title, 1.0);
          await scanMediaFile(destinationPath);
        } else {
          throw Exception('Failed to compile Ugoira animation to MP4.');
        }

        notifyListeners();
        return;
      }

      // 3. Standard Direct File / Video Streaming
      await _dio.download(
        task.selectedStream.url,
        partFilePath,
        options: Options(headers: task.selectedStream.headers),
        cancelToken: task.cancelToken,
        onReceiveProgress: (received, total) {
          final now = DateTime.now();
          final durationDelta = now.difference(lastTime).inMilliseconds;

          if (durationDelta >= 500) {
            final bytesDelta = received - lastBytes;
            task.speedBytesPerSec = (bytesDelta / (durationDelta / 1000.0));
            lastBytes = received;
            lastTime = now;
          }

          task.receivedBytes = received;
          task.totalBytes = total;
          task.progress = total > 0 ? (received / total) : 0.0;

          final speedMb = (task.speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1);
          final percent = (task.progress * 100).toInt();

          _updateNotification(
            '$percent% ($speedMb MB/s) - Downloading',
            task.metadata.title,
            task.progress,
          );

          notifyListeners();
        },
      );

      // 4. Rename .part file to final destination upon success
      final partFile = File(partFilePath);
      if (await partFile.exists()) {
        await partFile.rename(destinationPath);
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        _updateNotification('Download Complete', task.metadata.title, 1.0);
        await scanMediaFile(destinationPath);
      } else {
        throw Exception('Downloaded file not found after completion.');
      }
    } catch (e) {
      if (task.status != DownloadStatus.cancelled) {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.toString();
        _updateNotification('Download Failed', task.metadata.title, 0.0);
      }
      // Zero Orphaned Files: Clean up partial or empty files
      if (task.savedFilePath != null) {
        await CleanCancel.cleanupPartialFile(task.savedFilePath!);
      }
    } finally {
      notifyListeners();
    }
  }

  void _updateNotification(String title, String body, double progress) {
    try {
      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: body,
      );
    } catch (_) {}
  }
}
