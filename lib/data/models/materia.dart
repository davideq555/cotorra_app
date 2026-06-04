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
