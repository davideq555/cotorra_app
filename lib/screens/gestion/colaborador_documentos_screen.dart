import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/admin_service.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Documentos de las carreras inscriptas de un COLABORADOR.
///
/// Fuente: GET /admin/documentos (operationId `admin_documentos_list`). Es el
/// endpoint único que reemplazó a los viejos /admin/documentos/{todos,
/// pendientes,eliminados}. La app no tiene flujo de ADMIN, así que en la
/// práctica este listado es el del COLABORADOR: el servidor lo acota a los
/// documentos de las materias de sus carreras inscriptas. `todos` incluye
/// pendientes y aprobados, pero nunca eliminados.
///
/// A diferencia del listado docente (array plano), acá la paginación es real:
/// skip/limit + `meta.has_more`. Las páginas se acumulan y [RefreshableList]
/// pide la siguiente vía [onLoadMore] al acercarse al final; un guard de
/// concurrencia ([_isLoadingMore]) impide load-mores duplicados y un guard de
/// secuencia ([_fetchSeq]) impide que una respuesta vieja pise a otra más
/// nueva cuando se cambia de chip. Pull-to-refresh reinicia a la página 0.
///
/// Chips: Pendientes / Aprobados / Todos. `eliminados` NO se expone en la UI
/// a propósito: aunque el endpoint lo soporte, esta pantalla no debe ser una
/// superficie para ver documentos borrados. Los tres valores visibles sí están
/// documentados por el pattern de `estado`, así que se envían tal cual,
/// incluido el literal 'todos' (a diferencia del listado docente, donde
/// 'todos' se omite por no estar documentado).
///
/// Aprobar/Desaprobar piden confirmación explícita; cancelar no envía nada.
/// Errores (403 fuera de scope, red): SnackBar + refetch a la verdad del
/// servidor, nunca éxito optimista; [_isProcessing] bloquea el doble envío
/// (patrón MisCarrerasScreen). El filtro client-side se mantiene como red de
/// seguridad por si el backend ignorara `estado`.
enum ColaboradorFiltroDocumentos { pendientes, aprobados, todos }

class ColaboradorDocumentosScreen extends StatefulWidget {
  const ColaboradorDocumentosScreen({super.key});

  /// Única fuente de verdad chip → valor de wire del query param `estado`.
  ///
  /// El contrato documenta `estado` con pattern
  /// `^(todos|pendientes|aprobados|eliminados)$`, así que los tres valores
  /// visibles son válidos y se envían siempre (no se omite ninguno). El chip
  /// `eliminados` no existe en la UI aunque el wire value exista.
  static String estadoParam(ColaboradorFiltroDocumentos filtro) {
    switch (filtro) {
      case ColaboradorFiltroDocumentos.pendientes:
        return 'pendientes';
      case ColaboradorFiltroDocumentos.aprobados:
        return 'aprobados';
      case ColaboradorFiltroDocumentos.todos:
        return 'todos';
    }
  }

  @override
  State<ColaboradorDocumentosScreen> createState() =>
      _ColaboradorDocumentosScreenState();
}

class _ColaboradorDocumentosScreenState
    extends State<ColaboradorDocumentosScreen> {
  /// Tamaño de página: default documentado del contrato (1..100).
  static const int _limit = 20;

  final List<Documento> _items = [];
  ColaboradorFiltroDocumentos _filtro = ColaboradorFiltroDocumentos.pendientes;

  /// Offsets de paginación y "hay más" derivado de `meta.has_more`.
  int _skip = 0;
  bool _hasMore = true;

  /// Contador de fetches de primera página: cada uno toma su número y solo
  /// aplica su resultado si sigue siendo el último. Evita que una respuesta
  /// lenta de un chip anterior pise la selección más reciente.
  int _fetchSeq = 0;
  bool _isLoading = false;

  /// True mientras hay un fetch de primera página en vuelo. Bloquea que un
  /// load-more arranque en paralelo y duplique la página 0.
  bool _isFetching = false;
  bool _isLoadingMore = false;
  bool _isProcessing = false;
  String? _errorMessage;

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

  /// Igual que [_service] pero para las mutaciones de moderación, que viven
  /// en las rutas globales /documentos/{id}/aprobar y /desaprobar.
  DocumentsService _documentsService(BuildContext context) {
    final client = ApiClient();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && token.isNotEmpty) client.setToken(token);
    return DocumentsService(client);
  }

  Future<void> _loadInitial() => _fetch();

  Future<void> _refresh() => _fetch();

  /// Trae la primera página con el filtro activo y reemplaza la lista.
  ///
  /// [showSpinner] fuerza el spinner aunque ya haya lista: se usa al cambiar
  /// de chip, porque la lista visible pertenece al filtro anterior.
  Future<void> _fetch({bool showSpinner = false}) async {
    final seq = ++_fetchSeq;
    setState(() {
      _isFetching = true;
      _isLoading = showSpinner || _items.isEmpty;
      _isLoadingMore = false;
      _errorMessage = null;
      _skip = 0;
      _hasMore = true;
    });
    try {
      final page = await _service(context).getDocumentos(
        skip: 0,
        limit: _limit,
        estado: ColaboradorDocumentosScreen.estadoParam(_filtro),
      );
      // Un fetch más nuevo ya salió: este resultado quedó obsoleto.
      if (!mounted || seq != _fetchSeq) return;
      setState(() {
        _items
          ..clear()
          ..addAll(_documentosDe(page.items));
        _ordenarPendientesPrimero();
        _skip = _items.length;
        _hasMore = page.meta.hasMore;
        _isLoading = false;
        _isFetching = false;
      });
    } catch (e) {
      if (!mounted || seq != _fetchSeq) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar los documentos.';
        _isLoading = false;
        _isFetching = false;
      });
    }
  }

  /// Carga la siguiente página y la anexa; "hay más" lo dicta `meta.has_more`.
  Future<void> _loadMore() async {
    if (_isLoadingMore || _isFetching || _isLoading || !_hasMore) return;
    final seq = _fetchSeq;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service(context).getDocumentos(
        skip: _skip,
        limit: _limit,
        estado: ColaboradorDocumentosScreen.estadoParam(_filtro),
      );
      // Un cambio de chip reinició el listado: descartamos esta página.
      if (!mounted || seq != _fetchSeq) return;
      setState(() {
        _items.addAll(_documentosDe(page.items));
        _ordenarPendientesPrimero();
        _skip = _items.length;
        _hasMore = page.meta.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _fetchSeq) return;
      // El load-more falla silencioso: la lista ya cargada sigue útil.
      setState(() => _isLoadingMore = false);
    }
  }

  /// `DocumentoPaginatedResponse.items` es `List<dynamic>`: cada elemento es
  /// un JSON de Documento y se mapea explícitamente con [Documento.fromJson].
  static List<Documento> _documentosDe(List<dynamic> items) =>
      items.map((j) => Documento.fromJson(j as Map<String, dynamic>)).toList();

  /// Cambia de chip y refetchea: la lista actual es de otro filtro, por eso
  /// se muestra spinner y se limpia el error antes de pedir.
  void _seleccionarFiltro(ColaboradorFiltroDocumentos valor) {
    if (_filtro == valor) return;
    setState(() {
      _filtro = valor;
      _isLoading = true;
      _errorMessage = null;
    });
    _fetch(showSpinner: true);
  }

  /// Orden client-side: pendientes (!aprobado) primero; dentro de cada
  /// grupo, fecha_subida descendente. El servidor no documenta orden, así
  /// que se normaliza acá. Se aplica sobre la lista acumulada completa.
  void _ordenarPendientesPrimero() {
    _items.sort((a, b) {
      if (a.aprobado != b.aprobado) return a.aprobado ? 1 : -1;
      return _fecha(b).compareTo(_fecha(a));
    });
  }

  /// Fecha de subida parseada; sin fecha o inválida cuenta como la más
  /// vieja para que quede al final de su grupo.
  static DateTime _fecha(Documento doc) {
    final raw = doc.fechaSubida;
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Filtro client-side sobre el listado ya ordenado. Red de seguridad: si
  /// el backend ignorara `estado`, la UI igual muestra el subconjunto correcto.
  /// No afecta la paginación: el offset avanza sobre las páginas del servidor.
  List<Documento> get _visibles {
    switch (_filtro) {
      case ColaboradorFiltroDocumentos.pendientes:
        return _items.where((d) => !d.aprobado).toList();
      case ColaboradorFiltroDocumentos.aprobados:
        return _items.where((d) => d.aprobado).toList();
      case ColaboradorFiltroDocumentos.todos:
        return _items;
    }
  }

  String get _emptyMessage {
    switch (_filtro) {
      case ColaboradorFiltroDocumentos.pendientes:
        return 'No hay documentos pendientes de revisión.';
      case ColaboradorFiltroDocumentos.aprobados:
        return 'No hay documentos aprobados.';
      case ColaboradorFiltroDocumentos.todos:
        return 'Tus carreras todavía no tienen documentos.';
    }
  }

  /// Confirma antes de mutar. Cancelar retorna sin enviar ninguna request.
  Future<void> _cambiarEstado(Documento doc) async {
    if (_isProcessing) return;
    final aprobar = !doc.aprobado;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(aprobar ? '¿Aprobar documento?' : '¿Desaprobar documento?'),
        content: Text(
          aprobar
              ? '"${doc.titulo}" quedará aprobado y visible para los alumnos.'
              : '"${doc.titulo}" volverá a quedar pendiente de revisión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: aprobar
                  ? const Color(0xFF7CB342)
                  : Colors.redAccent,
            ),
            child: Text(aprobar ? 'Aprobar' : 'Desaprobar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = _documentsService(context);
      if (aprobar) {
        await service.aprobarDocumento(doc.id);
      } else {
        await service.desaprobarDocumento(doc.id);
      }
      // Verdad del servidor después de mutar: refetch, nada optimista.
      await _fetch();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            aprobar ? 'Documento aprobado.' : 'Documento desaprobado.',
          ),
          backgroundColor: const Color(0xFF7CB342),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo ${aprobar ? 'aprobar' : 'desaprobar'} el documento. '
            '${_errorMsg(e)}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Tras un error la lista se refresca a la verdad del servidor
      // (spec: nunca éxito optimista ni UI estancada).
      await _fetch();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _errorMsg(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) return 'Tu sesión expiró.';
      if (e.statusCode == 403) {
        return 'No tenés permisos sobre este documento.';
      }
      final message = e.message.trim();
      if (message.isNotEmpty) return message;
    }
    return 'Revisá tu conexión e intentá de nuevo.';
  }

  /// Acción de fila: pendiente → Aprobar; aprobado → Desaprobar.
  /// Disabled mientras hay una mutación en vuelo ([_isProcessing]).
  Widget _accionPara(Documento doc) {
    final pendiente = !doc.aprobado;
    return TextButton.icon(
      onPressed: _isProcessing ? null : () => _cambiarEstado(doc),
      icon: Icon(pendiente ? Icons.check : Icons.undo, size: 16),
      label: Text(pendiente ? 'Aprobar' : 'Desaprobar'),
      style: TextButton.styleFrom(
        foregroundColor: pendiente ? const Color(0xFF7CB342) : Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _chip(String label, ColaboradorFiltroDocumentos valor, Color color) {
    final seleccionado = _filtro == valor;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      showCheckmark: false,
      onSelected: (_) => _seleccionarFiltro(valor),
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: seleccionado ? color : Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Documentos de mis carreras',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Chips con filtro server-side (`estado`); por defecto Pendientes,
          // que es el foco del flujo de moderación. `eliminados` no se ofrece.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _chip(
                  'Pendientes',
                  ColaboradorFiltroDocumentos.pendientes,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _chip(
                  'Aprobados',
                  ColaboradorFiltroDocumentos.aprobados,
                  const Color(0xFF7CB342),
                ),
                const SizedBox(width: 8),
                _chip('Todos', ColaboradorFiltroDocumentos.todos, Colors.blue),
              ],
            ),
          ),
          Expanded(
            child: RefreshableList<Documento>(
              items: _visibles,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              emptyMessage: _emptyMessage,
              horizontalPadding: 16,
              onRefresh: _refresh,
              onRetry: _loadInitial,
              onLoadMore: _hasMore ? _loadMore : null,
              itemBuilder: (context, doc, index) =>
                  DocumentCard(doc: doc, trailing: _accionPara(doc)),
            ),
          ),
        ],
      ),
      // Indicador de carga "siguiente página" sin tap: scroll-anchored.
      bottomNavigationBar: _isLoadingMore
          ? const SafeArea(child: LinearProgressIndicator(minHeight: 2))
          : null,
    );
  }
}
