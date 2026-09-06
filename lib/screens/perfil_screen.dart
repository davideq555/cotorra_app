import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/usuario_stats.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/favorites_cache_provider.dart';
import 'package:cotorra_app/providers/user_documents_cache_provider.dart';
import 'package:cotorra_app/services/api/documents_service.dart';
import 'package:cotorra_app/services/api/users_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/utils/document_action_errors.dart';
import 'package:cotorra_app/widgets/common/document_actions_sheet.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/document_edit_sheet.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:cotorra_app/widgets/profile/profile_info.dart';
import 'package:cotorra_app/widgets/profile/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  static const _verdeExito = Color(0xFF7CB342);

  /// Estadísticas del backend (GET /usuarios/{id}/stats). Null mientras
  /// carga o si falla — en ese caso la grilla usa fallbacks locales.
  UsuarioStats? _stats;

  /// Guard de mutaciones concurrentes (editar/eliminar): mientras una
  /// tarjeta tiene una acción en vuelo, las acciones de otras tarjetas se
  /// ignoran. Una mutación a la vez mantiene lista y caché coherentes.
  int? _processingDocId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
      _loadStats();
    });
  }

  void _loadDocuments() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.read<UserDocumentsCacheProvider>().load(
        auth.token!,
        auth.userId!,
      );
      context.read<FavoritesCacheProvider>().load(auth.token!, auth.userId!);
      auth.updateFavoritesCount(
        (context.read<FavoritesCacheProvider>().favorites.length),
      );
    }
  }

  /// GET /usuarios/{id}/stats — fallback silencioso: si falla se mantiene
  /// null y la grilla muestra los valores locales.
  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    try {
      final client = ApiClient();
      client.setToken(auth.token!);
      final stats = await UsersService(client).getUsuarioStats(auth.userId!);
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {
      if (!mounted) return;
      setState(() => _stats = null);
    }
  }

  // ─── Acciones sobre documentos propios (R1/R3/R4) ─────────────────

  void _mostrarSnackbar(String mensaje, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: backgroundColor),
    );
  }

  /// Abre el sheet de acciones de [doc] y despacha el flujo elegido.
  Future<void> _mostrarAcciones(Documento doc) async {
    if (_processingDocId != null && _processingDocId != doc.id) return;
    final accion = await DocumentActionsSheet.show(context);
    if (!mounted || accion == null) return;
    switch (accion) {
      case DocumentAction.edit:
        await _editarDocumento(doc);
      case DocumentAction.delete:
        await _eliminarDocumento(doc);
    }
  }

  /// Flujo de edición: el sheet hace el PUT; acá solo se aplica el
  /// resultado a la lista/caché locales (R5) y se refrescan las stats.
  Future<void> _editarDocumento(Documento doc) async {
    if (_processingDocId != null && _processingDocId != doc.id) return;
    _processingDocId = doc.id;
    try {
      final result = await DocumentEditSheet.show(context, original: doc);
      if (!mounted || result == null) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) return;
      final provider = context.read<UserDocumentsCacheProvider>();
      if (result.removeLocally) {
        // 404: el sheet ya showed la Snackbar "ya no existe" — acá solo
        // se quita el documento de lista y caché.
        await provider.applyDelete(
          doc.id,
          token: auth.token!,
          userId: auth.userId!,
        );
      } else if (result.documento != null) {
        await provider.applyUpdate(
          result.documento!,
          token: auth.token!,
          userId: auth.userId!,
        );
        if (mounted) {
          _mostrarSnackbar(
            'Documento actualizado.',
            backgroundColor: _verdeExito,
          );
        }
      }
      await _loadStats();
    } finally {
      _processingDocId = null;
    }
  }

  /// Flujo de borrado: confirmación (Cancelar no envía nada, R4), DELETE
  /// vía DocumentsService con el mismo patrón ApiClient de _loadStats
  /// (R7 — sin el servicio deprecado), y recién con 200 se muta lista y
  /// caché.
  Future<void> _eliminarDocumento(Documento doc) async {
    if (_processingDocId != null && _processingDocId != doc.id) return;
    final confirmado = await confirmarEliminacion(
      context,
      documentoTitulo: doc.titulo,
    );
    if (!confirmado || !mounted) return;
    _processingDocId = doc.id;
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) return;
      final token = auth.token!;
      // Capturados antes del async gap: el SnackBar debe sobrevivir y el
      // provider se resuelve sin tocar el context después del await.
      final messenger = ScaffoldMessenger.of(context);
      final provider = context.read<UserDocumentsCacheProvider>();
      try {
        final client = ApiClient();
        client.setToken(token);
        await DocumentsService(client).deleteDocumento(doc.id);
        await provider.applyDelete(doc.id, token: token, userId: auth.userId!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Documento eliminado.'),
            backgroundColor: _verdeExito,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(documentActionErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      await _loadStats();
    } finally {
      _processingDocId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final docsProvider = context.watch<UserDocumentsCacheProvider>();
    final favProvider = context.watch<FavoritesCacheProvider>();

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        ProfileInfo(
          nombre: auth.userName ?? 'Usuario',
          email: auth.userEmail ?? '',
          rol: auth.userRol ?? 'ALUMNO',
          inicial: (auth.userName != null && auth.userName!.isNotEmpty)
              ? auth.userName![0].toUpperCase()
              : 'U',
          bio: auth.userBio,
        ),
        const SizedBox(height: 32),
        StatsGrid(
          subidas: _stats?.totalDocumentos ?? docsProvider.documentos.length,
          descargas: _stats?.totalDescargas ?? 0,
          favoritos: _stats?.totalFavoritos ?? favProvider.favorites.length,
          karma: _stats?.karma ?? 0,
        ),
        const SizedBox(height: 32),
        const Text(
          'Mis Documentos Subidos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: RefreshableList(
            items: docsProvider.documentos,
            isLoading: docsProvider.isLoading,
            errorMessage: docsProvider.errorMessage,
            emptyMessage: 'No has subido documentos aún',
            itemSpacing: 12,
            onRefresh: () async {
              if (auth.isAuthenticated) {
                await docsProvider.reload(auth.token!, auth.userId!);
                await _loadStats();
              }
            },
            itemBuilder: (context, doc, index) {
              // Solo los documentos propios exponen acciones (R1): ⋮ y
              // long-press abren el mismo sheet.
              return DocumentCard(
                doc: doc,
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  tooltip: 'Acciones del documento',
                  onPressed: () => _mostrarAcciones(doc),
                ),
                onLongPress: () => _mostrarAcciones(doc),
              );
            },
          ),
        ),
      ],
    );
  }
}
