import 'package:cotorra_app/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación con Google (google_sign_in 7.x).
///
/// En v7 la API cambió por completo: `GoogleSignIn` es un singleton que exige
/// `initialize()` **una sola vez** antes de cualquier otro método, y la
/// autenticación (`authenticate`) es un paso separado de la autorización.
/// En Android esto corre sobre Credential Manager (la API que reemplazó al
/// Google Sign-In SDK deprecado de v6).
///
/// Flujo:
/// 1. `initialize()` con el WEB client ID como `serverClientId`
/// 2. `authenticate()` abre el selector y devuelve la cuenta elegida
/// 3. El `idToken` se envía al backend POST /auth/google
/// 4. Retorna el [LoginResult] (mismo que login normal)
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// `initialize()` debe llamarse exactamente una vez en la vida del proceso.
  /// Cachear el Future garantiza eso aunque signIn/signOut se llamen en paralelo.
  Future<void>? _initFuture;

  Future<void> _ensureInitialized() => _initFuture ??= _initialize();

  Future<void> _initialize() async {
    final webClientId = Env.googleWebClientId;
    if (webClientId.isEmpty) {
      debugPrint(
        '[GoogleAuth] ⚠️ GOOGLE_WEB_CLIENT_ID está VACÍO en .env — '
        'sin google-services.json, Android NO puede autenticar sin serverClientId.',
      );
    } else {
      debugPrint(
        '[GoogleAuth] initialize() — serverClientId='
        '${webClientId.substring(0, webClientId.length > 22 ? 22 : webClientId.length)}… '
        '(${webClientId.length} chars)',
      );
    }

    // Este proyecto NO usa google-services.json: según la doc de
    // google_sign_in_android, en ese caso es obligatorio pasar el client ID
    // de la app WEB registrada como serverClientId. Play Services identifica
    // a la app Android por package name + huella SHA-1 de la consola.
    await _googleSignIn.initialize(serverClientId: webClientId);
    debugPrint('[GoogleAuth] ✅ initialize() completado.');
  }

  /// Inicia el flujo de Google Sign-In.
  ///
  /// Retorna el [LoginResult] del backend si fue exitoso.
  /// Lanza [GoogleAuthException] si el usuario cancela o hay error.
  Future<LoginResult> signIn() async {
    await _ensureInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      debugPrint(
        '[GoogleAuth] ❌ supportsAuthenticate() = false — esta plataforma no '
        'permite disparar el login con UI propia.',
      );
      throw GoogleAuthException(
        'Esta plataforma no permite iniciar sesión con Google desde la app.',
      );
    }

    // 1. Abrir el selector de cuentas y autenticar
    GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e, st) {
      debugPrint(
        '[GoogleAuth] ❌ authenticate() lanzó code=${e.code.name} '
        'description=${e.description ?? '(sin descripción)'}',
      );
      debugPrint('[GoogleAuth] stack: $st');
      throw _mapException(e);
    }

    debugPrint(
      '[GoogleAuth] Cuenta elegida: ${account.email} '
      '(nombre: ${account.displayName}, id: ${account.id})',
    );

    // 2. En v7 el token viene directo de la cuenta (authentication es síncrono,
    //    sin llamada extra como en v6). Es válido por poco tiempo: se envía ya.
    final idToken = account.authentication.idToken;
    debugPrint(
      '[GoogleAuth] idToken=${idToken != null ? '${idToken.length} chars' : 'NULL'}',
    );

    if (idToken == null) {
      debugPrint(
        '[GoogleAuth] ❌ idToken nulo. Causas típicas en Android: '
        '(1) serverClientId (web client ID) no corresponde al proyecto OAuth, '
        '(2) falta la huella SHA-1 (debug y release) en Google Cloud Console, '
        '(3) package name distinto al registrado.',
      );
      throw GoogleAuthException('No se pudo obtener el token de Google');
    }

    // 3. Retornar el ID token para que el provider lo envíe al backend
    debugPrint('[GoogleAuth] ✅ ID token listo para enviar al backend.');
    return LoginResult(
      idToken: idToken,
      displayName: account.displayName,
      email: account.email,
    );
  }

  /// Cierra la sesión de Google (local al dispositivo).
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
      debugPrint('[GoogleAuth] signOut() completado.');
    } catch (e) {
      // No truncar el logout de la app por un fallo del logout de Google.
      debugPrint('[GoogleAuth] ⚠️ signOut() falló: ${e.runtimeType}: $e');
    }
  }

  /// Traduce los [GoogleSignInException] de v7 a mensajes accionables.
  GoogleAuthException _mapException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        // El plugin pasa tal cual el mensaje crudo de Credential Manager, así
        // que por acá llegan dos casos MUY distintos: una cancelación real del
        // usuario, o un error de cuenta/configuración que Credential Manager
        // reporta como "canceled" (ver troubleshooting de google_sign_in_android).
        final description = e.description ?? '';
        final pareceCancelacion =
            description.isEmpty || description.toLowerCase().contains('cancel');

        if (pareceCancelacion) {
          debugPrint('[GoogleAuth] Cancelación real del usuario.');
          return GoogleAuthException('El usuario canceló el inicio de sesión');
        }

        debugPrint(
          '[GoogleAuth] ⚠️ code=canceled con descripción "$description" — NO es '
          'una cancelación real: Credential Manager está enmascarando un error '
          '(cuenta que exige reauth, o configuración SHA-1/package/serverClientId).',
        );
        return GoogleAuthException(
          'No se pudo completar el inicio de sesión con Google. '
          'Intentá de nuevo; si persiste, revisá la cuenta de Google del '
          'dispositivo y la configuración de la app en Google Cloud Console.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return GoogleAuthException(
          'Google rechazó la configuración de la app (${e.code.name}). '
          'Verificá el package name, la huella SHA-1 de esta build y el '
          'serverClientId en Google Cloud Console.',
        );
      case GoogleSignInExceptionCode.interrupted:
        return GoogleAuthException(
          'El inicio de sesión se interrumpió. Intentá de nuevo.',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return GoogleAuthException(
          'No hay una interfaz de Google disponible en este dispositivo. '
          'Verificá que Google Play Services esté actualizado.',
        );
      default:
        return GoogleAuthException(
          'Falló Google Sign-In (${e.code.name}'
          '${e.description != null ? ': ${e.description}' : ''})',
        );
    }
  }
}

/// Resultado del Google Sign-In antes de enviar al backend.
class LoginResult {
  final String idToken;
  final String? displayName;
  final String? email;

  LoginResult({required this.idToken, this.displayName, this.email});
}

/// Excepción propia del flujo de Google con mensaje ya listo para mostrar.
///
/// Se llama `GoogleAuthException` (y no `GoogleSignInException`) para no
/// colisionar con la excepción homónima que exporta google_sign_in 7.x.
class GoogleAuthException implements Exception {
  final String message;
  GoogleAuthException(this.message);

  @override
  String toString() => message;
}
