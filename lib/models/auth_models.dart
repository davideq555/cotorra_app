// ─── Auth Models ─────────────────────────────────────────────────────
// DTOs de request/response para los 14 endpoints de autenticación.
// Basados en openapi.json v1.5.1 — components/schemas.
// ─────────────────────────────────────────────────────────────────────

import 'carrera.dart';
import 'enums.dart';
import 'usuario.dart';

// ─── Register ────────────────────────────────────────────────────────

class RegisterRequest {
  final String nombre;
  final String email;
  final String contrasena;
  final List<int> carreraIds;

  RegisterRequest({
    required this.nombre,
    required this.email,
    required this.contrasena,
    required this.carreraIds,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'email': email,
    'contraseña': contrasena,
    'carrera_ids': carreraIds,
  };
}

class RegisterResponse {
  final String message;
  final int userId;

  RegisterResponse({required this.message, required this.userId});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] ?? '',
      userId: json['user_id'] ?? 0,
    );
  }
}

// ─── Login ───────────────────────────────────────────────────────────

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// LoginResponse del backend. Incluye refresh_token (requerido).
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int userId;
  final String nombre;
  final String email;
  final String rol;
  final List<CarreraInfo> carreras;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.carreras,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      userId: json['user_id'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'ALUMNO',
      carreras:
          (json['carreras'] as List<dynamic>?)
              ?.map((c) => CarreraInfo.fromJson(c))
              .toList() ??
          [],
    );
  }

  /// Construye el [Usuario] desde la respuesta de login.
  Usuario toUsuario() => Usuario(
    id: userId,
    nombre: nombre,
    email: email,
    rol: RolEnum.values.firstWhere(
      (e) => e.toString().split('.').last == rol,
      orElse: () => RolEnum.ALUMNO,
    ),
    carreras: carreras.map((c) => c.toCarrera()).toList(),
  );
}

/// Versión simplificada de Carrera para el login response.
class CarreraInfo {
  final int id;
  final String nombre;
  final String? descripcion;

  CarreraInfo({required this.id, required this.nombre, this.descripcion});

  factory CarreraInfo.fromJson(Map<String, dynamic> json) {
    return CarreraInfo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }

  /// Convierte a Carrera completa para compatibilidad con modelos existentes.
  Carrera toCarrera() =>
      Carrera(id: id, nombre: nombre, descripcion: descripcion, facultadId: 0);
}

// ─── Login form (x-www-form-urlencoded) ──────────────────────────────

class LoginFormRequest {
  final String username;
  final String password;

  LoginFormRequest({required this.username, required this.password});

  Map<String, String> toFormBody() => {
    'username': username,
    'password': password,
  };
}

// ─── Google Login ────────────────────────────────────────────────────

class GoogleLoginRequest {
  final String credential;

  GoogleLoginRequest({required this.credential});

  Map<String, dynamic> toJson() => {'credential': credential};
}

// ─── Forgot / Reset Password ─────────────────────────────────────────

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordResponse {
  final String message;

  ForgotPasswordResponse({required this.message});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(message: json['message'] ?? '');
  }
}

class ResetPasswordRequest {
  final String token;
  final String nuevaContrasena;

  ResetPasswordRequest({required this.token, required this.nuevaContrasena});

  Map<String, dynamic> toJson() => {
    'token': token,
    'nueva_contraseña': nuevaContrasena,
  };
}

class ResetPasswordResponse {
  final String message;
  final bool success;

  ResetPasswordResponse({required this.message, required this.success});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
}

// ─── Verify Email ────────────────────────────────────────────────────

class VerifyEmailResponse {
  final String message;
  final bool success;

  VerifyEmailResponse({required this.message, required this.success});

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    return VerifyEmailResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
}

// ─── Verify Token ────────────────────────────────────────────────────

class VerifyTokenResponse {
  final bool valid;
  final int userId;
  final String email;
  final String role;

  VerifyTokenResponse({
    required this.valid,
    required this.userId,
    required this.email,
    required this.role,
  });

  factory VerifyTokenResponse.fromJson(Map<String, dynamic> json) {
    return VerifyTokenResponse(
      valid: json['valid'] ?? false,
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

// ─── Refresh Token ───────────────────────────────────────────────────

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

class RefreshTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      expiresIn: json['expires_in'] ?? 0,
    );
  }
}

// ─── Sessions ────────────────────────────────────────────────────────

class SessionInfo {
  final int id;
  final String? userAgent;
  final String? ipAddress;
  final String creadoEn;
  final String expiracion;
  final bool activa;

  SessionInfo({
    required this.id,
    this.userAgent,
    this.ipAddress,
    required this.creadoEn,
    required this.expiracion,
    required this.activa,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] ?? 0,
      userAgent: json['user_agent'],
      ipAddress: json['ip_address'],
      creadoEn: json['creado_en'] ?? '',
      expiracion: json['expiracion'] ?? '',
      activa: json['activa'] ?? false,
    );
  }
}

class SessionsListResponse {
  final List<SessionInfo> sesiones;
  final int total;

  SessionsListResponse({required this.sesiones, required this.total});

  factory SessionsListResponse.fromJson(Map<String, dynamic> json) {
    return SessionsListResponse(
      sesiones:
          (json['sesiones'] as List<dynamic>?)
              ?.map((s) => SessionInfo.fromJson(s))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

// ─── Cambiar Contraseña (usuarios, no auth, pero relacionado) ────────

class CambiarContrasenaRequest {
  final String contrasenaActual;
  final String contrasenaNueva;

  CambiarContrasenaRequest({
    required this.contrasenaActual,
    required this.contrasenaNueva,
  });

  Map<String, dynamic> toJson() => {
    'contraseña_actual': contrasenaActual,
    'contraseña_nueva': contrasenaNueva,
  };
}

class CambiarContrasenaResponse {
  final String message;
  final bool success;

  CambiarContrasenaResponse({required this.message, required this.success});

  factory CambiarContrasenaResponse.fromJson(Map<String, dynamic> json) {
    return CambiarContrasenaResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
}
