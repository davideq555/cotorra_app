import 'package:cotorra_app/config/env.dart';
import 'package:cotorra_app/models/auth_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación con Google.
///
/// Flujo:
/// 1. Abre el flujo de Google Sign-In
/// 2. Obtiene el ID token de Google
/// 3. Lo envía al backend POST /auth/google
/// 4. Retorna el LoginResponse (mismo que login normal)
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // En Android, el serverClientID se usa para intercambiar el ID token
    // por un access token en el servidor. El Web Client ID se usa aquí
    // para que Google pueda validar el token.
    serverClientId: Env.googleWebClientId,
  );

  /// Inicia el flujo de Google Sign-In.
  ///
  /// Retorna el [LoginResponse] del backend si fue exitoso.
  /// Lanza [GoogleSignInException] si el usuario cancela o hay error.
  Future<LoginResult> signIn() async {
    // 0. Diagnóstico: el client ID vacío/mal configurado es la causa #1 de
    // fallos silenciosos de Google Sign-In en Android.
    final clientId = Env.googleWebClientId;
    if (clientId.isEmpty) {
      debugPrint(
        '[GoogleAuth] ⚠️ GOOGLE_WEB_CLIENT_ID está VACÍO en .env — '
        'el flujo de Google NO puede funcionar. Configuralo en Google Cloud Console.',
      );
    } else {
      debugPrint(
        '[GoogleAuth] signIn() iniciado. '
        'serverClientId=${clientId.substring(0, clientId.length > 22 ? 22 : clientId.length)}… (${clientId.length} chars)',
      );
    }

    // 1. Iniciar sesión con Google
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } catch (e, st) {
      debugPrint('[GoogleAuth] ❌ signIn() lanzó ${e.runtimeType}: $e');
      debugPrint('[GoogleAuth] stack: $st');
      if (e is PlatformException) throw _mapPlatformError(e);
      rethrow;
    }

    if (googleUser == null) {
      debugPrint(
        '[GoogleAuth] ⚠️ signIn() devolvió null — el usuario cerró el selector '
        'o Google abortó el flujo sin aviso (pasá el log por filtro [GoogleAuth]).',
      );
      throw GoogleSignInException('El usuario canceló el inicio de sesión');
    }
    debugPrint(
      '[GoogleAuth] Cuenta elegida: ${googleUser.email} '
      '(nombre: ${googleUser.displayName}, id: ${googleUser.id})',
    );

    // 2. Obtener los detalles de autenticación
    GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e, st) {
      debugPrint(
        '[GoogleAuth] ❌ googleUser.authentication lanzó ${e.runtimeType}: $e',
      );
      debugPrint('[GoogleAuth] stack: $st');
      if (e is PlatformException) throw _mapPlatformError(e);
      rethrow;
    }
    debugPrint(
      '[GoogleAuth] authentication obtenido. '
      'accessToken=${googleAuth.accessToken != null ? '${googleAuth.accessToken!.length} chars' : 'NULL'}, '
      'idToken=${googleAuth.idToken != null ? '${googleAuth.idToken!.length} chars' : 'NULL'}',
    );

    if (googleAuth.idToken == null) {
      debugPrint(
        '[GoogleAuth] ❌ idToken nulo. Causas típicas en Android: '
        '(1) GOOGLE_WEB_CLIENT_ID no corresponde al proyecto OAuth de la app, '
        '(2) falta la huella SHA-1 (debug y release) cargada en Google Cloud Console / Firebase, '
        '(3) package name distinto al registrado. Revisá google-services.json y .env.',
      );
      throw GoogleSignInException('No se pudo obtener el token de Google');
    }

    // 3. Retornar el ID token para que el provider lo envíe al backend
    debugPrint('[GoogleAuth] ✅ ID token listo para enviar al backend.');
    return LoginResult(
      idToken: googleAuth.idToken!,
      displayName: googleUser.displayName,
      email: googleUser.email,
    );
  }

  /// Cierra la sesión de Google (local).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Convierte los PlatformException de google_sign_in (códigos de
  /// GoogleApi ApiException) en mensajes accionables para el usuario.
  GoogleSignInException _mapPlatformError(PlatformException e) {
    final msg = e.message ?? '';
    debugPrint('[GoogleAuth] _mapPlatformError code=${e.code} message=$msg');
    // ApiException 10 = DEVELOPER_ERROR: esta build (package + SHA-1) no está
    // registrada como OAuth client de Android en Google Cloud Console.
    if (msg.contains('ApiException: 10') || msg.contains('DeveloperError')) {
      return GoogleSignInException(
        'Google rechazó la configuración de la app (error 10). '
        'Falta registrar el package name y la huella SHA-1 de esta build '
        'como OAuth client de Android en Google Cloud Console.',
      );
    }
    if (msg.contains('ApiException: 12501') || e.code == 'canceled') {
      return GoogleSignInException('El usuario canceló el inicio de sesión');
    }
    if (msg.contains('ApiException: 12500')) {
      return GoogleSignInException(
        'No se pudo contactar a Google (error 12500). '
        'Puede ser la conexión o el Play Services del dispositivo.',
      );
    }
    return GoogleSignInException(
      'Falló Google Sign-In (${e.code}${msg.isNotEmpty ? ': $msg' : ''})',
    );
  }
}

/// Resultado del Google Sign-In antes de enviar al backend.
class LoginResult {
  final String idToken;
  final String? displayName;
  final String? email;

  LoginResult({required this.idToken, this.displayName, this.email});
}

/// Excepción personalizada para errores de Google Sign-In.
class GoogleSignInException implements Exception {
  final String message;
  GoogleSignInException(this.message);

  @override
  String toString() => message;
}
