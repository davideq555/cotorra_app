class Formato {
  final int id;
  final String nombre;
  final String? extensiones;
  final String? mimeType;
  final bool esEnlace;

  Formato({
    required this.id,
    required this.nombre,
    this.extensiones,
    this.mimeType,
    this.esEnlace = false,
  });

  factory Formato.fromJson(Map<String, dynamic> json) {
    return Formato(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      extensiones: json['extensiones'],
      mimeType: json['mime_type'],
      esEnlace: json['es_enlace'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'extensiones': extensiones,
      'mime_type': mimeType,
      'es_enlace': esEnlace,
    };
  }
}
