import 'package:cotorra_app/data/models/enums.dart';

class Usuario {
  final String nombre;
  final String email;
  final RolEnum rol;
  final int id;
  final String fechaCreacion;
  final bool verificado;

  Usuario({
    required this.nombre,
    required this.email,
    required this.rol,
    required this.id,
    required this.fechaCreacion,
    required this.verificado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    RolEnum parsedRol = RolEnum.ALUMNO;
    final rolStr = json['rol'];
    if (rolStr == 'DOCENTE') {
      parsedRol = RolEnum.DOCENTE;
    } else if (rolStr == 'ADMIN') {
      parsedRol = RolEnum.ADMIN;
    }

    return Usuario(
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: parsedRol,
      id: json['id'] ?? 0,
      fechaCreacion: json['fecha_creacion'] ?? '',
      verificado: json['verificado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol.toString().split('.').last,
      'id': id,
      'fecha_creacion': fechaCreacion,
      'verificado': verificado,
    };
  }
}
