import 'package:cotorra_app/models/admin_models.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/admin_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Acciones de resolución de un reporte (accion de ResolverReporteRequest).
enum AccionResolver { eliminar, descartar, revisar }

extension AccionResolverX on AccionResolver {
  String get apiValue => name;

  /// [esComentario] ajusta la etiqueta al sujeto reportado (documento vs
  /// comentario); el valor `accion` de la API es el mismo ("eliminar").
  String label({required bool esComentario}) {
    switch (this) {
      case AccionResolver.eliminar:
        return esComentario ? 'Eliminar comentario' : 'Eliminar documento';
      case AccionResolver.descartar:
        return 'Descartar reporte';
      case AccionResolver.revisar:
        return 'Marcar para revisar';
    }
  }

  String descripcion({required bool esComentario}) {
    switch (this) {
      case AccionResolver.eliminar:
        final sujeto = esComentario ? 'comentario' : 'documento';
        return 'Elimina el $sujeto reportado. Es destructivo: no hay '
            'restauración desde la app.';
      case AccionResolver.descartar:
        return esComentario
            ? 'Cierra el reporte sin tocar el comentario.'
            : 'Cierra el reporte sin tocar el documento.';
      case AccionResolver.revisar:
        return 'Deja el reporte en estado REVISADO para seguimiento posterior.';
    }
  }

  IconData get icon {
    switch (this) {
      case AccionResolver.eliminar:
        return Icons.delete_forever;
      case AccionResolver.descartar:
        return Icons.block_outlined;
      case AccionResolver.revisar:
        return Icons.rate_review_outlined;
    }
  }
}

/// Bottom sheet para resolver un reporte de documento (rol COLABORADOR).
///
/// Tres acciones (eliminar|descartar|revisar) con nota opcional.
/// [AccionResolver.eliminar] pide una confirmación extra en un AlertDialog:
/// cancelarla NO envía nada (escenario "Eliminar sin confirmar" del spec).
/// Patrón de [DocumentReportSheet]: el modal se cierra en éxito y error,
/// con SnackBar de feedback; el resultado [true] dispara refetch en la pantalla.
class ReportResolverSheet extends StatefulWidget {
  final Reporte reporte;

  const ReportResolverSheet({super.key, required this.reporte});

  /// Abre el sheet sobre [context]. Retorna true si el reporte se resolvió.
  static Future<bool?> show(BuildContext context, {required Reporte reporte}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        // Espacio inferior dinámico para que el teclado no tape el input.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportResolverSheet(reporte: reporte),
      ),
    );
  }

  @override
  State<ReportResolverSheet> createState() => _ReportResolverSheetState();
}

class _ReportResolverSheetState extends State<ReportResolverSheet> {
  static const primaryGreen = Color(0xFF7CB342);

  AccionResolver? _selected;
  final _notaController = TextEditingController();
  bool _isSubmitting = false;

  /// Título del sujeto reportado (documento o comentario); si el backend no
  /// lo trae, cae al id. La lógica vive en [Reporte.tituloMostrado].
  String get _tituloDocumento => widget.reporte.tituloMostrado;

  /// Sujeto de la confirmación de borrado, según el tipo de reporte.
  String get _sujetoEliminar {
    if (!widget.reporte.esComentario) return '«$_tituloDocumento»';
    final usuario = widget.reporte.usuarioUsername;
    return usuario != null && usuario.trim().isNotEmpty
        ? 'el comentario de @$usuario'
        : 'el comentario reportado';
  }

  Future<bool> _confirmarEliminar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          'Vas a eliminar $_sujetoEliminar de forma permanente. Esta '
          'acción no se puede deshacer desde la app.\n\n¿Eliminar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit() async {
    final accion = _selected;
    if (accion == null || _isSubmitting) return;

    // Borrar documento es destructivo: sin confirmación explícita no se envía.
    if (accion == AccionResolver.eliminar) {
      final confirmado = await _confirmarEliminar();
      // Cancelar deja el sheet abierto y no manda nada.
      if (!confirmado || !mounted) return;
    }

    // Capturamos messenger y navigator ANTES del async gap: el sheet se
    // cierra en ambos caminos (éxito/error) y el SnackBar debe vivir.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    try {
      // ApiClient propio con el token activo (patrón del resto de la app).
      final client = ApiClient();
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null && token.isNotEmpty) client.setToken(token);

      final nota = _notaController.text.trim();
      await AdminService(client).resolverReporte(
        widget.reporte.id,
        ResolverReporteRequest(
          accion: accion.apiValue,
          nota: nota.isEmpty ? null : nota,
        ),
      );

      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reporte #${widget.reporte.id} resuelto: '
            '${accion.label(esComentario: widget.reporte.esComentario).toLowerCase()}.',
          ),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      navigator.pop(false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_resolverErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Mensaje para el usuario: usa el mensaje del backend (ApiException)
  /// cuando existe; si no, un fallback según el tipo de error.
  String _resolverErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 403) {
        return 'No tenés permisos para resolver este reporte.';
      }
      if (error.statusCode == 401) {
        return 'Tu sesión expiró, volvé a iniciar sesión.';
      }
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    final str = error.toString();
    if (str.contains('SocketException') || str.contains('Connection')) {
      return 'No se pudo resolver el reporte. Verificá tu conexión a internet.';
    }
    return 'No se pudo resolver el reporte. Intentá de nuevo más tarde.';
  }

  @override
  Widget build(BuildContext context) {
    final esComentario = widget.reporte.esComentario;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Resolver reporte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _tituloDocumento,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Reporte #${widget.reporte.id} · '
              '${widget.reporte.motivo.replaceAll('_', ' ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Opciones de acción ───
                    RadioGroup<AccionResolver>(
                      groupValue: _selected,
                      onChanged: (value) {
                        if (_isSubmitting) return;
                        setState(() => _selected = value);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: AccionResolver.values
                            .map(
                              (accion) => RadioListTile<AccionResolver>(
                                value: accion,
                                activeColor: accion == AccionResolver.eliminar
                                    ? Colors.red
                                    : primaryGreen,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  accion.label(esComentario: esComentario),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  accion.descripcion(
                                    esComentario: esComentario,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                secondary: Icon(
                                  accion.icon,
                                  color: _selected == accion
                                      ? (accion == AccionResolver.eliminar
                                            ? Colors.red
                                            : primaryGreen)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    // ─── Nota: siempre opcional ───
                    const SizedBox(height: 8),
                    const Text(
                      'Nota de resolución (opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notaController,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText:
                            'Ej: material duplicado, ya existía en la '
                            'materia…',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting || _selected == null ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Resolver reporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }
}
