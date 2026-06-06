import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/tag.dart';
import 'package:cotorra_app/models/tipoDocumento.dart';
import 'package:cotorra_app/models/usuario.dart';

class Documento {
  final int id;
  final String titulo;
  final String archivoUrl;
  final String? autor;
  final String? descripcion;
  final int tipo;
  final int? materiaId;
  final String? anoAcademico; // mapped to "año_academico"
  final String fechaSubida; // mapped to "fecha_subida"
  //final String fechaEliminacion; // no esta en base de datos pero si en diagrama
  final bool aprobado;
  final int descargas;
  final int usuarioId; // mapped to "usuario_id"
  final bool eliminado;



  final Usuario? usuario;
  final TipoDocumento? tipoDocumento;
  final Materia? materia;
  final List<Tag>? tags;



  Documento({
    required this.id,
    required this.titulo,
    required this.archivoUrl,
    this.autor,
    this.descripcion,
    required this.tipo,
    this.materiaId,
    this.anoAcademico,
    required this.fechaSubida,
    required this.aprobado,
    required this.descargas,
    required this.usuarioId,
    required this.eliminado,
    this.usuario,
    this.tipoDocumento,
    this.materia,
    this.tags,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    List<Tag>? tagsList;
    if (json['tags'] != null && json['tags'] is List) {
      tagsList = (json['tags'] as List).map((t) => Tag.fromJson(t)).toList();
    }

    return Documento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      archivoUrl: json['archivo_url'] ?? '',
      autor: json['autor'],
      descripcion: json['descripcion'],
      tipo: json['tipo'] ?? 0,
      materiaId: json['materia_id'],
      anoAcademico: json['año_academico'],
      fechaSubida: json['fecha_subida'] ?? '',
      aprobado: json['aprobado'] ?? false,
      descargas: json['descargas'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      eliminado: json['eliminado'] ?? false,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      tipoDocumento: json['tipo_documento'] != null ? TipoDocumento.fromJson(json['tipo_documento']) : null,
      materia: json['materia'] != null ? Materia.fromJson(json['materia']) : null,
      tags: tagsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'archivo_url': archivoUrl,
      'autor': autor,
      'descripcion': descripcion,
      'tipo': tipo,
      'materia_id': materiaId,
      'año_academico': anoAcademico,
      'fecha_subida': fechaSubida,
      'aprobado': aprobado,
      'descargas': descargas,
      'usuario_id': usuarioId,
      'eliminado': eliminado,
      'usuario': usuario?.toJson(),
      'tipo_documento': tipoDocumento?.toJson(),
      'materia': materia?.toJson(),
      'tags': tags?.map((t) => t.toJson()).toList(),
    };
  }
}
