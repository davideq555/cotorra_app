import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/screens/profile_settings_screen.dart';
import 'package:cotorra_app/widgets/searchScreenComponent/documentCard.dart';
import 'package:cotorra_app/widgets/searchScreenComponent/statusChip.dart';
import 'package:flutter/material.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>{

  @override
  Widget build(BuildContext context) {
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
                  // color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    // side: BorderSide(color: Colors.grey.shade100),
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
                  // color: Colors.white,
                  elevation: 0,
                  // shape: RoundedRectangleBorder(
                  //   borderRadius: BorderRadius.circular(16),
                  //   side: BorderSide(color: Colors.grey.shade100),
                  // ),
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
            // color: Colors.white,
            elevation: 0,
            // shape: RoundedRectangleBorder(
            //   borderRadius: BorderRadius.circular(16),
            //   // side: BorderSide(color: Colors.grey.shade100),
            // ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  // color: Color(0xFFF1F8E9),
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
///////////////////////////////////////////////////////////////////
}