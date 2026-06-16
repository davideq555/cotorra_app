import 'dart:convert';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';


class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  Usuario? _user;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  int? get userId => _user?.id;
  String? get userName => _user?.nombre;
  String? get userEmail => _user?.email;
  String? get userRol => _user?.rol.toString().split('.').last;
  List<Carrera> get userCarreras => _user?.carreras ?? [];

  Future<bool> login(String username, String password) async {
    try {
      final tokenResponse = await _apiService.login(username, password);
      _token = tokenResponse.accessToken;
      _user = tokenResponse.toUsuario();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      // Guardar datos del usuario para auto-login
      await prefs.setString('user_data', jsonEncode(tokenResponse.toJson()));
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(UsuarioCreate userCreate) async {
    try {
      await _apiService.register(userCreate);
      return await login(userCreate.email, userCreate.contrasena);
    } catch (e) {
      print('Register error: $e');
      return false;
    }
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
    // Restaurar datos del usuario
    final userDataJson = prefs.getString('user_data');
    if (userDataJson != null) {
      _user = Usuario.fromJson(jsonDecode(userDataJson));
    }
    notifyListeners();
  }
}
