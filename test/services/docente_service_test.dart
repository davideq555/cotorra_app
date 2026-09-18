import 'dart:convert';

import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/models/materia.dart';
import 'package:cotorra_app/models/usuario_materia.dart';
import 'package:cotorra_app/services/api/docente_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

/// Arma una respuesta JSON con el status pedido.
http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _materiaRow = {
  'id': 1,
  'usuario_id': 9,
  'materia_id': 3,
  'tipo_relacion': 'DOCENTE',
  'fecha_relacion': '2026-01-01T00:00:00',
};

void main() {
  late MockHttpClient mockHttp;
  late ApiClient client;
  late DocenteService service;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockHttp = MockHttpClient();
    client = ApiClient(baseUrl: 'http://test-api/api/v1', httpClient: mockHttp);
    client.setToken('test-jwt');
    service = DocenteService(client);
  });

  /// Stub de GET para el client inyectado.
  void stubGet(http.Response response) {
    when(
      () => mockHttp.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => response);
  }

  /// Uri de la última invocación GET registrada en el mock.
  Uri lastGetUri() {
    final captured = verify(
      () => mockHttp.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    return captured.last as Uri;
  }

  group('DocenteService.getMateriasSuscritas', () {
    test(
      'pide GET /materias-suscritas/ con skip/limit y mapea UsuarioMateria',
      () async {
        stubGet(_json([_materiaRow]));

        final rows = await service.getMateriasSuscritas(skip: 20, limit: 50);

        final uri = lastGetUri();
        expect(uri.path, '/api/v1/materias-suscritas/');
        expect(uri.queryParameters['skip'], '20');
        expect(uri.queryParameters['limit'], '50');

        expect(rows, hasLength(1));
        expect(rows.first.id, 1);
        expect(rows.first.usuarioId, 9);
        expect(rows.first.materiaId, 3);
        expect(rows.first.tipoRelacion, 'DOCENTE');
        expect(rows.first.fechaRelacion, '2026-01-01T00:00:00');
      },
    );

    test(
      'usa defaults skip=0 limit=100 cuando no se pasan parámetros',
      () async {
        stubGet(_json([]));

        await service.getMateriasSuscritas();

        final uri = lastGetUri();
        expect(uri.queryParameters['skip'], '0');
        expect(uri.queryParameters['limit'], '100');
      },
    );

    test('respuesta vacía retorna lista vacía, no null', () async {
      stubGet(_json([]));

      final rows = await service.getMateriasSuscritas();

      expect(rows, isEmpty);
    });
  });

  group('DocenteService.getMateriasGestion', () {
    test(
      'pide GET /materias-suscritas/gestion y mapea filas materia completas',
      () async {
        // Forma live-verificada (design addendum): cada fila es un objeto
        // materia completo, no una suscripción usuario↔materia.
        stubGet(
          _json([
            {
              'id': 22,
              'nombre': 'Álgebra I',
              'descripcion': 'Estructuras algebraicas básicas',
              'codigo': 'ALG-1',
            },
            {'id': 23, 'nombre': 'Análisis Matemático', 'codigo': 'ANA-1'},
          ]),
        );

        final materias = await service.getMateriasGestion();

        final uri = lastGetUri();
        expect(uri.path, '/api/v1/materias-suscritas/gestion');
        expect(uri.queryParameters, isEmpty);

        expect(materias, hasLength(2));
        final Materia primera = materias.first;
        expect(primera.id, 22);
        expect(primera.nombre, 'Álgebra I');
        expect(primera.descripcion, 'Estructuras algebraicas básicas');
        expect(primera.codigo, 'ALG-1');
        expect(materias[1].descripcion, isNull);
        expect(materias[1].codigo, 'ANA-1');
      },
    );

    test('respuesta vacía retorna lista vacía, no null', () async {
      stubGet(_json([]));

      final materias = await service.getMateriasGestion();

      expect(materias, isEmpty);
    });

    test('403 fuera de scope lanza ApiException con statusCode', () async {
      stubGet(_json({'detail': 'No sos docente'}, 403));

      await expectLater(
        service.getMateriasGestion(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('DocenteService.getDocumentosMateria', () {
    test(
      'pide GET /docente/materias/{id}/documentos y mapea Documento',
      () async {
        stubGet(
          _json([
            {
              'id': 11,
              'titulo': 'Parcial 1',
              'archivo_url': 'http://files/p1.pdf',
              'tipo': 1,
              'usuario_id': 9,
              'aprobado': false,
              'materia_id': 7,
            },
          ]),
        );

        final docs = await service.getDocumentosMateria(7);

        final uri = lastGetUri();
        expect(uri.path, '/api/v1/docente/materias/7/documentos');
        expect(uri.queryParameters.containsKey('estado'), isFalse);

        expect(docs, hasLength(1));
        final Documento doc = docs.first;
        expect(doc.id, 11);
        expect(doc.titulo, 'Parcial 1');
        expect(doc.aprobado, isFalse);
      },
    );

    test(
      'envía estado solo cuando se especifica (passthrough opcional)',
      () async {
        stubGet(_json([]));

        await service.getDocumentosMateria(7, estado: 'pendiente');

        final uri = lastGetUri();
        expect(uri.queryParameters['estado'], 'pendiente');
      },
    );
  });

  group('UsuarioMateria (DTO)', () {
    test('fromJson mapea todas las columnas del contrato', () {
      final um = UsuarioMateria.fromJson(_materiaRow);

      expect(um.id, 1);
      expect(um.usuarioId, 9);
      expect(um.materiaId, 3);
      expect(um.tipoRelacion, 'DOCENTE');
      expect(um.fechaRelacion, '2026-01-01T00:00:00');
    });

    test('toJson round-trée con fromJson', () {
      final um = UsuarioMateria.fromJson(_materiaRow);

      expect(UsuarioMateria.fromJson(um.toJson()).tipoRelacion, 'DOCENTE');
      expect(um.toJson()['materia_id'], 3);
    });
  });
}
