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

  // Matches user profile & bookmark URLs: pixiv.net/users/12345 or /bookmarks
  static final RegExp _userRegex = RegExp(
    r'pixiv\.net/(?:[a-zA-Z_-]+/)?users/(\d+)(?:/(?:artworks|illustrations|manga|bookmarks))?',
    caseSensitive: false,
  );

  static const String defaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  @override
  bool canHandle(String url) {
    return _illustRegex.hasMatch(url) || _userRegex.hasMatch(url);
  }

  String? extractIllustId(String url) {
    final match = _illustRegex.firstMatch(url);
    return match?.group(1);
  }

  String? extractUserId(String url) {
    final match = _userRegex.firstMatch(url);
    return match?.group(1);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    // Case A: User Profile or Bookmarks URL
    final userId = extractUserId(url);
    final illustId = extractIllustId(url);

    if (userId != null && illustId == null) {
      return await _extractUserGallery(userId, url, cookieToken: cookieToken);
    }

    // Case B: Artwork URL (Single, Multi-page Manga, or Ugoira)
    if (illustId == null) {
      throw Exception('Format tautan Pixiv tidak valid: $url');
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
      throw Exception(msg.isNotEmpty ? msg : 'Gagal mengambil metadata karya Pixiv.');
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
      downloadHeaders['Cookie'] = headers['Cookie']!;
    }

    // 1. Ugoira Animation (illustType == 2)
    if (illustType == 2) {
      final ugoiraMetaUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId/ugoira_meta');
      final ugoiraResp = await http.get(ugoiraMetaUrl, headers: headers).timeout(const Duration(seconds: 10));
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
              qualityLabel: 'Animasi Ugoira (Otomatis Dikonversi ke MP4 60fps)',
              extension: 'mp4',
              headers: downloadHeaders,
            ),
          ],
        );
      }
    }

    // 2. Multi-Page Manga / Album Carousel (pageCount > 1)
    if (pageCount > 1) {
      final pagesUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$illustId/pages');
      final pagesResp = await http.get(pagesUrl, headers: headers).timeout(const Duration(seconds: 10));
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
            qualityLabel: 'Halaman ${i + 1}/$pageCount ($ext)',
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

    // 3. Single High-Res Illustration
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
          qualityLabel: 'Kualitas Master Asli ($ext)',
          extension: ext,
          headers: downloadHeaders,
        ),
      ],
    );
  }

  Future<MediaMetadata> _extractUserGallery(String userId, String url, {String? cookieToken}) async {
    final headers = <String, String>{
      'User-Agent': defaultUserAgent,
      'Referer': 'https://www.pixiv.net/',
      'Accept': 'application/json',
    };
    if (cookieToken != null && cookieToken.isNotEmpty) {
      final formatted = cookieToken.contains('=') ? cookieToken : 'PHPSESSID=$cookieToken';
      headers['Cookie'] = formatted;
    }

    final isBookmarks = url.contains('bookmarks');
    final profileUrl = Uri.parse('https://www.pixiv.net/ajax/user/$userId/profile/all');
    final resp = await http.get(profileUrl, headers: headers).timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception('Gagal memuat galeri pengguna Pixiv #$userId (HTTP ${resp.statusCode}).');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final body = data['body'] as Map<String, dynamic>?;
    if (body == null) {
      throw Exception('Data karya pengguna Pixiv tidak ditemukan.');
    }

    final illustsMap = isBookmarks
        ? (body['bookmarkIllusts'] as Map<String, dynamic>?) ?? (body['illusts'] as Map<String, dynamic>?)
        : (body['illusts'] as Map<String, dynamic>?);

    if (illustsMap == null || illustsMap.isEmpty) {
      throw Exception('Tidak ditemukan karya ilustrasi atau bookmark pada profil pengguna ini.');
    }

    final recentIds = illustsMap.keys.take(20).toList();
    final streams = <MediaStreamItem>[];
    String creator = 'Pixiv_User_$userId';
    String? thumb;

    final downloadHeaders = <String, String>{
      'User-Agent': defaultUserAgent,
      'Referer': 'https://www.pixiv.net/',
    };
    if (cookieToken != null && cookieToken.isNotEmpty) {
      downloadHeaders['Cookie'] = headers['Cookie']!;
    }

    // Resolve first batch
    for (int i = 0; i < recentIds.length; i++) {
      final id = recentIds[i];
      try {
        final ajaxUrl = Uri.parse('https://www.pixiv.net/ajax/illust/$id');
        final itemResp = await http.get(ajaxUrl, headers: headers).timeout(const Duration(seconds: 4));
        if (itemResp.statusCode == 200) {
          final itemJson = jsonDecode(itemResp.body) as Map<String, dynamic>;
          final itemBody = itemJson['body'] as Map<String, dynamic>?;
          if (itemBody != null) {
            creator = (itemBody['userName'] ?? creator).toString();
            final origUrl = (itemBody['urls']?['original'] ?? itemBody['urls']?['regular']) as String?;
            thumb ??= itemBody['urls']?['regular'] ?? itemBody['urls']?['thumb'];
            if (origUrl != null && origUrl.isNotEmpty) {
              final ext = origUrl.split('.').last.split('?').first;
              final itemTitle = itemBody['title'] ?? 'Karya_$id';
              streams.add(MediaStreamItem(
                url: origUrl,
                qualityLabel: '$itemTitle (#$id)',
                extension: ext,
                headers: downloadHeaders,
              ));
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (streams.isEmpty) {
      throw Exception('Tidak dapat memuat karya dari pengguna ini. Pastikan akun tidak privat.');
    }

    return MediaMetadata(
      title: isBookmarks ? 'Bookmark Pixiv ($creator)' : 'Koleksi Karya ($creator)',
      creatorName: creator,
      platform: MediaPlatform.pixiv,
      mediaType: MediaType.album,
      workId: userId,
      thumbnailUrl: thumb,
      isMultiPage: true,
      streams: streams,
    );
  }
}
