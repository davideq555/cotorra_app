import 'package:flutter/material.dart';

/// Acción elegida en el sheet de acciones sobre un documento propio.
///
/// El sheet es un selector puro: solo poplea la acción elegida; quien la
/// ejecuta (con red y confirmación incluida) es la pantalla que lo abrió.
enum DocumentAction { edit, delete }

/// Bottom sheet con las acciones del dueño sobre un documento subido
/// (R1: "Editar documento" / "Eliminar").
///
/// Patrón de [DocumentReportSheet]: `static show` abre el modal y devuelve
/// la elección como [Future]; null si el usuario lo descarta. No toca la
/// red ni muta nada: el flujo correspondiente lo dispara PerfilScreen.
class DocumentActionsSheet extends StatelessWidget {
  const DocumentActionsSheet({super.key});

  /// Abre el sheet sobre [context]. Retorna la acción elegida o null.
  static Future<DocumentAction?> show(BuildContext context) {
    return showModalBottomSheet<DocumentAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const DocumentActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acciones del documento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar documento'),
              onTap: () => Navigator.pop(context, DocumentAction.edit),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, DocumentAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de confirmación antes de eliminar un documento propio (R4).
///
/// Mismo gesto que la confirmación extra de [ReportResolverSheet]: botón
/// "Eliminar" en rojo y "Cancelar". Retorna true SOLO con confirmación
/// explícita — cancelar o descartar el diálogo no debe enviar ningún
/// request (escenario "Cancel sends nothing" del spec).
Future<bool> confirmarEliminacion(
  BuildContext context, {
  String? documentoTitulo,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text(
        documentoTitulo == null
            ? '¿Eliminar el documento? Esta acción no se puede deshacer.'
            : 'Vas a eliminar "$documentoTitulo" de forma permanente. '
                  'Esta acción no se puede deshacer desde la app.\n\n'
                  '¿Eliminar el documento?',
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
