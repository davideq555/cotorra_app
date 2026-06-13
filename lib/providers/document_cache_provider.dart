import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/cache_utils.dart';

/// Proveedor de caché para los mejores documentos.
/// TTL: 5 minutos — datos relativamente estáticos.
class DocumentCacheProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  static const String _cacheKey = 'cache_mejores_documentos';
  static const Duration _ttl = Duration(minutes: 5);

  List<Documento> _documentos = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _fromCache = false;

  List<Documento> get documentos => _documentos;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get fromCache => _fromCache;

  /// Carga inicial: muestra caché al toque, refresca en background si expiró.
  Future<void> load() async {
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
      _documentos = cached;
      _fromCache = true;
      _isLoading = false;
      notifyListeners();

      // 2. Refrescar en background si el TTL expiró
      if (_shouldRefresh()) {
        await _refresh();
      }
      return;
    }

    // 3. Sin caché: cargar del servidor
    await _refresh();
    _isLoading = false;
    notifyListeners();
  }

  /// Fuerza recarga desde el servidor (ignora caché).
  Future<void> reload() async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    await _refresh();

    _isRefreshing = false;
    notifyListeners();
  }

  bool _shouldRefresh() {
    // Simple: siempre refresca si came from cache
    // (en producción podrías guardar el timestamp exacto)
    return _fromCache;
  }

  Future<void> _refresh() async {
    try {
      final docs = await _apiService.getMejoresDocumentos();
      _documentos = docs;
      _errorMessage = null;
      _fromCache = false;

      // Guardar en caché
      await CacheUtils.setList<Documento>(
        key: _cacheKey,
        data: docs,
        toJson: (doc) => doc.toJson(),
      );
    } catch (e) {
      print('Error refreshing best documents: $e');
      _errorMessage = 'Error al cargar los documentos: $e';
      // Si ya tenemos datos en caché, no mostrar error
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
}
