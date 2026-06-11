import 'package:cotorra_app/models/models.dart';
import 'package:cotorra_app/screens/auth/profile_settings_screen.dart';
import 'package:cotorra_app/widgets/common/document_card.dart';
import 'package:cotorra_app/widgets/common/status_chip.dart';
import 'package:cotorra_app/widgets/profile/profile_info.dart';
import 'package:cotorra_app/widgets/profile/stats_row.dart';
import 'package:cotorra_app/widgets/profile/settings_tile.dart';
import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const ProfileInfo(
          nombre: 'María González',
          email: 'maria.gonzalez@universidad.edu',
          rol: 'ALUMNO',
          inicial: 'M',
        ),
        const SizedBox(height: 32),
        const StatsRow(
          favoritosCount: 12,
          documentosCount: 3,
        ),
        const SizedBox(height: 24),
        SettingsTile(
          title: 'Configuración de Perfil',
          icon: Icons.settings_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            );
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
          trailing: const StatusChip(label: 'Aprobado', color: Colors.green),
        ),
      ],
    );
  }
}
