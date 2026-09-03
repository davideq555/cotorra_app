import 'package:cotorra_app/config/env.dart';
import 'package:cotorra_app/models/auth_models.dart';
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
    // 1. Iniciar sesión con Google
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw GoogleSignInException('El usuario canceló el inicio de sesión');
    }

    // 2. Obtener los detalles de autenticación
    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw GoogleSignInException('No se pudo obtener el token de Google');
    }

    // 3. Retornar el ID token para que el provider lo envíe al backend
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
