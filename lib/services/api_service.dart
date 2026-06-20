import 'dart:convert';
import 'package:cotorra_app/config/env.dart';
import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/token.dart';
import 'package:cotorra_app/models/usuario.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';

import 'package:http/http.dart' as http;

// Servicio centralizado para interactuar con la API REST de Cotorra
// Maneja autenticación, registro de usuarios y gestión de documentos
class ApiService {
  // URL base del API (configurable via .env)
  String get baseUrl => Env.baseUrl;

  // ==================== AUTENTICACIÓN ====================

  /// Inicia sesión con credenciales username/password
  /// Retorna un Token para usar en requests autenticadas
  Future<Token> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/form'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      return Token.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  /// Registra un nuevo usuario en la plataforma
  /// Envía datos del nuevo usuario y retorna el Usuario creado
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

  // ==================== USUARIOS ====================

  /// Cambia la contraseña de un usuario
  /// Requiere contraseña actual para verificar identidad
  Future<Map<String, dynamic>> cambiarContrasena(
    String token,
    int usuarioId,
    String contrasenaActual,
    String contrasenaNueva,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/$usuarioId/cambiar-contraseña'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'contraseña_actual': contrasenaActual,
        'contraseña_nueva': contrasenaNueva,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

  // ==================== MATERIAS ====================

  /// Obtiene lista de materias con paginación opcional
  /// Acceso público permitido
  Future<List<Materia>> getMaterias({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/materias/?skip=$skip&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Materia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load materias: ${response.body}');
    }
  }

  // ==================== DOCUMENTOS ====================

  /// Obtiene lista de documentos aprobados con filtros y paginación
  /// Params: q (búsqueda), tipo, materia_id, año_academico, sort_by, sort_order
  Future<List<Documento>> getDocumentos(
    String token, {
    String? query,
    int? tipo,
    int? materiaId,
    String? anoAcademico,
    String sortBy = 'fecha_subida',
    String sortOrder = 'desc',
    int skip = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (tipo != null) params['tipo'] = tipo.toString();
    if (materiaId != null) params['materia_id'] = materiaId.toString();
    if (anoAcademico != null && anoAcademico.isNotEmpty) {
      params['año_academico'] = anoAcademico;
    }

    final uri = Uri.parse('$baseUrl/documentos/').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      
      // La API devuelve un objeto paginado con clave 'items' o un array directo
      List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data.containsKey('items')) {
        items = data['items'] as List<dynamic>;
      } else {
        throw Exception('Unexpected response format for documents');
      }
      
      return items.map((json) => Documento.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load documents: ${response.body}');
    }
  }

  /// Obtiene detalle de un documento específico por su ID
  Future<Documento> getDocumento(int documentoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/documentos/$documentoId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Documento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load document: ${response.body}');
    }
  }

  /// Obtiene los 6 documentos mejor rankeados (por descargas + valoración)
  Future<List<Documento>> getMejoresDocumentos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/documentos/mejores'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Documento.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load best documents: ${response.body}');
    }
  }

  /// Obtiene documentos de un usuario específico
  /// Solo admins pueden ver otros usuarios; usuarios normales ven solo los suyos
  Future<List<Documento>> getDocumentosUsuario(
    String token,
    int usuarioId, {
    int skip = 0,
    int limit = 20,
    bool includeDeleted = false,
  }) async {
    final uri = Uri.parse('$baseUrl/documentos/usuario/$usuarioId').replace(
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
        'include_deleted': includeDeleted.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Documento.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user documents: ${response.body}');
    }
  }

  /// Crea un documento a partir de datos (tipo FILE)
  /// Requiere token de autenticación
  Future<Documento> createDocumento(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/documentos/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Documento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create document: ${response.body}');
    }
  }

  /// Sube un documento con archivo (multipart)
  /// Solo tipo FILE; retorna el Documento creado
  Future<Documento> uploadDocumento(
    String token, {
    required String titulo,
    required String archivoBase64,
    required int tipo,
    String? descripcion,
    String? autor,
    int? materiaId,
    String? anoAcademico,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documentos/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    print('API uploadDocumento token: $token');
    request.fields['titulo'] = titulo;
    request.files.add(http.MultipartFile.fromBytes(
      'archivo',
      base64Decode(archivoBase64),
      filename: 'documento.pdf',
    ));
    request.fields['tipo'] = tipo.toString();
    if (descripcion != null) request.fields['descripcion'] = descripcion;
    if (autor != null) request.fields['autor'] = autor;
    if (materiaId != null) request.fields['materia_id'] = materiaId.toString();
    if (anoAcademico != null) request.fields['año_academico'] = anoAcademico;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('API uploadDocumento response status: ${response.statusCode}');
    print('API uploadDocumento response body: ${response.body}');

    if (response.statusCode == 201) {
      return Documento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to upload document: ${response.body}');
    }
  }

  /// Crea un documento a partir de un enlace externo (Google Drive, YouTube, GitHub, etc.)
  /// Solo tipo LINK
  Future<Documento> createDocumentoLink(
    String token, {
    required String titulo,
    required String urlExterna,
    required int tipo,
    String? descripcion,
    String? autor,
    int? materiaId,
    String? anoAcademico,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/documentos/link'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'titulo': titulo,
        'url_externa': urlExterna,
        'tipo': tipo,
        if (descripcion != null) 'descripcion': descripcion,
        if (autor != null) 'autor': autor,
        if (materiaId != null) 'materia_id': materiaId,
        if (anoAcademico != null) 'año_academico': anoAcademico,
      }),
    );

    print('API createDocumentoLink response status: ${response.statusCode}');
    print('API createDocumentoLink response body: ${response.body}');

    if (response.statusCode == 201) {
      return Documento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create link document: ${response.body}');
    }
  }

  /// Actualiza un documento existente
  Future<Documento> updateDocumento(
    String token,
    int documentoId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/documentos/$documentoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Documento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update document: ${response.body}');
    }
  }

  /// Elimina un documento (borrado lógico)
  Future<void> deleteDocumento(String token, int documentoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/documentos/$documentoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }

  /// Descarga un documento, incrementando el contador de descargas
  /// Retorna la URL/bytes del archivo
  Future<dynamic> descargarDocumento(int documentoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/documentos/$documentoId/descargar'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to download document: ${response.body}');
    }
  }

  // ==================== FAVORITOS ====================

  /// Obtiene todos los documentos favoritos del usuario autenticado
  Future<List<Documento>> getFavoritos(String token, {int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favoritos/?skip=$skip&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Documento.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load favorites: ${response.body}');
    }
  }

  /// Alterna el estado de favorito de un documento (agregar/quitar)
  /// Retorna {message, success, is_favorite}
  Future<Map<String, dynamic>> toggleFavorito(String token, int documentoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favoritos/toggle/$documentoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle favorite: ${response.body}');
    }
  }

  // ==================== FACULTADES ====================

  /// Obtiene lista de facultades
  Future<List<Facultad>> getFacultades() async {
    final response = await http.get(
      Uri.parse('$baseUrl/facultades/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Facultad.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load facultades: ${response.body}');
    }
  }

  // ==================== CARRERAS ====================

  /// Obtiene lista de carreras por facultad
  Future<List<Carrera>> getCarrerasPorFacultad(int facultadId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/carreras/facultad/$facultadId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Carrera.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carreras: ${response.body}');
    }
  }

  // ==================== MATERIAS ====================

  /// Obtiene lista de materias por carrera
  Future<List<Materia>> getMateriasPorCarrera(int carreraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/materias/carrera/$carreraId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Materia.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load materias: ${response.body}');
    }
  }
}
