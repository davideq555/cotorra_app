import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/favorites_cache_provider.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyFavorities extends StatefulWidget {
  const MyFavorities({super.key});

  @override
  State<MyFavorities> createState() => _MyFavoritiesState();
}

class _MyFavoritiesState extends State<MyFavorities> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.read<FavoritesCacheProvider>().load(auth.token!, auth.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favProvider = context.watch<FavoritesCacheProvider>();

    return RefreshableList(
      items: favProvider.favorites,
      isLoading: favProvider.isLoading,
      errorMessage: favProvider.errorMessage,
      emptyMessage: 'No tienes documentos favoritos aún',
      itemSpacing: 12,
      onRefresh: () async {
        if (auth.isAuthenticated) {
          await favProvider.reload(auth.token!, auth.userId!);
        }
      },
      itemBuilder: (context, doc, index) {
        return DocumentCard(doc: doc);
      },
    );
  }
}
