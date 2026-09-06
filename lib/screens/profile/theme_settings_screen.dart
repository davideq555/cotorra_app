import 'package:cotorra_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla de configuración de apariencia: Tema Sistema / Claro / Oscuro.
/// La preferencia se persiste en SharedPreferences vía ThemeProvider.
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apariencia',
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
          const Text(
            'TEMA DE LA APLICACIÓN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: theme.themeMode,
                onChanged: (mode) {
                  if (mode != null) theme.setMode(mode);
                },
                child: Column(
                  children: [
                    _ThemeOption(
                      mode: ThemeMode.system,
                      icon: Icons.brightness_auto_outlined,
                      title: 'Sistema',
                      subtitle: 'Sigue el claro/oscuro del teléfono',
                      activeColor: primaryGreen,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ThemeOption(
                      mode: ThemeMode.light,
                      icon: Icons.light_mode_outlined,
                      title: 'Claro',
                      subtitle: 'Tema claro siempre',
                      activeColor: primaryGreen,
                    ),
                    const Divider(height: 1, indent: 56),
                    _ThemeOption(
                      mode: ThemeMode.dark,
                      icon: Icons.dark_mode_outlined,
                      title: 'Oscuro',
                      subtitle: 'Tema oscuro siempre',
                      activeColor: primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tu elección se guarda en este dispositivo y se aplica al instante.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color activeColor;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: mode,
      activeColor: activeColor,
      secondary: Icon(icon, color: activeColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
