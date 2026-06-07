import 'package:cotorra_app/models/enums.dart';

class UsuarioCreate {
  final String nombre;
  final String email;
  final RolEnum rol;
  final String contrasena; // mapped to "contraseña" in JSON
  final List<int> carreraIds;

  UsuarioCreate({
    required this.nombre,
    required this.email,
    required this.rol,
    required this.contrasena,
    required this.carreraIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol.toString().split('.').last,
      'contraseña': contrasena, // API expects exactly 'contraseña' with 'ñ'
      'carrera_ids': carreraIds,
    };
  }
}
