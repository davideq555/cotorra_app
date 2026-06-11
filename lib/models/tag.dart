class Tag {
  final int id;
  final String nombre;

  Tag({
    required this.id,
    required this.nombre,
  });

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
