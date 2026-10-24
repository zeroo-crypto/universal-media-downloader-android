import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class InstagramExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:instagram\.com\/(?:p|reels?|tv|share)\/([a-zA-Z0-9_-]+))',
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

  String _cleanUrl(String raw) {
    return raw
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\/', '/')
        .replaceAll('&amp;', '&');
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    final shortcode = extractShortcode(url);
    if (shortcode == null) {
      throw Exception('Format tautan Instagram tidak valid: $url');
    }

    String title = 'Instagram_$shortcode';
    String creator = 'Instagram_Creator';
    String? thumb;
    final streams = <MediaStreamItem>[];
    MediaType type = MediaType.video;

    // 1. Primary Strategy: Instagram Public Embed Captioned Scraper
    try {
      final embedUri = Uri.parse('https://www.instagram.com/p/$shortcode/embed/captioned/');
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      };
      if (cookieToken != null && cookieToken.isNotEmpty) {
        headers['Cookie'] = cookieToken.contains('=') ? cookieToken : 'sessionid=$cookieToken';
      }

      final resp = await http.get(embedUri, headers: headers).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final html = resp.body;

        // Extract Creator Username
        final authorMatch = RegExp(r'<a[^>]+class="[a-zA-Z0-9_ ]*UsernameText"[^>]*>([^<]+)</a>').firstMatch(html) ??
            RegExp(r'"username":"([^"]+)"').firstMatch(html);
        if (authorMatch != null) {
          creator = authorMatch.group(1)?.trim() ?? creator;
        }

        // Extract Caption / Title
        final captionMatch = RegExp(r'<div[^>]+class="Caption"[^>]*>(.*?)</div>', dotAll: true).firstMatch(html);
        if (captionMatch != null) {
          final cleanCaption = captionMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
          if (cleanCaption.isNotEmpty) {
            title = cleanCaption.length > 50 ? '${cleanCaption.substring(0, 47)}...' : cleanCaption;
          }
        }

        // Extract Video Stream(s)
        final videoMatches = RegExp(r'video_url\\?":\\?"([^"\\]+)\\?"').allMatches(html);
        final foundVideos = <String>{};
        for (final m in videoMatches) {
          final raw = m.group(1);
          if (raw != null && raw.isNotEmpty) {
            final cleaned = _cleanUrl(raw);
            if (cleaned.contains('.mp4') && !foundVideos.contains(cleaned)) {
              foundVideos.add(cleaned);
              streams.add(MediaStreamItem(
                url: cleaned,
                qualityLabel: 'Reel Video MP4 HD ${foundVideos.length > 1 ? "#${foundVideos.length}" : ""}'.trim(),
                extension: 'mp4',
              ));
            }
          }
        }

        // Extract Display Images / Carousel Photos
        final imgMatches = RegExp(r'display_url\\?":\\?"([^"\\]+)\\?"').allMatches(html);
        final foundImages = <String>{};
        for (final m in imgMatches) {
          final raw = m.group(1);
          if (raw != null && raw.isNotEmpty) {
            final cleaned = _cleanUrl(raw);
            thumb ??= cleaned;
            if (!foundImages.contains(cleaned) && streams.isEmpty) {
              foundImages.add(cleaned);
              streams.add(MediaStreamItem(
                url: cleaned,
                qualityLabel: 'Foto ${foundImages.length} (Original JPG)',
                extension: 'jpg',
              ));
            }
          }
        }

        // Check fallback direct image tag in embed
        if (streams.isEmpty) {
          final mediaImgMatch = RegExp(r'<img[^>]+class="EmbeddedMediaImage"[^>]+src="([^"]+)"').firstMatch(html);
          if (mediaImgMatch != null) {
            final imgUrl = _cleanUrl(mediaImgMatch.group(1)!);
            thumb ??= imgUrl;
            streams.add(MediaStreamItem(
              url: imgUrl,
              qualityLabel: 'Foto Instagram (Original)',
              extension: 'jpg',
            ));
          }
        }
      }
    } catch (_) {}

    // 2. Secondary Strategy: Authenticated AJAX / GraphQL API
    if (streams.isEmpty && cookieToken != null && cookieToken.isNotEmpty) {
      try {
        final endpoint = Uri.parse('https://www.instagram.com/p/$shortcode/?__a=1&__d=dis');
        final headers = {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
          'Accept': 'application/json',
          'Cookie': cookieToken.contains('=') ? cookieToken : 'sessionid=$cookieToken',
        };

        final resp = await http.get(endpoint, headers: headers).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final items = data['items'] as List?;
          if (items != null && items.isNotEmpty) {
            final item = items[0] as Map<String, dynamic>;
            creator = (item['user']?['username'] ?? creator).toString();
            final cap = (item['caption']?['text'] ?? '').toString();
            if (cap.isNotEmpty) {
              title = cap.length > 50 ? '${cap.substring(0, 47)}...' : cap;
            }

            // Check Carousel
            final carousel = item['carousel_media'] as List?;
            if (carousel != null && carousel.isNotEmpty) {
              for (int i = 0; i < carousel.length; i++) {
                final c = carousel[i] as Map<String, dynamic>;
                final vList = c['video_versions'] as List?;
                if (vList != null && vList.isNotEmpty) {
                  final vUrl = vList[0]['url'] as String;
                  streams.add(MediaStreamItem(
                    url: vUrl,
                    qualityLabel: 'Slide ${i + 1}/${carousel.length} (Video MP4)',
                    extension: 'mp4',
                  ));
                } else {
                  final imgList = c['image_versions2']?['candidates'] as List?;
                  if (imgList != null && imgList.isNotEmpty) {
                    final imgUrl = imgList[0]['url'] as String;
                    thumb ??= imgUrl;
                    streams.add(MediaStreamItem(
                      url: imgUrl,
                      qualityLabel: 'Slide ${i + 1}/${carousel.length} (Foto JPG)',
                      extension: 'jpg',
                    ));
                  }
                }
              }
            } else {
              // Single Video
              final vList = item['video_versions'] as List?;
              if (vList != null && vList.isNotEmpty) {
                final vUrl = vList[0]['url'] as String;
                streams.add(MediaStreamItem(
                  url: vUrl,
                  qualityLabel: 'Reel Video MP4 HD',
                  extension: 'mp4',
                ));
              }
            }
          }
        }
      } catch (_) {}
    }

    if (streams.isEmpty) {
      throw Exception(
        'Tidak dapat mengambil media dari tautan Instagram ini. Jika postingan berasal dari akun privat, silakan masukkan Cookie sessionid di Pengaturan.',
      );
    }

    final isMulti = streams.length > 1;
    return MediaMetadata(
      title: title,
      creatorName: creator,
      platform: MediaPlatform.instagram,
      mediaType: isMulti ? MediaType.album : type,
      workId: shortcode,
      thumbnailUrl: thumb,
      isMultiPage: isMulti,
      streams: streams,
    );
  }
}
