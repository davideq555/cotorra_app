import 'package:cotorra_app/models/documento.dart';

/// Cadena de formulario: se recorta y el vacío se normaliza a null para
/// comparar de forma estable contra los campos nullable de [Documento].
String? _normalizeText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Construye el body parcial del PUT /documentos/{id} con SOLO los campos
/// modificados respecto del [original] (R3 — actualización parcial).
///
/// Es una función pura y compartida: el sheet de edición la usa antes de
/// decidir si envía el PUT (body vacío ⇒ cerrar sin request). Nunca incluye
/// `archivo_url` ni `aprobado`: la edición de metadatos no toca el archivo
/// ni la moderación.
///
/// Reglas de normalización:
/// - textos: `trim()`; cadena vacía ⇒ null (para campos nullable);
/// - `tipo`: el value del dropdown llega como String del catálogo y se
///   serializa como int;
/// - `año_academico`: el value del dropdown llega como int y se serializa
///   como String, el formato del modelo/backend;
/// - una clave solo entra al body si su valor normalizado `!=` el original.
Map<String, dynamic> buildUpdateBody(
  Documento original,
  String titulo,
  String descripcion,
  String tipo,
  int? materiaId,
  int? anoAcademico,
  String autor,
) {
  final body = <String, dynamic>{};

  // titulo es no-nullable en el modelo: se envía recortado, vacío nunca
  // puede ser un valor válido de edición.
  final nuevoTitulo = titulo.trim();
  if (nuevoTitulo != original.titulo) body['titulo'] = nuevoTitulo;

  final nuevaDescripcion = _normalizeText(descripcion);
  if (nuevaDescripcion != original.descripcion) {
    body['descripcion'] = nuevaDescripcion;
  }

  final nuevoAutor = _normalizeText(autor);
  if (nuevoAutor != original.autor) body['autor'] = nuevoAutor;

  final nuevoTipo = int.tryParse(tipo.trim());
  if (nuevoTipo != null && nuevoTipo != original.tipo) body['tipo'] = nuevoTipo;

  if (materiaId != original.materiaId) body['materia_id'] = materiaId;

  final nuevoAno = anoAcademico?.toString();
  if (nuevoAno != original.anoAcademico) body['año_academico'] = nuevoAno;

  return body;
}
