import 'package:cotorra_app/models/documento.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthProvider authProvider;
  
  List<Documento> _documentos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todos';
  bool _mejoresDocumentosLoaded = false;

  SearchProvider(this.authProvider);

  List<Documento> get documentos {
    if (_selectedCategory == 'Todos') {
      return _documentos;
    }
    return _documentos.where((doc) => doc.materia?.nombre == _selectedCategory).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Carga los documentos mejor rankeados para el dashboard
  /// Solo carga una vez; llamadas subsiguientes son no-ops hasta que se llame reloadMejoresDocumentos
  Future<void> loadMejoresDocumentos() async {
    if (_mejoresDocumentosLoaded) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documentos = await _apiService.getMejoresDocumentos();
      _mejoresDocumentosLoaded = true;
    } catch (e) {
      print('Error loading best documents: $e');
      _errorMessage = 'Error al cargar los documentos. Por favor intenta de nuevo.';
      _documentos = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fuerza la recarga de los mejores documentos (ignora el flag de carga única)
  Future<void> reloadMejoresDocumentos() async {
    _mejoresDocumentosLoaded = false;
    await loadMejoresDocumentos();
  }

  Future<void> searchDocumentos(String query) async {
    if (!authProvider.isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documentos = await _apiService.getDocumentos(authProvider.token!, query: query);
    } catch (e) {
      print('Error searching documents: $e');
      _errorMessage = 'Error al cargar los documentos. Por favor intenta de nuevo.';
      _documentos = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
