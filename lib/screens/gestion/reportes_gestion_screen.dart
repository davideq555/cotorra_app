import 'package:cotorra_app/models/admin_models.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/admin_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:cotorra_app/widgets/common/status_chip.dart';
import 'package:cotorra_app/widgets/gestion/report_resolver_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Cola de reportes de documentos para el rol COLABORADOR.
///
/// Fuente: GET /admin/reportes/ (array plano, sin total). El paginado es
/// skip/limit y "hay más" se infiere con `page.length == limit` (design):
/// nunca se muestra un total porque el backend no lo expone.
class ReportesGestionScreen extends StatefulWidget {
  const ReportesGestionScreen({super.key});

  @override
  State<ReportesGestionScreen> createState() => _ReportesGestionScreenState();
}

class _ReportesGestionScreenState extends State<ReportesGestionScreen> {
  static const int _limit = 20;

  final List<Reporte> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _skip = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  /// ApiClient ad-hoc con el token de sesión (design D3: sin provider nuevo).
  AdminService _service(BuildContext context) {
    final client = ApiClient();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && token.isNotEmpty) client.setToken(token);
    return AdminService(client);
  }

  Future<void> _loadInitial() => _fetch(replace: true);

  Future<void> _refresh() => _fetch(replace: true);

  Future<void> _fetch({required bool replace}) async {
    if (replace) {
      setState(() {
        _isLoading = _items.isEmpty;
        _errorMessage = null;
        _skip = 0;
        _hasMore = true;
      });
    }
    try {
      final page = await _service(context).getReportes(skip: 0, limit: _limit);
      if (!mounted) return;
      setState(() {
        if (replace) _items.clear();
        _items.addAll(page);
        _skip = _items.length;
        _hasMore = page.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar los reportes.';
        _isLoading = false;
      });
    }
  }

  /// Carga la siguiente página y la anexa. Sin total: solo "más/o menos".
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service(
        context,
      ).getReportes(skip: _skip, limit: _limit);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _skip = _items.length;
        _hasMore = page.length == _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      // El load-more falla silencioso: la lista ya cargada sigue útil.
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _resolver(Reporte reporte) async {
    final resolved = await ReportResolverSheet.show(context, reporte: reporte);
    if (resolved == true) {
      // Verdad del servidor después de mutar: refetch, nada optimista.
      await _fetch(replace: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportes de documentos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshableList<Reporte>(
        items: _items,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        emptyMessage: 'No hay reportes para revisar.',
        horizontalPadding: 16,
        onRefresh: _refresh,
        onRetry: _loadInitial,
        onLoadMore: _hasMore ? _loadMore : null,
        itemBuilder: (context, reporte, index) => _ReporteCard(
          reporte: reporte,
          onResolver: () => _resolver(reporte),
        ),
      ),
      // Indicador de carga "siguiente página" sin tap: scroll-anchored.
      bottomNavigationBar: _isLoadingMore
          ? const SafeArea(child: LinearProgressIndicator(minHeight: 2))
          : null,
    );
  }
}

/// Chip de estado: etiqueta + color por el estado del reporte en el backend.
Color _statusColorFor(String estado) {
  switch (estado) {
    case 'PENDIENTE':
      return Colors.orange;
    case 'REVISADO':
      return Colors.blue;
    case 'DESCARTADO':
      return Colors.grey;
    case 'RESUELTO':
      return const Color(0xFF7CB342);
    default:
      return Colors.grey;
  }
}

class _ReporteCard extends StatelessWidget {
  final Reporte reporte;
  final VoidCallback onResolver;

  const _ReporteCard({required this.reporte, required this.onResolver});

  /// El backend responde en español; mostramos el detail tal cual.
  bool get _resoluble =>
      reporte.estado == 'PENDIENTE' || reporte.estado == 'REVISADO';

  String get _fechaCorta {
    final t = reporte.fechaCreacion.split('T').first;
    return t.isEmpty ? '—' : t;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Documento ${reporte.documentoId ?? '—'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                StatusChip(
                  label: reporte.estado,
                  color: _statusColorFor(reporte.estado),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${reporte.motivo.replaceAll('_', ' ')} · $_fechaCorta',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (reporte.descripcion != null &&
                reporte.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reporte.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _resoluble ? onResolver : null,
                icon: const Icon(Icons.gavel, size: 16),
                label: const Text('Resolver'),
                style: TextButton.styleFrom(
                  foregroundColor: _resoluble
                      ? const Color(0xFF7CB342)
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
