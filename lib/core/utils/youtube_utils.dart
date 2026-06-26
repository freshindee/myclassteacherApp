/// Shared helpers for YouTube URLs and embeds.
class YoutubeUtils {
  YoutubeUtils._();

  /// Extracts YouTube video ID from various URL formats:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  static String? getVideoId(String url) {
    try {
      String cleanUrl = url.trim();
      if (cleanUrl.startsWith('@')) cleanUrl = cleanUrl.substring(1);
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null) return null;
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'] ?? (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parses start time from YouTube URL query "t" (e.g. t=3s, t=90, t=1m30s).
  /// Returns start time in seconds, or null if missing/invalid.
  static int? getStartTimeSeconds(String url) {
    try {
      final uri = Uri.tryParse(url.trim());
      if (uri == null) return null;
      final t = uri.queryParameters['t']?.trim();
      if (t == null || t.isEmpty) return null;
      return _parseYouTubeTimeString(t);
    } catch (_) {
      return null;
    }
  }

  static int? _parseYouTubeTimeString(String t) {
    final s = t.toLowerCase();
    if (s.isEmpty) return null;
    // Pure number = seconds (e.g. 90)
    final onlyDigits = int.tryParse(s);
    if (onlyDigits != null) return onlyDigits;
    // Ends with 's' only (e.g. 3s, 90s)
    if (s.endsWith('s') && s.length > 1) {
      final num = int.tryParse(s.substring(0, s.length - 1));
      if (num != null) return num;
    }
    // 1h2m3s or 2m30s or 1m30s style
    int total = 0;
    int i = 0;
    while (i < s.length) {
      int? num;
      int start = i;
      while (i < s.length && _isDigit(s[i])) i++;
      if (i > start) num = int.tryParse(s.substring(start, i));
      if (num == null) return null;
      if (i < s.length) {
        final unit = s[i];
        i++;
        if (unit == 'h') total += num * 3600;
        else if (unit == 'm') total += num * 60;
        else if (unit == 's') total += num;
        else return null;
      } else {
        total += num; // trailing number = seconds
        break;
      }
    }
    return total;
  }

  static bool _isDigit(String c) => c.length == 1 && c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

  /// Builds the YouTube embed page URL. Loading this directly in a WebView avoids
  /// Error 153 (configuration error) that can occur when embedding via iframe from a data: origin.
  static String embedUrl(String videoId, {bool autoplay = true, int? startSeconds}) {
    final autoplayParam = autoplay ? '1' : '0';
    final startParam = startSeconds != null && startSeconds > 0 ? '&start=$startSeconds' : '';
    return 'https://www.youtube.com/embed/$videoId?autoplay=$autoplayParam&playsinline=1$startParam';
  }

  /// Builds HTML document that embeds YouTube via iframe (for WebView).
  /// [videoId] must be the raw ID (e.g. dQw4w9WgXcQ).
  /// [startSeconds] optional; use with URLs that have t= (e.g. t=3s).
  static String embedHtml(String videoId, {bool autoplay = true, int? startSeconds}) {
    final autoplayParam = autoplay ? '1' : '0';
    final startParam = startSeconds != null && startSeconds > 0 ? '&start=$startSeconds' : '';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    .video-container {
      position: absolute;
      top: 0; left: 0; right: 0; bottom: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .video-container iframe {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <div class="video-container">
    <iframe
      src="https://www.youtube.com/embed/$videoId?autoplay=$autoplayParam&playsinline=1$startParam"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen>
    </iframe>
  </div>
</body>
</html>''';
  }
}
