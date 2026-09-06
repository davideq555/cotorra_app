/// DTO de una fila de GET /materias-suscritas/ (openapi: UsuarioMateria).
///
/// Representa la relación usuario↔materia. [tipoRelacion] distingue el rol
/// de la relación (ej: 'DOCENTE' para docentes asignados, 'ALUMNO' para
/// suscripciones de estudio). El endpoint no trae el nombre de la materia:
/// quien la muestra hace el join con el catálogo (design D3).
class UsuarioMateria {
  final int id;
  final int usuarioId;
  final int materiaId;
  final String tipoRelacion;
  final String? fechaRelacion;

  UsuarioMateria({
    required this.id,
    required this.usuarioId,
    required this.materiaId,
    required this.tipoRelacion,
    this.fechaRelacion,
  });

  factory UsuarioMateria.fromJson(Map<String, dynamic> json) {
    return UsuarioMateria(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      materiaId: json['materia_id'] ?? 0,
      tipoRelacion: json['tipo_relacion'] ?? '',
      fechaRelacion: json['fecha_relacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'materia_id': materiaId,
      'tipo_relacion': tipoRelacion,
      'fecha_relacion': fechaRelacion,
    };
  }
}
