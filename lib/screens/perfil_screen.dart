import 'package:cotorra_app/models/usuario_stats.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/favorites_cache_provider.dart';
import 'package:cotorra_app/providers/user_documents_cache_provider.dart';
import 'package:cotorra_app/services/api/users_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
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
  /// Estadísticas del backend (GET /usuarios/{id}/stats). Null mientras
  /// carga o si falla — en ese caso la grilla usa fallbacks locales.
  UsuarioStats? _stats;

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
              return DocumentCard(doc: doc);
            },
          ),
        ),
      ],
    );
  }
}
