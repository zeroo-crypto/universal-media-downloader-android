/// Pure Dart utility for extracting and sanitizing URLs from unstructured text.
///
/// Strips trailing punctuation, quotes, brackets, and braces commonly appended
/// by messaging platforms, markdown links, or user typing in share sheets.
class UrlSanitizer {
  /// Extracts the first HTTP/HTTPS URL from text and cleanly strips trailing punctuation
  /// (.,!?;:)>]) often appended by chat and social media share sheets.
  static String? extractUrl(String text) {
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    final match = urlRegex.firstMatch(text);
    if (match == null) return null;
    var rawUrl = match.group(0)!;
    // Strip trailing sentence punctuation, quotes, and braces
    rawUrl = rawUrl.replaceAll(RegExp(r"""[\.,!?;:\)\]>"'”’}]+$"""), '');
    return rawUrl.isNotEmpty ? rawUrl.trim() : null;
  }
}
