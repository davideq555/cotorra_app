import 'package:cotorra_app/data/services/mockData.dart';
import 'package:cotorra_app/providers/search_provider.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/dashboard/dashboard_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            'Ultimos Documentos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, child) {
              final docs = searchProvider.documentos;
              if (searchProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final displayDocs = docs.isNotEmpty ? docs : mockDocuments();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: displayDocs.length,
                itemBuilder: (context, index) {
                  return DocumentCard(doc: displayDocs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
