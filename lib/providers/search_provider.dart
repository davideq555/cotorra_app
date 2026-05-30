import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../data/models/models.dart';
import 'auth_provider.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthProvider authProvider;
  
  List<Documento> _documentos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todos';

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
