import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class PixivExtractor implements BaseExtractor {
  // Matches artwork IDs: pixiv.net/artworks/12345 or illust_id=12345
  static final RegExp _illustRegex = RegExp(
    r'(?:pixiv\.net/(?:[a-zA-Z_-]+/)?artworks/|pximg\.net/.*?/|illust_id=)(\d+)',
    caseSensitive: false,
  );

  static const String defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  @override
  bool canHandle(String url) {
    return _illustRegex.hasMatch(url);
  }

  String? extractIllustId(String url) {
    final match = _illustRegex.firstMatch(url);
    return match?.group(1);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    final illustId = extractIllustId(url);

    if (illustId == null) {
      throw Exception('Invalid Pixiv URL format (Format tautan Pixiv tidak valid): $url');
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

    final ajaxUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId');
    final resp = await http.get(ajaxUrl, headers: headers).timeout(const Duration(seconds: 12));

    if (resp.statusCode == 404) {
      throw Exception('Karya Pixiv #$illustId tidak ditemukan (Artwork not found or deleted).');
    } else if (resp.statusCode == 403) {
      throw Exception(
        'Akses ditolak (HTTP 403). Karya ini mungkin berstatus R-18/Sensitif. Silakan masukkan Cookie PHPSESSID akun Pixiv Anda di menu Pengaturan.',
      );
    } else if (resp.statusCode != 200) {
      throw Exception('Gagal memuat Pixiv API (HTTP ${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['error'] == true) {
      final msg = (data['message'] ?? '').toString();
      if (msg.toLowerCase().contains('login') || msg.toLowerCase().contains('r-18')) {
        throw Exception(
          'Karya ini dibatasi untuk pengguna dewasa (R-18). Silakan simpan Cookie PHPSESSID akun Pixiv Anda di menu Pengaturan.',
        );
      }
      throw Exception(msg.isNotEmpty ? msg : 'Gagal mengambil metadata karya Pixiv (Artwork not found).');
    }

    final body = data['body'] as Map<String, dynamic>;
    final title = (body['title'] ?? body['illustTitle'] ?? 'Pixiv_$illustId').toString();
    final creatorName = (body['userName'] ?? body['userAccount'] ?? 'General').toString();
    final illustType = body['illustType'] as int? ?? 0;
    final pageCount = body['pageCount'] as int? ?? 1;
    final thumb = body['urls']?['regular'] ?? body['urls']?['thumb'];

    final downloadHeaders = <String, String>{
      'User-Agent': defaultUserAgent,
      'Referer': 'https://www.pixiv.net/',
    };
    if (cookieToken != null && cookieToken.isNotEmpty) {
      downloadHeaders['Cookie'] = cookieToken.contains('=') ? cookieToken : 'PHPSESSID=$cookieToken';
    }

    // 1. Case: Pixiv Ugoira Animation (illustType == 2)
    if (illustType == 2) {
      final metaUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId/ugoira_meta');
      final metaResp = await http.get(metaUrl, headers: headers);
      if (metaResp.statusCode == 200) {
        final metaJson = jsonDecode(metaResp.body) as Map<String, dynamic>;
        final metaBody = metaJson['body'] as Map<String, dynamic>?;
        if (metaBody != null && (metaBody['originalSrc'] != null || metaBody['src'] != null)) {
          final zipUrl = (metaBody['originalSrc'] ?? metaBody['src']) as String;
          final frames = (metaBody['frames'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
                qualityLabel: 'Animasi Ugoira (ZIP -> MP4)',
                extension: 'mp4',
                headers: downloadHeaders,
              ),
            ],
          );
        }
      }
    }

    // 2. Case: Multi-page Manga / Illustration Album (pageCount > 1)
    if (pageCount > 1) {
      final pagesUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId/pages');
      final pagesResp = await http.get(pagesUrl, headers: headers);

      if (pagesResp.statusCode == 200) {
        final pagesData = jsonDecode(pagesResp.body) as Map<String, dynamic>;
        final pagesList = pagesData['body'] as List?;
        if (pagesList != null && pagesList.isNotEmpty) {
          final streams = <MediaStreamItem>[];
          for (int i = 0; i < pagesList.length; i++) {
            final page = pagesList[i] as Map<String, dynamic>;
            final origUrl = page['urls']?['original'] ?? page['urls']?['regular'];
            if (origUrl != null) {
              final ext = origUrl.toString().split('.').last.split('?').first;
              streams.add(MediaStreamItem(
                url: origUrl.toString(),
                qualityLabel: 'Halaman ${i + 1}/$pageCount (Original)',
                extension: ext.isNotEmpty ? ext : 'png',
                headers: downloadHeaders,
              ));
            }
          }

          if (streams.isNotEmpty) {
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
      }
    }

    // 3. Case: Single Master Illustration
    final originalUrl = body['urls']?['original'] ?? body['urls']?['regular'] ?? thumb;
    if (originalUrl == null) {
      throw Exception('Tidak ditemukan tautan gambar resolusi asli untuk karya #$illustId.');
    }

    final ext = originalUrl.toString().split('.').last.split('?').first;
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
          url: originalUrl.toString(),
          qualityLabel: 'Gambar Resolusi Asli (${ext.toUpperCase()})',
          extension: ext.isNotEmpty ? ext : 'png',
          headers: downloadHeaders,
        ),
      ],
    );
  }
}
