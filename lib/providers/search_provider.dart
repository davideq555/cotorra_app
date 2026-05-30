import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../data/models/models.dart';
import 'auth_provider.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthProvider authProvider;
  
  List<Documento> _documentos = [];
  bool _isLoading = false;

  SearchProvider(this.authProvider);

  List<Documento> get documentos => _documentos;
  bool get isLoading => _isLoading;

  Future<void> searchDocumentos(String query) async {
    if (!authProvider.isAuthenticated) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _documentos = await _apiService.getDocumentos(authProvider.token!, query: query);
    } catch (e) {
      print('Error searching documents: $e');
      _documentos = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
