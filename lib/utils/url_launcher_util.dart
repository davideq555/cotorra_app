import 'package:url_launcher/url_launcher.dart';

class UrlLauncherUtil {
  static String? extractYouTubeId(String url) {
    final regex = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})');
    final match = regex.firstMatch(url);
    if (match != null) return match.group(1);

    final regex2 = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})');
    final match2 = regex2.firstMatch(url);
    if (match2 != null) return match2.group(1);

    return null;
  }

  static String normalizeYouTubeUrl(String url) {
    final videoId = extractYouTubeId(url);
    if (videoId != null) {
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    return url;
  }

  static bool isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  static bool isGoogleDrive(String url) {
    return url.contains('drive.google.com') || url.contains('drive.usercontent.google.com');
  }

  static bool isGitHub(String url) {
    return url.contains('github.com');
  }

  static UrlType getUrlType(String url) {
    if (isYouTube(url)) return UrlType.youtube;
    if (isGoogleDrive(url)) return UrlType.googleDrive;
    if (isGitHub(url)) return UrlType.github;
    return UrlType.other;
  }

  static Future<bool> openUrl(String urlString) async {
    String normalizedUrl = urlString;

    if (isYouTube(urlString)) {
      normalizedUrl = normalizeYouTubeUrl(urlString);
    }

    final url = Uri.parse(normalizedUrl);

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    if (isYouTube(urlString)) {
      final videoId = extractYouTubeId(urlString);
      if (videoId != null) {
        final youtubeAppUrl = Uri.parse('vnd.youtube:$videoId');
        if (await canLaunchUrl(youtubeAppUrl)) {
          return await launchUrl(youtubeAppUrl);
        }
      }
    }

    return false;
  }
}

enum UrlType {
  youtube,
  googleDrive,
  github,
  other,
}
