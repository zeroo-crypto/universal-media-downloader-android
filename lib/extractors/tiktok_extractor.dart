import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class TikTokExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:tiktok\.com\/.*(?:video|photo|\bv\b)\/(\d+)|(?:vt|vm)\.tiktok\.com\/([a-zA-Z0-9_-]+))',
    caseSensitive: false,
  );

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    // 1. Resolve shortlink if needed (vt.tiktok.com, vm.tiktok.com)
    var targetUrl = url.trim();
    if (targetUrl.contains('vt.tiktok.com') || targetUrl.contains('vm.tiktok.com')) {
      final client = http.Client();
      try {
        final req = http.Request('GET', Uri.parse(targetUrl))..followRedirects = false;
        final res = await client.send(req).timeout(const Duration(seconds: 8));
        if (res.headers.containsKey('location')) {
          targetUrl = res.headers['location']!;
        }
      } catch (_) {
      } finally {
        client.close();
      }
    }

    final videoIdMatch = RegExp(r'/(?:video|photo)/(\d+)').firstMatch(targetUrl);
    final videoId = videoIdMatch?.group(1) ?? 'TikTok_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Query TikWM API
    final apiUri = Uri.parse('https://www.tikwm.com/api/?url=${Uri.encodeComponent(targetUrl)}');
    final resp = await http.get(apiUri, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception('Gagal menghubungi server TikTok API (HTTP ${resp.statusCode}).');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['code'] != 0 || json['data'] == null) {
      final msg = json['msg'] ?? 'Video atau foto TikTok tidak ditemukan atau berstatus privat.';
      throw Exception('TikTok: $msg');
    }

    final data = json['data'] as Map<String, dynamic>;
    final rawTitle = (data['title'] ?? 'TikTok_$videoId').toString();
    final author = (data['author']?['unique_id'] ?? data['author']?['nickname'] ?? 'TikTok_Creator').toString();
    final thumb = data['cover'] as String?;
    final streams = <MediaStreamItem>[];
    MediaType type = MediaType.video;

    final tiktokHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Referer': 'https://www.tiktok.com/',
    };

    String resolveUrl(String? u) {
      if (u == null || u.isEmpty) return '';
      if (u.startsWith('http://') || u.startsWith('https://')) return u;
      if (u.startsWith('//')) return 'https:$u';
      return 'https://www.tikwm.com$u';
    }

    // Check for Photo Slideshow (data['images'])
    final imagesList = data['images'] as List?;
    if (imagesList != null && imagesList.isNotEmpty) {
      type = MediaType.album;
      for (int i = 0; i < imagesList.length; i++) {
        final imgUrl = resolveUrl(imagesList[i].toString());
        if (imgUrl.isNotEmpty) {
          streams.add(MediaStreamItem(
            url: imgUrl,
            qualityLabel: 'Foto Slide ${i + 1}/${imagesList.length} (HD)',
            extension: 'jpg',
            headers: tiktokHeaders,
          ));
        }
      }
    }

    // Check for Watermark-Free Video (data['play'])
    final playUrl = resolveUrl(data['play'] as String?);
    if (playUrl.isNotEmpty) {
      if (streams.isEmpty) type = MediaType.video;
      streams.insert(
        0,
        MediaStreamItem(
          url: playUrl,
          qualityLabel: 'Video HD Tanpa Watermark (MP4)',
          extension: 'mp4',
          headers: tiktokHeaders,
        ),
      );
    }

    // HD Quality (data['hdplay'])
    final hdPlayUrl = resolveUrl(data['hdplay'] as String?);
    if (hdPlayUrl.isNotEmpty && hdPlayUrl != playUrl) {
      streams.insert(
        0,
        MediaStreamItem(
          url: hdPlayUrl,
          qualityLabel: 'Video Full HD 1080p (MP4)',
          extension: 'mp4',
          headers: tiktokHeaders,
        ),
      );
    }

    // Audio / Music (data['music'])
    final musicUrl = resolveUrl(data['music'] as String?);
    if (musicUrl.isNotEmpty) {
      streams.add(
        MediaStreamItem(
          url: musicUrl,
          qualityLabel: 'Audio Musik TikTok (MP3)',
          extension: 'mp3',
          headers: tiktokHeaders,
          isAudioOnly: true,
        ),
      );
    }

    if (streams.isEmpty) {
      throw Exception('Tidak ditemukan berkas video atau gambar yang dapat diunduh pada postingan TikTok ini.');
    }

    final isMulti = streams.length > 1;
    return MediaMetadata(
      title: rawTitle.length > 55 ? '${rawTitle.substring(0, 52)}...' : rawTitle,
      creatorName: author,
      platform: MediaPlatform.tiktok,
      mediaType: isMulti ? MediaType.album : type,
      workId: videoId,
      thumbnailUrl: thumb,
      isMultiPage: isMulti,
      streams: streams,
    );
  }
}
