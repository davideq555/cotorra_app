// ─── Reportes Models ─────────────────────────────────────────────────
// DTOs de request/response para el tag "reportes" de openapi.json v1.5.1.
// POST /reportes/ — motiva enum MotivoReporte, descripcion opcional.
// ─────────────────────────────────────────────────────────────────────

/// Motivos soportados por el backend (MotivoReporteEnum).
/// La UI de la app expone: copyright, duplicado, mal_etiquetado,
/// inapropiado y otros.
enum MotivoReporte { copyright, duplicado, malEtiquetado, inapropiado, otros }

extension MotivoReporteX on MotivoReporte {
  /// Valor para el API (string exacto del enum de FastAPI).
  String get apiValue {
    switch (this) {
      case MotivoReporte.copyright:
        return 'COPYRIGHT';
      case MotivoReporte.duplicado:
        return 'DUPLICADO';
      case MotivoReporte.malEtiquetado:
        return 'MAL_ETIQUETADO';
      case MotivoReporte.inapropiado:
        return 'INAPROPIADO';
      case MotivoReporte.otros:
        return 'OTROS';
    }
  }

  /// Etiqueta para mostrar en la UI.
  String get label {
    switch (this) {
      case MotivoReporte.copyright:
        return 'Tiene copyright';
      case MotivoReporte.duplicado:
        return 'Está duplicado';
      case MotivoReporte.malEtiquetado:
        return 'Está mal etiquetado';
      case MotivoReporte.inapropiado:
        return 'Contenido inapropiado';
      case MotivoReporte.otros:
        return 'Otro motivo';
    }
  }
}

/// ReporteCreate — body de POST /reportes/.
/// Requiere [motivo]; [documentoId] o [comentarioId] según lo que se reporte.
class ReporteCreate {
  final int? documentoId;
  final int? comentarioId;
  final MotivoReporte motivo;
  final String? descripcion;

  ReporteCreate({
    this.documentoId,
    this.comentarioId,
    required this.motivo,
    this.descripcion,
  });

  Map<String, dynamic> toJson() => {
    if (documentoId != null) 'documento_id': documentoId,
    if (comentarioId != null) 'comentario_id': comentarioId,
    'motivo': motivo.apiValue,
    if (descripcion != null && descripcion!.isNotEmpty)
      'descripcion': descripcion,
  };
}

/// ReporteResponse — 201 de POST /reportes/.
class ReporteResponse {
  final String message;
  final bool success;
  final int? totalReportes;

  ReporteResponse({
    required this.message,
    required this.success,
    this.totalReportes,
  });

  factory ReporteResponse.fromJson(Map<String, dynamic> json) {
    return ReporteResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      totalReportes: json['total_reportes'] as int?,
    );
  }
}
