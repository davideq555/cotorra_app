import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/catalogs_service.dart';
import 'package:cotorra_app/services/api/users_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Gestión de las carreras del usuario: listar, quitar y agregar.
/// Backend: GET/POST/DELETE /usuarios/{id}/carreras[/{carrera_id}]
/// y catálogo GET /carreras/.
class MisCarrerasScreen extends StatefulWidget {
  const MisCarrerasScreen({super.key});

  @override
  State<MisCarrerasScreen> createState() => _MisCarrerasScreenState();
}

class _MisCarrerasScreenState extends State<MisCarrerasScreen> {
  bool _isProcessing = false;

  ApiClient _authedClient() {
    final client = ApiClient();
    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) client.setToken(token);
    return client;
  }

  Future<List<Carrera>?> _reloadCarreras(int usuarioId) async {
    try {
      final carreras = await UsersService(
        _authedClient(),
      ).getUsuarioCarreras(usuarioId);
      if (!mounted) return null;
      await context.read<AuthProvider>().applyCarreras(carreras);
      return carreras;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo refrescar tus carreras. $_errorMsg(e)'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _removeCarrera(Carrera carrera) async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null || _isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Quitar carrera?'),
        content: Text(
          'Vas a quitar "${carrera.nombre}" de tu perfil. '
          'Podés volver a agregarla cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UsersService(
        _authedClient(),
      ).removeCarreraFromUsuario(auth.userId!, carrera.id);
      await _reloadCarreras(auth.userId!);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Quitaste "${carrera.nombre}"'),
          backgroundColor: const Color(0xFF7CB342),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo quitar la carrera. ${_errorMsg(e)}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _addCarrera() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null || _isProcessing) return;

    final selected = await showModalBottomSheet<Carrera>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CarreraPickerSheet(
        excludeIds: auth.userCarreras.map((c) => c.id).toSet(),
        authedClientFactory: _authedClient,
      ),
    );
    if (selected == null || !mounted) return;

    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UsersService(
        _authedClient(),
      ).addCarreraToUsuario(auth.userId!, selected.id);
      await _reloadCarreras(auth.userId!);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Agregaste "${selected.nombre}"'),
          backgroundColor: const Color(0xFF7CB342),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo agregar la carrera. ${_errorMsg(e)}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _errorMsg(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Tu sesión expiró.';
      final message = e.message.trim();
      if (message.isNotEmpty) return message;
    }
    return 'Revisá tu conexión e intentá de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final carreras = context.watch<AuthProvider>().userCarreras;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis carreras',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: carreras.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Todavía no tenés carreras asignadas.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                ...carreras.map(
                  (carrera) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF7CB342),
                      ),
                      title: Text(
                        carrera.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Quitar carrera',
                        onPressed: _isProcessing
                            ? null
                            : () => _removeCarrera(carrera),
                      ),
                    ),
                  ),
                ),
                if (_isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _addCarrera,
        backgroundColor: const Color(0xFF7CB342),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar carrera'),
      ),
    );
  }
}

/// Bottom sheet con el catálogo de carreras, con buscador.
class _CarreraPickerSheet extends StatefulWidget {
  final Set<int> excludeIds;
  final ApiClient Function() authedClientFactory;

  const _CarreraPickerSheet({
    required this.excludeIds,
    required this.authedClientFactory,
  });

  @override
  State<_CarreraPickerSheet> createState() => _CarreraPickerSheetState();
}

class _CarreraPickerSheetState extends State<_CarreraPickerSheet> {
  final _searchController = TextEditingController();
  List<Carrera>? _todas;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final carreras = await CatalogsService(
        widget.authedClientFactory(),
      ).getCarreras(limit: 200);
      if (!mounted) return;
      setState(() {
        _todas = carreras
            .where((c) => !widget.excludeIds.contains(c.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las carreras del catálogo.';
        _isLoading = false;
      });
    }
  }

  List<Carrera> get _filtradas {
    final todas = _todas ?? [];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return todas;
    return todas.where((c) => c.nombre.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agregar carrera',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar carrera…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : _filtradas.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _todas!.isEmpty
                            ? 'Ya tenés todas las carreras del catálogo.'
                            : 'No encontramos carreras con ese nombre.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtradas.length,
                      itemBuilder: (context, index) {
                        final carrera = _filtradas[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.school_outlined,
                            color: Color(0xFF7CB342),
                          ),
                          title: Text(
                            carrera.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, carrera),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
