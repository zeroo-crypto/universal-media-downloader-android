import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  static StreamSubscription? _intentSub;

  /// Initializes listening to Android Share Sheet intents
  static void init({required Function(String url) onUrlReceived}) {
    // 1. Listen for intent while app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      for (final item in value) {
        if (item.path.isNotEmpty) {
          final extractedUrl = _extractUrlFromText(item.path);
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
          final extractedUrl = _extractUrlFromText(item.path);
          if (extractedUrl != null) {
            onUrlReceived(extractedUrl);
            break;
          }
        }
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  static String? _extractUrlFromText(String text) {
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  static void dispose() {
    _intentSub?.cancel();
  }
}
