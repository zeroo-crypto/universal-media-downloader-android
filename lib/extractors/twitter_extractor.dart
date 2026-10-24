import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class TwitterExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:twitter\.com|x\.com)\/(?:#!\/)?([a-zA-Z0-9_]+)\/status\/(\d+)',
    caseSensitive: false,
  );

  @override
  bool canHandle(String url) {
    return _urlRegex.hasMatch(url);
  }

  @override
  Future<MediaMetadata> extract(String url, {String? cookieToken}) async {
    final match = _urlRegex.firstMatch(url);
    if (match == null) {
      throw Exception('Invalid X / Twitter URL format (Format tautan X / Twitter tidak valid): $url');
    }

    final screenName = match.group(1) ?? 'i';
    final statusId = match.group(2) ?? '';
    if (statusId.isEmpty) {
      throw Exception('ID status X / Twitter tidak ditemukan pada URL.');
    }

    // 1. Cascade Approach: Primary FxTwitter API -> Secondary vxTwitter -> Tertiary Twimg Syndication
    MediaMetadata? result;
    Exception? lastError;

    // Strategy 1: FxTwitter API
    try {
      result = await _extractFromFxTwitter(screenName, statusId);
    } catch (e) {
      lastError = Exception(e.toString());
    }

    // Strategy 2: vxTwitter API
    if (result == null || result.streams.isEmpty) {
      try {
        result = await _extractFromVxTwitter(statusId);
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }

    // Strategy 3: Twimg Syndication Fallback
    if (result == null || result.streams.isEmpty) {
      try {
        result = await _extractFromTwimg(screenName, statusId);
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }

    if (result == null || result.streams.isEmpty) {
      throw lastError ??
          Exception(
              'Postingan X / Twitter tidak ditemukan (Tweet not found or deleted), atau tidak mengandung media foto/video.');
    }

    return result;
  }

  Future<MediaMetadata?> _extractFromFxTwitter(String screenName, String statusId) async {
    final uri = Uri.parse('https://api.fxtwitter.com/$screenName/status/$statusId');
    final resp = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; ZALLDownloader/2.1.2)',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 404) {
      throw Exception('Tweet not found or deleted (HTTP 404)');
    }
    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['code'] != 200 || json['tweet'] == null) return null;

    final tweet = json['tweet'] as Map<String, dynamic>;
    final text = (tweet['text'] ?? 'Twitter_$statusId').toString();
    final author = tweet['author'] as Map<String, dynamic>?;
    final creatorName = author?['name'] ?? author?['screen_name'] ?? screenName;

    final streams = <MediaStreamItem>[];
    String? thumb;
    MediaType mediaType = MediaType.image;

    // Check media object
    final media = tweet['media'] as Map<String, dynamic>?;
    if (media != null) {
      // Videos
      final videos = media['videos'] as List?;
      if (videos != null && videos.isNotEmpty) {
        mediaType = MediaType.video;
        for (int i = 0; i < videos.length; i++) {
          final v = videos[i] as Map<String, dynamic>;
          final vUrl = v['url'] as String?;
          thumb ??= v['thumbnail_url'] as String?;
          if (vUrl != null && vUrl.isNotEmpty) {
            streams.add(MediaStreamItem(
              url: vUrl,
              qualityLabel: 'Video MP4 HD ${videos.length > 1 ? "#${i + 1}" : ""}'.trim(),
              extension: 'mp4',
            ));
          }
        }
      }

      // Photos
      final photos = media['photos'] as List?;
      if (photos != null && photos.isNotEmpty) {
        if (streams.isEmpty) mediaType = MediaType.image;
        for (int i = 0; i < photos.length; i++) {
          final p = photos[i] as Map<String, dynamic>;
          var pUrl = (p['url'] as String?) ?? '';
          if (pUrl.isNotEmpty) {
            thumb ??= pUrl;
            final ext = pUrl.split('.').last.split('?').first;
            streams.add(MediaStreamItem(
              url: pUrl,
              qualityLabel: 'Foto ${i + 1}/${photos.length} (Original)',
              extension: ext.isNotEmpty ? ext : 'jpg',
            ));
          }
        }
      }
    }

    // Check media_extended fallback array
    final mediaExt = tweet['media_extended'] as List?;
    if (streams.isEmpty && mediaExt != null && mediaExt.isNotEmpty) {
      for (int i = 0; i < mediaExt.length; i++) {
        final m = mediaExt[i] as Map<String, dynamic>;
        final mType = (m['type'] ?? 'image').toString();
        final mUrl = (m['url'] ?? '').toString();
        thumb ??= (m['thumbnail_url'] ?? mUrl).toString();

        if (mUrl.isNotEmpty) {
          if (mType.contains('video') || mType.contains('gif')) {
            mediaType = MediaType.video;
            streams.add(MediaStreamItem(
              url: mUrl,
              qualityLabel: 'Video MP4 HD',
              extension: 'mp4',
            ));
          } else {
            final ext = mUrl.split('.').last.split('?').first;
            streams.add(MediaStreamItem(
              url: mUrl,
              qualityLabel: 'Foto ${i + 1}/${mediaExt.length} (Original)',
              extension: ext.isNotEmpty ? ext : 'jpg',
            ));
          }
        }
      }
    }

    if (streams.isEmpty) return null;

    final isMulti = streams.length > 1;
    return MediaMetadata(
      title: text.length > 60 ? '${text.substring(0, 57)}...' : text,
      creatorName: creatorName,
      platform: MediaPlatform.twitter,
      mediaType: isMulti ? MediaType.album : mediaType,
      workId: statusId,
      thumbnailUrl: thumb,
      isMultiPage: isMulti,
      streams: streams,
    );
  }

  Future<MediaMetadata?> _extractFromVxTwitter(String statusId) async {
    final uri = Uri.parse('https://api.vxtwitter.com/Twitter/status/$statusId');
    final resp = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; ZALLDownloader/2.1.2)',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 404) {
      throw Exception('Tweet not found or deleted (HTTP 404)');
    }
    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (json['text'] ?? 'Twitter_$statusId').toString();
    final creatorName = (json['user_name'] ?? json['user_screen_name'] ?? 'Twitter_User').toString();
    final mediaExt = json['media_extended'] as List?;

    if (mediaExt == null || mediaExt.isEmpty) return null;

    final streams = <MediaStreamItem>[];
    String? thumb;
    MediaType mediaType = MediaType.image;

    for (int i = 0; i < mediaExt.length; i++) {
      final m = mediaExt[i] as Map<String, dynamic>;
      final mType = (m['type'] ?? 'image').toString();
      final mUrl = (m['url'] ?? '').toString();
      thumb ??= (m['thumbnail_url'] ?? mUrl).toString();

      if (mUrl.isNotEmpty) {
        if (mType.contains('video') || mType.contains('gif')) {
          mediaType = MediaType.video;
          streams.add(MediaStreamItem(
            url: mUrl,
            qualityLabel: 'Video MP4 HD',
            extension: 'mp4',
          ));
        } else {
          final ext = mUrl.split('.').last.split('?').first;
          streams.add(MediaStreamItem(
            url: mUrl,
            qualityLabel: 'Foto ${i + 1}/${mediaExt.length} (Original)',
            extension: ext.isNotEmpty ? ext : 'jpg',
          ));
        }
      }
    }

    if (streams.isEmpty) return null;

    final isMulti = streams.length > 1;
    return MediaMetadata(
      title: text.length > 60 ? '${text.substring(0, 57)}...' : text,
      creatorName: creatorName,
      platform: MediaPlatform.twitter,
      mediaType: isMulti ? MediaType.album : mediaType,
      workId: statusId,
      thumbnailUrl: thumb,
      isMultiPage: isMulti,
      streams: streams,
    );
  }

  Future<MediaMetadata?> _extractFromTwimg(String screenName, String statusId) async {
    final syndicationUrl = Uri.parse(
        'https://cdn.syndication.twimg.com/tweet-result?id=$statusId&lang=en');

    final resp = await http.get(syndicationUrl, headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    }).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 404) {
      throw Exception('Tweet not found or deleted (HTTP 404)');
    }
    if (resp.statusCode != 200) return null;

    final tweet = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (tweet['text'] ?? 'Tweet_$statusId').toString();
    final user = tweet['user'] as Map<String, dynamic>?;
    final creatorName = user?['screen_name'] ?? user?['name'] ?? screenName;

    final mediaList = (tweet['mediaDetails'] as List?) ?? [];
    if (mediaList.isEmpty) return null;

    final streams = <MediaStreamItem>[];
    MediaType type = MediaType.image;
    String? thumb;

    for (int i = 0; i < mediaList.length; i++) {
      final m = mediaList[i] as Map<String, dynamic>;
      final mType = m['type'] as String? ?? 'photo';

      if (mType == 'video' || mType == 'animated_gif') {
        type = MediaType.video;
        thumb = m['media_url_https'];

        final variants = (m['video_info']?['variants'] as List?) ?? [];
        String? bestVideoUrl;
        int highestBitrate = -1;

        for (final v in variants) {
          final contentType = v['content_type'] as String? ?? '';
          final bitrate = v['bitrate'] as int? ?? 0;
          if (contentType.contains('mp4') && bitrate >= highestBitrate) {
            highestBitrate = bitrate;
            bestVideoUrl = v['url'] as String?;
          }
        }

        if (bestVideoUrl != null) {
          streams.add(MediaStreamItem(
            url: bestVideoUrl,
            qualityLabel: 'Video MP4 HD',
            extension: 'mp4',
          ));
        }
      } else {
        var photoUrl = (m['media_url_https'] as String?) ?? '';
        if (photoUrl.isNotEmpty) {
          final cleanUrl = photoUrl.split('?').first;
          final origUrl = '$cleanUrl?name=orig';
          thumb ??= origUrl;
          final ext = cleanUrl.split('.').last;

          streams.add(MediaStreamItem(
            url: origUrl,
            qualityLabel: 'Foto ${i + 1}/${mediaList.length} (Original)',
            extension: ext,
          ));
        }
      }
    }

    if (streams.isEmpty) return null;

    final isMulti = streams.length > 1;
    return MediaMetadata(
      title: text.length > 60 ? '${text.substring(0, 57)}...' : text,
      creatorName: creatorName,
      platform: MediaPlatform.twitter,
      mediaType: isMulti ? MediaType.album : type,
      workId: statusId,
      thumbnailUrl: thumb,
      isMultiPage: isMulti,
      streams: streams,
    );
  }
}
