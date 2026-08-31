import 'package:cotorra_app/models/admin_models.dart';
import 'package:cotorra_app/models/auth_models.dart';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de usuarios — perfil, carreras, contraseña.
class UsersService {
  final ApiClient _client;

  UsersService(this._client);

  // ─── Perfil ───────────────────────────────────────────────────────

  /// GET /auth/me — Usuario autenticado actual (delega a auth, pero
  /// aquí va como consulta de usuario para providers).
  Future<Usuario> getMe() async {
    final response = await _client.get('/auth/me');
    return Usuario.fromJson(_client.decodeResponse(response));
  }

  /// PUT /usuarios/me/perfil — Actualiza nombre, username y bio.
  Future<Usuario> updatePerfil(UsuarioPerfilUpdate request) async {
    final response = await _client.put(
      '/usuarios/me/perfil',
      body: request.toJson(),
    );
    return Usuario.fromJson(_client.decodeResponse(response));
  }

  // ─── Detalle / Stats ─────────────────────────────────────────────

  /// GET /usuarios/{id} — Obtiene un usuario por ID.
  Future<Usuario> getUsuarioById(int usuarioId) async {
    final response = await _client.get('/usuarios/$usuarioId');
    return Usuario.fromJson(_client.decodeResponse(response));
  }

  /// GET /usuarios/by-username/{username} — Obtiene un usuario por username.
  Future<Usuario> getUsuarioByUsername(String username) async {
    final response = await _client.get('/usuarios/by-username/$username');
    return Usuario.fromJson(_client.decodeResponse(response));
  }

  /// GET /usuarios/{id}/stats — Estadísticas de un usuario.
  Future<Map<String, dynamic>> getUsuarioStats(int usuarioId) async {
    final response = await _client.get('/usuarios/$usuarioId/stats');
    return _client.decodeResponse(response);
  }

  // ─── Carreras del usuario ────────────────────────────────────────

  /// GET /usuarios/{id}/carreras — Carreras de un usuario.
  Future<List<Carrera>> getUsuarioCarreras(int usuarioId) async {
    final response = await _client.get('/usuarios/$usuarioId/carreras');
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((c) => Carrera.fromJson(c))
            .toList() ??
        [];
  }

  /// POST /usuarios/{uid}/carreras/{cid} — Agrega carrera al usuario.
  Future<void> addCarreraToUsuario(int usuarioId, int carreraId) async {
    await _client.post('/usuarios/$usuarioId/carreras/$carreraId');
  }

  /// DELETE /usuarios/{uid}/carreras/{cid} — Remueve carrera del usuario.
  Future<void> removeCarreraFromUsuario(int usuarioId, int carreraId) async {
    await _client.delete('/usuarios/$usuarioId/carreras/$carreraId');
  }

  /// PUT /usuarios/{uid}/carreras/{cid}/status?activa= — Actualiza estado.
  Future<void> updateCarreraStatus(
      int usuarioId, int carreraId, bool activa) async {
    await _client.put(
      '/usuarios/$usuarioId/carreras/$carreraId/status',
      body: {'activa': activa},
    );
  }

  // ─── Contraseña ──────────────────────────────────────────────────

  /// POST /usuarios/{id}/cambiar-contraseña — Cambia la contraseña.
  Future<CambiarContrasenaResponse> cambiarContrasena(
    int usuarioId,
    String contrasenaActual,
    String contrasenaNueva,
  ) async {
    final response = await _client.post(
      '/usuarios/$usuarioId/cambiar-contraseña',
      body: {
        'contraseña_actual': contrasenaActual,
        'contraseña_nueva': contrasenaNueva,
      },
    );
    return CambiarContrasenaResponse.fromJson(
        _client.decodeResponse(response));
  }
}
