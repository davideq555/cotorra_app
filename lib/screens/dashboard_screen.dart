import 'package:cotorra_app/providers/document_cache_provider.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/refreshable_list.dart';
import 'package:cotorra_app/widgets/dashboard/dashboard_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar los mejores documentos al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentCacheProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardHeader(),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Top Documentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<DocumentCacheProvider>(
            builder: (context, provider, child) {
              return RefreshableList(
                items: provider.documentos,
                isLoading: provider.isLoading,
                errorMessage: provider.errorMessage,
                emptyMessage: 'No hay documentos disponibles',
                horizontalPadding: 20,
                itemSpacing: 8,
                onRefresh: provider.reload,
                itemBuilder: (context, doc, index) {
                  return DocumentCard(doc: doc);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
