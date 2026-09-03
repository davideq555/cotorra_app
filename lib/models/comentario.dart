import 'usuario.dart';
import 'documento.dart';

class Comentario {
  final int id;
  final String contenido;
  final int usuarioId;
  final int documentoId;
  final DateTime? fecha;
  final Usuario? usuario;
  final Documento? documento;

  Comentario({
    required this.id,
    required this.contenido,
    required this.usuarioId,
    required this.documentoId,
    this.fecha,
    this.usuario,
    this.documento,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'] ?? 0,
      contenido: json['contenido'] ?? '',
      usuarioId: json['usuario_id'] ?? 0,
      documentoId: json['documento_id'] ?? 0,
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      usuario: json['usuario'] != null
          ? Usuario.fromJson(json['usuario'])
          : null,
      documento: json['documento'] != null
          ? Documento.fromJson(json['documento'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenido': contenido,
      'usuario_id': usuarioId,
      'documento_id': documentoId,
      'fecha': fecha?.toIso8601String(),
      'usuario': usuario?.toJson(),
      'documento': documento?.toJson(),
    };
  }
}
