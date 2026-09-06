import 'dart:io';

import 'package:cotorra_app/services/api_client.dart';
import 'package:http/http.dart' as http;

const _sessionExpiredMessage = 'Tu sesión expiró, volvé a iniciar sesión.';
const _noPermissionMessage = 'No tenés permisos sobre este documento.';
const _notFoundMessage = 'El documento ya no existe.';
const _offlineMessage = 'Verificá tu conexión a internet…';

/// Mapea un error de las acciones sobre documentos (editar/eliminar) al
/// mensaje exacto de la Snackbar roja del perfil (R6).
///
/// Códigos mapeados explícitamente: 401 (sesión expirada), 403 (sin
/// permisos) y 404 (documento inexistente). Cualquier otro [ApiException]
/// muestra el `message` que devolvió el backend. Los errores de red
/// ([SocketException] o [http.ClientException] de conexión) informan
/// desconexión. Errores inesperados caen en su `toString()` para que la UI
/// nunca reviente por pintar un mensaje.
String documentActionErrorMessage(Object error) {
  if (error is SocketException) return _offlineMessage;
  if (error is http.ClientException &&
      error.message.toLowerCase().contains('connection')) {
    return _offlineMessage;
  }
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return _sessionExpiredMessage;
      case 403:
        return _noPermissionMessage;
      case 404:
        return _notFoundMessage;
      default:
        return error.message;
    }
  }
  return error.toString();
}
