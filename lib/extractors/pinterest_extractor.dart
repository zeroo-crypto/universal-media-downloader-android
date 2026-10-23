import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class PinterestExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:pinterest\.(?:com|[a-z]{2})/pin/|pin\.it/)(\d+|[a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    // 1. Follow shortlink redirects (e.g. pin.it/xyz -> pinterest.com/pin/12345)
    var resolvedUri = Uri.parse(url);
    final client = http.Client();
    try {
      final req = http.Request('GET', resolvedUri)..followRedirects = false;
      req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/125.0.0.0';
      final response = await client.send(req);
      if (response.isRedirect && response.headers.containsKey('location')) {
        resolvedUri = Uri.parse(response.headers['location']!);
      }
    } finally {
      client.close();
    }

    final pageUrl = resolvedUri.toString();
    final match = RegExp(r'/pin/(\d+)').firstMatch(pageUrl);
    final pinId = match?.group(1) ?? 'Pin_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Fetch page HTML to extract rich JSON schema or __PWS_DATA__
    final pageResp = await http.get(Uri.parse(pageUrl), headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
    });

    String title = 'Pinterest_$pinId';
    String creator = 'General';
    String? boardName;
    bool isCreatedPin = true;
    String? mediaUrl;
    bool isVideo = false;

    if (pageResp.statusCode == 200) {
      final html = pageResp.body;

      // Extract JSON-LD Schema
      final schemaMatch = RegExp(r'<script type="application/ld\+json">([\s\S]*?)</script>').firstMatch(html);
      if (schemaMatch != null) {
        try {
          final jsonLd = jsonDecode(schemaMatch.group(1)!) as Map<String, dynamic>;
          title = jsonLd['headline'] ?? jsonLd['name'] ?? title;
          if (jsonLd.containsKey('creator') && jsonLd['creator'] is Map) {
            creator = jsonLd['creator']['name'] ?? creator;
          }
          if (jsonLd.containsKey('image')) {
            mediaUrl = jsonLd['image'] is String ? jsonLd['image'] : jsonLd['image']?['url'];
          }
        } catch (_) {}
      }

      // Extract video stream if available (v.pinimg.com)
      final videoMatch = RegExp(r'https://v\.pinimg\.com/videos/[a-zA-Z0-9_\/]+\.mp4').firstMatch(html);
      if (videoMatch != null) {
        mediaUrl = videoMatch.group(0);
        isVideo = true;
      }

      // Upgrade image from /736x/ or /474x/ to /originals/ (Highest Res)
      if (mediaUrl != null && !isVideo) {
        mediaUrl = mediaUrl.replaceAll(RegExp(r'/(?:736x|564x|474x|236x)/'), '/originals/');
      }

      // Detect Board Name if present in meta tags or breadcrumbs
      final boardMatch = RegExp(r'"board":\s*\{[^}]*"name":\s*"([^"]+)"').firstMatch(html);
      if (boardMatch != null) {
        boardName = boardMatch.group(1);
        isCreatedPin = false;
      }
    }

    mediaUrl ??= 'https://i.pinimg.com/originals/pin_$pinId.jpg';
    final ext = isVideo ? 'mp4' : 'jpg';

    return MediaMetadata(
      title: title,
      creatorName: creator,
      platform: MediaPlatform.pinterest,
      mediaType: isVideo ? MediaType.video : MediaType.image,
      workId: pinId,
      thumbnailUrl: mediaUrl,
      pinterestBoardName: boardName,
      isPinterestCreatedPin: isCreatedPin,
      streams: [
        MediaStreamItem(
          url: mediaUrl,
          qualityLabel: isVideo ? 'Original High-Res Video (MP4)' : 'Original High-Res Image (JPG/PNG)',
          extension: ext,
        ),
      ],
    );
  }
}
