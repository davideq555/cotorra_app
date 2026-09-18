import 'dart:convert';

import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/services/api/admin_service.dart';
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

void main() {
  late MockHttpClient mockHttp;
  late AdminService service;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockHttp = MockHttpClient();
    final client = ApiClient(
      baseUrl: 'http://test-api/api/v1',
      httpClient: mockHttp,
    );
    client.setToken('test-jwt');
    service = AdminService(client);
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

  group('AdminService.getDocumentos', () {
    test(
      'pide GET /admin/documentos con defaults skip=0 limit=20 estado=todos',
      () async {
        stubGet(
          _json({
            'items': [],
            'meta': {'total': 0, 'skip': 0, 'limit': 20, 'has_more': false},
          }),
        );

        await service.getDocumentos();

        final uri = lastGetUri();
        expect(uri.path, '/api/v1/admin/documentos');
        expect(uri.queryParameters['skip'], '0');
        expect(uri.queryParameters['limit'], '20');
        expect(uri.queryParameters['estado'], 'todos');
      },
    );

    test('envía skip/limit y un estado explícito (pendientes)', () async {
      stubGet(
        _json({
          'items': [],
          'meta': {'total': 0, 'skip': 40, 'limit': 10, 'has_more': true},
        }),
      );

      await service.getDocumentos(skip: 40, limit: 10, estado: 'pendientes');

      final uri = lastGetUri();
      expect(uri.path, '/api/v1/admin/documentos');
      expect(uri.queryParameters['skip'], '40');
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['estado'], 'pendientes');
    });

    test(
      'mapea el sobre paginado {items, meta} y cada item a Documento',
      () async {
        stubGet(
          _json({
            'items': [
              {
                'id': 11,
                'titulo': 'Parcial 1',
                'archivo_url': 'http://files/p1.pdf',
                'tipo': 1,
                'usuario_id': 9,
                'aprobado': false,
                'materia_id': 7,
              },
              {
                'id': 12,
                'titulo': 'Resumen 2',
                'archivo_url': 'http://files/r2.pdf',
                'tipo': 1,
                'usuario_id': 9,
                'aprobado': true,
                'materia_id': 7,
              },
            ],
            'meta': {'total': 42, 'skip': 0, 'limit': 20, 'has_more': true},
          }),
        );

        final page = await service.getDocumentos();

        expect(page.items, hasLength(2));
        expect(page.meta.total, 42);
        expect(page.meta.hasMore, isTrue);

        final Documento primero = Documento.fromJson(
          page.items.first as Map<String, dynamic>,
        );
        expect(primero.id, 11);
        expect(primero.titulo, 'Parcial 1');
        expect(primero.aprobado, isFalse);
        expect(primero.materiaId, 7);
      },
    );

    test('sobre vacío sin meta no rompe el mapeo', () async {
      stubGet(_json({'items': []}));

      final page = await service.getDocumentos();

      expect(page.items, isEmpty);
      expect(page.meta.total, 0);
      expect(page.meta.hasMore, isFalse);
    });
  });
}
