import 'package:cotorra_app/models/documento.dart';
import 'package:http/http.dart' as http;
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de documentos — CRUD, búsqueda, upload, descarga.
class DocumentsService {
  final ApiClient _client;

  DocumentsService(this._client);

  // ─── Búsqueda / Listado ───────────────────────────────────────────

  /// GET /documentos/ — Lista documentos aprobados con filtros y paginación.
  Future<List<Documento>> getDocumentos({
    String? query,
    int? tipo,
    int? materiaId,
    String? anoAcademico,
    String sortBy = 'fecha_subida',
    String sortOrder = 'desc',
    int skip = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (tipo != null) params['tipo'] = tipo.toString();
    if (materiaId != null) params['materia_id'] = materiaId.toString();
    if (anoAcademico != null && anoAcademico.isNotEmpty) {
      params['año_academico'] = anoAcademico;
    }

    final response = await _client.get('/documentos/', queryParams: params);
    final data = _client.decodeResponse(response);

    // Backend devuelve {items: [...]} o array directo
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic> && data.containsKey('items')) {
      items = data['items'] as List<dynamic>;
    } else {
      items = [];
    }
    return items.map((json) => Documento.fromJson(json)).toList();
  }

  /// GET /documentos/mejores — Los 6 documentos mejor rankeados.
  Future<List<Documento>> getMejoresDocumentos() async {
    final response = await _client.get('/documentos/mejores');
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Documento.fromJson(j))
            .toList() ??
        [];
  }

  // ─── Detalle ──────────────────────────────────────────────────────

  /// GET /documentos/{id} — Detalle de un documento.
  Future<Documento> getDocumento(int documentoId) async {
    final response = await _client.get('/documentos/$documentoId');
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// GET /documentos/usuario/{id} — Documentos de un usuario.
  Future<List<Documento>> getDocumentosUsuario(
    int usuarioId, {
    int skip = 0,
    int limit = 20,
    bool includeDeleted = false,
  }) async {
    final response = await _client.get(
      '/documentos/usuario/$usuarioId',
      queryParams: {
        'skip': skip.toString(),
        'limit': limit.toString(),
        'include_deleted': includeDeleted.toString(),
      },
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Documento.fromJson(j))
            .toList() ??
        [];
  }

  // ─── CRUD ─────────────────────────────────────────────────────────

  /// POST /documentos/ — Crea un documento (tipo FILE o LINK).
  Future<Documento> createDocumento(Map<String, dynamic> data) async {
    final response = await _client.post('/documentos/', body: data);
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// POST /documentos/upload — Sube documento con archivo (multipart).
  Future<Documento> uploadDocumento({
    required String titulo,
    required List<int> archivoBytes,
    required int tipo,
    String? descripcion,
    String? autor,
    int? materiaId,
    String? anoAcademico,
    List<String>? tags,
  }) async {
    final response = await _client.multipartPost(
      '/documentos/upload',
      fields: {
        'titulo': titulo,
        'tipo': tipo.toString(),
        if (descripcion != null) 'descripcion': descripcion,
        if (autor != null) 'autor': autor,
        if (materiaId != null) 'materia_id': materiaId.toString(),
        if (anoAcademico != null) 'año_academico': anoAcademico,
        if (tags != null) 'tags': tags.join(','),
      },
      files: [
        http.MultipartFile.fromBytes(
          'archivo',
          archivoBytes,
          filename: 'documento.pdf',
        ),
      ],
    );
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// POST /documentos/link — Crea documento desde enlace externo.
  Future<Documento> createDocumentoLink({
    required String titulo,
    required String urlExterna,
    required int tipo,
    String? descripcion,
    String? autor,
    int? materiaId,
    String? anoAcademico,
    List<String>? tags,
  }) async {
    final response = await _client.post(
      '/documentos/link',
      body: {
        'titulo': titulo,
        'url_externa': urlExterna,
        'tipo': tipo,
        if (descripcion != null) 'descripcion': descripcion,
        if (autor != null) 'autor': autor,
        if (materiaId != null) 'materia_id': materiaId,
        if (anoAcademico != null) 'año_academico': anoAcademico,
        if (tags != null) 'tags': tags,
      },
    );
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// PUT /documentos/{id} — Actualiza un documento.
  Future<Documento> updateDocumento(
      int documentoId, Map<String, dynamic> data) async {
    final response = await _client.put('/documentos/$documentoId', body: data);
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// DELETE /documentos/{id} — Elimina un documento (borrado lógico).
  Future<void> deleteDocumento(int documentoId) async {
    await _client.delete('/documentos/$documentoId');
  }

  // ─── Descarga ─────────────────────────────────────────────────────

  /// GET /documentos/{id}/descargar — Descarga el archivo.
  /// Retorna los bytes del archivo.
  Future<List<int>> descargarDocumento(int documentoId) async {
    final response = await _client.get('/documentos/$documentoId/descargar');
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download: ${response.statusCode}');
  }

  // ─── Moderação (DOCENTE/COLABORADOR) ──────────────────────────────

  /// POST /documentos/{id}/aprobar — Aprueba un documento.
  Future<Documento> aprobarDocumento(int documentoId) async {
    final response = await _client.post('/documentos/$documentoId/aprobar');
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// POST /documentos/{id}/desaprobar — Des aprueba un documento.
  Future<Documento> desaprobarDocumento(int documentoId) async {
    final response = await _client.post('/documentos/$documentoId/desaprobar');
    return Documento.fromJson(_client.decodeResponse(response));
  }

  /// POST /documentos/{id}/restaurar — Restaura un documento eliminado.
  Future<Documento> restaurarDocumento(int documentoId) async {
    final response = await _client.post('/documentos/$documentoId/restaurar');
    return Documento.fromJson(_client.decodeResponse(response));
  }
}
