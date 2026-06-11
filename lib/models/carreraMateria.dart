import 'carrera.dart';
import 'materia.dart';

class CarreraMateria {
  final int carreraId;
  final int materiaId;
  final int? anoAcademico;
  final int cuatrimestre;
  final Carrera? carrera;
  final Materia? materia;

  CarreraMateria({
    required this.carreraId,
    required this.materiaId,
    this.anoAcademico,
    this.cuatrimestre = 0,
    this.carrera,
    this.materia,
  });

  factory CarreraMateria.fromJson(Map<String, dynamic> json) {
    return CarreraMateria(
      carreraId: json['carrera_id'] ?? 0,
      materiaId: json['materia_id'] ?? 0,
      anoAcademico: json['año_academico'],
      cuatrimestre: json['cuatrimestre'] ?? 0,
      carrera: json['carrera'] != null ? Carrera.fromJson(json['carrera']) : null,
      materia: json['materia'] != null ? Materia.fromJson(json['materia']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carrera_id': carreraId,
      'materia_id': materiaId,
      'año_academico': anoAcademico,
      'cuatrimestre': cuatrimestre,
      'carrera': carrera?.toJson(),
      'materia': materia?.toJson(),
    };
  }
}
