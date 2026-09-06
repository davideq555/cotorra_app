import 'carrera.dart';
import 'enums.dart';

class Usuario {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final String? bio;
  final RolEnum rol;
  final String? fechaCreacion;
  final bool verificado;
  final List<Carrera> carreras;

  Usuario({
    required this.id,
    required this.nombre,
    this.username = '',
    required this.email,
    this.bio,
    required this.rol,
    this.fechaCreacion,
    this.verificado = false,
    this.carreras = const [],
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      rol: RolEnum.values.firstWhere(
        (e) => e.toString().split('.').last == json['rol'],
        orElse: () => RolEnum.ALUMNO,
      ),
      fechaCreacion: json['fecha_creacion'],
      verificado: json['verificado'] ?? false,
      carreras:
          (json['carreras'] as List<dynamic>?)
              ?.map((c) => Carrera.fromJson(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'username': username,
      'email': email,
      'bio': bio,
      'rol': rol.toString().split('.').last,
      'fecha_creacion': fechaCreacion,
      'verificado': verificado,
      'carreras': carreras.map((c) => c.toJson()).toList(),
    };
  }
}
