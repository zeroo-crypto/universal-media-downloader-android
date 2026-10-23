import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/platforms.dart';
import 'base_extractor.dart';

class PixivExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:pixiv\.net/(?:[a-zA-Z_-]+/)?artworks/|pximg\.net/.*?/|illust_id=)(\d+)',
    caseSensitive: false,
  );

  static const String defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  String? extractIllustId(String url) {
    final match = _urlRegex.firstMatch(url);
    return match?.group(1);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    final illustId = extractIllustId(url);
    if (illustId == null) {
      throw Exception('Format URL Pixiv tidak valid: $url');
    }

    final headers = <String, String>{
      'User-Agent': defaultUserAgent,
      'Referer': 'https://www.pixiv.net/',
      'Accept': 'application/json',
      'Accept-Language': 'en-US,en;q=0.9,ja;q=0.8',
    };

    if (cookieToken != null && cookieToken.isNotEmpty) {
      final formatted = cookieToken.contains('=') ? cookieToken : 'PHPSESSID=$cookieToken';
      headers['Cookie'] = formatted;
    }

    // 1. Fetch artwork details from Pixiv AJAX API
    final ajaxUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId');
    final resp = await http.get(ajaxUrl, headers: headers);

    if (resp.statusCode == 404) {
      throw Exception('Karya Pixiv #$illustId tidak ditemukan atau dihapus.');
    } else if (resp.statusCode == 403) {
      throw Exception('Akses ditolak (HTTP 403). Silakan periksa atau masukkan Cookie PHPSESSID akun Anda di Pengaturan.');
    } else if (resp.statusCode != 200) {
      throw Exception('Gagal memuat Pixiv API (HTTP ${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['error'] == true) {
      throw Exception(data['message'] ?? 'Gagal mengambil metadata Pixiv');
    }

    final body = data['body'] as Map<String, dynamic>;
    final title = (body['title'] ?? body['illustTitle'] ?? 'Pixiv_$illustId').toString();
    final creatorName = (body['userName'] ?? body['userAccount'] ?? 'General').toString();
    final illustType = body['illustType'] as int? ?? 0;
    final pageCount = body['pageCount'] as int? ?? 1;
    final thumb = body['urls']?['regular'] ?? body['urls']?['thumb'];

    // Common download headers (Pixiv CDN blocks requests without Pixiv Referer)
    final downloadHeaders = <String, String>{
      'User-Agent': defaultUserAgent,
      'Referer': 'https://www.pixiv.net/',
    };
    if (cookieToken != null && cookieToken.isNotEmpty) {
      downloadHeaders['Cookie'] = headers['Cookie']!;
    }

    // 2. Case Ugoira Animation (illustType == 2)
    if (illustType == 2) {
      final ugoiraMetaUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId/ugoira_meta');
      final ugoiraResp = await http.get(ugoiraMetaUrl, headers: headers);
      if (ugoiraResp.statusCode == 200) {
        final ugoiraData = jsonDecode(ugoiraResp.body) as Map<String, dynamic>;
        final ugoiraBody = ugoiraData['body'] as Map<String, dynamic>;
        final zipUrl = (ugoiraBody['originalSrc'] ?? ugoiraBody['src']) as String;
        final frames = (ugoiraBody['frames'] as List).cast<Map<String, dynamic>>();

        return MediaMetadata(
          title: title,
          creatorName: creatorName,
          platform: MediaPlatform.pixiv,
          mediaType: MediaType.ugoira,
          workId: illustId,
          thumbnailUrl: thumb,
          isUgoira: true,
          ugoiraFrames: frames,
          streams: [
            MediaStreamItem(
              url: zipUrl,
              qualityLabel: 'Ugoira Animation (Auto-convert to MP4)',
              extension: 'mp4',
              headers: downloadHeaders,
            ),
          ],
        );
      }
    }

    // 3. Case Multi-Page Manga / Album Carousel (pageCount > 1)
    if (pageCount > 1) {
      final pagesUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId/pages');
      final pagesResp = await http.get(pagesUrl, headers: headers);
      if (pagesResp.statusCode == 200) {
        final pagesData = jsonDecode(pagesResp.body) as Map<String, dynamic>;
        final pagesList = pagesData['body'] as List;

        final streams = <MediaStreamItem>[];
        for (int i = 0; i < pagesList.length; i++) {
          final pageItem = pagesList[i] as Map<String, dynamic>;
          final origUrl = pageItem['urls']['original'] as String;
          final ext = origUrl.split('.').last.split('?').first;

          streams.add(MediaStreamItem(
            url: origUrl,
            qualityLabel: 'Page ${i + 1}/$pageCount ($ext)',
            extension: ext,
            headers: downloadHeaders,
          ));
        }

        return MediaMetadata(
          title: title,
          creatorName: creatorName,
          platform: MediaPlatform.pixiv,
          mediaType: MediaType.album,
          workId: illustId,
          thumbnailUrl: thumb,
          isMultiPage: true,
          streams: streams,
        );
      }
    }

    // 4. Case Single High-Res Illustration
    final originalUrl = (body['urls']?['original'] ?? body['urls']?['regular']) as String;
    final ext = originalUrl.split('.').last.split('?').first;

    return MediaMetadata(
      title: title,
      creatorName: creatorName,
      platform: MediaPlatform.pixiv,
      mediaType: MediaType.image,
      workId: illustId,
      thumbnailUrl: thumb,
      isMultiPage: false,
      streams: [
        MediaStreamItem(
          url: originalUrl,
          qualityLabel: 'Original Quality ($ext)',
          extension: ext,
          headers: downloadHeaders,
        ),
      ],
    );
  }
}
