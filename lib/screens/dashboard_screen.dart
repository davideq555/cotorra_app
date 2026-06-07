import 'package:cotorra_app/data/services/mockData.dart';
import 'package:cotorra_app/providers/search_provider.dart';
import 'package:cotorra_app/screens/upload_screen.dart';
import 'package:cotorra_app/widgets/searchScreenComponent/documentCard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget{

  const DashboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>{
  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Green Header Block
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 40,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Little Parrot Logo
                  Container(
                    width: 44,
                    height: 44,
                    child: Image.asset(
                      'assets/images/free.png',
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFDCEDC8),
                        child: const Icon(
                          Icons.pets,
                          color: primaryGreen,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kotorra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '¡Hola de nuevo! Comparte tu conocimiento',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Plus Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.upload,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Material disponible Card
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material disponible',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1,247 documentos',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Recientes Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ultimos Documentos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // TextButton(
              //   onPressed: () {
              //     setState(() => _selectedIndex = 1); // Switch to search tab
              //   },
              //   child: const Text(
              //     'Ver todos',
              //     style: TextStyle(
              //       color: primaryGreen,
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Document List
        Expanded(
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, child) {
              final docs = searchProvider.documentos;
              if (searchProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }

              // Fallback list matching target image mock data if API is empty
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