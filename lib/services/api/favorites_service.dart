import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de favoritos — listar, agregar, quitar, toggle, check.
class FavoritesService {
  final ApiClient _client;

  FavoritesService(this._client);

  // ─── Listado ──────────────────────────────────────────────────────

  /// GET /favoritos/ — Documentos favoritos del usuario.
  Future<List<Documento>> getFavoritos({int skip = 0, int limit = 100}) async {
    final response = await _client.get(
      '/favoritos/',
      queryParams: {'skip': skip.toString(), 'limit': limit.toString()},
    );
    final data = _client.decodeResponse(response);
    return (data as List<dynamic>?)
            ?.map((j) => Documento.fromJson(j))
            .toList() ??
        [];
  }

  // ─── Toggle ───────────────────────────────────────────────────────

  /// POST /favoritos/toggle/{id} — Alterna favorito (agregar/quitar).
  Future<Map<String, dynamic>> toggleFavorito(int documentoId) async {
    final response = await _client.post('/favoritos/toggle/$documentoId');
    return _client.decodeResponse(response);
  }

  // ─── Add / Remove explícitos ─────────────────────────────────────

  /// POST /favoritos/{id} — Agrega a favoritos.
  Future<Map<String, dynamic>> addFavorito(int documentoId) async {
    final response = await _client.post('/favoritos/$documentoId');
    return _client.decodeResponse(response);
  }

  /// DELETE /favoritos/{id} — Quita de favoritos.
  Future<Map<String, dynamic>> removeFavorito(int documentoId) async {
    final response = await _client.delete('/favoritos/$documentoId');
    return _client.decodeResponse(response);
  }

  // ─── Check ────────────────────────────────────────────────────────

  /// GET /favoritos/check/{id} — Verifica si un doc es favorito.
  Future<bool> checkFavorito(int documentoId) async {
    final response = await _client.get('/favoritos/check/$documentoId');
    final data = _client.decodeResponse(response);
    return data['is_favorite'] ?? false;
  }
}
