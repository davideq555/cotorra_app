// ─── Admin Models ────────────────────────────────────────────────────
// DTOs de request/response para los 28 endpoints de administración.
// Basados en openapi.json v1.5.1 — components/schemas.
// ─────────────────────────────────────────────────────────────────────

import 'carrera.dart';
import 'enums.dart';
import 'facultad.dart';

// ─── Pagination ──────────────────────────────────────────────────────

class PaginationMeta {
  final int total;
  final int skip;
  final int limit;
  final bool hasMore;

  PaginationMeta({
    required this.total,
    required this.skip,
    required this.limit,
    required this.hasMore,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 0,
      hasMore: json['has_more'] ?? false,
    );
  }
}

// ─── Usuario Admin ───────────────────────────────────────────────────

class UsuarioAdminListItem {
  final int id;
  final String nombre;
  final String? username;
  final String email;
  final RolEnum rol;
  final String? bio;
  final String? fechaCreacion;
  final bool verificado;
  final List<Carrera> carreras;

  UsuarioAdminListItem({
    required this.id,
    required this.nombre,
    this.username,
    required this.email,
    required this.rol,
    this.bio,
    this.fechaCreacion,
    required this.verificado,
    this.carreras = const [],
  });

  factory UsuarioAdminListItem.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminListItem(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      rol: RolEnum.values.firstWhere(
        (e) => e.toString().split('.').last == json['rol'],
        orElse: () => RolEnum.ALUMNO,
      ),
      bio: json['bio'],
      fechaCreacion: json['fecha_creacion'],
      verificado: json['verificado'] ?? false,
      carreras: (json['carreras'] as List<dynamic>?)
              ?.map((c) => Carrera.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class UsuarioPaginatedResponse {
  final List<UsuarioAdminListItem> items;
  final PaginationMeta meta;

  UsuarioPaginatedResponse({required this.items, required this.meta});

  factory UsuarioPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioPaginatedResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => UsuarioAdminListItem.fromJson(i))
              .toList() ??
          [],
      meta: PaginationMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class UsuarioPerfilUpdate {
  final String? nombre;
  final String? username;
  final String? bio;

  UsuarioPerfilUpdate({this.nombre, this.username, this.bio});

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (username != null) 'username': username,
        if (bio != null) 'bio': bio,
      };
}

class UsuarioUpdateAdmin {
  final String? nombre;
  final String? username;
  final String? email;
  final bool? verificado;
  final String? bio;

  UsuarioUpdateAdmin({
    this.nombre,
    this.username,
    this.email,
    this.verificado,
    this.bio,
  });

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (verificado != null) 'verificado': verificado,
        if (bio != null) 'bio': bio,
      };
}

class CambiarRolRequest {
  final RolEnum rol;

  CambiarRolRequest({required this.rol});

  Map<String, dynamic> toJson() => {
        'rol': rol.toString().split('.').last,
      };
}

class UsuarioWithAcademicInfo {
  final int id;
  final String nombre;
  final String? username;
  final String email;
  final RolEnum rol;
  final String? bio;
  final String? fechaCreacion;
  final bool verificado;
  final List<CarreraWithUniversidad> carreras;

  UsuarioWithAcademicInfo({
    required this.id,
    required this.nombre,
    this.username,
    required this.email,
    required this.rol,
    this.bio,
    this.fechaCreacion,
    required this.verificado,
    this.carreras = const [],
  });

  factory UsuarioWithAcademicInfo.fromJson(Map<String, dynamic> json) {
    return UsuarioWithAcademicInfo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      username: json['username'],
      email: json['email'] ?? '',
      rol: RolEnum.values.firstWhere(
        (e) => e.toString().split('.').last == json['rol'],
        orElse: () => RolEnum.ALUMNO,
      ),
      bio: json['bio'],
      fechaCreacion: json['fecha_creacion'],
      verificado: json['verificado'] ?? false,
      carreras: (json['carreras'] as List<dynamic>?)
              ?.map((c) => CarreraWithUniversidad.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class CarreraWithUniversidad {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? duracion;
  final String? urlInformacion;
  final int facultadId;
  final Facultad? facultad;

  CarreraWithUniversidad({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.duracion,
    this.urlInformacion,
    required this.facultadId,
    this.facultad,
  });

  factory CarreraWithUniversidad.fromJson(Map<String, dynamic> json) {
    return CarreraWithUniversidad(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      duracion: json['duracion'],
      urlInformacion: json['url_informacion'],
      facultadId: json['facultad_id'] ?? 0,
      facultad: json['facultad'] != null
          ? Facultad.fromJson(json['facultad'])
          : null,
    );
  }
}

// ─── Message ─────────────────────────────────────────────────────────

class MessageResponse {
  final String message;

  MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(message: json['message'] ?? '');
  }
}

// ─── Taxonomía CRUD ──────────────────────────────────────────────────

class CarreraCreate {
  final String nombre;
  final String? descripcion;
  final String? duracion;
  final String? urlInformacion;
  final int facultadId;

  CarreraCreate({
    required this.nombre,
    this.descripcion,
    this.duracion,
    this.urlInformacion,
    required this.facultadId,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (duracion != null) 'duracion': duracion,
        if (urlInformacion != null) 'url_informacion': urlInformacion,
        'facultad_id': facultadId,
      };
}

class CarreraUpdate {
  final String? nombre;
  final String? descripcion;
  final String? duracion;
  final String? urlInformacion;
  final int? facultadId;

  CarreraUpdate({
    this.nombre,
    this.descripcion,
    this.duracion,
    this.urlInformacion,
    this.facultadId,
  });

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (duracion != null) 'duracion': duracion,
        if (urlInformacion != null) 'url_informacion': urlInformacion,
        if (facultadId != null) 'facultad_id': facultadId,
      };
}

class MateriaCreate {
  final String nombre;
  final String? descripcion;
  final String? codigo;

  MateriaCreate({required this.nombre, this.descripcion, this.codigo});

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (codigo != null) 'codigo': codigo,
      };
}

class MateriaUpdate {
  final String? nombre;
  final String? descripcion;
  final String? codigo;

  MateriaUpdate({this.nombre, this.descripcion, this.codigo});

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (codigo != null) 'codigo': codigo,
      };
}

class CarreraMateriaCreate {
  final int carreraId;
  final int materiaId;
  final int? anioAcademico;
  final int? cuatrimestre;

  CarreraMateriaCreate({
    required this.carreraId,
    required this.materiaId,
    this.anioAcademico,
    this.cuatrimestre,
  });

  Map<String, dynamic> toJson() => {
        'carrera_id': carreraId,
        'materia_id': materiaId,
        if (anioAcademico != null) 'año_academico': anioAcademico,
        if (cuatrimestre != null) 'cuatrimestre': cuatrimestre,
      };
}

class CarreraMateriaUpdate {
  final int? anioAcademico;
  final int? cuatrimestre;

  CarreraMateriaUpdate({this.anioAcademico, this.cuatrimestre});

  Map<String, dynamic> toJson() => {
        if (anioAcademico != null) 'año_academico': anioAcademico,
        if (cuatrimestre != null) 'cuatrimestre': cuatrimestre,
      };
}

class UniversidadCreate {
  final String nombre;
  final String? descripcion;
  final String? pais;
  final String? ciudad;

  UniversidadCreate({
    required this.nombre,
    this.descripcion,
    this.pais,
    this.ciudad,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (pais != null) 'pais': pais,
        if (ciudad != null) 'ciudad': ciudad,
      };
}

class UniversidadUpdate {
  final String? nombre;
  final String? descripcion;
  final String? pais;
  final String? ciudad;

  UniversidadUpdate({this.nombre, this.descripcion, this.pais, this.ciudad});

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (pais != null) 'pais': pais,
        if (ciudad != null) 'ciudad': ciudad,
      };
}

class FacultadCreate {
  final String nombre;
  final String? descripcion;
  final int universidadId;

  FacultadCreate({
    required this.nombre,
    this.descripcion,
    required this.universidadId,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'universidad_id': universidadId,
      };
}

class FacultadUpdate {
  final String? nombre;
  final String? descripcion;
  final int? universidadId;

  FacultadUpdate({this.nombre, this.descripcion, this.universidadId});

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (universidadId != null) 'universidad_id': universidadId,
      };
}

// ─── Gestión de Materias ─────────────────────────────────────────────

class MateriaSuscripcionResponse {
  final String message;
  final bool success;

  MateriaSuscripcionResponse({required this.message, required this.success});

  factory MateriaSuscripcionResponse.fromJson(Map<String, dynamic> json) {
    return MateriaSuscripcionResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
}

class MateriaGestionResponse {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? codigo;
  final bool yaAsignado;

  MateriaGestionResponse({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.codigo,
    this.yaAsignado = false,
  });

  factory MateriaGestionResponse.fromJson(Map<String, dynamic> json) {
    return MateriaGestionResponse(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      codigo: json['codigo'],
      yaAsignado: json['ya_asignado'] ?? false,
    );
  }
}

// ─── Documentos Admin (paginated) ────────────────────────────────────

class DocumentoPaginatedResponse {
  final List<dynamic> items; // Documento[] — se importa desde documento.dart donde se use
  final PaginationMeta meta;

  DocumentoPaginatedResponse({required this.items, required this.meta});

  factory DocumentoPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return DocumentoPaginatedResponse(
      items: json['items'] as List<dynamic>? ?? [],
      meta: PaginationMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

// ─── Reportes ────────────────────────────────────────────────────────

class Reporte {
  final int id;
  final int? documentoId;
  final int? comentarioId;
  final int usuarioId;
  final String motivo;
  final String? descripcion;
  final String estado;
  final String fechaCreacion;
  final int? resueltoPor;
  final String? fechaResolucion;
  final String? notaResolucion;

  Reporte({
    required this.id,
    this.documentoId,
    this.comentarioId,
    required this.usuarioId,
    required this.motivo,
    this.descripcion,
    required this.estado,
    required this.fechaCreacion,
    this.resueltoPor,
    this.fechaResolucion,
    this.notaResolucion,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: json['id'] ?? 0,
      documentoId: json['documento_id'],
      comentarioId: json['comentario_id'],
      usuarioId: json['usuario_id'] ?? 0,
      motivo: json['motivo'] ?? '',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'PENDIENTE',
      fechaCreacion: json['fecha_creacion'] ?? '',
      resueltoPor: json['resuelto_por'],
      fechaResolucion: json['fecha_resolucion'],
      notaResolucion: json['nota_resolucion'],
    );
  }
}

class ReporteCreate {
  final int? documentoId;
  final int? comentarioId;
  final String motivo;
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
        'motivo': motivo,
        if (descripcion != null) 'descripcion': descripcion,
      };
}

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
      totalReportes: json['total_reportes'],
    );
  }
}

class ResolverReporteRequest {
  final String accion; // "eliminar" | "descartar" | "revisar"
  final String? nota;

  ResolverReporteRequest({required this.accion, this.nota});

  Map<String, dynamic> toJson() => {
        'accion': accion,
        if (nota != null) 'nota': nota,
      };
}

// ─── Solicitudes de Rol ──────────────────────────────────────────────

class SolicitudCambioRol {
  final int id;
  final int usuarioId;
  final String rolSolicitado;
  final String motivo;
  final String? documentoUrl;
  final String estado;
  final String fechaCreacion;
  final int? resueltoPor;
  final String? fechaResolucion;
  final String? notaResolucion;

  SolicitudCambioRol({
    required this.id,
    required this.usuarioId,
    required this.rolSolicitado,
    required this.motivo,
    this.documentoUrl,
    required this.estado,
    required this.fechaCreacion,
    this.resueltoPor,
    this.fechaResolucion,
    this.notaResolucion,
  });

  factory SolicitudCambioRol.fromJson(Map<String, dynamic> json) {
    return SolicitudCambioRol(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      rolSolicitado: json['rol_solicitado'] ?? '',
      motivo: json['motivo'] ?? '',
      documentoUrl: json['documento_url'],
      estado: json['estado'] ?? 'PENDIENTE',
      fechaCreacion: json['fecha_creacion'] ?? '',
      resueltoPor: json['resuelto_por'],
      fechaResolucion: json['fecha_resolucion'],
      notaResolucion: json['nota_resolucion'],
    );
  }
}

class SolicitudCambioRolResponse {
  final String message;
  final bool success;

  SolicitudCambioRolResponse({required this.message, required this.success});

  factory SolicitudCambioRolResponse.fromJson(Map<String, dynamic> json) {
    return SolicitudCambioRolResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
}

class ResolverSolicitudRequest {
  final String accion; // "aprobar" | "rechazar"
  final String? nota;

  ResolverSolicitudRequest({required this.accion, this.nota});

  Map<String, dynamic> toJson() => {
        'accion': accion,
        if (nota != null) 'nota': nota,
      };
}

class BodySolicitudesRolCreate {
  final String rolSolicitado;
  final String motivo;
  // documento: multipart file, se maneja en el servicio

  BodySolicitudesRolCreate({
    required this.rolSolicitado,
    required this.motivo,
  });

  Map<String, String> toFormFields() => {
        'rol_solicitado': rolSolicitado,
        'motivo': motivo,
      };
}
