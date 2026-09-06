import 'dart:io';

import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:cotorra_app/utils/document_action_errors.dart';
import 'package:cotorra_app/utils/document_update_body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Original de referencia: todos sus campos "de formulario" tienen valor,
/// para que cada test cambie exactamente una cosa.
Documento _original() => Documento(
  id: 1,
  titulo: 'Álgebra I — Parcial 1',
  archivoUrl: 'files/1.pdf',
  tipo: 2,
  usuarioId: 42,
  autor: 'Juan Pérez',
  descripcion: 'Primer parcial 2024',
  materiaId: 5,
  anoAcademico: '2024',
);

/// Body con los valores del original sin cambios: cualquier clave que
/// aparezca en el resultado es una falsa-diferencia del diff.
Map<String, dynamic> _bodyUnchanged({
  String titulo = 'Álgebra I — Parcial 1',
  String descripcion = 'Primer parcial 2024',
  String tipo = '2',
  int? materiaId = 5,
  int? anoAcademico = 2024,
  String autor = 'Juan Pérez',
}) => buildUpdateBody(
  _original(),
  titulo,
  descripcion,
  tipo,
  materiaId,
  anoAcademico,
  autor,
);

void main() {
  group('buildUpdateBody — diff parcial para PUT (R3)', () {
    test('cambio de un solo campo → body con solo esa clave', () {
      final body = _bodyUnchanged(titulo: 'Álgebra I — Parcial 2');
      expect(body, {'titulo': 'Álgebra I — Parcial 2'});
    });

    test('sin cambios → body vacío (el sheet lo trata como no-op)', () {
      expect(_bodyUnchanged(), isEmpty);
    });

    test('recorta espacios y normaliza cadena vacía a null', () {
      // titulo y autor cambiantes pierden espacios sobrantes; descripcion
      // en blanco se normaliza a null (distinta del valor original).
      final body = _bodyUnchanged(
        titulo: '  Nuevo título  ',
        descripcion: '   ',
        autor: '  Ana Gómez  ',
      );
      expect(body, {
        'titulo': 'Nuevo título',
        'descripcion': null,
        'autor': 'Ana Gómez',
      });
    });

    test('descripcion ya nula y campo en blanco → sin clave descripcion', () {
      final original = _original();
      final body = buildUpdateBody(
        original,
        original.titulo,
        '', // blanco sobre descripcion con valor → cambia a null
        '2',
        5,
        2024,
        original.autor ?? '',
      );
      expect(body, {'descripcion': null});
      // Y con original.sin descripción y texto vacío, no hay diferencia.
      final originalSinDesc = Documento(
        id: 1,
        titulo: 'T',
        archivoUrl: 'u',
        tipo: 2,
        usuarioId: 42,
      );
      expect(
        buildUpdateBody(originalSinDesc, 'T', '  ', '2', null, null, ''),
        isEmpty,
      );
    });

    test('tipo, materia_id y año_académico modificados entran con su tipo', () {
      final body = _bodyUnchanged(tipo: '3', materiaId: 8, anoAcademico: 2025);
      // tipo va como int (Dropdown value del catálogo) y año como String
      // (formato del modelo/backend), materia como int?.
      expect(body, {'tipo': 3, 'materia_id': 8, 'año_academico': '2025'});
    });

    test('materia limpiada sobre original con materia → null explícito', () {
      final body = _bodyUnchanged(materiaId: null);
      expect(body, {'materia_id': null});
    });
  });

  group('documentActionErrorMessage — tabla de errores (R6)', () {
    test('401 → sesión expirada', () {
      expect(
        documentActionErrorMessage(
          const ApiException(statusCode: 401, message: 'token expirado'),
        ),
        'Tu sesión expiró, volvé a iniciar sesión.',
      );
    });

    test('403 → sin permisos', () {
      expect(
        documentActionErrorMessage(
          const ApiException(statusCode: 403, message: 'forbidden'),
        ),
        'No tenés permisos sobre este documento.',
      );
    });

    test('404 → ya no existe', () {
      expect(
        documentActionErrorMessage(
          const ApiException(statusCode: 404, message: 'not found'),
        ),
        'El documento ya no existe.',
      );
    });

    test('otro status → passthrough del message del backend', () {
      expect(
        documentActionErrorMessage(
          const ApiException(
            statusCode: 422,
            message: 'El título es obligatorio',
          ),
        ),
        'El título es obligatorio',
      );
    });

    test('SocketException → sin conexión', () {
      expect(
        documentActionErrorMessage(
          SocketException('Connection refused'),
        ),
        'Verificá tu conexión a internet…',
      );
    });

    test('ClientException de conexión → sin conexión', () {
      expect(
        documentActionErrorMessage(
          http.ClientException('Connection closed during request'),
        ),
        'Verificá tu conexión a internet…',
      );
    });

    test('error no tipado → representación del error (no revienta)', () {
      expect(
        documentActionErrorMessage(StateError('estado roto')),
        contains('estado roto'),
      );
    });
  });
}
