import '../core/constants/platforms.dart';

class MediaStreamItem {
  final String url;
  final String qualityLabel;
  final String extension;
  final Map<String, String> headers;
  final bool isAudioOnly;
  final int? fileSize;

  MediaStreamItem({
    required this.url,
    required this.qualityLabel,
    required this.extension,
    this.headers = const {},
    this.isAudioOnly = false,
    this.fileSize,
  });
}

class MediaMetadata {
  final String title;
  final String creatorName;
  final MediaPlatform platform;
  final MediaType mediaType;
  final String workId;
  final String? thumbnailUrl;
  final List<MediaStreamItem> streams;
  final bool isMultiPage;
  final bool isUgoira;
  final List<Map<String, dynamic>>? ugoiraFrames;
  final String? pinterestBoardName;
  final bool isPinterestCreatedPin;
  final Map<String, dynamic> extra;

  MediaMetadata({
    required this.title,
    required this.creatorName,
    required this.platform,
    required this.mediaType,
    required this.workId,
    this.thumbnailUrl,
    required this.streams,
    this.isMultiPage = false,
    this.isUgoira = false,
    this.ugoiraFrames,
    this.pinterestBoardName,
    this.isPinterestCreatedPin = false,
    this.extra = const {},
  });
}

abstract class BaseExtractor {
  bool canHandle(String url);
  Future<MediaMetadata> extract(String url, {String? cookieToken});
}
