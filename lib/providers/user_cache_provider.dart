import 'package:cotorra_app/models/usuario.dart';
import 'package:flutter/foundation.dart';
import '../utils/cache_utils.dart';

/// Proveedor de caché para el perfil de usuario.
/// TTL: 15 minutos — datos de perfil no cambian frecuentemente.
/// Nota: usar ApiService cuando el backend tenga endpoint GET /usuarios/{id}
class UserCacheProvider with ChangeNotifier {
  static const String _cacheKey = 'cache_user_profile';
  static const Duration _ttl = Duration(minutes: 15);

  Usuario? _user;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _fromCache = false;

  Usuario? get user => _user;
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
    final cached = await CacheUtils.get<Usuario>(
      key: _cacheKey,
      fromJson: Usuario.fromJson,
      ttl: _ttl,
    );

    if (cached != null) {
      _user = cached;
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
      // Asumiendo que existe un endpoint GET /usuarios/{id}
      // Si no existe, usar getDocumentos del usuario para validar que sigue autenticado
      // y usar datos del token si están disponibles
      // Por ahora, solo guardamos en caché cuando vienen del servidor
      // Este método se puede adaptar cuando el backend tenga endpoint de perfil
      _errorMessage = null;
    } catch (e) {
      print('Error refreshing user profile: $e');
      if (_user == null) {
        _errorMessage = 'Error al cargar el perfil.';
      }
    }
    notifyListeners();
  }

  /// Actualiza el perfil en caché (ej. después de editar).
  Future<void> updateCache(Usuario user) async {
    _user = user;
    await CacheUtils.set<Usuario>(
      key: _cacheKey,
      data: user,
      toJson: (u) => u.toJson(),
    );
    notifyListeners();
  }

  /// Invalida la caché del perfil (ej. después de editar).
  Future<void> invalidate() async {
    await CacheUtils.invalidate(_cacheKey);
    _user = null;
    _fromCache = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
