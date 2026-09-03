import 'facultad.dart';

class Carrera {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? duracion;
  final String? urlInformacion;
  final int facultadId;
  final Facultad? facultad;

  Carrera({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.duracion,
    this.urlInformacion,
    required this.facultadId,
    this.facultad,
  });

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      duracion: json['duracion'],
      urlInformacion: json['url_informacion'],
      facultadId: json['facultad_id'] ?? 0,
      facultad: json['facultad'] != null
          ? Facultad.fromJson(json['facultad'])
          : null,
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
      'facultad': facultad?.toJson(),
    };
  }
}
