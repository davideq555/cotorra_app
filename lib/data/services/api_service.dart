import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'https://apicotorra.deqa.com.ar/api/v1';

  Future<Token> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/access-token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      return Token.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Usuario> register(UsuarioCreate usuarioCreate) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/registro/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(usuarioCreate.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Usuario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<List<Documento>> getDocumentos(String token, {String? query}) async {
    String url = '$baseUrl/documentos/';
    if (query != null && query.isNotEmpty) {
      // In a real app, you might want to use proper query parameters.
      // Assuming there's a search parameter or we just fetch and filter client-side if API doesn't support it directly.
      // We will add it as query parameter for now, e.g. ?q=query
      url += '?q=${Uri.encodeComponent(query)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Documento.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load documents: ${response.body}');
    }
  }

  // Example to get a single document details
  Future<Documento> getDocumento(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/documentos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Documento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load document details: ${response.body}');
    }
  }
}
