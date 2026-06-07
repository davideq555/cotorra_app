import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/materia.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import 'upload_screen.dart';
import 'profile_settings_screen.dart';
import 'document_view_screen.dart';

import 'package:cotorra_app/widgets/documentCard.dart';
import 'package:cotorra_app/widgets/statusChip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).searchDocumentos('');
    });
  }

  void _performSearch() {
    Provider.of<SearchProvider>(
      context,
      listen: false,
    ).searchDocumentos(_searchController.text.trim());
  }

  ///////////////////////////////////////////////////////

  Widget _buildDashboard() {
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
              final displayDocs = docs.isNotEmpty ? docs : _mockDocuments();

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

  /////////////////////////////////////////////////////////////

  Widget _buildSearchTab() {
    const primaryGreen = Color(0xFF7CB342);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar documentos...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    fillColor: const Color(0xFFF5F5F5),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _performSearch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                if (searchProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }

                final displayDocs = searchProvider.documentos.isNotEmpty
                    ? searchProvider.documentos
                    : _mockDocuments();

                return ListView.builder(
                  itemCount: displayDocs.length,
                  itemBuilder: (context, index) {
                    return DocumentCard(doc: displayDocs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /////////////////////////////////////////////////////////////////

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /////////////////////////////////////////////////////////////////

  Widget _buildProfileTab() {
    const primaryGreen = Color(0xFF7CB342);

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // User Info Section
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'María González',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'maria.gonzalez@universidad.edu',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ALUMNO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Stats Row
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        '12',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Favoritos',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        '3',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Documentos',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Settings Action
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: primaryGreen,
                size: 20,
              ),
            ),
            title: const Text(
              'Configuración de Perfil',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        // Mis Documentos Header
        const Text(
          'Mis Documentos Subidos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Congruent cards with custom trailing status chips
        DocumentCard(
          doc: Documento(
            id: 101,
            titulo: 'Resumen Álgebra II - Matrices',
            archivoUrl: '',
            autor: 'María González',
            tipo: 1,
            fechaSubida: '2026-05-28',
            aprobado: true,
            descargas: 14,
            usuarioId: 1,
            eliminado: false,
            materia: Materia(id: 1, nombre: 'Matemáticas'),
          ),
          trailing: StatusChip(label: 'Aprobado',color: Colors.green),
        ),
        DocumentCard(
          doc: Documento(
            // Agregado 'doc:'
            id: 102,
            // Agregado 'id:'
            titulo: 'Laboratorio 1 Electrónica',
            // Agregado 'titulo:'
            archivoUrl: '',
            autor: 'María González',
            tipo: 2,
            fechaSubida: '2026-05-25',
            aprobado: true,
            descargas: 8,
            usuarioId: 1,
            eliminado: false,
            materia: Materia(
              id: 3,
              nombre: 'Física',
            ), // Agregado 'id:' y 'nombre:'
          ),
          trailing: StatusChip(
            label: 'Aprobado',
            color: Colors.green,
          ), // Agregado 'trailing:'
        ),
        DocumentCard(
          doc: Documento(
            id: 103,
            titulo: 'Final Programación 2025',
            archivoUrl: '',
            autor: 'María González',
            tipo: 1,
            fechaSubida: '2026-05-29',
            aprobado: false,
            descargas: 0,
            usuarioId: 1,
            eliminado: false,
            materia: Materia(id: 5, nombre: 'Programación'),
          ),
          trailing: StatusChip(label: 'Pendiente', color:  Colors.orange),
        ),
      ],
    );
  }


  ////////////////////////////////////////////////////
  List<Documento> _mockDocuments() {
    return [
      Documento(
        id: 1,
        titulo: 'Apuntes Cálculo I - Derivadas',
        archivoUrl: '',
        autor: 'María González',
        tipo: 1,
        fechaSubida: '2026-05-28',
        aprobado: true,
        descargas: 24,
        usuarioId: 1,
        eliminado: false,
        materia: Materia(id: 1, nombre: 'Matemáticas'),
      ),
      Documento(
        id: 2,
        titulo: 'Resumen Arquitectura de Computadoras',
        archivoUrl: '',
        autor: 'Carlos Ruiz',
        tipo: 1,
        fechaSubida: '2026-05-27',
        aprobado: true,
        descargas: 18,
        usuarioId: 2,
        eliminado: false,
        materia: Materia(id: 2, nombre: 'Sistemas'),
      ),
      Documento(
        id: 3,
        titulo: 'Ejercicios Física II - Electromagnetismo',
        archivoUrl: '',
        autor: 'Ana Martínez',
        tipo: 2,
        fechaSubida: '2026-05-25',
        aprobado: true,
        descargas: 31,
        usuarioId: 3,
        eliminado: false,
        materia: Materia(id: 3, nombre: 'Física'),
      ),
      Documento(
        id: 4,
        titulo: 'Tesis: Machine Learning en Medicina',
        archivoUrl: '',
        autor: 'Dr. López',
        tipo: 1,
        fechaSubida: '2026-05-20',
        aprobado: true,
        descargas: 42,
        usuarioId: 4,
        eliminado: false,
        materia: Materia(id: 4, nombre: 'Investigación'),
      ),
    ];
  }

  ///////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(
                _selectedIndex == 1
                    ? 'Buscar'
                    : _selectedIndex == 2
                    ? 'Favoritos'
                    : 'Mi Perfil',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
          ? _buildSearchTab()
          : _selectedIndex == 2
          ? _buildPlaceholderTab('Mis Favoritos')
          : _buildProfileTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
