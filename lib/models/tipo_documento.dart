class TipoDocumento {
  final int id;
  final String nombre;

  TipoDocumento({required this.id, required this.nombre});

  factory TipoDocumento.fromJson(Map<String, dynamic> json) {
    return TipoDocumento(id: json['id'] ?? 0, nombre: json['nombre'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }
}
