import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/screens/gestion/docente_materias_screen.dart';
import 'package:cotorra_app/screens/gestion/reportes_gestion_screen.dart';
import 'package:cotorra_app/widgets/profile/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hub de gestión por rol. Único punto de entrada (icono en el AppBar de
/// Perfil, ver [MainScreen]) para DOCENTE y COLABORADOR.
///
/// El gating es cosmético: el servidor impone el scope real de cada
/// endpoint. Aun así, si la pantalla se abre forzada con un rol no
/// habilitado, no se renderiza ninguna sección (spec: "Coerced gated role").
class GestionScreen extends StatelessWidget {
  const GestionScreen({super.key});

  /// Roles con acceso a la gestión. Case-insensitive: normaliza mayúsculas
  /// y espacios porque el rol llega como string libre desde la sesión.
  static bool gatedRole(String? rol) {
    final normalized = rol?.trim().toUpperCase();
    return normalized == 'DOCENTE' || normalized == 'COLABORADOR';
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.watch<AuthProvider>().userRol;
    final habilitado = gatedRole(rol);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: habilitado
          ? ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                if (rol?.trim().toUpperCase() == 'DOCENTE') ...[
                  _sectionHeader('Docente'),
                  SettingsTile(
                    title: 'Moderación de documentos',
                    subtitle: 'Materias a cargo y documentos pendientes',
                    icon: Icons.school_outlined,
                    onTap: () => _push(context, const DocenteMateriasScreen()),
                  ),
                ],
                if (rol?.trim().toUpperCase() == 'COLABORADOR') ...[
                  _sectionHeader('Colaborador'),
                  SettingsTile(
                    title: 'Cola de reportes',
                    subtitle: 'Reportes de documentos pendientes de resolución',
                    icon: Icons.report_gmailerrorred_outlined,
                    onTap: () => _push(context, const ReportesGestionScreen()),
                  ),
                ],
              ],
            )
          : Center(
              child: Text(
                'No tenés secciones de gestión disponibles.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
