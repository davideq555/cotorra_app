import 'carrera.dart';
import 'usuario.dart';

class Token {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String nombre;
  final String email;
  final String rol;
  final List<Carrera> carreras;

  Token({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.carreras,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? '',
      userId: json['user_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'ALUMNO',
      carreras: (json['carreras'] as List<dynamic>?)
              ?.map((c) => Carrera.fromJson(c))
              .toList() ??
          [],
    );
  }

  /// Convierte a Usuario para compatibilidad con AuthProvider
  Usuario toUsuario() {
    return Usuario.fromJson({
      'id': userId,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'carreras': carreras.map((c) => c.toJson()).toList(),
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user_id': userId,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'carreras': carreras.map((c) => c.toJson()).toList(),
    };
  }
}