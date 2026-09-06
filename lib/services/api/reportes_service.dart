import 'package:cotorra_app/models/reportes.dart';
import 'package:cotorra_app/services/api_client.dart';

/// Servicio de reportes — tag "reportes" de openapi.json.
///
/// Requiere autenticación Bearer (el [ApiClient] debe tener token activo).
///
/// Uso:
/// ```dart
/// final client = ApiClient()..setToken(token);
/// final reportes = ReportesService(client);
/// final result = await reportes.create(
///   ReporteCreate(documentoId: 42, motivo: MotivoReporte.copyright),
/// );
/// ```
class ReportesService {
  final ApiClient _client;

  ReportesService(this._client);

  /// POST /reportes/ — crea un reporte de documento o comentario.
  Future<ReporteResponse> create(ReporteCreate request) async {
    final response = await _client.post('/reportes/', body: request.toJson());
    return ReporteResponse.fromJson(_client.decodeResponse(response));
  }
}
