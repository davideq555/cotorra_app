import 'package:cotorra_app/models/comentario.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de comentarios — lectura puntual.
///
/// Requiere autenticación Bearer (el [ApiClient] debe tener token activo).
///
/// Uso:
/// ```dart
/// final client = ApiClient()..setToken(token);
/// final comentario = await CommentsService(client).getComentario(42);
/// ```
class CommentsService {
  final ApiClient _client;

  CommentsService(this._client);

  /// GET /comentarios/{id} — Obtiene un comentario por ID (requiere auth).
  Future<Comentario> getComentario(int comentarioId) async {
    final response = await _client.get('/comentarios/$comentarioId');
    return Comentario.fromJson(_client.decodeResponse(response));
  }
}
