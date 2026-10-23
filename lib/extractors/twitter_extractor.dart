import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/platforms.dart';
import 'base_extractor.dart';

class TwitterExtractor implements BaseExtractor {
  static final RegExp _urlRegex = RegExp(
    r'(?:twitter\.com|x\.com)\/([a-zA-Z0-9_]+)\/status\/(\d+)',
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
      throw Exception('Format URL Twitter/X tidak valid: $url');
    }

    final creatorScreenName = match.group(1) ?? 'Twitter_User';
    final statusId = match.group(2) ?? 'Status';

    // 1. Fetch Tweet data via syndication API (No Auth / High Reliability)
    final syndicationUrl = Uri.parse(
        'https://cdn.syndication.twimg.com/tweet-result?id=$statusId&lang=en');

    final resp = await http.get(syndicationUrl, headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    });

    if (resp.statusCode != 200) {
      throw Exception('Tweet tidak ditemukan atau dibatasi (HTTP ${resp.statusCode}).');
    }

    final tweet = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (tweet['text'] ?? 'Tweet_$statusId').toString();
    final user = tweet['user'] as Map<String, dynamic>?;
    final creatorName = user?['screen_name'] ?? creatorScreenName;

    final mediaList = (tweet['mediaDetails'] as List?) ?? [];
    final streams = <MediaStreamItem>[];
    MediaType type = MediaType.image;
    String? thumb;

    if (mediaList.isNotEmpty) {
      for (int i = 0; i < mediaList.length; i++) {
        final m = mediaList[i] as Map<String, dynamic>;
        final mType = m['type'] as String? ?? 'photo';

        if (mType == 'video' || mType == 'animated_gif') {
          type = MediaType.video;
          thumb = m['media_url_https'];

          // Extract highest bitrate MP4 variant
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
              qualityLabel: 'MP4 Video (${highestBitrate > 0 ? "${(highestBitrate / 1000).round()} kbps" : "HD"})',
              extension: 'mp4',
            ));
          }
        } else {
          // Photos: append ?name=orig for original master resolution
          var photoUrl = (m['media_url_https'] as String?) ?? '';
          if (photoUrl.isNotEmpty) {
            final cleanUrl = photoUrl.split('?').first;
            final origUrl = '$cleanUrl?name=orig';
            thumb ??= origUrl;
            final ext = cleanUrl.split('.').last;

            streams.add(MediaStreamItem(
              url: origUrl,
              qualityLabel: 'Photo ${i + 1}/${mediaList.length} (Original $ext)',
              extension: ext,
            ));
          }
        }
      }
    }

    final isMulti = streams.length > 1;

    return MediaMetadata(
      title: text.length > 50 ? '${text.substring(0, 47)}...' : text,
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
