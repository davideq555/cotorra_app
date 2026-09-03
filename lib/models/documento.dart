import 'formato.dart';
import 'materia.dart';
import 'tag.dart';
import 'tipoDocumento.dart';
import 'usuario.dart';

class Documento {
  final int id;
  final String titulo;
  final String archivoUrl;
  final String? archivoUrlPublica;
  final String? autor;
  final String? descripcion;
  final int tipo;
  final int? formatoId;
  final Formato? formato;
  final int? materiaId;
  final String? anoAcademico;
  final String? fechaSubida;
  final bool aprobado;
  final int descargas;
  final int usuarioId;
  final bool eliminado;
  final double valoracionPromedio;
  final int totalValoraciones;

  final Usuario? usuario;
  final TipoDocumento? tipoDocumento;
  final Materia? materia;
  final List<Tag>? tags;

  Documento({
    required this.id,
    required this.titulo,
    required this.archivoUrl,
    this.archivoUrlPublica,
    this.autor,
    this.descripcion,
    required this.tipo,
    this.formatoId,
    this.formato,
    this.materiaId,
    this.anoAcademico,
    this.fechaSubida,
    this.aprobado = false,
    this.descargas = 0,
    required this.usuarioId,
    this.eliminado = false,
    this.valoracionPromedio = 0.0,
    this.totalValoraciones = 0,
    this.usuario,
    this.tipoDocumento,
    this.materia,
    this.tags,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      archivoUrl: json['archivo_url'] ?? '',
      archivoUrlPublica: json['archivo_url_publica'],
      autor: json['autor'],
      descripcion: json['descripcion'],
      tipo: json['tipo'] ?? 0,
      formatoId: json['formato_id'],
      formato: json['formato'] != null
          ? Formato.fromJson(json['formato'])
          : null,
      materiaId: json['materia_id'],
      anoAcademico: json['año_academico'],
      fechaSubida: json['fecha_subida'],
      aprobado: json['aprobado'] ?? false,
      descargas: json['descargas'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      eliminado: json['eliminado'] ?? false,
      valoracionPromedio: (json['valoracion_promedio'] ?? 0.0).toDouble(),
      totalValoraciones: json['total_valoraciones'] ?? 0,
      usuario: json['usuario'] != null
          ? Usuario.fromJson(json['usuario'])
          : null,
      tipoDocumento: json['tipo_documento'] != null
          ? TipoDocumento.fromJson(json['tipo_documento'])
          : null,
      materia: json['materia'] != null
          ? Materia.fromJson(json['materia'])
          : null,
      tags: (json['tags'] as List?)?.map((t) => Tag.fromJson(t)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'archivo_url': archivoUrl,
      'archivo_url_publica': archivoUrlPublica,
      'autor': autor,
      'descripcion': descripcion,
      'tipo': tipo,
      'formato_id': formatoId,
      'formato': formato?.toJson(),
      'materia_id': materiaId,
      'año_academico': anoAcademico,
      'fecha_subida': fechaSubida,
      'aprobado': aprobado,
      'descargas': descargas,
      'usuario_id': usuarioId,
      'eliminado': eliminado,
      'valoracion_promedio': valoracionPromedio,
      'total_valoraciones': totalValoraciones,
      'usuario': usuario?.toJson(),
      'tipo_documento': tipoDocumento?.toJson(),
      'materia': materia?.toJson(),
      'tags': tags?.map((t) => t.toJson()).toList(),
    };
  }
}
