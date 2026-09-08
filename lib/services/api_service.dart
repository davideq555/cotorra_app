import 'dart:convert';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/token.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:cotorra_app/services/api/favorites_service.dart';
import 'package:cotorra_app/services/api/catalogs_service.dart';
import 'package:cotorra_app/services/api/users_service.dart';

/// ──────────────────────────────────────────────────────────────────────
/// FACHADA DE COMPATIBILIDAD — delega a los nuevos servicios.
/// Migrada desde el monolito original. Los screens/widgets que aún
/// importan esta clase siguen funcionando sin cambios.
///
/// Nuevos providers y servicios DEBEN usar directamente:
/// - ApiClient + AuthService
/// - ApiClient + DocumentsService
/// - ApiClient + FavoritesService
/// - ApiClient + CatalogsService
/// - ApiClient + UsersService
/// ──────────────────────────────────────────────────────────────────────
@Deprecated('Usar AuthService, DocumentsService, etc. directamente')
class ApiService {
  final ApiClient _client = ApiClient();
  late final DocumentsService _docs = DocumentsService(_client);
  late final FavoritesService _fav = FavoritesService(_client);
  late final CatalogsService _catalogs = CatalogsService(_client);
  late final UsersService _users = UsersService(_client);

  String get baseUrl => _client.baseUrl;

  // ─── AUTH ──────────────────────────────────────────────────────────

  Future<Token> login(String username, String password) async {
    final response = await _client.formPost(
      '/auth/login/form',
      body: {'username': username, 'password': password},
      requireAuth: false,
    );
    if (response.statusCode == 200) {
      return Token.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(UsuarioCreate usuarioCreate) async {
    return _client.decodeResponse(
      await _client.post(
        '/auth/register',
        body: usuarioCreate.toJson(),
        requireAuth: false,
      ),
    );
  }

  // ─── USERS ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> cambiarContrasena(
    String token,
    int usuarioId,
    String contrasenaActual,
    String contrasenaNueva,
  ) async {
    _client.setToken(token);
    final result = await _users.cambiarContrasena(
      usuarioId,
      contrasenaActual,
      contrasenaNueva,
    );
    return {'message': result.message, 'success': result.success};
  }

  // ─── CATALOGS ──────────────────────────────────────────────────────

  Future<List<Materia>> getMaterias({int skip = 0, int limit = 100}) =>
      _catalogs.getMaterias(skip: skip, limit: limit);

  Future<List<Facultad>> getFacultades() => _catalogs.getFacultades();

  Future<List<Carrera>> getCarrerasPorFacultad(int facultadId) =>
      _catalogs.getCarrerasByFacultadId(facultadId);

  Future<List<Materia>> getMateriasPorCarrera(int carreraId) =>
      _catalogs.getMateriasByCarreraId(carreraId);

  // ─── DOCUMENTS ─────────────────────────────────────────────────────

  Future<List<Documento>> getDocumentos(
    String token, {
    String? query,
    int? tipo,
    int? materiaId,
    String? anoAcademico,
    String sortBy = 'fecha_subida',
    String sortOrder = 'desc',
    int skip = 0,
    int limit = 20,
  }) async {
    _client.setToken(token);
    return _docs.getDocumentos(
      query: query,
      tipo: tipo,
      materiaId: materiaId,
      anoAcademico: anoAcademico,
      sortBy: sortBy,
      sortOrder: sortOrder,
      skip: skip,
      limit: limit,
    );
  }

  Future<Documento> getDocumento(int documentoId) =>
      _docs.getDocumento(documentoId);

  Future<int> getDocumentosTotal() => _docs.getDocumentosTotal();

  Future<List<Documento>> getMejoresDocumentos() =>
      _docs.getMejoresDocumentos();

  Future<List<Documento>> getDocumentosUsuario(
    String token,
    int usuarioId, {
    int skip = 0,
    int limit = 20,
    bool includeDeleted = false,
  }) async {
    _client.setToken(token);
    return _docs.getDocumentosUsuario(
      usuarioId,
      skip: skip,
      limit: limit,
      includeDeleted: includeDeleted,
    );
  }

  Future<Documento> createDocumento(
    String token,
    Map<String, dynamic> data,
  ) async {
    _client.setToken(token);
    return _docs.createDocumento(data);
  }

  Future<Documento> uploadDocumento(
    String token, {
    required String titulo,
    required String archivoBase64,
    required int tipo,
    String? descripcion,
    String? autor,
    int? materiaId,
    String? anoAcademico,
  }) async {
    _client.setToken(token);
    return _docs.uploadDocumento(
      titulo: titulo,
      archivoBytes: base64Decode(archivoBase64),
      tipo: tipo,
      descripcion: descripcion,
      autor: autor,
      materiaId: materiaId,
      anoAcademico: anoAcademico,
    );
  }

  Future<Documento> createDocumentoLink(
    String token, {
    required String titulo,
    required String urlExterna,
    required int tipo,
    String? descripcion,
    String? autor,
    int? materiaId,
    String? anoAcademico,
  }) async {
    _client.setToken(token);
    return _docs.createDocumentoLink(
      titulo: titulo,
      urlExterna: urlExterna,
      tipo: tipo,
      descripcion: descripcion,
      autor: autor,
      materiaId: materiaId,
      anoAcademico: anoAcademico,
    );
  }

  Future<Documento> updateDocumento(
    String token,
    int documentoId,
    Map<String, dynamic> data,
  ) async {
    _client.setToken(token);
    return _docs.updateDocumento(documentoId, data);
  }

  Future<void> deleteDocumento(String token, int documentoId) async {
    _client.setToken(token);
    await _docs.deleteDocumento(documentoId);
  }

  Future<dynamic> descargarDocumento(int documentoId) async {
    final bytes = await _docs.descargarDocumento(documentoId);
    return bytes;
  }

  // ─── FAVORITES ─────────────────────────────────────────────────────

  Future<List<Documento>> getFavoritos(
    String token, {
    int skip = 0,
    int limit = 100,
  }) async {
    _client.setToken(token);
    return _fav.getFavoritos(skip: skip, limit: limit);
  }

  Future<Map<String, dynamic>> toggleFavorito(
    String token,
    int documentoId,
  ) async {
    _client.setToken(token);
    return _fav.toggleFavorito(documentoId);
  }
}
