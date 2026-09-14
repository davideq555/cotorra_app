import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/cache_utils.dart';

/// Proveedor de caché para los documentos subidos por el usuario.
/// TTL: 15 minutos — datos del perfil cambian solo con acción del usuario.
class UserDocumentsCacheProvider with ChangeNotifier {
  /// [client] es opcional y solo para tests: permite inyectar un ApiClient
  /// con HTTP mock. Sin inyectar, se comporta igual que antes (main.dart
  /// construye `UserDocumentsCacheProvider()` sin argumentos).
  UserDocumentsCacheProvider({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;
  late final DocumentsService _docsService = DocumentsService(_client);

  static const String _cacheKey = 'cache_user_documents';
  static const Duration _ttl = Duration(minutes: 15);

  List<Documento> _documentos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Documento> get documentos => _documentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga inicial: muestra caché al toque, refresca en background si expiró.
  Future<void> load(String token, int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Intentar mostrar caché primero
    final cached = await CacheUtils.getList<Documento>(
      key: _cacheKey,
      fromJson: Documento.fromJson,
      ttl: _ttl,
    );

    if (cached != null) {
      _documentos = cached;
      _isLoading = false;
      notifyListeners();

      // 2. Refrescar en background
      await _refresh(token, userId);
      return;
    }

    // 3. Sin caché: cargar del servidor
    await _refresh(token, userId);
    _isLoading = false;
    notifyListeners();
  }

  /// Fuerza recarga desde el servidor (ignora caché).
  Future<void> reload(String token, int userId) async {
    _errorMessage = null;
    await _refresh(token, userId);
    notifyListeners();
  }

  Future<void> _refresh(String token, int userId) async {
    try {
      _client.setToken(token);
      _documentos = await _docsService.getDocumentosUsuario(userId);
      _errorMessage = null;
      _isLoading = false;

      await CacheUtils.setList<Documento>(
        key: _cacheKey,
        data: _documentos,
        toJson: (doc) => doc.toJson(),
      );
    } catch (e) {
      debugPrint('Error refreshing user documents: $e');
      _isLoading = false;
      if (_documentos.isEmpty) {
        _errorMessage = 'Error al cargar los documentos.';
      }
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Aplica una edición local tras un PUT exitoso (R5: coherencia de caché).
  ///
  /// Si el [updated] ya está en memoria: reemplaza en el lugar, re-persiste
  /// `cache_user_documents` y notifica — sin GET extra. Si el id no está
  /// (la lista local quedó desincronizada), la mutación no tiene dónde
  /// aplicarse: se invalida la caché y se refresca desde el servidor, que
  /// es la fuente de verdad.
  Future<void> applyUpdate(
    Documento updated, {
    required String token,
    required int userId,
  }) async {
    final index = _documentos.indexWhere((doc) => doc.id == updated.id);
    if (index == -1) {
      await _invalidateAndRefresh(token, userId);
      return;
    }
    _documentos[index] = updated;
    await _persistCacheAndNotify();
  }

  /// Aplica un borrado local tras un DELETE exitoso (R5: coherencia de caché).
  ///
  /// Quita el [id] de memoria, re-persiste la caché y notifica. Si el id no
  /// estaba en la lista local (desincronización), invalida la caché y
  /// refresca desde el servidor. Nota: al quedar la lista vacía,
  /// `CacheUtils.getList` la trata como "sin caché" (retorna null), por lo
  /// que la próxima apertura del perfil cargará del servidor y mostrará el
  /// estado vacío — el id eliminado nunca resucita.
  Future<void> applyDelete(
    int id, {
    required String token,
    required int userId,
  }) async {
    final before = _documentos.length;
    _documentos.removeWhere((doc) => doc.id == id);
    if (_documentos.length == before) {
      await _invalidateAndRefresh(token, userId);
      return;
    }
    await _persistCacheAndNotify();
  }

  /// Re-persiste `cache_user_documents` con el estado actual y notifica.
  /// Actualizar el timestamp en cada mutación es lo que garantiza que las
  /// lecturas dentro del TTL vean el estado nuevo (R5).
  Future<void> _persistCacheAndNotify() async {
    await CacheUtils.setList<Documento>(
      key: _cacheKey,
      data: _documentos,
      toJson: (doc) => doc.toJson(),
    );
    notifyListeners();
  }

  /// Manejo común de mutaciones sobre un id desconocido localmente:
  /// invalidar la caché y traer el estado del servidor.
  Future<void> _invalidateAndRefresh(String token, int userId) async {
    await CacheUtils.invalidate(_cacheKey);
    await _refresh(token, userId);
  }
}
