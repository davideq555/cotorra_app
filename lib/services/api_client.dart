import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cotorra_app/config/env.dart';

/// Cliente HTTP base para toda la app.
/// Centraliza: baseUrl, headers Authorization, parsing de errores, y multipart.
///
/// Uso:
/// ```dart
/// final client = ApiClient();
/// client.setToken('mi-jwt');
/// final response = await client.get('/auth/me');
/// ```
class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrlOverride = baseUrl;

  final String? _baseUrlOverride;
  String? _token;

  /// Base URL usada por este cliente (incluye /api/v1).
  /// Resuelta perezosamente para no depender de que dotenv esté cargado
  /// en el momento de la construcción (mismos tiempos que el viejo ApiService).
  String get baseUrl => _baseUrlOverride ?? Env.baseUrl;

  // ─── Token management ──────────────────────────────────────────────

  /// Establece el token JWT para requests autenticadas.
  void setToken(String token) => _token = token;

  /// Limpia el token (logout).
  void clearToken() => _token = null;

  /// Retorna true si hay un token activo.
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // ─── Headers ───────────────────────────────────────────────────────

  Map<String, String> _jsonHeaders({bool includeAuth = true}) => {
        'Content-Type': 'application/json',
        if (includeAuth && _token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── HTTP methods ─────────────────────────────────────────────────

  /// GET request. Returns the raw [http.Response].
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams,
    );
    return http.get(uri, headers: _jsonHeaders(includeAuth: requireAuth));
  }

  /// POST request with JSON body.
  Future<http.Response> post(
    String path, {
    Object? body,
    bool requireAuth = true,
  }) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _jsonHeaders(includeAuth: requireAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// PUT request with JSON body.
  Future<http.Response> put(
    String path, {
    Object? body,
    bool requireAuth = true,
  }) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _jsonHeaders(includeAuth: requireAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// DELETE request.
  Future<http.Response> delete(
    String path, {
    bool requireAuth = true,
  }) async {
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _jsonHeaders(includeAuth: requireAuth),
    );
  }

  /// POST with x-www-form-urlencoded body (para OAuth2 / login form).
  Future<http.Response> formPost(
    String path, {
    required Map<String, String> body,
    bool requireAuth = true,
  }) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (requireAuth && _token != null) 'Authorization': 'Bearer $_token',
      },
      body: body,
    );
  }

  /// POST multipart request (para uploads).
  Future<http.Response> multipartPost(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool requireAuth = true,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    );

    if (requireAuth && _token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  // ─── Error helpers ─────────────────────────────────────────────────

  /// Parsea la respuesta y lanza [ApiException] si el status code no es 2xx.
  /// Retorna el body decodificado como Map o List.
  dynamic decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // Intentar extraer el mensaje de error del backend
    String message;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        // FastAPI validation error: { detail: [...] }
        if (body.containsKey('detail')) {
          final detail = body['detail'];
          if (detail is List && detail.isNotEmpty) {
            message = detail.map((e) => e['msg'] ?? e.toString()).join('; ');
          } else {
            message = detail.toString();
          }
        } else if (body.containsKey('message')) {
          message = body['message'].toString();
        } else {
          message = response.body;
        }
      } else {
        message = response.body;
      }
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Error desconocido';
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }
}

/// Excepción tipada para errores del API.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
