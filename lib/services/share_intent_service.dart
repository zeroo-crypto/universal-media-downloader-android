import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:universal_media_downloader/core/utils/url_sanitizer.dart';

class ShareIntentService {
  static StreamSubscription? _intentSub;

  /// Initializes listening to Android Share Sheet intents
  static void init({required Function(String url) onUrlReceived}) {
    // 1. Listen for intent while app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      for (final item in value) {
        if (item.path.isNotEmpty) {
          final extractedUrl = extractUrl(item.path);
          if (extractedUrl != null) {
            onUrlReceived(extractedUrl);
            break;
          }
        }
      }
    }, onError: (_) {});

    // 2. Handle intent if app was closed and opened via Share Sheet
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      for (final item in value) {
        if (item.path.isNotEmpty) {
          final extractedUrl = extractUrl(item.path);
          if (extractedUrl != null) {
            onUrlReceived(extractedUrl);
            break;
          }
        }
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  /// Extracts the first HTTP/HTTPS URL from text and cleanly strips trailing punctuation
  /// (.,!?;:)>]) often appended by chat and social media share sheets.
  /// Delegates directly to pure Dart [UrlSanitizer.extractUrl].
  static String? extractUrl(String text) => UrlSanitizer.extractUrl(text);

  static void dispose() {
    _intentSub?.cancel();
  }
}
