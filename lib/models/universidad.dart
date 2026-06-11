class Universidad {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? pais;
  final String? ciudad;

  Universidad({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.pais,
    this.ciudad,
  });

  factory Universidad.fromJson(Map<String, dynamic> json) {
    return Universidad(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      pais: json['pais'],
      ciudad: json['ciudad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'pais': pais,
      'ciudad': ciudad,
    };
  }
}
