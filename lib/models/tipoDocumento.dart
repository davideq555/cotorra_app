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