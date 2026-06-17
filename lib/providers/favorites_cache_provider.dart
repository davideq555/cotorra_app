import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/cache_utils.dart';

/// Proveedor de caché para favoritos del usuario.
/// TTL: 15 minutos — favoritos cambian solo con acción del usuario.
class FavoritesCacheProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  static const String _cacheKey = 'cache_favorites';
  static const String _countKey = 'favorites_count';
  static const Duration _ttl = Duration(minutes: 15);

  List<Documento> _favorites = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _fromCache = false;

  List<Documento> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get fromCache => _fromCache;

  /// Carga inicial: muestra caché al toque, refresca en background si expiró.
  Future<void> load(String token, int userId) async {
    _isLoading = true;
    _errorMessage = null;
    _fromCache = false;
    notifyListeners();

    // 1. Intentar mostrar caché primero
    final cached = await CacheUtils.getList<Documento>(
      key: _cacheKey,
      fromJson: Documento.fromJson,
      ttl: _ttl,
    );

    if (cached != null) {
      _favorites = cached;
      _fromCache = true;
      _isLoading = false;
      notifyListeners();

      // 2. Refrescar en background si hay datos
      if (_fromCache) {
        await _refresh(token, userId);
      }
      return;
    }

    // 3. Sin caché: cargar del servidor
    await _refresh(token, userId);
    _isLoading = false;
    notifyListeners();
  }

  /// Fuerza recarga desde el servidor (ignora caché).
  Future<void> reload(String token, int userId) async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    await _refresh(token, userId);

    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _refresh(String token, int userId) async {
    try {
      _favorites = await _apiService.getFavoritos(token);
      _errorMessage = null;
      _fromCache = false;

      // Guardar en caché y persistir count
      await CacheUtils.setList<Documento>(
        key: _cacheKey,
        data: _favorites,
        toJson: (doc) => doc.toJson(),
      );
      await _persistCount(_favorites.length);
    } catch (e) {
      print('Error refreshing favorites: $e');
      if (_favorites.isEmpty) {
        _errorMessage = 'Error al cargar favoritos.';
      }
    }
    notifyListeners();
  }

  Future<void> _persistCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, count);
  }

  /// Alterna favorito y actualiza caché localmente.
  Future<void> toggleFavorite(String token, int documentoId) async {
    try {
      final result = await _apiService.toggleFavorito(token, documentoId);
      final isFavorite = result['is_favorite'] as bool;

      if (isFavorite) {
        // Remover de favoritos locales (no tenemos el doc completo)
        _favorites.removeWhere((doc) => doc.id == documentoId);
      } else {
        // Agregar a favoritos (necesitaríamos el doc del servidor)
        // Por ahora, invalidamos para forzar refresh
        await invalidate();
        return;
      }

      // Actualizar caché
      await CacheUtils.setList<Documento>(
        key: _cacheKey,
        data: _favorites,
        toJson: (doc) => doc.toJson(),
      );

      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      _errorMessage = 'Error al actualizar favorito.';
      notifyListeners();
    }
  }

  /// Invalida la caché de favoritos.
  Future<void> invalidate() async {
    await CacheUtils.invalidate(_cacheKey);
    _favorites = [];
    _fromCache = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtiene el count de favoritos persistido (sin hacer request).
  static Future<int> getPersistedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }
}
