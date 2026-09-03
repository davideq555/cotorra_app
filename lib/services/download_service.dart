import 'dart:convert';
import 'dart:io';

import 'package:cotorra_app/config/env.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resultado de una descarga: bytes + nombre de archivo sugerido.
class DownloadedFile {
  final Uint8List bytes;
  final String fileName;

  const DownloadedFile({required this.bytes, required this.fileName});
}

/// Descarga documentos del backend y los guarda en la carpeta pública
/// de Descargas del dispositivo vía el canal nativo `cotorra/downloads`
/// (MainActivity.java usa MediaStore; sin plugins de terceros).
///
/// Usa GET /documentos/{id}/descargar — que además incrementa el
/// contador de descargas en el servidor.
class DownloadService {
  final Dio _dio = Dio();

  static const _channel = MethodChannel('cotorra/downloads');

  /// Descarga el archivo del documento y lo guarda en Downloads.
  /// Retorna el nombre con el que se guardó.
  /// Lanza [DioException] ante errores de red/HTTP.
  Future<String> downloadToDownloads(
    int documentoId,
    String token, {
    required String fallbackName,
  }) async {
    final url = '${Env.baseUrl}/documentos/$documentoId/descargar';
    debugPrint(
      '[DownloadService] GET $url (token: ${token.isEmpty ? 'VACIO' : '${token.length} chars'})',
    );

    try {
      final response = await _dio.get<Uint8List>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final bytes = response.data;
      debugPrint(
        '[DownloadService] status=${response.statusCode} '
        'bytes=${bytes?.length ?? 0} '
        'content-type=${response.headers.value('content-type')} '
        'content-disposition=${response.headers.value('content-disposition')}',
      );
      if (bytes == null || bytes.isEmpty) {
        throw const SocketException('El backend devolvió un archivo vacío');
      }

      final fileName =
          _fileNameFrom(response.headers.value('content-disposition')) ??
          fallbackName;
      debugPrint('[DownloadService] fileName resuelto: "$fileName"');

      final saved = await _saveToDownloads(bytes, fileName);
      debugPrint('[DownloadService] Guardado en: $saved');
      return fileName;
    } catch (e) {
      debugPrint('[DownloadService] FALLO: $e');
      if (e is DioException) {
        debugPrint(
          '[DownloadService]   tipo=${e.type} message=${e.message} '
          'status=${e.response?.statusCode}',
        );
        final body = e.response?.data;
        if (body is List<int> && body.isNotEmpty) {
          // Cuerpo de error (suele ser JSON con "detail"), recortado.
          final text = utf8.decode(body, allowMalformed: true);
          debugPrint(
            '[DownloadService]   body=${text.length > 300 ? '${text.substring(0, 300)}…' : text}',
          );
        }
      }
      rethrow;
    }
  }

  /// Publica los bytes en Descargas vía el canal nativo.
  /// Lanza [PlatformException] con el mensaje del sistema si no se pudo.
  Future<String> _saveToDownloads(Uint8List bytes, String fileName) async {
    final saved = await _channel.invokeMethod<String>('saveToDownloads', {
      'fileName': fileName,
      'bytes': bytes,
    });
    if (saved == null || saved.isEmpty) {
      throw Exception('El canal nativo no devolvió la ruta guardada');
    }
    return saved;
  }

  /// Extrae el filename del Content-Disposition del backend
  /// (llega con el título del documento). Soporta la forma
  /// `filename*=UTF-8''...` y la simple `filename="..."`.
  String? _fileNameFrom(String? header) {
    if (header == null) return null;

    final utf = RegExp(
      "filename\\*\\s*=\\s*UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header);
    if (utf != null) {
      final raw = utf.group(1)!.trim();
      try {
        return _sanitize(Uri.decodeComponent(raw));
      } catch (_) {
        return _sanitize(raw);
      }
    }

    final simple = RegExp('filename\\s*=\\s*"?([^";]+)"?').firstMatch(header);
    if (simple != null) return _sanitize(simple.group(1)!.trim());
    return null;
  }

  static final _invalid = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// Limpia caracteres inválidos para nombres de archivo en Android.
  static String _sanitize(String name) {
    var clean = name.replaceAll(_invalid, '_').trim();
    if (clean.isEmpty) clean = 'documento';
    if (clean.length > 120) clean = clean.substring(0, 120);
    return clean;
  }
}
