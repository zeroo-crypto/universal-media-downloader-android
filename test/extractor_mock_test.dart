import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:universal_media_downloader/core/constants/platforms.dart';
import 'package:universal_media_downloader/extractors/youtube_extractor.dart';
import 'package:universal_media_downloader/extractors/pixiv_extractor.dart';
import 'package:universal_media_downloader/extractors/twitter_extractor.dart';
import 'package:universal_media_downloader/extractors/tiktok_extractor.dart';
import 'package:universal_media_downloader/extractors/instagram_extractor.dart';
import 'package:universal_media_downloader/extractors/pinterest_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PixivExtractor Mock Payload Tests', () {
    test('Tier 1: Parses single illustration artwork JSON payload correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/ajax/illust/105356665') {
          return http.Response(
            jsonEncode({
              'error': false,
              'message': '',
              'body': {
                'illustId': '105356665',
                'illustTitle': 'Starlight Symphony',
                'userName': 'HoshinoArtist',
                'illustType': 0,
                'pageCount': 1,
                'urls': {
                  'regular': 'https://i.pximg.net/img-master/img/2026/10/23/00/00/00/105356665_p0_master1200.jpg',
                  'original': 'https://i.pximg.net/img-original/img/2026/10/23/00/00/00/105356665_p0.png',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = PixivExtractor();
        final metadata = await extractor.extract('https://www.pixiv.net/artworks/105356665');

        expect(metadata.title, equals('Starlight Symphony'));
        expect(metadata.creatorName, equals('HoshinoArtist'));
        expect(metadata.platform, equals(MediaPlatform.pixiv));
        expect(metadata.mediaType, equals(MediaType.image));
        expect(metadata.workId, equals('105356665'));
        expect(metadata.isMultiPage, isFalse);
        expect(metadata.isUgoira, isFalse);
        expect(metadata.streams.length, equals(1));
        expect(metadata.streams[0].url, contains('105356665_p0.png'));
        expect(metadata.streams[0].extension, equals('png'));
        expect(metadata.streams[0].headers['Referer'], equals('https://www.pixiv.net/'));
      }, () => mockClient);
    });

    test('Tier 1: Parses Ugoira animation metadata JSON with frame delays', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/ajax/illust/99887766') {
          return http.Response(
            jsonEncode({
              'error': false,
              'body': {
                'illustId': '99887766',
                'illustTitle': 'Running Cat Animation',
                'userName': 'AnimatorCat',
                'illustType': 2, // Ugoira type
                'pageCount': 1,
                'urls': {
                  'regular': 'https://i.pximg.net/img-master/thumb.jpg',
                },
              },
            }),
            200,
          );
        } else if (request.url.path == '/ajax/illust/99887766/ugoira_meta') {
          return http.Response(
            jsonEncode({
              'error': false,
              'body': {
                'src': 'https://i.pximg.net/img-zip-ugoira/99887766_ugoira1920x1080.zip',
                'originalSrc': 'https://i.pximg.net/img-zip-ugoira/99887766_ugoira0.zip',
                'mime_type': 'image/vnd.pixiv.ugoira+zip',
                'frames': [
                  {'file': '000000.jpg', 'delay': 125},
                  {'file': '000001.jpg', 'delay': 125},
                  {'file': '000002.jpg', 'delay': 125},
                  {'file': '000003.jpg', 'delay': 125},
                ],
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = PixivExtractor();
        final metadata = await extractor.extract('https://www.pixiv.net/artworks/99887766');

        expect(metadata.title, equals('Running Cat Animation'));
        expect(metadata.creatorName, equals('AnimatorCat'));
        expect(metadata.mediaType, equals(MediaType.ugoira));
        expect(metadata.isUgoira, isTrue);
        expect(metadata.ugoiraFrames, isNotNull);
        expect(metadata.ugoiraFrames!.length, equals(4));
        expect(metadata.ugoiraFrames![0]['delay'], equals(125));
        expect(metadata.streams.length, equals(1));
        expect(metadata.streams[0].url, contains('99887766_ugoira0.zip'));
        expect(metadata.streams[0].extension, equals('mp4')); // Target assembled extension
      }, () => mockClient);
    });

    test('Tier 2: Parses multi-page manga carousel album (pageCount > 1)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/ajax/illust/55443322') {
          return http.Response(
            jsonEncode({
              'error': false,
              'body': {
                'illustId': '55443322',
                'illustTitle': 'Short Comic Chapter 1',
                'userName': 'MangakaSensei',
                'illustType': 1,
                'pageCount': 3,
                'urls': {'regular': 'https://i.pximg.net/thumb.jpg'},
              },
            }),
            200,
          );
        } else if (request.url.path == '/ajax/illust/55443322/pages') {
          return http.Response(
            jsonEncode({
              'error': false,
              'body': [
                {'urls': {'original': 'https://i.pximg.net/55443322_p0.jpg'}},
                {'urls': {'original': 'https://i.pximg.net/55443322_p1.jpg'}},
                {'urls': {'original': 'https://i.pximg.net/55443322_p2.png'}},
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = PixivExtractor();
        final metadata = await extractor.extract('https://www.pixiv.net/artworks/55443322');

        expect(metadata.title, equals('Short Comic Chapter 1'));
        expect(metadata.creatorName, equals('MangakaSensei'));
        expect(metadata.mediaType, equals(MediaType.album));
        expect(metadata.isMultiPage, isTrue);
        expect(metadata.streams.length, equals(3));
        expect(metadata.streams[0].url, contains('55443322_p0.jpg'));
        expect(metadata.streams[2].url, contains('55443322_p2.png'));
        expect(metadata.streams[2].extension, equals('png'));
      }, () => mockClient);
    });

    test('Tier 2: Handles HTTP 404 deleted artwork error with descriptive message', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": true, "message": "Artwork deleted"}', 404);
      });

      await http.runWithClient(() async {
        final extractor = PixivExtractor();
        try {
          await extractor.extract('https://www.pixiv.net/artworks/40404040');
          expect(false, isTrue, reason: 'Expected exception on 404');
        } catch (e) {
          expect(e.toString(), contains('not found'));
        }
      }, () => mockClient);
    });

    test('Tier 2: Handles HTTP 403 cookie restriction directing user to PHPSESSID settings', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      await http.runWithClient(() async {
        final extractor = PixivExtractor();
        try {
          await extractor.extract('https://www.pixiv.net/artworks/18181818');
          expect(false, isTrue, reason: 'Expected exception on 403');
        } catch (e) {
          expect(e.toString(), contains('PHPSESSID'));
        }
      }, () => mockClient);
    });
  });

  group('YouTubeExtractor Mock Payload Tests', () {
    test('Tier 1: Parses OEMBED metadata and generates tiered stream priorities', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('youtube.com') && request.url.path.contains('/oembed')) {
          return http.Response(
            jsonEncode({
              'title': 'Flutter 3.24 Release Overview',
              'author_name': 'Google for Developers',
              'thumbnail_url': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
            }),
            200,
          );
        }
        return http.Response('OK', 200);
      });

      await http.runWithClient(() async {
        final extractor = YouTubeExtractor();
        final metadata = await extractor.extract('https://www.youtube.com/watch?v=dQw4w9WgXcQ');

        expect(metadata.title, equals('Flutter 3.24 Release Overview'));
        expect(metadata.creatorName, equals('Google for Developers'));
        expect(metadata.platform, equals(MediaPlatform.youtube));
        expect(metadata.mediaType, equals(MediaType.video));
        expect(metadata.workId, equals('dQw4w9WgXcQ'));
        expect(metadata.streams.length, equals(3));
        expect(metadata.streams[0].qualityLabel, contains('1080p'));
        expect(metadata.streams[1].qualityLabel, contains('720p'));
        expect(metadata.streams[2].qualityLabel, contains('Audio'));
        expect(metadata.streams[2].isAudioOnly, isTrue);
      }, () => mockClient);
    });

    test('Tier 2: Rejects invalid YouTube URL formats with descriptive exception', () async {
      final extractor = YouTubeExtractor();
      try {
        await extractor.extract('https://youtube.com/invalid_path');
        expect(false, isTrue, reason: 'Expected exception on invalid url');
      } catch (e) {
        expect(e.toString(), contains('Invalid'));
      }
    });
  });

  group('TwitterExtractor Mock Payload Tests', () {
    test('Tier 1: Selects highest bitrate MP4 variant from video tweet payload', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('syndication.twimg.com')) {
          return http.Response(
            jsonEncode({
              'id_str': '1234567890123456789',
              'text': 'Rocket launch 4K demo',
              'user': {'screen_name': 'SpaceX'},
              'mediaDetails': [
                {
                  'type': 'video',
                  'media_url_https': 'https://pbs.twimg.com/thumb.jpg',
                  'video_info': {
                    'variants': [
                      {'content_type': 'video/mp4', 'bitrate': 288000, 'url': 'https://video.twimg.com/288k.mp4'},
                      {'content_type': 'video/mp4', 'bitrate': 2176000, 'url': 'https://video.twimg.com/2176k.mp4'},
                      {'content_type': 'video/mp4', 'bitrate': 832000, 'url': 'https://video.twimg.com/832k.mp4'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = TwitterExtractor();
        final metadata = await extractor.extract('https://twitter.com/SpaceX/status/1234567890123456789');

        expect(metadata.title, equals('Rocket launch 4K demo'));
        expect(metadata.creatorName, equals('SpaceX'));
        expect(metadata.mediaType, equals(MediaType.video));
        expect(metadata.streams.length, equals(1));
        // Highest bitrate (2176k) must be selected
        expect(metadata.streams[0].url, equals('https://video.twimg.com/2176k.mp4'));
        expect(metadata.streams[0].extension, equals('mp4'));
      }, () => mockClient);
    });

    test('Tier 1: Parses multi-photo tweet with original master quality (?name=orig)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('syndication.twimg.com')) {
          return http.Response(
            jsonEncode({
              'id_str': '9876543210987654321',
              'text': 'Photo gallery from Tokyo',
              'user': {'screen_name': 'TravelerTokyo'},
              'mediaDetails': [
                {'type': 'photo', 'media_url_https': 'https://pbs.twimg.com/media/photo1.jpg'},
                {'type': 'photo', 'media_url_https': 'https://pbs.twimg.com/media/photo2.png'},
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = TwitterExtractor();
        final metadata = await extractor.extract('https://x.com/TravelerTokyo/status/9876543210987654321');

        expect(metadata.creatorName, equals('TravelerTokyo'));
        expect(metadata.isMultiPage, isTrue);
        expect(metadata.mediaType, equals(MediaType.album));
        expect(metadata.streams.length, equals(2));
        expect(metadata.streams[0].url, equals('https://pbs.twimg.com/media/photo1.jpg?name=orig'));
        expect(metadata.streams[1].url, equals('https://pbs.twimg.com/media/photo2.png?name=orig'));
        expect(metadata.streams[1].extension, equals('png'));
      }, () => mockClient);
    });

    test('Tier 2: Handles deleted or restricted tweet (HTTP 404) gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Tweet deleted', 404);
      });

      await http.runWithClient(() async {
        final extractor = TwitterExtractor();
        try {
          await extractor.extract('https://x.com/user/status/0000000000000000000');
          expect(false, isTrue, reason: 'Expected exception');
        } catch (e) {
          expect(e.toString(), contains('not found'));
        }
      }, () => mockClient);
    });
  });

  group('TikTokExtractor Mock Payload Tests', () {
    test('Tier 1: Parses TikWM API JSON payload for watermark-free HD stream', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('tikwm.com')) {
          return http.Response(
            jsonEncode({
              'code': 0,
              'msg': 'success',
              'data': {
                'id': '7123456789012345678',
                'title': 'Viral Dance Trend 2026',
                'play': 'https://www.tikwm.com/video/media/7123456789012345678.mp4',
                'cover': 'https://www.tikwm.com/video/cover/7123456789012345678.jpg',
                'author': {'unique_id': 'dance_pro'},
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = TikTokExtractor();
        final metadata = await extractor.extract('https://www.tiktok.com/@dance_pro/video/7123456789012345678');

        expect(metadata.title, equals('Viral Dance Trend 2026'));
        expect(metadata.creatorName, equals('dance_pro'));
        expect(metadata.platform, equals(MediaPlatform.tiktok));
        expect(metadata.mediaType, equals(MediaType.video));
        expect(metadata.workId, equals('7123456789012345678'));
        expect(metadata.streams.length, equals(1));
        expect(metadata.streams[0].url, contains('7123456789012345678.mp4'));
        expect(metadata.streams[0].extension, equals('mp4'));
      }, () => mockClient);
    });
  });

  group('InstagramExtractor Mock Payload Tests', () {
    test('Tier 1: Parses Instagram Reel JSON with video versions', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host.contains('instagram.com')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'code': 'C-abc987xyz',
                  'user': {'username': 'creative_director'},
                  'caption': {'text': 'Behind the scenes at the studio'},
                  'video_versions': [
                    {'url': 'https://scontent.cdninstagram.com/v/t50/reel1.mp4', 'width': 1080},
                    {'url': 'https://scontent.cdninstagram.com/v/t50/reel2.mp4', 'width': 720},
                  ],
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final extractor = InstagramExtractor();
        final metadata = await extractor.extract('https://www.instagram.com/reel/C-abc987xyz/');

        expect(metadata.creatorName, equals('creative_director'));
        expect(metadata.title, equals('Behind the scenes at the studio'));
        expect(metadata.mediaType, equals(MediaType.video));
        expect(metadata.streams.length, equals(1));
        expect(metadata.streams[0].url, contains('reel1.mp4'));
        expect(metadata.streams[0].extension, equals('mp4'));
      }, () => mockClient);
    });

    test('Tier 2: Fallback handling when Instagram API returns non-200 or empty data', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Login Required', 401);
      });

      await http.runWithClient(() async {
        final extractor = InstagramExtractor();
        final metadata = await extractor.extract('https://www.instagram.com/p/C-xyz123abc/');

        expect(metadata.workId, equals('C-xyz123abc'));
        expect(metadata.streams.length, equals(1));
        expect(metadata.streams[0].url, contains('C-xyz123abc'));
      }, () => mockClient);
    });
  });

  group('PinterestExtractor Mock Payload Tests', () {
    test('Tier 1: Parses HTML with JSON-LD schema and upgrades image to /originals/', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
              {
                "@context": "http://schema.org",
                "@type": "ImageObject",
                "headline": "Modern Minimalist Interior",
                "creator": {"name": "ArchDesign"},
                "image": "https://i.pinimg.com/736x/ab/cd/ef/abcdef123456.jpg"
              }
              </script>
            </head>
            <body></body>
          </html>
          ''',
          200,
        );
      });

      await http.runWithClient(() async {
        final extractor = PinterestExtractor();
        final metadata = await extractor.extract('https://www.pinterest.com/pin/1234567890/');

        expect(metadata.title, equals('Modern Minimalist Interior'));
        expect(metadata.creatorName, equals('ArchDesign'));
        expect(metadata.mediaType, equals(MediaType.image));
        expect(metadata.streams.length, equals(1));
        // Must upgrade /736x/ to /originals/
        expect(metadata.streams[0].url, equals('https://i.pinimg.com/originals/ab/cd/ef/abcdef123456.jpg'));
        expect(metadata.streams[0].extension, equals('jpg'));
      }, () => mockClient);
    });

    test('Tier 1: Detects video stream (v.pinimg.com) and board metadata in HTML', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''
          <!DOCTYPE html>
          <html>
            <body>
              <script>
                "board": {"name": "Living Room Inspo", "url": "/user/living-room/"}
              </script>
              <video src="https://v.pinimg.com/videos/mc/720p/1234567890.mp4"></video>
            </body>
          </html>
          ''',
          200,
        );
      });

      await http.runWithClient(() async {
        final extractor = PinterestExtractor();
        final metadata = await extractor.extract('https://www.pinterest.com/pin/1234567890/');

        expect(metadata.mediaType, equals(MediaType.video));
        expect(metadata.pinterestBoardName, equals('Living Room Inspo'));
        expect(metadata.isPinterestCreatedPin, isFalse);
        expect(metadata.streams[0].url, contains('v.pinimg.com/videos/mc/720p/1234567890.mp4'));
        expect(metadata.streams[0].extension, equals('mp4'));
      }, () => mockClient);
    });
  });
}
