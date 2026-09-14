import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/api/documents_service.dart';
import '../services/api/catalogs_service.dart';
import 'auth_provider.dart';

class SearchProvider with ChangeNotifier {
  final ApiClient _client = ApiClient();
  late final DocumentsService _docsService = DocumentsService(_client);
  late final CatalogsService _catalogs = CatalogsService(_client);
  final AuthProvider authProvider;

  List<Documento> _documentos = [];
  List<Materia> _materias = [];
  bool _isLoading = false;
  bool _materiasLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todos';
  bool _mejoresDocumentosLoaded = false;

  // Advanced filters
  Materia? _selectedMateria;
  String? _selectedYear;
  String _searchQuery = '';
  bool _filtersExpanded = false;

  // Cascade filters: facultades -> carreras -> materias
  List<Facultad> _facultades = [];
  List<Carrera> _carreras = [];
  List<Materia> _carreraMaterias = [];
  Facultad? _selectedFacultad;
  Carrera? _selectedCarrera;
  bool _facultadesLoading = false;
  bool _carrerasLoading = false;
  bool _carreraMateriasLoading = false;

  SearchProvider(this.authProvider);

  List<Documento> get documentos {
    if (_selectedCategory == 'Todos') {
      return _documentos;
    }
    return _documentos
        .where((doc) => doc.materia?.nombre == _selectedCategory)
        .toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  Materia? get selectedMateria => _selectedMateria;
  String? get selectedYear => _selectedYear;
  List<Materia> get materias => _materias;
  bool get materiasLoading => _materiasLoading;
  bool get filtersExpanded => _filtersExpanded;
  bool get hasActiveFilters =>
      _selectedMateria != null || _selectedYear != null;

  // Cascade getters
  List<Facultad> get facultades => _facultades;
  List<Carrera> get carreras => _carreras;
  List<Materia> get carreraMaterias => _carreraMaterias;
  Facultad? get selectedFacultad => _selectedFacultad;
  Carrera? get selectedCarrera => _selectedCarrera;
  bool get facultadesLoading => _facultadesLoading;
  bool get carrerasLoading => _carrerasLoading;
  bool get carreraMateriasLoading => _carreraMateriasLoading;
  bool get hasCascadeFilters =>
      _selectedCarrera != null || _selectedMateria != null;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleFiltersExpanded() {
    _filtersExpanded = !_filtersExpanded;
    notifyListeners();
  }

  void setSelectedMateria(Materia? materia) {
    _selectedMateria = materia;
    notifyListeners();
  }

  void setSelectedYear(String? year) {
    _selectedYear = year;
    notifyListeners();
  }

  void clearFilters() {
    _selectedMateria = null;
    _selectedYear = null;
    notifyListeners();
  }

  /// Generates list of academic years (current year down to 2020)
  List<String> getAvailableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(
      currentYear - 2019,
      (index) => (currentYear - index).toString(),
    );
  }

  /// Loads all materias for the dropdown filter
  Future<void> loadMaterias() async {
    if (_materias.isNotEmpty) return;

    _materiasLoading = true;
    notifyListeners();

    try {
      _materias = await _catalogs.getMaterias();
    } catch (e) {
      debugPrint('Error loading materias: $e');
      _materias = [];
    }

    _materiasLoading = false;
    notifyListeners();
  }

  /// Loads facultades for cascade filter
  Future<void> loadFacultades() async {
    if (_facultades.isNotEmpty) return;

    _facultadesLoading = true;
    notifyListeners();

    try {
      _facultades = await _catalogs.getFacultades();
    } catch (e) {
      debugPrint('Error loading facultades: $e');
      _facultades = [];
    }

    _facultadesLoading = false;
    notifyListeners();
  }

  /// Loads carreras when a facultad is selected
  Future<void> loadCarrerasPorFacultad(int facultadId) async {
    _carrerasLoading = true;
    _carreraMaterias = [];
    _selectedCarrera = null;
    _selectedMateria = null;
    notifyListeners();

    try {
      _carreras = await _catalogs.getCarrerasByFacultadId(facultadId);
    } catch (e) {
      debugPrint('Error loading carreras: $e');
      _carreras = [];
    }

    _carrerasLoading = false;
    notifyListeners();
  }

  /// Loads materias when a carrera is selected
  Future<void> loadMateriasPorCarrera(int carreraId) async {
    _carreraMateriasLoading = true;
    _selectedMateria = null;
    notifyListeners();

    try {
      _carreraMaterias = await _catalogs.getMateriasByCarreraId(carreraId);
    } catch (e) {
      debugPrint('Error loading materias: $e');
      _carreraMaterias = [];
    }

    _carreraMateriasLoading = false;
    notifyListeners();
  }

  /// Initializes filters with user's first carrera
  Future<void> initUserFilters() async {
    if (_selectedCarrera != null) return;
    if (authProvider.userCarreras.isEmpty) return;

    _selectedCarrera = authProvider.userCarreras.first;
    notifyListeners();
    await loadMateriasPorCarrera(_selectedCarrera!.id);
  }

  /// Sets selected facultad and resets downstream selections
  void setSelectedFacultad(Facultad? facultad) {
    _selectedFacultad = facultad;
    _selectedCarrera = null;
    _selectedMateria = null;
    _carreras = [];
    _carreraMaterias = [];

    if (facultad != null) {
      loadCarrerasPorFacultad(facultad.id);
    } else {
      notifyListeners();
    }
  }

  /// Sets selected carrera and resets materia selection
  void setSelectedCarrera(Carrera? carrera) {
    _selectedCarrera = carrera;
    _selectedMateria = null;
    _carreraMaterias = [];

    if (carrera != null) {
      loadMateriasPorCarrera(carrera.id);
    } else {
      notifyListeners();
    }
  }

  /// Clears all cascade filters
  void clearCascadeFilters() {
    _selectedCarrera = null;
    _selectedMateria = null;
    _carreraMaterias = [];
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
      _documentos = await _docsService.getMejoresDocumentos();
      _mejoresDocumentosLoaded = true;
    } catch (e) {
      debugPrint('Error loading best documents: $e');
      _errorMessage =
          'Error al cargar los documentos. Por favor intenta de nuevo.';
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
    _searchQuery = query;
    await searchWithFilters();
  }

  /// Performs search with all active filters
  Future<void> searchWithFilters() async {
    if (!authProvider.isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (authProvider.token != null) {
        _client.setToken(authProvider.token!);
      }
      _documentos = await _docsService.getDocumentos(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        materiaId: _selectedMateria?.id,
        anoAcademico: _selectedYear,
      );
    } catch (e) {
      debugPrint('Error searching documents: $e');
      _errorMessage =
          'Error al cargar los documentos. Por favor intenta de nuevo.';
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
