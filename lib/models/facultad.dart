class Facultad {
  final int id;
  final String nombre;
  final String? descripcion;
  final int universidadId;

  Facultad({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.universidadId,
  });

  factory Facultad.fromJson(Map<String, dynamic> json) {
    return Facultad(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      universidadId: json['universidad_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'universidad_id': universidadId,
    };
  }
}
