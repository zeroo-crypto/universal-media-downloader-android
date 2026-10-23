import '../constants/platforms.dart';

export '../constants/platforms.dart';

/// Legacy model bridge providing MediaPlatform access and MediaItem typing
class MediaItem {
  final String id;
  final String title;
  final String creatorName;
  final MediaPlatform platform;
  final MediaType mediaType;

  MediaItem({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.platform,
    required this.mediaType,
  });
}
