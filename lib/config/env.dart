import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de variables de entorno para la app Cotorra.
/// Carga automáticamente desde .env en la raíz del proyecto.
///
/// Ejemplo .env:
/// ```
/// API_BASE_URL=https://apicotorra.deqa.com.ar/api/v1
/// ENVIRONMENT=development
/// TEST_USER_EMAIL=admin@gmail.com
/// TEST_USER_PASSWORD=123456
/// ```
class Env {
  Env._();

  /// URL base del API de Cotorra
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://apicotorra.deqa.com.ar/api/v1';

  /// Ambiente actual: 'development' | 'production' | 'staging'
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Indica si estamos en desarrollo
  static bool get isDevelopment => environment == 'development';

  /// Indica si estamos en producción
  static bool get isProduction => environment == 'production';

  /// Indica si estamos en staging
  static bool get isStaging => environment == 'staging';

  /// Email para tests de integración
  static String get testUserEmail =>
      dotenv.env['TEST_USER_EMAIL'] ?? 'admin@gmail.com';

  /// Password para tests de integración
  static String get testUserPassword =>
      dotenv.env['TEST_USER_PASSWORD'] ?? '123456';
}