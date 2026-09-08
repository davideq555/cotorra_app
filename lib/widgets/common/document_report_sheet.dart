import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reportes.dart';
import '../../providers/auth_provider.dart';
import '../../services/api/reportes_service.dart';
import '../../services/api_client.dart';

/// Bottom sheet para reportar un documento.
///
/// Muestra los 5 motivos de la API (MotivoReporteEnum) con selección
/// única; al elegir "Otro motivo" se abre un campo de descripción.
/// Envía POST /reportes/ con el token de [AuthProvider].
class DocumentReportSheet extends StatefulWidget {
  final int documentoId;
  final String documentoTitulo;

  const DocumentReportSheet({
    super.key,
    required this.documentoId,
    required this.documentoTitulo,
  });

  /// Abre el sheet sobre [context]. Retorna true si el reporte se envió.
  static Future<bool?> show(
    BuildContext context, {
    required int documentoId,
    required String documentoTitulo,
  }) {
    // El sheet sigue el theme activo (claro/oscuro) en vez de forzar blanco.
    final theme = Theme.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        // Espacio inferior dinámico para que el teclado no tape el input.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DocumentReportSheet(
          documentoId: documentoId,
          documentoTitulo: documentoTitulo,
        ),
      ),
    );
  }

  @override
  State<DocumentReportSheet> createState() => _DocumentReportSheetState();
}

class _DocumentReportSheetState extends State<DocumentReportSheet> {
  static const primaryGreen = Color(0xFF7CB342);

  /// Los 5 motivos expuestos por la app (SPAM y ACOSO no se muestran).
  static const _motivos = [
    MotivoReporte.copyright,
    MotivoReporte.duplicado,
    MotivoReporte.malEtiquetado,
    MotivoReporte.inapropiado,
    MotivoReporte.otros,
  ];

  static IconData _iconFor(MotivoReporte motivo) {
    switch (motivo) {
      case MotivoReporte.copyright:
        return Icons.copyright;
      case MotivoReporte.duplicado:
        return Icons.content_copy;
      case MotivoReporte.malEtiquetado:
        return Icons.label_off_outlined;
      case MotivoReporte.inapropiado:
        return Icons.report_outlined;
      case MotivoReporte.otros:
        return Icons.more_horiz;
    }
  }

  MotivoReporte? _selected;
  final _descripcionController = TextEditingController();
  bool _isSubmitting = false;

  bool get _showDescripcion => _selected == MotivoReporte.otros;

  Future<void> _submit() async {
    final motivo = _selected;
    if (motivo == null) return;

    // Capturamos messenger y navigator ANTES del async gap: el sheet se
    // cierra en ambos caminos (éxito/error) y el SnackBar debe vivir.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // ApiClient propio con el token activo (patrón del resto de la app).
      final client = ApiClient();
      final token = authProvider.token;
      if (token != null && token.isNotEmpty) client.setToken(token);

      await ReportesService(client).create(
        ReporteCreate(
          documentoId: widget.documentoId,
          motivo: motivo,
          descripcion: _showDescripcion
              ? _descripcionController.text.trim()
              : null,
        ),
      );

      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reporte enviado exitosamente. '
            'El equipo de moderación lo revisará.',
          ),
          backgroundColor: Color(0xFF7CB342),
        ),
      );
    } catch (e) {
      navigator.pop(false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_reportErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Mensaje para el usuario: usa el `detail` del backend (ApiException)
  /// cuando existe; si no, un fallback según el tipo de error.
  String _reportErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Tu sesión expiró, volvé a iniciar sesión.';
      }
      final message = error.message.trim();
      if (message.isNotEmpty) {
        // El backend ya responde en español (ej: "Ya reportaste este
        // documento" en 409). Lo mostramos tal cual.
        return message;
      }
    }
    final str = error.toString();
    if (str.contains('SocketException') || str.contains('Connection')) {
      return 'No se pudo enviar el reporte. Verificá tu conexión a internet.';
    }
    return 'No se pudo enviar el reporte. Intentá de nuevo más tarde.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  color: theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reportar documento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.documentoTitulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Opciones de motivo ───
                    RadioGroup<MotivoReporte>(
                      groupValue: _selected,
                      onChanged: (value) {
                        if (_isSubmitting) return;
                        setState(() => _selected = value);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _motivos
                            .map(
                              (motivo) => RadioListTile<MotivoReporte>(
                                value: motivo,
                                activeColor: primaryGreen,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  motivo.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                secondary: Icon(
                                  _iconFor(motivo),
                                  color: _selected == motivo
                                      ? primaryGreen
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    // ─── Descripción: solo para "Otro motivo" ───
                    if (_showDescripcion) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Contanos cuál es el problema',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descripcionController,
                        maxLines: 3,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText:
                              'Ej: el material es de otro sitio y no está '
                              'autorizado…',
                          // `filled`/`fillColor` vienen del inputDecorationTheme
                          // del app (gris claro en modo claro, 0xFF1E1E1E en dark).
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
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
                      'Enviar reporte',
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
    _descripcionController.dispose();
    super.dispose();
  }
}
