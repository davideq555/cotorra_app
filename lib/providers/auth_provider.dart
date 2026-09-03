import 'dart:convert';
import 'package:cotorra_app/models/auth_models.dart';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/api/auth_service.dart';
import '../services/google_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _client = ApiClient();
  late final AuthService _authService = AuthService(_client);
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  static const String _favoritesCountKey = 'favorites_count';

  String? _token;
  Usuario? _user;
  int _favoritesCount = 0;
  String? _errorMessage;

  AuthProvider() {
    // Pieza 1: refresh-on-401 — ApiClient llama esto cuando recibe 401.
    _client.tokenRefresher = _refreshAccessToken;
    // Cuando el refresh falla, forzamos logout + redirect a login.
    _client.onSessionExpired = _handleSessionExpired;
  }

  /// Callback para ApiClient: refresca el access_token usando el refresh_token.
  Future<String> _refreshAccessToken(String refreshToken) async {
    final result = await _authService.refreshToken(refreshToken);
    return result.accessToken;
  }

  /// Callback para ApiClient: sesión realmente expirada → logout.
  void _handleSessionExpired() {
    logout(); // async fire-and-forget; limpia estado y notifica
  }

  String? get errorMessage => _errorMessage;
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  int? get userId => _user?.id;
  String? get userName => _user?.nombre;
  String? get userUsername =>
      (_user == null || _user!.username.isEmpty) ? null : _user!.username;
  String? get userBio => _user?.bio;
  String? get userEmail => _user?.email;
  String? get userRol => _user?.rol.toString().split('.').last;
  List<Carrera> get userCarreras => _user?.carreras ?? [];
  int get favoritesCount => _favoritesCount;

  /// Aplica el Usuario devuelto por PUT /usuarios/me/perfil.
  /// Conserva las carreras si la respuesta no las trae.
  Future<void> applyUpdatedUser(Usuario updated) async {
    var usuario = updated;
    if (updated.carreras.isEmpty &&
        _user != null &&
        _user!.carreras.isNotEmpty) {
      usuario = Usuario(
        id: updated.id,
        nombre: updated.nombre,
        username: updated.username,
        email: updated.email,
        bio: updated.bio,
        rol: updated.rol,
        fechaCreacion: updated.fechaCreacion,
        verificado: updated.verificado,
        carreras: _user!.carreras,
      );
    }
    _user = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(usuario.toJson()));
    notifyListeners();
  }

  /// Reemplaza la lista de carreras del usuario (tras agregar/quitar)
  /// y la persiste.
  Future<void> applyCarreras(List<Carrera> carreras) async {
    if (_user == null) return;
    _user = Usuario(
      id: _user!.id,
      nombre: _user!.nombre,
      username: _user!.username,
      email: _user!.email,
      bio: _user!.bio,
      rol: _user!.rol,
      fechaCreacion: _user!.fechaCreacion,
      verificado: _user!.verificado,
      carreras: carreras,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final tokenResponse = await _authService.loginForm(
        username: username,
        password: password,
      );
      _token = tokenResponse.accessToken;
      _client.setToken(_token!);
      _user = tokenResponse.toUsuario();
      _errorMessage = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('refresh_token', tokenResponse.refreshToken);
      // Guardamos la forma canónica (Usuario.toJson) para que
      // tryAutoLogin() -> Usuario.fromJson() round-trée sin divergencias.
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Registra una cuenta normal (email + contraseña).
  ///
  /// NO hace auto-login: el backend envía un email de verificación y la
  /// app debe mostrar [EmailVerificationScreen]. El usuario loguea después
  /// de verificar. Las cuentas de Google no pasan por acá (ver
  /// [loginWithGoogle], que loguea directo sin verificación).
  Future<bool> register(UsuarioCreate userCreate) async {
    try {
      await _authService.register(
        RegisterRequest(
          nombre: userCreate.nombre,
          email: userCreate.email,
          contrasena: userCreate.contrasena,
          carreraIds: userCreate.carreraIds,
        ),
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Login/registro con Google Sign-In.
  /// Si el usuario ya existe → login normal.
  /// Si es nuevo → registro automático (sin verificación de email).
  Future<bool> loginWithGoogle() async {
    try {
      // 1. Obtener ID token de Google
      final googleResult = await _googleAuthService.signIn();

      // 2. Enviar al backend
      final tokenResponse = await _authService.loginGoogle(
        GoogleLoginRequest(credential: googleResult.idToken),
      );

      // 3. Guardar sesión (mismo flujo que login normal)
      _token = tokenResponse.accessToken;
      _client.setToken(_token!);
      _user = tokenResponse.toUsuario();
      _errorMessage = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('refresh_token', tokenResponse.refreshToken);
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Solicita un link de recuperación de contraseña por email.
  /// POST /auth/forgot-password — el backend manda el email con el link.
  Future<bool> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(ForgotPasswordRequest(email: email));
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Extrae el mensaje de error del backend desde una Exception
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString();
    // Intentar extraer el JSON del mensaje de error
    // Formato: "Exception: Failed to login: {\"detail\": \"...\"}"
    final jsonMatch = RegExp(r'\{.*\}').firstMatch(errorStr);
    if (jsonMatch != null) {
      try {
        final json = jsonDecode(jsonMatch.group(0)!);
        if (json is Map && json.containsKey('detail')) {
          final detail = json['detail'].toString();
          // Traducir mensajes comunes del backend
          if (detail.toLowerCase().contains('incorrect') ||
              detail.toLowerCase().contains('invalid')) {
            return 'Email o contraseña incorrectos';
          }
          return detail;
        }
        if (json is Map && json.containsKey('message')) {
          return json['message'].toString();
        }
      } catch (_) {
        // Si no se puede parsear, usar el mensaje original
      }
    }
    // Mensaje por defecto si no se puede extraer
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection')) {
      return 'No se pudo conectar al servidor. Verificá tu conexión a internet.';
    }
    return 'Ocurrió un error. Por favor intentá de nuevo.';
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    notifyListeners();
  }

  /// Limpia token, usuario y prefs sin notificar (usado por logout y tryAutoLogin).
  Future<void> _clearSession(SharedPreferences prefs) async {
    _token = null;
    _user = null;
    _client.clearToken();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  /// Restaura la sesión al reiniciar la app.
  /// Pieza 3: valida expiración del JWT. Si está vencido, intenta refresh.
  /// Si el refresh también falla, limpia la sesión (el usuario debe reloguear).
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    if (_token == null) return;

    // Si el JWT está vencido, intentar refresh ANTES de restaurar la sesión.
    if (ApiClient.isTokenExpired(_token!)) {
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSession(prefs);
        return;
      }
      try {
        final result = await _authService.refreshToken(refreshToken);
        _token = result.accessToken;
        await prefs.setString('token', _token!);
        // El refresh_token existente sigue válido (el backend no rota).
      } catch (_) {
        // Refresh falló → sesión muerta, limpiar todo.
        await _clearSession(prefs);
        return;
      }
    }

    _client.setToken(_token!);
    final userDataJson = prefs.getString('user_data');
    if (userDataJson != null) {
      _user = Usuario.fromJson(jsonDecode(userDataJson));
    }
    _favoritesCount = prefs.getInt(_favoritesCountKey) ?? 0;
    notifyListeners();
  }

  /// Actualiza el count de favoritos.
  void updateFavoritesCount(int count) {
    _favoritesCount = count;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_favoritesCountKey, count);
    });
    notifyListeners();
  }
}
