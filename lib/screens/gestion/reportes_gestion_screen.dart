import 'package:cotorra_app/models/admin_models.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/screens/document_view_manger_screen.dart';
import 'package:cotorra_app/services/api/admin_service.dart';
import 'package:cotorra_app/services/api/comments_service.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:cotorra_app/widgets/common/status_chip.dart';
import 'package:cotorra_app/widgets/gestion/report_resolver_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Cola de reportes (documento y comentario) para el rol COLABORADOR.
///
/// Fuente: GET /admin/reportes/ unificado — responde {items, meta} desde
/// openapi v1.5.1. El paginado es skip/limit y "hay más" sale de
/// `meta.has_more` (el backend ya expone el total en `meta.total`).
class ReportesGestionScreen extends StatefulWidget {
  const ReportesGestionScreen({super.key});

  @override
  State<ReportesGestionScreen> createState() => _ReportesGestionScreenState();
}

class _ReportesGestionScreenState extends State<ReportesGestionScreen> {
  static const int _limit = 20;
  static const String _sortBy = 'fecha_creacion';
  static const String _sortOrder = 'desc';

  final List<Reporte> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _skip = 0;
  bool _hasMore = true;

  /// Id del reporte con una acción async en curso: bloquea dobles taps y
  /// taps sobre otros reportes mientras hay una petición en vuelo.
  int? _busyReporteId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  /// ApiClient ad-hoc con el token de sesión (design D3: sin provider nuevo).
  ApiClient _authedClient(BuildContext context) {
    final client = ApiClient();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && token.isNotEmpty) client.setToken(token);
    return client;
  }

  AdminService _service(BuildContext context) =>
      AdminService(_authedClient(context));

  Future<void> _loadInitial() => _fetch(replace: true);

  Future<void> _refresh() => _fetch(replace: true);

  /// Garantiza "más recientes primero" aunque el backend no aplique el orden
  /// pedido. Fechas vacías/ inválidas caen al final.
  void _ordenarMasRecientesPrimero() {
    _items.sort((a, b) {
      final fa =
          DateTime.tryParse(a.fechaCreacion) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final fb =
          DateTime.tryParse(b.fechaCreacion) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return fb.compareTo(fa);
    });
  }

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
      final page = await _service(context).getReportes(
        skip: 0,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (!mounted) return;
      setState(() {
        if (replace) _items.clear();
        _items.addAll(page.items);
        _ordenarMasRecientesPrimero();
        _skip = _items.length;
        _hasMore = page.meta.hasMore;
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

  /// Carga la siguiente página y la anexa; "hay más" lo dicta `meta.has_more`.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service(context).getReportes(
        skip: _skip,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _ordenarMasRecientesPrimero();
        _skip = _items.length;
        _hasMore = page.meta.hasMore;
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

  /// Muestra un SnackBar de error si el widget sigue montado.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Trae el comentario reportado bajo demanda y lo muestra en un diálogo.
  Future<void> _verComentario(Reporte reporte) async {
    if (_busyReporteId != null) return;
    final comentarioId = reporte.comentarioId;
    if (comentarioId == null) return;

    setState(() => _busyReporteId = reporte.id);
    try {
      final comentario = await CommentsService(
        _authedClient(context),
      ).getComentario(comentarioId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Comentario reportado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${comentario.usuario?.username ?? '—'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(comentario.contenido),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (_) {
      _showError('No se pudo cargar la información. Verificá tu conexión.');
    } finally {
      if (mounted) setState(() => _busyReporteId = null);
    }
  }

  /// Resuelve el documento del reporte (para comentarios lo trae del
  /// comentario) y navega a su visualización.
  Future<void> _verDocumento(Reporte reporte) async {
    if (_busyReporteId != null) return;

    setState(() => _busyReporteId = reporte.id);
    try {
      final client = _authedClient(context);
      int? docId = reporte.documentoId;
      if (docId == null && reporte.comentarioId != null) {
        final comentario = await CommentsService(
          client,
        ).getComentario(reporte.comentarioId!);
        docId = comentario.documentoId;
      }
      if (docId == null) {
        _showError('No se pudo determinar el documento.');
        return;
      }

      final documento = await DocumentsService(client).getDocumento(docId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentViewScreen(documento: documento),
        ),
      );
    } catch (_) {
      _showError('No se pudo cargar la información. Verificá tu conexión.');
    } finally {
      if (mounted) setState(() => _busyReporteId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportes de documentos y comentarios',
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
          isBusy: _busyReporteId == reporte.id,
          onVerComentario: reporte.esComentario && reporte.comentarioId != null
              ? () => _verComentario(reporte)
              : null,
          onVerDocumento: () => _verDocumento(reporte),
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
  final VoidCallback? onVerComentario;
  final VoidCallback onVerDocumento;
  final bool isBusy;

  const _ReporteCard({
    required this.reporte,
    required this.onResolver,
    this.onVerComentario,
    required this.onVerDocumento,
    required this.isBusy,
  });

  /// El backend responde en español; mostramos el detail tal cual.
  bool get _resoluble =>
      reporte.estado == 'PENDIENTE' || reporte.estado == 'REVISADO';

  String get _fechaCorta {
    final t = reporte.fechaCreacion.split('T').first;
    return t.isEmpty ? '—' : t;
  }

  /// Pastilla compacta que distingue reportes de documento/comentario.
  Widget _tipoBadge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esComentario = reporte.esComentario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esComentario ? Icons.comment : Icons.description,
            size: 12,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            esComentario ? 'Comentario' : 'Documento',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
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
                    reporte.tituloMostrado,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            Row(
              children: [
                _tipoBadge(context),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${reporte.motivo.replaceAll('_', ' ')} · $_fechaCorta',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
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
              child: Wrap(
                spacing: 4,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onVerComentario != null)
                    TextButton.icon(
                      onPressed: isBusy ? null : onVerComentario,
                      icon: const Icon(Icons.comment, size: 16),
                      label: const Text('Ver comentario'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: isBusy ? null : onVerDocumento,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver documento'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: (!isBusy && _resoluble) ? onResolver : null,
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('Resolver'),
                    style: TextButton.styleFrom(
                      foregroundColor: (!isBusy && _resoluble)
                          ? const Color(0xFF7CB342)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
