import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/cache_utils.dart';

/// Proveedor de caché para los documentos subidos por el usuario.
/// TTL: 15 minutos — datos del perfil cambian solo con acción del usuario.
class UserDocumentsCacheProvider with ChangeNotifier {
  final ApiClient _client = ApiClient();
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
      print('Error refreshing user documents: $e');
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
}
