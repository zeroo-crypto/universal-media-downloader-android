enum MediaPlatform {
  youtube,
  pixiv,
  pinterest,
  twitter,
  instagram,
  tiktok,
  facebook,
  spotify,
  telegram,
  googledrive,
  generic;

  String get displayName {
    switch (this) {
      case MediaPlatform.youtube:
        return 'YouTube';
      case MediaPlatform.pixiv:
        return 'Pixiv';
      case MediaPlatform.pinterest:
        return 'Pinterest';
      case MediaPlatform.twitter:
        return 'Twitter/X';
      case MediaPlatform.instagram:
        return 'Instagram';
      case MediaPlatform.tiktok:
        return 'TikTok';
      case MediaPlatform.facebook:
        return 'Facebook';
      case MediaPlatform.spotify:
        return 'Spotify';
      case MediaPlatform.telegram:
        return 'Telegram';
      case MediaPlatform.googledrive:
        return 'Google Drive';
      case MediaPlatform.generic:
        return 'Direct URL';
    }
  }

  static MediaPlatform detect(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return MediaPlatform.youtube;
    } else if (lower.contains('pixiv.net') || lower.contains('pximg.net')) {
      return MediaPlatform.pixiv;
    } else if (lower.contains('pinterest.') || lower.contains('pin.it')) {
      return MediaPlatform.pinterest;
    } else if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return MediaPlatform.twitter;
    } else if (lower.contains('instagram.com')) {
      return MediaPlatform.instagram;
    } else if (lower.contains('tiktok.com')) {
      return MediaPlatform.tiktok;
    } else if (lower.contains('facebook.com') || lower.contains('fb.watch')) {
      return MediaPlatform.facebook;
    } else if (lower.contains('spotify.com')) {
      return MediaPlatform.spotify;
    } else if (lower.contains('t.me/')) {
      return MediaPlatform.telegram;
    } else if (lower.contains('drive.google.com')) {
      return MediaPlatform.googledrive;
    }
    return MediaPlatform.generic;
  }
}

enum MediaType {
  image,
  video,
  audio,
  album,
  ugoira;

  String get label {
    switch (this) {
      case MediaType.image:
        return 'Image';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return 'Audio';
      case MediaType.album:
        return 'Album / Multi-Page';
      case MediaType.ugoira:
        return 'Pixiv Ugoira Animation';
    }
  }
}
