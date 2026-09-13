import 'package:cotorra_app/models/auth_models.dart';
import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de autenticación — 14 endpoints de openapi.json tag "authentication".
///
/// Uso:
/// ```dart
/// final client = ApiClient();
/// final auth = AuthService(client);
///
/// // Login
/// final login = await auth.loginForm(username: 'user', password: 'pass');
/// client.setToken(login.accessToken);
///
/// // Registro
/// final reg = await auth.register(RegisterRequest(...));
///
/// // Refresh
/// final refreshed = await auth.refreshToken(oldRefreshToken);
/// ```
class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  // ─── 1. Register ─────────────────────────────────────────────────
  /// POST /auth/register — Registra un nuevo usuario y envía email de verificación.
  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _client.post(
      '/auth/register',
      body: request.toJson(),
      requireAuth: false,
    );
    return RegisterResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 2. Login (JSON) ─────────────────────────────────────────────
  /// POST /auth/login — Autentica con email+password (JSON body).
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _client.post(
      '/auth/login',
      body: request.toJson(),
      requireAuth: false,
    );
    return LoginResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 3. Login (form) ─────────────────────────────────────────────
  /// POST /auth/login/form — Login con x-www-form-urlencoded (compatible OAuth2).
  /// Retorna [LoginResponse] con access_token y refresh_token.
  Future<LoginResponse> loginForm({
    required String username,
    required String password,
  }) async {
    final request = LoginFormRequest(username: username, password: password);
    final response = await _client.formPost(
      '/auth/login/form',
      body: request.toFormBody(),
      requireAuth: false,
    );
    return LoginResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 4. Login (Google) ───────────────────────────────────────────
  /// POST /auth/google — Login/registro vía Google OAuth ID token.
  Future<LoginResponse> loginGoogle(GoogleLoginRequest request) async {
    final response = await _client.post(
      '/auth/google',
      body: request.toJson(),
      requireAuth: false,
    );
    return LoginResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 5. Verify Email ─────────────────────────────────────────────
  /// GET /auth/verify-email?token= — Verifica el email con el token del link.
  Future<VerifyEmailResponse> verifyEmail(String token) async {
    final response = await _client.get(
      '/auth/verify-email',
      queryParams: {'token': token},
      requireAuth: false,
    );
    return VerifyEmailResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 6. Forgot Password ──────────────────────────────────────────
  /// POST /auth/forgot-password — Solicita link de reset por email.
  Future<ForgotPasswordResponse> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    final response = await _client.post(
      '/auth/forgot-password',
      body: request.toJson(),
      requireAuth: false,
    );
    return ForgotPasswordResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 7. Reset Password ───────────────────────────────────────────
  /// POST /auth/reset-password — Resetea contraseña con token válido.
  Future<ResetPasswordResponse> resetPassword(
    ResetPasswordRequest request,
  ) async {
    final response = await _client.post(
      '/auth/reset-password',
      body: request.toJson(),
      requireAuth: false,
    );
    return ResetPasswordResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 8. Refresh Token ────────────────────────────────────────────
  /// POST /auth/refresh — Obtiene nuevo access_token usando refresh_token.
  Future<RefreshTokenResponse> refreshToken(String refreshToken) async {
    final response = await _client.post(
      '/auth/refresh',
      body: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      requireAuth: false,
      skipRefresh: true, // évitamos loop: refresh no puede trigger refresh
    );
    return RefreshTokenResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 9. Auth Me ──────────────────────────────────────────────────
  /// GET /auth/me — Retorna el usuario autenticado actual.
  Future<Usuario> getMe() async {
    final response = await _client.get('/auth/me');
    return Usuario.fromJson(_client.decodeResponse(response));
  }

  // ─── 10. Verify Token ────────────────────────────────────────────
  /// GET /auth/verify-token — Verifica si el token actual es válido.
  Future<VerifyTokenResponse> verifyToken() async {
    final response = await _client.get('/auth/verify-token');
    return VerifyTokenResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 11. Logout ──────────────────────────────────────────────────
  /// POST /auth/logout — Cierra sesión en este dispositivo.
  ///
  /// Si [refreshToken] no es null ni vacío, se envía en el header
  /// `X-Refresh-Token` para que el backend finalice la sesión server-side.
  Future<void> logout({String? refreshToken}) async {
    await _client.post(
      '/auth/logout',
      skipRefresh: true,
      headers: _refreshTokenHeaders(refreshToken),
    );
  }

  // ─── 12. Logout All ──────────────────────────────────────────────
  /// POST /auth/logout-all — Cierra sesión en TODOS los dispositivos.
  ///
  /// Si [refreshToken] no es null ni vacío, se envía en el header
  /// `X-Refresh-Token` para que el backend finalice la sesión server-side.
  Future<void> logoutAll({String? refreshToken}) async {
    await _client.post(
      '/auth/logout-all',
      headers: _refreshTokenHeaders(refreshToken),
    );
  }

  /// Arma el header `X-Refresh-Token` solo si [refreshToken] tiene valor.
  Map<String, String>? _refreshTokenHeaders(String? refreshToken) {
    if (refreshToken == null || refreshToken.isEmpty) return null;
    return {'X-Refresh-Token': refreshToken};
  }

  // ─── 13. Sessions List ───────────────────────────────────────────
  /// GET /auth/sessions — Lista sesiones activas del usuario.
  Future<SessionsListResponse> getSessions() async {
    final response = await _client.get('/auth/sessions');
    return SessionsListResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 14. Session Revoke ──────────────────────────────────────────
  /// DELETE /auth/sessions/{session_id} — Revoca una sesión específica.
  Future<void> revokeSession(int sessionId) async {
    await _client.delete('/auth/sessions/$sessionId');
  }
}
