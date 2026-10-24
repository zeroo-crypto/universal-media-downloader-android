import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class ExtractorException implements Exception {
  final String message;
  ExtractorException(this.message);

  @override
  String toString() => 'ExtractorException: $message';
}

class InstagramExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:instagram\.com\/(?:p|reels?|tv)\/([a-zA-Z0-9_-]+))',
    caseSensitive: false,
  );

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  String? extractShortcode(String url) {
    final match = _urlRegex.firstMatch(url);
    return match?.group(1);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    final shortcode = extractShortcode(url);
    if (shortcode == null) {
      throw ExtractorException('Invalid Instagram URL format: $url');
    }

    final endpoint = Uri.parse('https://www.instagram.com/p/$shortcode/?__a=1&__d=dis');
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
      'Accept': '*/*',
    };

    if (cookieToken != null && cookieToken.isNotEmpty) {
      headers['Cookie'] = cookieToken.contains('=') ? cookieToken : 'sessionid=$cookieToken';
    }

    final resp = await http.get(endpoint, headers: headers);
    String title = 'Instagram_$shortcode';
    String creator = 'Instagram_Creator';
    final streams = <MediaStreamItem>[];
    MediaType type = MediaType.video;

    if (resp.statusCode == 200) {
      try {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final item = items[0] as Map<String, dynamic>;
          creator = item['user']?['username'] ?? creator;
          title = item['caption']?['text'] ?? title;

          // Video
          final videoVersions = item['video_versions'] as List?;
          if (videoVersions != null && videoVersions.isNotEmpty) {
            final bestVideo = videoVersions[0]['url'] as String;
            streams.add(MediaStreamItem(
              url: bestVideo,
              qualityLabel: 'HD Video Reel (MP4)',
              extension: 'mp4',
            ));
          } else {
            // Photo candidates
            type = MediaType.image;
            final imageCandidates = item['image_versions2']?['candidates'] as List?;
            if (imageCandidates != null && imageCandidates.isNotEmpty) {
              final bestPhoto = imageCandidates[0]['url'] as String;
              streams.add(MediaStreamItem(
                url: bestPhoto,
                qualityLabel: 'HD Photo (JPG)',
                extension: 'jpg',
              ));
            }
          }
        }
      } catch (_) {}
    }

    if (streams.isEmpty) {
      // Direct media fallback endpoint resolving CDN image rather than downloading web HTML page as .mp4
      streams.add(MediaStreamItem(
        url: 'https://www.instagram.com/p/$shortcode/media/?size=l',
        qualityLabel: 'Media Stream (Direct CDN)',
        extension: 'jpg',
      ));
    }

    return MediaMetadata(
      title: title.length > 50 ? '${title.substring(0, 47)}...' : title,
      creatorName: creator,
      platform: MediaPlatform.instagram,
      mediaType: type,
      workId: shortcode,
      streams: streams,
    );
  }
}
