import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';


class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  Usuario? _user;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<bool> login(String username, String password) async {
    try {
      final tokenResponse = await _apiService.login(username, password);
      _token = tokenResponse.accessToken;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
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
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;
    
    _token = prefs.getString('token');
    notifyListeners();
  }
}
