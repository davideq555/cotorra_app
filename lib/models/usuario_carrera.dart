class UsuarioCarrera {
  final int usuarioId;
  final int carreraId;
  final DateTime? fechaInicio;
  final bool activa;

  UsuarioCarrera({
    required this.usuarioId,
    required this.carreraId,
    this.fechaInicio,
    this.activa = true,
  });

  factory UsuarioCarrera.fromJson(Map<String, dynamic> json) {
    return UsuarioCarrera(
      usuarioId: json['usuario_id'] ?? 0,
      carreraId: json['carrera_id'] ?? 0,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : null,
      activa: json['activa'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'carrera_id': carreraId,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'activa': activa,
    };
  }
}
