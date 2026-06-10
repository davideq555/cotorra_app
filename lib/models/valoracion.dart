import 'usuario.dart';
import 'documento.dart';

class Valoracion {
  final int id;
  final int usuarioId;
  final int documentoId;
  final int puntuacion;
  final Usuario? usuario;
  final Documento? documento;


  Valoracion({
    required this.id,
    required this.usuarioId,
    required this.documentoId,
    required this.puntuacion,
    this.usuario,
    this.documento,
  });

  factory Valoracion.fromJson(Map<String, dynamic> json) {
    return Valoracion(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      documentoId: json['documento_id'] ?? 0,
      puntuacion: json['puntuacion'] ?? 0,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      documento: json['documento'] != null ? Documento.fromJson(json['documento']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'documento_id': documentoId,
      'puntuacion': puntuacion,
      'usuario': usuario?.toJson(),
      'documento': documento?.toJson(),
    };
  }
}
