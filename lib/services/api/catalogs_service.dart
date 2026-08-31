import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/carreraMateria.dart';
import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/tag.dart';
import 'package:cotorra_app/models/tipoDocumento.dart';
import 'package:cotorra_app/models/universidad.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/models/formato.dart';

/// Servicio de catálogos — tipos-doc, formatos, universidades,
/// facultades, carreras, materias, tags. Todos públicos o con auth.
class CatalogsService {
  final ApiClient _client;

  CatalogsService(this._client);

  // ─── Tipos de Documento ───────────────────────────────────────────

  /// GET /tipos-documento/ — Lista tipos de documento.
  Future<List<TipoDocumento>> getTiposDocumento({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.get(
      '/tipos-documento/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => TipoDocumento.fromJson(j))
            .toList() ??
        [];
  }

  /// POST /tipos-documento/ — Crea tipo (admin).
  Future<TipoDocumento> createTipoDocumento(String nombre) async {
    final response = await _client.post(
      '/tipos-documento/',
      body: {'nombre': nombre},
    );
    return TipoDocumento.fromJson(_client.decodeResponse(response));
  }

  /// PUT /tipos-documento/{id} — Actualiza tipo (admin).
  Future<TipoDocumento> updateTipoDocumento(int id, String nombre) async {
    final response = await _client.put(
      '/tipos-documento/$id',
      body: {'nombre': nombre},
    );
    return TipoDocumento.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /tipos-documento/{id} — Elimina tipo (admin).
  Future<void> deleteTipoDocumento(int id) async {
    await _client.delete('/tipos-documento/$id');
  }

  // ─── Formatos de Documento ────────────────────────────────────────

  /// GET /formatos-documento/ — Lista formatos.
  Future<List<Formato>> getFormatosDocumento({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.get(
      '/formatos-documento/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Formato.fromJson(j))
            .toList() ??
        [];
  }

  /// POST /formatos-documento/ — Crea formato (admin).
  Future<Formato> createFormatoDocumento(Map<String, dynamic> data) async {
    final response = await _client.post(
      '/formatos-documento/',
      body: data,
    );
    return Formato.fromJson(_client.decodeResponse(response));
  }

  /// PUT /formatos-documento/{id} — Actualiza formato (admin).
  Future<Formato> updateFormatoDocumento(
      int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '/formatos-documento/$id',
      body: data,
    );
    return Formato.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /formatos-documento/{id} — Elimina formato (admin).
  Future<void> deleteFormatoDocumento(int id) async {
    await _client.delete('/formatos-documento/$id');
  }

  // ─── Universidades ────────────────────────────────────────────────

  /// GET /universidades/ — Lista universidades.
  Future<List<Universidad>> getUniversidades({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.get(
      '/universidades/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Universidad.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /universidades/{id} — Detalle de universidad.
  Future<Universidad> getUniversidadById(int id) async {
    final response = await _client.get('/universidades/$id', requireAuth: false);
    return Universidad.fromJson(_client.decodeResponse(response));
  }

  /// GET /universidades/{id}/facultades — Facultades de una universidad.
  Future<List<Facultad>> getFacultadesByUniversidad(int universidadId,
      {int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/universidades/$universidadId/facultades',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Facultad.fromJson(j))
            .toList() ??
        [];
  }

  // ─── Facultades ──────────────────────────────────────────────────

  /// GET /facultades/ — Lista facultades.
  Future<List<Facultad>> getFacultades({int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/facultades/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Facultad.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /facultades/{id} — Detalle de facultad.
  Future<Facultad> getFacultadById(int id) async {
    final response = await _client.get('/facultades/$id', requireAuth: false);
    return Facultad.fromJson(_client.decodeResponse(response));
  }

  /// GET /facultades/universidad/{uid} — Facultades por universidad.
  Future<List<Facultad>> getFacultadesByUniversidadId(int universidadId,
      {int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/facultades/universidad/$universidadId',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Facultad.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /facultades/{id}/carreras — Carreras de una facultad.
  Future<List<Carrera>> getCarrerasByFacultad(int facultadId,
      {int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/facultades/$facultadId/carreras',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Carrera.fromJson(j))
            .toList() ??
        [];
  }

  // ─── Carreras ────────────────────────────────────────────────────

  /// GET /carreras/ — Lista carreras.
  Future<List<Carrera>> getCarreras({int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/carreras/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Carrera.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /carreras/{id} — Detalle de carrera.
  Future<Carrera> getCarreraById(int id) async {
    final response = await _client.get('/carreras/$id', requireAuth: false);
    return Carrera.fromJson(_client.decodeResponse(response));
  }

  /// GET /carreras/{id}/materias — Materias de una carrera.
  Future<List<CarreraMateria>> getMateriasByCarrera(int carreraId) async {
    final response = await _client.get(
      '/carreras/$carreraId/materias',
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => CarreraMateria.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /carreras/facultad/{fid} — Carreras por facultad.
  Future<List<Carrera>> getCarrerasByFacultadId(int facultadId,
      {int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/carreras/facultad/$facultadId',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Carrera.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /carreras/{id}/usuarios — Usuarios de una carrera.
  Future<List<dynamic>> getUsuariosByCarrera(int carreraId) async {
    final response = await _client.get(
      '/carreras/$carreraId/usuarios',
      requireAuth: false,
    );
    return _client.decodeResponse(response) as List<dynamic>? ?? [];
  }

  // ─── Materias ────────────────────────────────────────────────────

  /// GET /materias/ — Lista materias.
  Future<List<Materia>> getMaterias({int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/materias/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Materia.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /materias/{id} — Detalle de materia.
  Future<Materia> getMateriaById(int id) async {
    final response = await _client.get('/materias/$id', requireAuth: false);
    return Materia.fromJson(_client.decodeResponse(response));
  }

  /// GET /materias/buscar?q= — Busca materias por nombre.
  Future<List<Materia>> buscarMaterias(String query) async {
    final response = await _client.get(
      '/materias/buscar',
      queryParams: {'q': query},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Materia.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /materias/carrera/{cid} — Materias por carrera.
  Future<List<Materia>> getMateriasByCarreraId(int carreraId) async {
    final response = await _client.get(
      '/materias/carrera/$carreraId',
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Materia.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /materias/{id}/carreras — Carreras donde se dicta una materia.
  Future<List<CarreraMateria>> getCarrerasByMateriaId(int materiaId) async {
    final response = await _client.get(
      '/materias/$materiaId/carreras',
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => CarreraMateria.fromJson(j))
            .toList() ??
        [];
  }

  // ─── Tags ────────────────────────────────────────────────────────

  /// GET /tags/ — Lista tags.
  Future<List<Tag>> getTags({int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/tags/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
      requireAuth: false,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Tag.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /tags/{id} — Detalle de tag.
  Future<Tag> getTagById(int id) async {
    final response = await _client.get('/tags/$id', requireAuth: false);
    return Tag.fromJson(_client.decodeResponse(response));
  }
}
