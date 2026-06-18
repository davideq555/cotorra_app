import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/favorites_cache_provider.dart';
import 'package:cotorra_app/providers/user_documents_cache_provider.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:cotorra_app/widgets/profile/profile_info.dart';
import 'package:cotorra_app/widgets/profile/stats_row.dart';
import 'package:cotorra_app/widgets/profile/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  void _loadDocuments() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.read<UserDocumentsCacheProvider>().load(auth.token!, auth.userId!);
      context.read<FavoritesCacheProvider>().load(auth.token!, auth.userId!);
      auth.updateFavoritesCount(
        (context.read<FavoritesCacheProvider>().favorites.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final docsProvider = context.watch<UserDocumentsCacheProvider>();
    final favProvider = context.watch<FavoritesCacheProvider>();
    final carreras = auth.userCarreras;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        ProfileInfo(
          nombre: auth.userName ?? 'Usuario',
          email: auth.userEmail ?? '',
          rol: auth.userRol ?? 'ALUMNO',
          inicial: (auth.userName ?? 'U')[0].toUpperCase(),
        ),
        const SizedBox(height: 32),
        StatsRow(
          favoritosCount: favProvider.favorites.length,
          documentosCount: docsProvider.documentos.length,
        ),
        if (carreras.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Mis Carreras',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...carreras.map((carrera) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(carrera.nombre),
              subtitle: carrera.descripcion != null
                  ? Text(
                      carrera.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
            ),
          )),
        ],
        const SizedBox(height: 24),
        SettingsTile(
          title: 'Configuración de Perfil',
          icon: Icons.settings_outlined,
          onTap: () {
            Navigator.pushNamed(context, '/profile-settings');
          },
        ),
        const SizedBox(height: 32),
        const Text(
          'Mis Documentos Subidos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
