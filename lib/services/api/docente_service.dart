import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/usuario_materia.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio del flujo DOCENTE — endpoints scopeados de openapi.json.
///
/// El servidor restringe el scope por token: si el usuario no es docente
/// de la materia/documento, responde 403 y [ApiClient.decodeResponse]
/// lo propaga como [ApiException]. El cliente nunca simula permisos.
class DocenteService {
  final ApiClient _client;

  DocenteService(this._client);

  /// GET /materias-suscritas/ — suscripciones usuario↔materia del usuario
  /// autenticado. Incluye también suscripciones de alumno: quien necesite
  /// solo materias docentes filtra por [UsuarioMateria.tipoRelacion].
  ///
  /// Default [limit] 100: la pantalla de materias del docente toma todo
  /// en una sola página (no se espera volumen mayor por docente).
  Future<List<UsuarioMateria>> getMateriasSuscritas({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.get(
      '/materias-suscritas/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => UsuarioMateria.fromJson(j))
            .toList() ??
        [];
  }

  /// GET /materias-suscritas/gestion — materias a cargo del docente
  /// autenticado, verificadas en vivo (2026-09-04): cada fila es un objeto
  /// materia completo {id, nombre, descripcion, codigo}, no una suscripción
  /// usuario↔materia; el servidor ya resuelve los nombres.
  ///
  /// NOTA DE CONTRATO: el endpoint ya figura en openapi.json. [Materia.fromJson]
  /// tolera la forma verificada en vivo (campos opcionales con defaults) sin
  /// afectar a consumidores existentes.
  /// Devuelve la lista completa: el endpoint no pagina (design addendum).
  Future<List<Materia>> getMateriasGestion() async {
    final response = await _client.get('/materias-suscritas/gestion');
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)?.map((j) => Materia.fromJson(j)).toList() ??
        [];
  }

  /// GET /docente/materias/{id}/documentos — documentos de una materia
  /// gestionada por el docente (array plano, sin paginación).
  ///
  /// [estado] es un filtro server-side. La UI ahora lo envía para los chips
  /// Pendientes ('pendientes') y Aprobados ('aprobados'), y lo OMITE para
  /// Todos: el set de valores NO está documentado en este endpoint (string
  /// plano, sin enum), así que nunca se envía el literal 'todos'. El filtro
  /// client-side se mantiene como red de seguridad por si el backend ignora
  /// el parámetro.
  Future<List<Documento>> getDocumentosMateria(
    int materiaId, {
    String? estado,
  }) async {
    final response = await _client.get(
      '/docente/materias/$materiaId/documentos',
      queryParams: estado != null && estado.isNotEmpty
          ? {'estado': estado}
          : null,
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Documento.fromJson(j))
            .toList() ??
        [];
  }
}
