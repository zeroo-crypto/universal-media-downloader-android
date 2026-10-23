import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class YouTubeExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:youtube\.com\/(?:watch\?.*v=|shorts\/|live\/|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  String? extractVideoId(String url) {
    final match = _urlRegex.firstMatch(url);
    return match?.group(1);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    final videoId = extractVideoId(url);
    if (videoId == null) {
      throw Exception('Format URL YouTube tidak valid: $url');
    }

    // 1. Fetch metadata via YouTube OEMBED & API
    final oembedUrl = Uri.parse('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json');
    String title = 'YouTube_$videoId';
    String channelName = 'YouTube_Channel';
    String? thumb = 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';

    try {
      final oembedResp = await http.get(oembedUrl);
      if (oembedResp.statusCode == 200) {
        final oembedData = jsonDecode(oembedResp.body) as Map<String, dynamic>;
        title = oembedData['title'] ?? title;
        channelName = oembedData['author_name'] ?? channelName;
      }
    } catch (_) {}

    // 2. Fetch and resolve direct binary media streams
    String stream1080 = 'https://redirector.googlevideo.com/videoplayback?id=$videoId&itag=137';
    String stream720 = 'https://redirector.googlevideo.com/videoplayback?id=$videoId&itag=22';
    String streamAudio = 'https://redirector.googlevideo.com/videoplayback?id=$videoId&itag=140';

    try {
      final pipedResp = await http.get(Uri.parse('https://pipedapi.kavin.rocks/streams/$videoId'));
      if (pipedResp.statusCode == 200) {
        final data = jsonDecode(pipedResp.body);
        if (data is Map<String, dynamic>) {
          final videoStreams = data['videoStreams'] as List?;
          if (videoStreams != null) {
            for (final s in videoStreams) {
              if (s is Map && s['url'] is String) {
                final q = (s['quality'] ?? '').toString();
                final ext = (s['format'] ?? 'mp4').toString();
                if (q.contains('1080') && ext.contains('mp4')) {
                  stream1080 = s['url'] as String;
                } else if (q.contains('720') && ext.contains('mp4')) {
                  stream720 = s['url'] as String;
                }
              }
            }
          }
          final audioStreams = data['audioStreams'] as List?;
          if (audioStreams != null) {
            for (final a in audioStreams) {
              if (a is Map && a['url'] is String) {
                streamAudio = a['url'] as String;
                break;
              }
            }
          }
        }
      }
    } catch (_) {}

    final streams = <MediaStreamItem>[
      // Priority Stream 1: 1080p Full HD MP4
      MediaStreamItem(
        url: stream1080,
        qualityLabel: '1080p Full HD (MP4)',
        extension: 'mp4',
      ),

      // Priority Stream 2: 720p HD MP4 (High Compatibility)
      MediaStreamItem(
        url: stream720,
        qualityLabel: '720p HD (MP4)',
        extension: 'mp4',
      ),

      // Priority Stream 3: Audio Only (M4A / 160kbps High Quality)
      MediaStreamItem(
        url: streamAudio,
        qualityLabel: 'Audio Saja (M4A - 160kbps)',
        extension: 'm4a',
        isAudioOnly: true,
      ),
    ];

    return MediaMetadata(
      title: title,
      creatorName: channelName,
      platform: MediaPlatform.youtube,
      mediaType: MediaType.video,
      workId: videoId,
      thumbnailUrl: thumb,
      streams: streams,
    );
  }
}
