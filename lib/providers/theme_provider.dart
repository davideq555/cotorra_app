import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema de la app con persistencia en el almacenamiento del dispositivo.
/// Modos: system (sigue al teléfono), light, dark.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  /// Carga la preferencia guardada. Se llama una vez en main() antes de
  /// runApp para que el primer frame ya salga con el tema correcto.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _themeMode = switch (prefs.getString(_prefsKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_prefsKey, mode.name);
  }

  /// Etiqueta legible en español, para subtítulos/tooltips.
  static String labelFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Sistema',
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
  };
}
