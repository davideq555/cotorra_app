import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/providers/theme_provider.dart';
import 'package:cotorra_app/screens/profile/change_password_screen.dart';
import 'package:cotorra_app/screens/profile/datos_personales_screen.dart';
import 'package:cotorra_app/screens/profile/mis_carreras_screen.dart';
import 'package:cotorra_app/screens/profile/theme_settings_screen.dart';
import 'package:cotorra_app/widgets/profile/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Punto único de configuración de la cuenta: datos, contraseña,
/// apariencia y carreras. Desde el perfil solo se llega acá.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrerasCount = context.watch<AuthProvider>().userCarreras.length;
    final temaLabel = ThemeProvider.labelFor(
      context.watch<ThemeProvider>().themeMode,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _sectionHeader('Cuenta'),
          SettingsTile(
            title: 'Datos personales',
            subtitle: 'Nombre, usuario y bio',
            icon: Icons.person_outline,
            onTap: () => _push(context, const DatosPersonalesScreen()),
          ),
          const SizedBox(height: 12),
          SettingsTile(
            title: 'Cambiar contraseña',
            subtitle: 'Actualizá tus credenciales',
            icon: Icons.lock_outline,
            onTap: () => _push(context, const ChangePasswordScreen()),
          ),
          const SizedBox(height: 28),
          _sectionHeader('Apariencia'),
          SettingsTile(
            title: 'Tema',
            subtitle: 'Actual: $temaLabel',
            icon: Icons.palette_outlined,
            onTap: () => _push(context, const ThemeSettingsScreen()),
          ),
          const SizedBox(height: 28),
          _sectionHeader('Académico'),
          SettingsTile(
            title: 'Mis carreras',
            subtitle: carrerasCount == 1
                ? '1 carrera asignada'
                : '$carrerasCount carreras asignadas',
            icon: Icons.school_outlined,
            onTap: () => _push(context, const MisCarrerasScreen()),
          ),
        ],
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
