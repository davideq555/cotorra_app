class DocumentoFavorito {
  final int usuarioId;
  final int documentoId;
  final DateTime? fechaAgregado;

  DocumentoFavorito({
    required this.usuarioId,
    required this.documentoId,
    this.fechaAgregado,
  });

  factory DocumentoFavorito.fromJson(Map<String, dynamic> json) {
    return DocumentoFavorito(
      usuarioId: json['usuario_id'] ?? 0,
      documentoId: json['documento_id'] ?? 0,
      fechaAgregado: json['fecha_agregado'] != null
          ? DateTime.parse(json['fecha_agregado'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'documento_id': documentoId,
      'fecha_agregado': fechaAgregado?.toIso8601String(),
    };
  }
}
