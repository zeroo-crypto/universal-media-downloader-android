import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class TikTokExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:tiktok\.com\/.*(?:video|\bv\b)\/(\d+)|vt\.tiktok\.com\/([a-zA-Z0-9]+))',
    caseSensitive: false,
  );

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    // 1. Resolve shortlink if needed
    var targetUrl = url;
    if (url.contains('vt.tiktok.com')) {
      final client = http.Client();
      try {
        final req = http.Request('GET', Uri.parse(url))..followRedirects = false;
        final res = await client.send(req);
        if (res.headers.containsKey('location')) {
          targetUrl = res.headers['location']!;
        }
      } finally {
        client.close();
      }
    }

    final videoIdMatch = RegExp(r'/video/(\d+)').firstMatch(targetUrl);
    final videoId = videoIdMatch?.group(1) ?? 'TikTok_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Fetch watermark-free stream via mobile TikWM API
    final apiUri = Uri.parse('https://www.tikwm.com/api/?url=${Uri.encodeComponent(targetUrl)}');
    final resp = await http.get(apiUri);

    String title = 'TikTok_$videoId';
    String author = 'TikTok_Creator';
    String? thumb;
    String? noWatermarkVideoUrl;

    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['code'] == 0 && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        title = data['title'] ?? title;
        author = data['author']?['unique_id'] ?? author;
        thumb = data['cover'];
        noWatermarkVideoUrl = data['play']; // HD without watermark
      }
    }

    noWatermarkVideoUrl ??= targetUrl;

    return MediaMetadata(
      title: title.length > 50 ? '${title.substring(0, 47)}...' : title,
      creatorName: author,
      platform: MediaPlatform.tiktok,
      mediaType: MediaType.video,
      workId: videoId,
      thumbnailUrl: thumb,
      streams: [
        MediaStreamItem(
          url: noWatermarkVideoUrl,
          qualityLabel: 'HD Video Tanpa Watermark (MP4)',
          extension: 'mp4',
        ),
      ],
    );
  }
}
