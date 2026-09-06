import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/screens/gestion/docente_documentos_screen.dart';
import 'package:cotorra_app/services/api/docente_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Materias a cargo del DOCENTE (T2.2).
///
/// Fuente: GET /materias-suscritas/gestion — el servidor devuelve objetos
/// materia completos con nombre y código, sin join de catálogo (design
/// addendum, reemplaza a D3 para el hub docente). El endpoint no pagina:
/// se carga la lista completa. Tap → documentos de la materia (T2.3).
class DocenteMateriasScreen extends StatefulWidget {
  const DocenteMateriasScreen({super.key});

  @override
  State<DocenteMateriasScreen> createState() => _DocenteMateriasScreenState();
}

class _DocenteMateriasScreenState extends State<DocenteMateriasScreen> {
  final List<Materia> _materias = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  /// ApiClient ad-hoc con el token de sesión (design D3: sin provider nuevo).
  DocenteService _service(BuildContext context) {
    final client = ApiClient();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && token.isNotEmpty) client.setToken(token);
    return DocenteService(client);
  }

  Future<void> _loadInitial() => _fetch();

  Future<void> _refresh() => _fetch();

  Future<void> _fetch() async {
    setState(() {
      _isLoading = _materias.isEmpty;
      _errorMessage = null;
    });
    try {
      final materias = await _service(context).getMateriasGestion();
      if (!mounted) return;
      setState(() {
        _materias
          ..clear()
          ..addAll(materias);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar tus materias.';
        _isLoading = false;
      });
    }
  }

  void _openDocumentos(Materia materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocenteDocumentosScreen(materia: materia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Moderación de documentos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshableList<Materia>(
        items: _materias,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        // Spec cross-cutting: cero materias es estado vacío explícito,
        // nunca un error.
        emptyMessage: 'No tenés materias a cargo.',
        horizontalPadding: 16,
        onRefresh: _refresh,
        onRetry: _loadInitial,
        itemBuilder: (context, materia, index) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFF7CB342),
            ),
            title: Text(
              materia.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: materia.codigo == null || materia.codigo!.isEmpty
                ? null
                : Text(
                    materia.codigo!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _openDocumentos(materia),
          ),
        ),
      ),
    );
  }
}
