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
    return url.contains('drive.google.com') ||
        url.contains('drive.usercontent.google.com');
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

  static String normalizeGoogleDriveUrl(String url) {
    final fileIdMatch = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (fileIdMatch != null) {
      return 'https://drive.google.com/file/d/${fileIdMatch.group(1)}/preview';
    }

    final openIdMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (openIdMatch != null) {
      return 'https://drive.google.com/file/d/${openIdMatch.group(1)}/preview';
    }

    final ucMatch = RegExp(r'/uc\?.*id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (ucMatch != null) {
      return 'https://drive.google.com/file/d/${ucMatch.group(1)}/preview';
    }

    return url;
  }

  static Future<bool> openUrl(String urlString) async {
    String urlToOpen = urlString;

    if (isYouTube(urlString)) {
      urlToOpen = normalizeYouTubeUrl(urlString);
    } else if (isGoogleDrive(urlString)) {
      urlToOpen = normalizeGoogleDriveUrl(urlString);
    }

    final uri = Uri.parse(urlToOpen);

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening URL: $e');
      return false;
    }
  }

  /// Abre la app de correo del usuario (Android).
  ///
  /// Estrategia en capas:
  /// 1. Gmail: la app registra un intent filter para mail.google.com, así
  ///    que abrir ese link con externalApplication lanza la app de Gmail
  ///    directo a la bandeja de entrada (si está instalada).
  /// 2. Fallback: mailto: abre la app de email por defecto del sistema
  ///    (Outlook, Yahoo, el cliente que el usuario tenga configurado).
  ///
  /// NOTA: url_launcher NO soporta la sintaxis intent://, por eso se usa
  /// el deep link de Gmail. Si Gmail no está instalado y el navegador
  /// intercepta el link, el usuario cae en Gmail web — igual puede leer
  /// su correo ahí.
  ///
  /// Retorna true si logró abrir alguna, false si ninguna funcionó.
  static Future<bool> openMailApp() async {
    final gmailInbox = Uri.parse('https://mail.google.com/mail/u/0/#inbox');
    try {
      if (await launchUrl(gmailInbox, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Gmail no disponible, probar con el cliente de mail por defecto.
    }

    final mailto = Uri.parse('mailto:');
    try {
      if (await launchUrl(mailto, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Sin app de mail disponible.
    }

    return false;
  }
}

enum UrlType { youtube, googleDrive, github, other }
