// Models and schemas for CotorraApp to map API responses
/*
admin@gmail.com
123456
*/
enum RolEnum { ALUMNO, DOCENTE, ADMIN }

////////////  TOKEN /////////////

class Token {
  final String accessToken;
  final String tokenType;

  Token({required this.accessToken, required this.tokenType});

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }
}

////////////////////  USUARIO ///////////////////////////////////
class Usuario {
  final String nombre;
  final String email;
  final RolEnum rol;
  final int id;
  final String fechaCreacion;
  final bool verificado;

  Usuario({
    required this.nombre,
    required this.email,
    required this.rol,
    required this.id,
    required this.fechaCreacion,
    required this.verificado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    RolEnum parsedRol = RolEnum.ALUMNO;
    final rolStr = json['rol'];
    if (rolStr == 'DOCENTE') {
      parsedRol = RolEnum.DOCENTE;
    } else if (rolStr == 'ADMIN') {
      parsedRol = RolEnum.ADMIN;
    }

    return Usuario(
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: parsedRol,
      id: json['id'] ?? 0,
      fechaCreacion: json['fecha_creacion'] ?? '',
      verificado: json['verificado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol.toString().split('.').last,
      'id': id,
      'fecha_creacion': fechaCreacion,
      'verificado': verificado,
    };
  }
}


/////////////  CREATE USER ///////////////////

class UsuarioCreate {
  final String nombre;
  final String email;
  final RolEnum rol;
  final String contrasena; // mapped to "contraseña" in JSON
  final List<int> carreraIds;

  UsuarioCreate({
    required this.nombre,
    required this.email,
    required this.rol,
    required this.contrasena,
    required this.carreraIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol.toString().split('.').last,
      'contraseña': contrasena, // API expects exactly 'contraseña' with 'ñ'
      'carrera_ids': carreraIds,
    };
  }
}

////////////    CARRERA   ///////////

class Carrera {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? duracion;
  final String? urlInformacion;
  final int facultadId;

  Carrera({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.duracion,
    this.urlInformacion,
    required this.facultadId,
  });

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      duracion: json['duracion'],
      urlInformacion: json['url_informacion'],
      facultadId: json['facultad_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'duracion': duracion,
      'url_informacion': urlInformacion,
      'facultad_id': facultadId,
    };
  }
}

//////////  TAG ////////////

class Tag {
  final int id;
  final String nombre;

  Tag({required this.id, required this.nombre});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

////////// TIPO DOCUMENTO ////////////

class TipoDocumento {
  final int id;
  final String nombre;
  final String? descripcion;  // no esta en el back ni en la base datos

  TipoDocumento({required this.id, required this.nombre, this.descripcion});

  factory TipoDocumento.fromJson(Map<String, dynamic> json) {
    return TipoDocumento(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}

////////////  MATERIA ////////////

class Materia {
  final int id;
  final String nombre;
  final String? codigo;
  final int? departamentoId;

  Materia({required this.id, required this.nombre, this.codigo, this.departamentoId});

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      codigo: json['codigo'],
      departamentoId: json['departamento_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'departamento_id': departamentoId,
    };
  }
}

//////////////  DOCUMENTO //////////////

class Documento {
  final int id;
  final String titulo;
  final String archivoUrl;
  final String? autor;
  final String? descripcion;
  final int tipo;
  final int? materiaId;
  final String? anoAcademico; // mapped to "año_academico"
  final String fechaSubida; // mapped to "fecha_subida"
  final bool aprobado;
  final int descargas;
  final int usuarioId; // mapped to "usuario_id"
  final bool eliminado;
  final Usuario? usuario;
  final TipoDocumento? tipoDocumento;
  final Materia? materia;
  final List<Tag>? tags;

  Documento({
    required this.id,
    required this.titulo,
    required this.archivoUrl,
    this.autor,
    this.descripcion,
    required this.tipo,
    this.materiaId,
    this.anoAcademico,
    required this.fechaSubida,
    required this.aprobado,
    required this.descargas,
    required this.usuarioId,
    required this.eliminado,
    this.usuario,
    this.tipoDocumento,
    this.materia,
    this.tags,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    List<Tag>? tagsList;
    if (json['tags'] != null && json['tags'] is List) {
      tagsList = (json['tags'] as List).map((t) => Tag.fromJson(t)).toList();
    }

    return Documento(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      archivoUrl: json['archivo_url'] ?? '',
      autor: json['autor'],
      descripcion: json['descripcion'],
      tipo: json['tipo'] ?? 0,
      materiaId: json['materia_id'],
      anoAcademico: json['año_academico'],
      fechaSubida: json['fecha_subida'] ?? '',
      aprobado: json['aprobado'] ?? false,
      descargas: json['descargas'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      eliminado: json['eliminado'] ?? false,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
      tipoDocumento: json['tipo_documento'] != null ? TipoDocumento.fromJson(json['tipo_documento']) : null,
      materia: json['materia'] != null ? Materia.fromJson(json['materia']) : null,
      tags: tagsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'archivo_url': archivoUrl,
      'autor': autor,
      'descripcion': descripcion,
      'tipo': tipo,
      'materia_id': materiaId,
      'año_academico': anoAcademico,
      'fecha_subida': fechaSubida,
      'aprobado': aprobado,
      'descargas': descargas,
      'usuario_id': usuarioId,
      'eliminado': eliminado,
      'usuario': usuario?.toJson(),
      'tipo_documento': tipoDocumento?.toJson(),
      'materia': materia?.toJson(),
      'tags': tags?.map((t) => t.toJson()).toList(),
    };
  }
}
