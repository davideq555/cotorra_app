import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/docente_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Documentos de una materia a cargo del DOCENTE (T2.3).
///
/// Fuente: GET /docente/materias/{id}/documentos — array plano sin
/// paginación: se pide solo esta materia (spec: lazy, sin fan-out).
/// Orden pendientes-first en cliente (design D5: `estado` no tiene enum
/// documentado, así que no se usa como filtro server-side). Los chips
/// Pendientes/Aprobados/Todos filtran en cliente sobre el mismo listado.
///
/// Aprobar/Desaprobar piden confirmación explícita; cancelar no envía
/// nada. Errores (403 fuera de scope, red): SnackBar + refetch a la
/// verdad del servidor, nunca éxito optimista; [_isProcessing] bloquea
/// el doble envío (patrón MisCarrerasScreen).
enum _FiltroDocumentos { pendientes, aprobados, todos }

class DocenteDocumentosScreen extends StatefulWidget {
  final Materia materia;

  const DocenteDocumentosScreen({super.key, required this.materia});

  @override
  State<DocenteDocumentosScreen> createState() =>
      _DocenteDocumentosScreenState();
}

class _DocenteDocumentosScreenState extends State<DocenteDocumentosScreen> {
  final List<Documento> _documentos = [];
  _FiltroDocumentos _filtro = _FiltroDocumentos.pendientes;
  bool _isLoading = false;
  bool _isProcessing = false;
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
      _isLoading = _documentos.isEmpty;
      _errorMessage = null;
    });
    try {
      final docs = await _service(
        context,
      ).getDocumentosMateria(widget.materia.id);
      if (!mounted) return;
      setState(() {
        _documentos
          ..clear()
          ..addAll(_ordenarPendientesPrimero(docs));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar los documentos.';
        _isLoading = false;
      });
    }
  }

  /// Orden client-side (design D5): pendientes (!aprobado) primero;
  /// dentro de cada grupo, fecha_subida descendente. Copia defensiva
  /// para no mutar la lista que devuelve el servicio.
  static List<Documento> _ordenarPendientesPrimero(List<Documento> docs) {
    final copia = [...docs];
    copia.sort((a, b) {
      if (a.aprobado != b.aprobado) return a.aprobado ? 1 : -1;
      return _fecha(b).compareTo(_fecha(a));
    });
    return copia;
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

  /// Filtro client-side sobre el listado ya ordenado.
  List<Documento> get _visibles {
    switch (_filtro) {
      case _FiltroDocumentos.pendientes:
        return _documentos.where((d) => !d.aprobado).toList();
      case _FiltroDocumentos.aprobados:
        return _documentos.where((d) => d.aprobado).toList();
      case _FiltroDocumentos.todos:
        return _documentos;
    }
  }

  String get _emptyMessage {
    switch (_filtro) {
      case _FiltroDocumentos.pendientes:
        return 'No hay documentos pendientes de revisión.';
      case _FiltroDocumentos.aprobados:
        return 'No hay documentos aprobados.';
      case _FiltroDocumentos.todos:
        return 'Esta materia todavía no tiene documentos.';
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
      final service = _service(context);
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

  Widget _chip(String label, _FiltroDocumentos valor, Color color) {
    final seleccionado = _filtro == valor;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtro = valor),
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
        title: Text(
          widget.materia.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Segmentos client-side (design D5): por defecto Pendientes,
          // que es el foco del flujo de moderación.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _chip(
                  'Pendientes',
                  _FiltroDocumentos.pendientes,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _chip(
                  'Aprobados',
                  _FiltroDocumentos.aprobados,
                  const Color(0xFF7CB342),
                ),
                const SizedBox(width: 8),
                _chip('Todos', _FiltroDocumentos.todos, Colors.blue),
                const Spacer(),
                if (widget.materia.codigo != null &&
                    widget.materia.codigo!.isNotEmpty)
                  Text(
                    widget.materia.codigo!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
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
              itemBuilder: (context, doc, index) =>
                  DocumentCard(doc: doc, trailing: _accionPara(doc)),
            ),
          ),
        ],
      ),
    );
  }
}
