import 'dart:convert';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';


class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const String _favoritesCountKey = 'favorites_count';

  String? _token;
  Usuario? _user;
  int _favoritesCount = 0;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  int? get userId => _user?.id;
  String? get userName => _user?.nombre;
  String? get userEmail => _user?.email;
  String? get userRol => _user?.rol.toString().split('.').last;
  List<Carrera> get userCarreras => _user?.carreras ?? [];
  int get favoritesCount => _favoritesCount;

  Future<bool> login(String username, String password) async {
    try {
      final tokenResponse = await _apiService.login(username, password);
      _token = tokenResponse.accessToken;
      _user = tokenResponse.toUsuario();
      _errorMessage = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      // Guardar datos del usuario para auto-login
      await prefs.setString('user_data', jsonEncode(tokenResponse.toJson()));
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      print('Login error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(UsuarioCreate userCreate) async {
    try {
      await _apiService.register(userCreate);
      // Registro exitoso, ahora hacer login
      return await login(userCreate.email, userCreate.contrasena);
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      print('Register error: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  /// Extrae el mensaje de error del backend desde una Exception
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString();
    // Intentar extraer el JSON del mensaje de error
    // Formato: "Exception: Failed to login: {\"detail\": \"...\"}"
    final jsonMatch = RegExp(r'\{.*\}').firstMatch(errorStr);
    if (jsonMatch != null) {
      try {
        final json = jsonDecode(jsonMatch.group(0)!);
        if (json is Map && json.containsKey('detail')) {
          final detail = json['detail'].toString();
          // Traducir mensajes comunes del backend
          if (detail.toLowerCase().contains('incorrect') || 
              detail.toLowerCase().contains('invalid')) {
            return 'Email o contraseña incorrectos';
          }
          return detail;
        }
        if (json is Map && json.containsKey('message')) {
          return json['message'].toString();
        }
      } catch (_) {
        // Si no se puede parsear, usar el mensaje original
      }
    }
    // Mensaje por defecto si no se puede extraer
    if (errorStr.contains('SocketException') || errorStr.contains('Connection')) {
      return 'No se pudo conectar al servidor. Verificá tu conexión a internet.';
    }
    return 'Ocurrió un error. Por favor intentá de nuevo.';
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;
    
    _token = prefs.getString('token');
    // user_data se guarda en cada login
    final userDataJson = prefs.getString('user_data');
    if (userDataJson != null) {
      _user = Usuario.fromJson(jsonDecode(userDataJson));
    }
    // Cargar count de favoritos persistido
    _favoritesCount = prefs.getInt(_favoritesCountKey) ?? 0;
    notifyListeners();
  }

  /// Actualiza el count de favoritos.
  void updateFavoritesCount(int count) {
    _favoritesCount = count;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_favoritesCountKey, count);
    });
    notifyListeners();
  }
}
