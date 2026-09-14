// ignore_for_file: constant_identifier_names
//
// Enum identifiers are the wire contract with the backend: models parse the
// role via `e.toString().split('.').last == json['rol']`. Renaming them to
// lowerCamelCase would break role parsing.
enum RolEnum { ALUMNO, DOCENTE, COLABORADOR, ADMIN }
