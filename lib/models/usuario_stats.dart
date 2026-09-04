/// Estadísticas de un usuario — GET /usuarios/{id}/stats.
/// Basado en openapi.json — components/schemas/UsuarioStatsResponse.
class UsuarioStats {
  final int usuarioId;
  final int totalDocumentos;
  final int totalDescargas;
  final int totalFavoritos;
  final double valoracionPromedio;
  final int totalUpvotesComentarios;
  final int karma;

  UsuarioStats({
    required this.usuarioId,
    this.totalDocumentos = 0,
    this.totalDescargas = 0,
    this.totalFavoritos = 0,
    this.valoracionPromedio = 0.0,
    this.totalUpvotesComentarios = 0,
    this.karma = 0,
  });

  factory UsuarioStats.fromJson(Map<String, dynamic> json) {
    return UsuarioStats(
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      totalDocumentos: (json['total_documentos'] as num?)?.toInt() ?? 0,
      totalDescargas: (json['total_descargas'] as num?)?.toInt() ?? 0,
      totalFavoritos: (json['total_favoritos'] as num?)?.toInt() ?? 0,
      valoracionPromedio:
          (json['valoracion_promedio'] as num?)?.toDouble() ?? 0.0,
      totalUpvotesComentarios:
          (json['total_upvotes_comentarios'] as num?)?.toInt() ?? 0,
      karma: (json['karma'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'total_documentos': totalDocumentos,
      'total_descargas': totalDescargas,
      'total_favoritos': totalFavoritos,
      'valoracion_promedio': valoracionPromedio,
      'total_upvotes_comentarios': totalUpvotesComentarios,
      'karma': karma,
    };
  }
}
