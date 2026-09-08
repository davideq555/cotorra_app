import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cotorra_app/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente HTTP base para toda la app.
/// Centraliza: baseUrl, headers Authorization, parsing de errores, multipart,
/// y refresh-on-401 transparente (single-flight retry).
///
/// Registro de callbacks de sesión:
/// AuthProvider setea `ApiClient.sharedTokenRefresher` y
/// `ApiClient.sharedOnSessionExpired` en su constructor, UNA sola vez; TODA
/// instancia de ApiClient hereda esos callbacks como fallback, por lo que el
/// refresh-on-401 funciona también en clientes ad-hoc (pantallas, sheets,
/// providers) sin cablear cada uno. Una instancia puede hacer override con
/// sus propios callbacks de instancia (tienen precedencia sobre los
/// estáticos compartidos).
///
/// Uso:
/// ```dart
/// final client = ApiClient();
/// client.setToken('mi-jwt');
/// // Opcional: callbacks de instancia (preceden a los estáticos compartidos).
/// client.tokenRefresher = (refreshToken) async => ...; // inyectado por AuthProvider
/// client.onSessionExpired = () { /* redirect a login */ };
/// final response = await client.get('/auth/me');
/// ```
class ApiClient {
  /// [httpClient] es opcional y solo para tests: permite inyectar un client
  /// mock. En producción se usa el client compartido de [_http] (mismo
  /// comportamiento de keep-alive de las funciones top-level de package:http).
  ApiClient({String? baseUrl, http.Client? httpClient})
    : _baseUrlOverride = baseUrl,
      _httpClient = httpClient;

  final String? _baseUrlOverride;
  final http.Client? _httpClient;
  String? _token;

  /// Client HTTP por defecto, compartido entre instancias sin inyectar
  /// (réplica del singleton interno que usan http.get/http.post top-level).
  static final http.Client _sharedClient = http.Client();

  /// Client efectivo para los métodos verbos: inyectado o compartido.
  http.Client get _http => _httpClient ?? _sharedClient;

  /// Función async para refrescar el access_token usando el refresh_token.
  /// Inyectada por AuthProvider tras login.
  Future<String> Function(String refreshToken)? tokenRefresher;

  /// Callback llamado cuando el refresh falla (sesión realmente expirada).
  void Function()? onSessionExpired;

  /// Refresher compartido de sesión: AuthProvider lo registra UNA vez y TODAS
  /// las instancias de ApiClient lo usan como fallback cuando no definen los
  /// suyos propios. Así el refresh-on-401 funciona en clientes ad-hoc
  /// (pantallas, sheets, providers) sin cablear cada uno.
  static Future<String> Function(String refreshToken)? sharedTokenRefresher;

  /// Handler compartido de sesión expirada (fallback análogo al anterior).
  static void Function()? sharedOnSessionExpired;

  bool _refreshInProgress = false;

  /// Base URL usada por este cliente (incluye /api/v1).
  /// Resuelta perezosamente para no depender de dotenv en construcción.
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

  // ─── Token refresh on 401 ─────────────────────────────────────────

  /// Intenta refrescar el access_token usando el refresh_token almacenado.
  /// Retorna el nuevo access_token si tuvo éxito, null si falló.
  Future<String?> _tryRefreshToken() async {
    // Fallback instancia → estático: si esta instancia no definió su propio
    // refresher, usamos el compartido registrado por AuthProvider.
    final refresher = tokenRefresher ?? sharedTokenRefresher;
    if (_refreshInProgress || refresher == null) return null;
    _refreshInProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final newAccessToken = await refresher(refreshToken);
      _token = newAccessToken;
      await prefs.setString('token', newAccessToken);
      return newAccessToken;
    } catch (_) {
      return null;
    } finally {
      _refreshInProgress = false;
    }
  }

  /// Ejecuta una petición HTTP. Si devuelve 401, intenta un refresh
  /// y reintenta UNA sola vez. Si el refresh falla, llama onSessionExpired.
  /// Usar [skip] en endpoints que no deben disparar refresh
  /// (login, refresh, logout).
  Future<http.Response> _retryOn401(
    Future<http.Response> Function() doRequest, {
    bool skip = false,
  }) async {
    var response = await doRequest();
    if (response.statusCode == 401 && !skip && _token != null) {
      final newToken = await _tryRefreshToken();
      if (newToken != null) {
        response = await doRequest(); // reintento único con token nuevo
      } else {
        // Fallback instancia → estático: handler compartido si la instancia
        // no definió el suyo.
        final sessionExpiredHandler =
            onSessionExpired ?? sharedOnSessionExpired;
        sessionExpiredHandler?.call();
      }
    }
    return response;
  }

  // ─── HTTP methods ─────────────────────────────────────────────────

  /// GET request. Returns the raw [http.Response].
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
    bool skipRefresh = false,
  }) async {
    return _retryOn401(() {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParams);
      return _http.get(uri, headers: _jsonHeaders(includeAuth: requireAuth));
    }, skip: skipRefresh);
  }

  /// POST request with JSON body.
  Future<http.Response> post(
    String path, {
    Object? body,
    bool requireAuth = true,
    bool skipRefresh = false,
  }) async {
    return _retryOn401(() {
      return _http.post(
        Uri.parse('$baseUrl$path'),
        headers: _jsonHeaders(includeAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      );
    }, skip: skipRefresh);
  }

  /// PUT request with JSON body.
  Future<http.Response> put(
    String path, {
    Object? body,
    bool requireAuth = true,
    bool skipRefresh = false,
  }) async {
    return _retryOn401(() {
      return _http.put(
        Uri.parse('$baseUrl$path'),
        headers: _jsonHeaders(includeAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      );
    }, skip: skipRefresh);
  }

  /// DELETE request.
  Future<http.Response> delete(
    String path, {
    bool requireAuth = true,
    bool skipRefresh = false,
  }) async {
    return _retryOn401(() {
      return _http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _jsonHeaders(includeAuth: requireAuth),
      );
    }, skip: skipRefresh);
  }

  /// POST with x-www-form-urlencoded body (para OAuth2 / login form).
  Future<http.Response> formPost(
    String path, {
    required Map<String, String> body,
    bool requireAuth = true,
    bool skipRefresh = false,
  }) async {
    return _retryOn401(() {
      return _http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          if (requireAuth && _token != null) 'Authorization': 'Bearer $_token',
        },
        body: body,
      );
    }, skip: skipRefresh);
  }

  /// POST multipart request (para uploads).
  Future<http.Response> multipartPost(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool requireAuth = true,
    bool skipRefresh = false,
  }) async {
    return _retryOn401(() async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

      if (requireAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.fields.addAll(fields);
      request.files.addAll(files);

      // Con client inyectado se enruta por él (permite mockear uploads);
      // sin inyectar, request.send() conserva el comportamiento original.
      final streamedResponse =
          await (_httpClient?.send(request) ?? request.send());
      return http.Response.fromStream(streamedResponse);
    }, skip: skipRefresh);
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

    throw ApiException(statusCode: response.statusCode, message: message);
  }

  /// Decodifica el payload de un JWT sin dependencias externas.
  /// Retorna el Map de claims o null si no se puede parsear.
  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(utf8.decode(base64Url.decode(parts[1])));
      if (payload is Map<String, dynamic>) return payload;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Retorna true si el JWT está vencido (exp < now) o no se puede parsear.
  static bool isTokenExpired(String token) {
    final payload = decodeJwtPayload(token);
    if (payload == null) return true;
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry);
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
