import 'package:cotorra_app/models/admin_models.dart';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/universidad.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de administración — endpoints de openapi.json tag "admin"
/// (openapi v1.5.1: reportes de documento y comentario unificados en
/// /admin/reportes/ paginado; ya no existe /admin/reportes-comentarios/).
///
/// Todos los endpoints requieren rol ADMIN o COLABORADOR.
class AdminService {
  final ApiClient _client;

  AdminService(this._client);

  // ─── 1. Usuarios ──────────────────────────────────────────────────

  /// GET /admin/usuarios — Lista todos los usuarios con filtros y paginación.
  Future<UsuarioPaginatedResponse> getUsuarios({
    int skip = 0,
    int limit = 20,
    String? q,
    String? rol,
    bool? verificado,
    String sortBy = 'nombre',
    String sortOrder = 'asc',
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (rol != null) params['rol'] = rol;
    if (verificado != null) params['verificado'] = verificado.toString();

    final response = await _client.get('/admin/usuarios', queryParams: params);
    return UsuarioPaginatedResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 2-4. Universidades CRUD ──────────────────────────────────────

  /// POST /admin/universidades — Crea una universidad.
  Future<Universidad> createUniversidad(UniversidadCreate request) async {
    final response = await _client.post(
      '/admin/universidades',
      body: request.toJson(),
    );
    return Universidad.fromJson(_client.decodeResponse(response));
  }

  /// PUT /admin/universidades/{id} — Actualiza una universidad.
  Future<Universidad> updateUniversidad(
    int id,
    UniversidadUpdate request,
  ) async {
    final response = await _client.put(
      '/admin/universidades/$id',
      body: request.toJson(),
    );
    return Universidad.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /admin/universidades/{id} — Elimina una universidad.
  Future<MessageResponse> deleteUniversidad(int id) async {
    final response = await _client.delete('/admin/universidades/$id');
    return MessageResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 5-7. Facultades CRUD ────────────────────────────────────────

  /// POST /admin/facultades — Crea una facultad.
  Future<Facultad> createFacultad(FacultadCreate request) async {
    final response = await _client.post(
      '/admin/facultades',
      body: request.toJson(),
    );
    return Facultad.fromJson(_client.decodeResponse(response));
  }

  /// PUT /admin/facultades/{id} — Actualiza una facultad.
  Future<Facultad> updateFacultad(int id, FacultadUpdate request) async {
    final response = await _client.put(
      '/admin/facultades/$id',
      body: request.toJson(),
    );
    return Facultad.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /admin/facultades/{id} — Elimina una facultad.
  Future<MessageResponse> deleteFacultad(int id) async {
    final response = await _client.delete('/admin/facultades/$id');
    return MessageResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 8-10. Carreras CRUD ─────────────────────────────────────────

  /// POST /admin/carreras — Crea una carrera.
  Future<Carrera> createCarrera(CarreraCreate request) async {
    final response = await _client.post(
      '/admin/carreras',
      body: request.toJson(),
    );
    return Carrera.fromJson(_client.decodeResponse(response));
  }

  /// PUT /admin/carreras/{id} — Actualiza una carrera.
  Future<Carrera> updateCarrera(int id, CarreraUpdate request) async {
    final response = await _client.put(
      '/admin/carreras/$id',
      body: request.toJson(),
    );
    return Carrera.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /admin/carreras/{id} — Elimina una carrera.
  Future<MessageResponse> deleteCarrera(int id) async {
    final response = await _client.delete('/admin/carreras/$id');
    return MessageResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 11-13. Materias CRUD ────────────────────────────────────────

  /// POST /admin/materias — Crea una materia.
  Future<Materia> createMateria(MateriaCreate request) async {
    final response = await _client.post(
      '/admin/materias',
      body: request.toJson(),
    );
    return Materia.fromJson(_client.decodeResponse(response));
  }

  /// PUT /admin/materias/{id} — Actualiza una materia.
  Future<Materia> updateMateria(int id, MateriaUpdate request) async {
    final response = await _client.put(
      '/admin/materias/$id',
      body: request.toJson(),
    );
    return Materia.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /admin/materias/{id} — Elimina una materia.
  Future<MessageResponse> deleteMateria(int id) async {
    final response = await _client.delete('/admin/materias/$id');
    return MessageResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 14-16. Carrera-Materias CRUD ────────────────────────────────

  /// POST /admin/carrera-materias — Asocia materia con carrera.
  Future<Map<String, dynamic>> createCarreraMateria(
    CarreraMateriaCreate request,
  ) async {
    final response = await _client.post(
      '/admin/carrera-materias',
      body: request.toJson(),
    );
    return _client.decodeResponse(response);
  }

  /// PUT /admin/carrera-materias/{cid}/{mid} — Actualiza asociación.
  Future<Map<String, dynamic>> updateCarreraMateria(
    int carreraId,
    int materiaId,
    CarreraMateriaUpdate request,
  ) async {
    final response = await _client.put(
      '/admin/carrera-materias/$carreraId/$materiaId',
      body: request.toJson(),
    );
    return _client.decodeResponse(response);
  }

  /// DELETE /admin/carrera-materias/{cid}/{mid} — Elimina asociación.
  Future<MessageResponse> deleteCarreraMateria(
    int carreraId,
    int materiaId,
  ) async {
    final response = await _client.delete(
      '/admin/carrera-materias/$carreraId/$materiaId',
    );
    return MessageResponse.fromJson(_client.decodeResponse(response));
  }

  // ─── 17-19. Gestión de Materias/Docentes ─────────────────────────

  /// POST /admin/materias/{mid}/asignar/{uid} — Asigna materia a docente.
  Future<MateriaSuscripcionResponse> asignarMateria(
    int materiaId,
    int usuarioId,
  ) async {
    final response = await _client.post(
      '/admin/materias/$materiaId/asignar/$usuarioId',
    );
    return MateriaSuscripcionResponse.fromJson(
      _client.decodeResponse(response),
    );
  }

  /// DELETE /admin/materias/{mid}/desasignar/{uid} — Desasigna materia.
  Future<MateriaSuscripcionResponse> desasignarMateria(
    int materiaId,
    int usuarioId,
  ) async {
    final response = await _client.delete(
      '/admin/materias/$materiaId/desasignar/$usuarioId',
    );
    return MateriaSuscripcionResponse.fromJson(
      _client.decodeResponse(response),
    );
  }

  /// GET /admin/materias/{uid}/disponibles — Materias disponibles para un docente.
  Future<List<MateriaGestionResponse>> getMateriasDisponibles(
    int usuarioId,
  ) async {
    final response = await _client.get(
      '/admin/materias/$usuarioId/disponibles',
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((m) => MateriaGestionResponse.fromJson(m))
            .toList() ??
        [];
  }

  // ─── 20. Documentos Admin ────────────────────────────────────────

  /// GET /admin/documentos — Documentos visibles para administración.
  /// ADMIN ve todos; COLABORADOR solo los de las materias de sus carreras
  /// inscriptas. `todos` incluye pendientes y aprobados, pero no eliminados.
  /// Los docentes usan /docente/documentos.
  ///
  /// [estado] acepta el pattern documentado (todos|pendientes|aprobados|
  /// eliminados) y se envía SIEMPRE, incluido el literal 'todos': acá el
  /// valor sí está documentado, así que no hay que omitirlo como en otros
  /// endpoints. [skip]/[limit] son la paginación estándar (limit 1..100).
  Future<DocumentoPaginatedResponse> getDocumentos({
    int skip = 0,
    int limit = 20,
    String estado = 'todos',
  }) async {
    final response = await _client.get(
      '/admin/documentos',
      queryParams: {
        'skip': skip.toString(),
        'limit': limit.toString(),
        'estado': estado,
      },
    );
    return DocumentoPaginatedResponse.fromJson(
      _client.decodeResponse(response),
    );
  }

  // ─── 23-24. Reportes (documento + comentario unificados) ─────────

  /// GET /admin/reportes/ — Lista reportes de documento y comentario en un
  /// único endpoint paginado ({items, meta}, openapi v1.5.1).
  ///
  /// [tipo] filtra por sujeto: 'documento' o 'comentario' (null = todos).
  /// [estado] filtra por EstadoReporteEnum: PENDIENTE | REVISADO |
  /// DESCARTADO | RESUELTO (null = todos).
  /// [sortBy]/[sortOrder] se envían como `sort_by`/`sort_order`
  /// (fecha_creacion + desc por defecto: los más recientes primero).
  Future<ReportePaginatedResponse> getReportes({
    int skip = 0,
    int limit = 20,
    String? tipo,
    String? estado,
    String sortBy = 'fecha_creacion',
    String sortOrder = 'desc',
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (tipo != null && tipo.isNotEmpty) params['tipo'] = tipo;
    if (estado != null && estado.isNotEmpty) params['estado'] = estado;

    final response = await _client.get('/admin/reportes/', queryParams: params);
    return ReportePaginatedResponse.fromJson(_client.decodeResponse(response));
  }

  /// PUT /admin/reportes/{id}/resolver — Resuelve un reporte (único resolver
  /// para reportes de documento y de comentario).
  Future<Reporte> resolverReporte(
    int reporteId,
    ResolverReporteRequest request,
  ) async {
    final response = await _client.put(
      '/admin/reportes/$reporteId/resolver',
      body: request.toJson(),
    );
    return Reporte.fromJson(_client.decodeResponse(response));
  }

  // ─── 25-26. Solicitudes de Rol ───────────────────────────────────

  /// GET /admin/solicitudes-rol/ — Lista solicitudes de cambio de rol.
  Future<List<SolicitudCambioRol>> getSolicitudesRol({
    int skip = 0,
    int limit = 20,
    String? rolSolicitado,
    String? estado,
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (rolSolicitado != null) params['rol_solicitado'] = rolSolicitado;
    if (estado != null) params['estado'] = estado;

    final response = await _client.get(
      '/admin/solicitudes-rol/',
      queryParams: params,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((s) => SolicitudCambioRol.fromJson(s))
            .toList() ??
        [];
  }

  /// PUT /admin/solicitudes-rol/{id}/resolver — Resuelve solicitud de rol.
  Future<SolicitudCambioRol> resolverSolicitudRol(
    int solicitudId,
    ResolverSolicitudRequest request,
  ) async {
    final response = await _client.put(
      '/admin/solicitudes-rol/$solicitudId/resolver',
      body: request.toJson(),
    );
    return SolicitudCambioRol.fromJson(_client.decodeResponse(response));
  }
}

// ─── Imports necesarios para tipos de respuesta ──────────────────────
// Universidad y Facultad se importan desde sus modelos existentes.
// carreras, materias, etc. se importan donde se usen.
